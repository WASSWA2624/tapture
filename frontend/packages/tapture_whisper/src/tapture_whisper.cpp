// tapture_whisper ABI v1: the C shim over whisper.cpp 1.9.4 and ggml 0.23.0.
//
// app-write-up §30.4.1 is the contract; dev-plan task 103 builds it. The
// shim owns every allocation it returns, verifies every model by size and
// SHA-256 before whisper.cpp parses a byte of it, keeps an explicit
// whisper_state per context, aborts per graph node through patch 0001 and a
// shared cell, and never logs a model path or transcript text.
//
// TW_ENGINE=0 builds the stub library for architectures without an engine:
// the ABI, struct, cell, SHA-256, log, CPU and memory functions work and every
// open returns TW_ERR_ENGINE_NOT_BUILT.

#include "tapture_whisper.h"
#include "tw_sha256.h"

#include <algorithm>
#include <atomic>
#include <cfloat>
#include <chrono>
#include <cmath>
#include <cstddef>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <mutex>
#include <new>
#include <string>
#include <thread>
#include <vector>

#ifndef TW_ENGINE
#define TW_ENGINE 1
#endif

#if TW_ENGINE
#include "ggml.h"
#include "whisper.h"
#endif

#if defined(_WIN32)
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#include <io.h>
#include <share.h>
#include <sys/stat.h>
#include <sys/types.h>
#else
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>
#endif

#if defined(__APPLE__)
#include <TargetConditionals.h>
#include <mach/mach.h>
#include <sys/sysctl.h>
#if TARGET_OS_IPHONE
#include <os/proc.h>
#endif
#endif

#if (defined(__linux__) || defined(__ANDROID__)) && \
    (defined(__aarch64__) || defined(__arm__))
#include <sys/auxv.h>
#endif

#if defined(_MSC_VER) && (defined(_M_X64) || defined(_M_IX86))
#include <intrin.h>
#define TW_X86 1
#elif defined(__x86_64__) || defined(__i386__)
#include <cpuid.h>
#define TW_X86 1
#else
#define TW_X86 0
#endif

// ---------------------------------------------------------------------------
// Layout: every struct is pinned to the size the header publishes, so the
// Dart bindings and the WebAssembly worker can trust TW_SIZEOF_*.
// ---------------------------------------------------------------------------

static_assert(sizeof(tw_context_options) == TW_SIZEOF_CONTEXT_OPTIONS, "layout");
static_assert(sizeof(tw_transcribe_options) == TW_SIZEOF_TRANSCRIBE_OPTIONS, "layout");
static_assert(sizeof(tw_cpu_info) == TW_SIZEOF_CPU_INFO, "layout");
static_assert(sizeof(tw_memory_info) == TW_SIZEOF_MEMORY_INFO, "layout");
static_assert(sizeof(tw_model_facts) == TW_SIZEOF_MODEL_FACTS, "layout");
static_assert(sizeof(tw_segment) == TW_SIZEOF_SEGMENT, "layout");
static_assert(sizeof(tw_token) == TW_SIZEOF_TOKEN, "layout");
static_assert(sizeof(tw_span) == TW_SIZEOF_SPAN, "layout");
static_assert(sizeof(tw_log_entry) == TW_SIZEOF_LOG_ENTRY, "layout");
static_assert(sizeof(tw_vad_options) == TW_SIZEOF_VAD_OPTIONS, "layout");

static_assert(alignof(tw_context_options) == 4, "layout");
static_assert(alignof(tw_transcribe_options) == 4, "layout");
static_assert(alignof(tw_cpu_info) == 8, "layout");
static_assert(alignof(tw_memory_info) == 8, "layout");
static_assert(alignof(tw_model_facts) == 4, "layout");
static_assert(alignof(tw_segment) == 8, "layout");
static_assert(alignof(tw_token) == 8, "layout");
static_assert(alignof(tw_span) == 8, "layout");
static_assert(alignof(tw_log_entry) == 4, "layout");
static_assert(alignof(tw_vad_options) == 4, "layout");

static_assert(offsetof(tw_context_options, flash_attn) == 9, "layout");
static_assert(offsetof(tw_transcribe_options, n_max_text_ctx) == 28, "layout");
static_assert(offsetof(tw_transcribe_options, temperature) == 32, "layout");
static_assert(offsetof(tw_transcribe_options, token_thold_ptsum) == 64, "layout");
static_assert(offsetof(tw_transcribe_options, translate) == 68, "layout");
static_assert(offsetof(tw_transcribe_options, carry_initial_prompt) == 75, "layout");
static_assert(offsetof(tw_transcribe_options, language) == 76, "layout");
static_assert(offsetof(tw_cpu_info, runtime_features) == 16, "layout");
static_assert(offsetof(tw_cpu_info, supported) == 32, "layout");
static_assert(offsetof(tw_memory_info, total_bytes) == 8, "layout");
static_assert(offsetof(tw_model_facts, multilingual) == 52, "layout");
static_assert(offsetof(tw_segment, text_offset) == 16, "layout");
static_assert(offsetof(tw_segment, no_speech_prob) == 32, "layout");
static_assert(offsetof(tw_token, p) == 12, "layout");
static_assert(offsetof(tw_token, t0_ms) == 16, "layout");
static_assert(offsetof(tw_log_entry, text) == 8, "layout");
static_assert(offsetof(tw_vad_options, samples_overlap_s) == 24, "layout");

static_assert(sizeof(std::atomic<int32_t>) == sizeof(int32_t), "cell layout");

namespace {

// ---------------------------------------------------------------------------
// Live-object counters.
// ---------------------------------------------------------------------------

constexpr int kObjectKinds = 6;
std::atomic<int32_t> g_live[kObjectKinds];

void tw_count(tw_object_kind kind, int32_t delta) {
  g_live[kind].fetch_add(delta, std::memory_order_relaxed);
}

// ---------------------------------------------------------------------------
// Logging: a filtered, mutex-guarded ring of the last 256 kept lines.
// ---------------------------------------------------------------------------

struct tw_log_ring {
  std::mutex mutex;
  tw_log_entry entries[TW_LOG_RING_CAPACITY];
  int32_t head = 0;  // index of the oldest entry
  int32_t count = 0;
};

tw_log_ring g_ring;
std::atomic<uint32_t> g_log_dropped{0};
std::atomic<int32_t> g_log_min_level{TW_LOG_WARN};

void tw_log_push(int32_t level, const char* text, size_t length) {
  while (length > 0 && (text[length - 1] == '\n' || text[length - 1] == '\r')) {
    length--;
  }
  if (length == 0) {
    return;
  }
  if (length > TW_LOG_TEXT_CAPACITY - 1) {
    length = TW_LOG_TEXT_CAPACITY - 1;
  }
  std::lock_guard<std::mutex> lock(g_ring.mutex);
  int32_t slot;
  if (g_ring.count == TW_LOG_RING_CAPACITY) {
    slot = g_ring.head;
    g_ring.head = (g_ring.head + 1) % TW_LOG_RING_CAPACITY;
    g_log_dropped.fetch_add(1, std::memory_order_relaxed);
  } else {
    slot = (g_ring.head + g_ring.count) % TW_LOG_RING_CAPACITY;
    g_ring.count++;
  }
  tw_log_entry& entry = g_ring.entries[slot];
  entry.level = level;
  entry.length = static_cast<int32_t>(length);
  std::memcpy(entry.text, text, length);
  entry.text[length] = '\0';
}

// Records one of the shim's own lines, prefixed "tapture_whisper:". Callers
// pass only fixed text and numbers: never a path, a prompt or a transcript.
void tw_log_own(int32_t level, const char* format, int32_t value) {
  if (level < g_log_min_level.load(std::memory_order_relaxed)) {
    return;
  }
  char line[TW_LOG_TEXT_CAPACITY];
  const int n = std::snprintf(line, sizeof(line), "tapture_whisper: ");
  std::snprintf(line + n, sizeof(line) - static_cast<size_t>(n), format, value);
  tw_log_push(level, line, std::strlen(line));
}

#if TW_ENGINE
// Sink for whisper and ggml. DEBUG lines (which carry decoded prompt text) and
// continuation fragments are dropped, then anything below the minimum level.
void tw_log_sink(enum ggml_log_level level, const char* text, void* user) {
  (void)user;
  if (text == nullptr || level == GGML_LOG_LEVEL_DEBUG ||
      level == GGML_LOG_LEVEL_CONT || level == GGML_LOG_LEVEL_NONE) {
    return;
  }
  if (static_cast<int32_t>(level) < g_log_min_level.load(std::memory_order_relaxed)) {
    return;
  }
  tw_log_push(static_cast<int32_t>(level), text, std::strlen(text));
}
#endif

// ---------------------------------------------------------------------------
// Crash file: ggml's last words before abort(), for the next launch to read.
// ---------------------------------------------------------------------------

std::mutex g_crash_mutex;
std::string g_crash_path;

#if defined(_WIN32)
bool tw_utf8_to_wide(const char* utf8, std::wstring* out) {
  const int n = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, utf8, -1, nullptr, 0);
  if (n <= 0) {
    return false;
  }
  out->assign(static_cast<size_t>(n), L'\0');
  if (MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, utf8, -1, &(*out)[0], n) != n) {
    return false;
  }
  out->resize(static_cast<size_t>(n - 1));
  return true;
}
#endif

[[maybe_unused]] FILE* tw_open_append(const std::string& path) {
#if defined(_WIN32)
  std::wstring wide;
  if (!tw_utf8_to_wide(path.c_str(), &wide)) {
    return nullptr;
  }
  return _wfopen(wide.c_str(), L"ab");
#else
  return std::fopen(path.c_str(), "ab");
#endif
}

#if TW_ENGINE
void tw_on_ggml_abort(const char* message) {
  const char* text = message != nullptr ? message : "ggml abort";
  tw_log_push(TW_LOG_ERROR, text, std::strlen(text));
  std::lock_guard<std::mutex> lock(g_crash_mutex);
  if (g_crash_path.empty()) {
    return;
  }
  FILE* file = tw_open_append(g_crash_path);
  if (file == nullptr) {
    return;
  }
  const long long now_ms = static_cast<long long>(
      std::chrono::duration_cast<std::chrono::milliseconds>(
          std::chrono::system_clock::now().time_since_epoch())
          .count());
  std::fprintf(file, "%lld\t%s\n", now_ms, text);
  std::fclose(file);
}
#endif

// ---------------------------------------------------------------------------
// One-time initialisation of whatever touches whisper or ggml.
// ---------------------------------------------------------------------------

std::once_flag g_init_once;

void tw_init() {
  std::call_once(g_init_once, [] {
#if defined(_MSC_VER)
    _set_abort_behavior(0, _WRITE_ABORT_MSG | _CALL_REPORTFAULT);
#endif
#if TW_ENGINE
    whisper_log_set(tw_log_sink, nullptr);
    ggml_set_abort_callback(tw_on_ggml_abort);
#endif
  });
}

// ---------------------------------------------------------------------------
// CPU and memory probes.
// ---------------------------------------------------------------------------

int32_t tw_logical_threads() {
  const unsigned n = std::thread::hardware_concurrency();
  return n == 0 ? 1 : static_cast<int32_t>(n);
}

int32_t tw_max_threads() {
#if defined(__EMSCRIPTEN__) && !defined(TW_WASM_THREADS)
  return 1;
#else
  return std::min<int32_t>(tw_logical_threads(), TW_MAX_THREADS);
#endif
}

[[maybe_unused]] int32_t tw_clamp_threads(int32_t requested) {
  return std::max<int32_t>(1, std::min<int32_t>(requested, tw_max_threads()));
}

uint32_t tw_arch_now() {
#if defined(__x86_64__) || defined(_M_X64)
  return TW_ARCH_X86_64;
#elif defined(__aarch64__) || defined(_M_ARM64)
  return TW_ARCH_ARM64;
#elif defined(__arm__) || defined(_M_ARM)
  return TW_ARCH_ARM32;
#elif defined(__wasm32__)
  return TW_ARCH_WASM32;
#elif defined(__i386__) || defined(_M_IX86)
  return TW_ARCH_X86;
#else
  return TW_ARCH_UNKNOWN;
#endif
}

// What the compiler targets, for builds that do not pass TW_REQUIRED_FEATURES
// (the Darwin forwarders): CMake builds pass the ggml-cpu mask instead,
// because this file itself is compiled without architecture flags.
constexpr uint64_t tw_compiled_features() {
  return 0
#if defined(__SSE3__)
         | TW_CPU_SSE3
#endif
#if defined(__SSSE3__)
         | TW_CPU_SSSE3
#endif
#if defined(__SSE4_2__)
         | TW_CPU_SSE42
#endif
#if defined(__AVX__)
         | TW_CPU_AVX
#endif
#if defined(__AVX2__)
         | TW_CPU_AVX2
#endif
#if defined(__FMA__)
         | TW_CPU_FMA
#endif
#if defined(__F16C__)
         | TW_CPU_F16C
#endif
#if defined(__BMI2__)
         | TW_CPU_BMI2
#endif
#if defined(__ARM_NEON) && defined(__aarch64__)
         | TW_CPU_NEON
#endif
#if defined(__ARM_FEATURE_DOTPROD)
         | TW_CPU_DOTPROD
#endif
#if defined(__ARM_FEATURE_FP16_VECTOR_ARITHMETIC)
         | TW_CPU_FP16_VA
#endif
#if defined(__ARM_FEATURE_MATMUL_INT8)
         | TW_CPU_I8MM
#endif
#if defined(__wasm_simd128__)
         | TW_CPU_WASM_SIMD
#endif
      ;
}

#ifdef TW_REQUIRED_FEATURES
constexpr uint64_t kRequiredFeatures = TW_REQUIRED_FEATURES;
#else
constexpr uint64_t kRequiredFeatures = tw_compiled_features();
#endif

#if TW_X86
void tw_cpuid(uint32_t leaf, uint32_t subleaf, uint32_t regs[4]) {
#if defined(_MSC_VER)
  int out[4];
  __cpuidex(out, static_cast<int>(leaf), static_cast<int>(subleaf));
  for (int i = 0; i < 4; i++) {
    regs[i] = static_cast<uint32_t>(out[i]);
  }
#else
  unsigned a = 0, b = 0, c = 0, d = 0;
  if (!__get_cpuid_count(leaf, subleaf, &a, &b, &c, &d)) {
    a = b = c = d = 0;
  }
  regs[0] = a;
  regs[1] = b;
  regs[2] = c;
  regs[3] = d;
#endif
}

uint64_t tw_xcr0() {
#if defined(_MSC_VER)
  return _xgetbv(0);
#else
  uint32_t eax = 0, edx = 0;
  __asm__ volatile(".byte 0x0f, 0x01, 0xd0" : "=a"(eax), "=d"(edx) : "c"(0));
  return (static_cast<uint64_t>(edx) << 32) | eax;
#endif
}
#endif

uint64_t tw_runtime_features() {
  uint64_t features = 0;
#if TW_X86
  uint32_t r[4];
  tw_cpuid(0, 0, r);
  const uint32_t max_leaf = r[0];
  tw_cpuid(1, 0, r);
  const uint32_t ecx1 = r[2];
  if (ecx1 & (1u << 0)) features |= TW_CPU_SSE3;
  if (ecx1 & (1u << 9)) features |= TW_CPU_SSSE3;
  if (ecx1 & (1u << 20)) features |= TW_CPU_SSE42;
  const bool osxsave = (ecx1 & (1u << 27)) != 0;
  const uint64_t xcr0 = osxsave ? tw_xcr0() : 0;
  const bool avx_state = (xcr0 & 6u) == 6u;
  const bool avx512_state = (xcr0 & 0xE6u) == 0xE6u;
  if (avx_state) {
    if (ecx1 & (1u << 28)) features |= TW_CPU_AVX;
    if (ecx1 & (1u << 12)) features |= TW_CPU_FMA;
    if (ecx1 & (1u << 29)) features |= TW_CPU_F16C;
  }
  if (max_leaf >= 7) {
    tw_cpuid(7, 0, r);
    const uint32_t ebx7 = r[1];
    const uint32_t max_sub7 = r[0];
    if (ebx7 & (1u << 8)) features |= TW_CPU_BMI2;
    if (avx_state && (ebx7 & (1u << 5))) features |= TW_CPU_AVX2;
    if (avx512_state && (ebx7 & (1u << 16))) features |= TW_CPU_AVX512F;
    if (max_sub7 >= 1) {
      tw_cpuid(7, 1, r);
      if (avx_state && (r[0] & (1u << 4))) features |= TW_CPU_AVX_VNNI;
    }
  }
#elif (defined(__linux__) || defined(__ANDROID__)) && defined(__aarch64__)
  const unsigned long hwcap = getauxval(AT_HWCAP);
  const unsigned long hwcap2 = getauxval(AT_HWCAP2);
  if (hwcap & (1ul << 1)) features |= TW_CPU_NEON | TW_CPU_ARM_FMA;  // ASIMD
  if ((hwcap & (1ul << 9)) && (hwcap & (1ul << 10))) features |= TW_CPU_FP16_VA;
  if (hwcap & (1ul << 20)) features |= TW_CPU_DOTPROD;  // ASIMDDP
  if (hwcap & (1ul << 22)) features |= TW_CPU_SVE;
  if (hwcap2 & (1ul << 13)) features |= TW_CPU_I8MM;
  if (hwcap2 & (1ul << 23)) features |= TW_CPU_SME;
#elif (defined(__linux__) || defined(__ANDROID__)) && defined(__arm__)
  const unsigned long hwcap = getauxval(AT_HWCAP);
  if (hwcap & (1ul << 12)) features |= TW_CPU_NEON;  // HWCAP_NEON
  if (hwcap & (1ul << 16)) features |= TW_CPU_ARM_FMA;  // HWCAP_VFPv4
#elif defined(__APPLE__) && defined(__aarch64__)
  auto has = [](const char* name) {
    int value = 0;
    size_t size = sizeof(value);
    return sysctlbyname(name, &value, &size, nullptr, 0) == 0 && value != 0;
  };
  features |= TW_CPU_NEON | TW_CPU_ARM_FMA;
  if (has("hw.optional.arm.FEAT_FP16")) features |= TW_CPU_FP16_VA;
  if (has("hw.optional.arm.FEAT_DotProd")) features |= TW_CPU_DOTPROD;
  if (has("hw.optional.arm.FEAT_I8MM")) features |= TW_CPU_I8MM;
  if (has("hw.optional.arm.FEAT_SME")) features |= TW_CPU_SME;
#elif defined(__wasm32__)
#if defined(__wasm_simd128__)
  features |= TW_CPU_WASM_SIMD;  // the module would not have validated without it
#endif
#endif
  return features;
}

#if defined(__linux__) || defined(__ANDROID__)
long long tw_read_number(const char* path) {
  FILE* file = std::fopen(path, "r");
  if (file == nullptr) {
    return -1;
  }
  long long value = -1;
  if (std::fscanf(file, "%lld", &value) != 1) {
    value = -1;
  }
  std::fclose(file);
  return value;
}
#endif

int32_t tw_performance_cores(int32_t n_logical) {
#if defined(_WIN32)
  DWORD length = 0;
  GetLogicalProcessorInformationEx(RelationProcessorCore, nullptr, &length);
  if (length == 0) {
    return n_logical;
  }
  std::vector<uint8_t> buffer(length);
  auto* first = reinterpret_cast<PSYSTEM_LOGICAL_PROCESSOR_INFORMATION_EX>(buffer.data());
  if (!GetLogicalProcessorInformationEx(RelationProcessorCore, first, &length)) {
    return n_logical;
  }
  int32_t best_class = -1;
  int32_t cores = 0;
  for (DWORD offset = 0; offset < length;) {
    auto* info = reinterpret_cast<PSYSTEM_LOGICAL_PROCESSOR_INFORMATION_EX>(buffer.data() + offset);
    if (info->Relationship == RelationProcessorCore) {
      const int32_t efficiency = info->Processor.EfficiencyClass;
      if (efficiency > best_class) {
        best_class = efficiency;
        cores = 1;
      } else if (efficiency == best_class) {
        cores++;
      }
    }
    if (info->Size == 0) {
      break;
    }
    offset += info->Size;
  }
  return cores > 0 ? cores : n_logical;
#elif defined(__linux__) || defined(__ANDROID__)
  struct cpu {
    long long max_freq;
    long long core_id;
    long long package_id;
  };
  std::vector<cpu> cpus;
  long long top = 0;
  for (int32_t i = 0; i < n_logical && i < 1024; i++) {
    char path[128];
    std::snprintf(path, sizeof(path), "/sys/devices/system/cpu/cpu%d/cpufreq/cpuinfo_max_freq", i);
    const long long freq = tw_read_number(path);
    std::snprintf(path, sizeof(path), "/sys/devices/system/cpu/cpu%d/topology/core_id", i);
    const long long core = tw_read_number(path);
    std::snprintf(path, sizeof(path), "/sys/devices/system/cpu/cpu%d/topology/physical_package_id", i);
    const long long package = tw_read_number(path);
    cpus.push_back({freq, core, package});
    top = std::max(top, freq);
  }
  if (top <= 0) {
    return n_logical;
  }
  std::vector<std::pair<long long, long long>> seen;
  for (const cpu& c : cpus) {
    if (c.max_freq * 10 < top * 8) {
      continue;
    }
    const std::pair<long long, long long> key{c.package_id, c.core_id < 0 ? static_cast<long long>(seen.size()) + 100000 : c.core_id};
    if (std::find(seen.begin(), seen.end(), key) == seen.end()) {
      seen.push_back(key);
    }
  }
  return seen.empty() ? n_logical : static_cast<int32_t>(seen.size());
#elif defined(__APPLE__)
  int value = 0;
  size_t size = sizeof(value);
  if (sysctlbyname("hw.perflevel0.physicalcpu", &value, &size, nullptr, 0) == 0 && value > 0) {
    return value;
  }
  size = sizeof(value);
  if (sysctlbyname("hw.physicalcpu", &value, &size, nullptr, 0) == 0 && value > 0) {
    return value;
  }
  return n_logical;
#else
  return n_logical;
#endif
}

std::atomic<bool> g_cpu_forced_unsupported{false};

bool tw_engine_supported() {
  if (!TW_ENGINE || g_cpu_forced_unsupported.load()) {
    return false;
  }
  return (tw_runtime_features() & kRequiredFeatures) == kRequiredFeatures;
}

void tw_fill_memory(tw_memory_info* out) {
  out->reserved = 0;
  out->total_bytes = -1;
  out->available_bytes = -1;
  out->process_limit_bytes = -1;
#if defined(_WIN32)
  MEMORYSTATUSEX status;
  status.dwLength = sizeof(status);
  if (GlobalMemoryStatusEx(&status)) {
    out->total_bytes = static_cast<int64_t>(status.ullTotalPhys);
    out->available_bytes = static_cast<int64_t>(status.ullAvailPhys);
  }
#elif defined(__linux__) || defined(__ANDROID__)
  FILE* file = std::fopen("/proc/meminfo", "r");
  if (file != nullptr) {
    char line[256];
    while (std::fgets(line, sizeof(line), file) != nullptr) {
      long long kib = 0;
      if (std::sscanf(line, "MemTotal: %lld kB", &kib) == 1) {
        out->total_bytes = kib * 1024;
      } else if (std::sscanf(line, "MemAvailable: %lld kB", &kib) == 1) {
        out->available_bytes = kib * 1024;
      }
    }
    std::fclose(file);
  }
#elif defined(__APPLE__)
  uint64_t memsize = 0;
  size_t size = sizeof(memsize);
  if (sysctlbyname("hw.memsize", &memsize, &size, nullptr, 0) == 0) {
    out->total_bytes = static_cast<int64_t>(memsize);
  }
  vm_statistics64_data_t stats;
  mach_msg_type_number_t count = HOST_VM_INFO64_COUNT;
  if (host_statistics64(mach_host_self(), HOST_VM_INFO64,
                        reinterpret_cast<host_info64_t>(&stats), &count) == KERN_SUCCESS) {
    vm_size_t page = 0;
    host_page_size(mach_host_self(), &page);
    out->available_bytes = static_cast<int64_t>(
        (static_cast<uint64_t>(stats.free_count) + stats.inactive_count + stats.purgeable_count) * page);
  }
#if TARGET_OS_IPHONE
  out->process_limit_bytes = static_cast<int64_t>(os_proc_available_memory());
#endif
#endif
}

// ---------------------------------------------------------------------------
// Abort cells: an atomic value first, so the int32_t* handed out is the value
// itself (JavaScript Atomics use the same address on WebAssembly threads).
// ---------------------------------------------------------------------------

struct tw_cell_block {
  std::atomic<int32_t> value{0};
  std::atomic<int32_t> references{1};
};
static_assert(offsetof(tw_cell_block, value) == 0, "cell layout");

tw_cell_block* tw_cell_of(const int32_t* cell) {
  return reinterpret_cast<tw_cell_block*>(const_cast<int32_t*>(cell));
}

[[maybe_unused]] bool tw_cell_reached(const int32_t* cell, int32_t job_id) {
  return cell != nullptr && job_id > 0 &&
         tw_cell_of(cell)->value.load(std::memory_order_acquire) >= job_id;
}

// ---------------------------------------------------------------------------
// Handle gate: one call at a time per handle, and a close that arrives during
// a call is carried out by that call when it leaves.
// ---------------------------------------------------------------------------

constexpr uint32_t kBusy = 1;
constexpr uint32_t kClosing = 2;

template <typename T>
bool tw_enter(T* handle) {
  uint32_t current = handle->flags.load(std::memory_order_acquire);
  do {
    if (current & (kBusy | kClosing)) {
      return false;
    }
  } while (!handle->flags.compare_exchange_weak(current, current | kBusy, std::memory_order_acq_rel));
  return true;
}

// Returns true when the caller must now destroy the handle.
template <typename T>
bool tw_leave(T* handle) {
  const uint32_t previous = handle->flags.fetch_and(~kBusy, std::memory_order_acq_rel);
  return (previous & kClosing) != 0;
}

// Returns true when the caller must destroy the handle now.
template <typename T>
bool tw_request_close(T* handle) {
  const uint32_t previous = handle->flags.fetch_or(kClosing, std::memory_order_acq_rel);
  return (previous & kBusy) == 0;
}

#if TW_ENGINE
// ---------------------------------------------------------------------------
// Verified model sources: one handle is sized, hashed, checked for the magic
// and then parsed, so the bytes that are parsed are the bytes that were hashed.
// ---------------------------------------------------------------------------

constexpr uint8_t kGgmlMagic[4] = {0x6C, 0x6D, 0x67, 0x67};  // 0x67676d6c LE
constexpr size_t kHashChunk = 64 * 1024;

class tw_source {
 public:
  virtual ~tw_source() = default;
  virtual int64_t size() const = 0;
  virtual bool rewind() = 0;
  virtual size_t read(void* destination, size_t n) = 0;
  virtual bool at_end() const = 0;
};

class tw_file_source final : public tw_source {
 public:
  tw_file_source() = default;
  tw_file_source(const tw_file_source&) = delete;
  tw_file_source& operator=(const tw_file_source&) = delete;
  ~tw_file_source() override {
    if (file_ != nullptr) {
      std::fclose(file_);
    }
  }

  // Opens path_utf8 for reading and denies writers for as long as it is open
  // (Windows). Returns TW_OK, TW_ERR_INVALID_ARGUMENT or TW_ERR_FILE_OPEN.
  int32_t open(const char* path_utf8) {
#if defined(_WIN32)
    std::wstring wide;
    if (!tw_utf8_to_wide(path_utf8, &wide)) {
      return TW_ERR_INVALID_ARGUMENT;
    }
    file_ = _wfsopen(wide.c_str(), L"rb", _SH_DENYWR);
    if (file_ == nullptr) {
      return TW_ERR_FILE_OPEN;
    }
    struct _stat64 status;
    if (_fstat64(_fileno(file_), &status) != 0 || (status.st_mode & _S_IFREG) == 0) {
      return TW_ERR_FILE_OPEN;
    }
    size_ = static_cast<int64_t>(status.st_size);
#else
    const int fd = ::open(path_utf8, O_RDONLY | O_CLOEXEC);
    if (fd < 0) {
      return TW_ERR_FILE_OPEN;
    }
    struct stat status;
    if (fstat(fd, &status) != 0 || !S_ISREG(status.st_mode)) {
      ::close(fd);
      return TW_ERR_FILE_OPEN;
    }
    file_ = fdopen(fd, "rb");
    if (file_ == nullptr) {
      ::close(fd);
      return TW_ERR_FILE_OPEN;
    }
    size_ = static_cast<int64_t>(status.st_size);
#endif
    return TW_OK;
  }

  int64_t size() const override { return size_; }

  bool rewind() override {
    std::clearerr(file_);
    return std::fseek(file_, 0, SEEK_SET) == 0;
  }

  size_t read(void* destination, size_t n) override {
    return std::fread(destination, 1, n, file_);
  }

  bool at_end() const override { return std::feof(file_) != 0; }

 private:
  FILE* file_ = nullptr;
  int64_t size_ = -1;
};

class tw_buffer_source final : public tw_source {
 public:
  tw_buffer_source(const void* data, size_t size)
      : data_(static_cast<const uint8_t*>(data)), size_(size) {}

  int64_t size() const override { return static_cast<int64_t>(size_); }

  bool rewind() override {
    position_ = 0;
    return true;
  }

  size_t read(void* destination, size_t n) override {
    const size_t take = std::min(n, size_ - position_);
    if (take > 0) {
      std::memcpy(destination, data_ + position_, take);
    }
    position_ += take;
    return take;
  }

  bool at_end() const override { return position_ >= size_; }

 private:
  const uint8_t* data_;
  size_t size_;
  size_t position_ = 0;
};

// Size check (expected_bytes < 0 skips it), streamed SHA-256 (a null sha
// skips it), then the magic. Leaves the source rewound to byte 0.
int32_t tw_verify(tw_source& source, int64_t expected_bytes, const uint8_t* expected_sha256) {
  if (expected_bytes >= 0 && source.size() != expected_bytes) {
    tw_log_own(TW_LOG_WARN, "model size differs from the expectation (%d)", TW_ERR_MODEL_MISMATCH);
    return TW_ERR_MODEL_MISMATCH;
  }
  if (expected_sha256 != nullptr) {
    std::vector<uint8_t> chunk(kHashChunk);
    tw_sha256_state state;
    tw_sha256_state_begin(&state);
    int64_t total = 0;
    for (;;) {
      const size_t n = source.read(chunk.data(), chunk.size());
      if (n == 0) {
        break;
      }
      tw_sha256_state_feed(&state, chunk.data(), n);
      total += static_cast<int64_t>(n);
    }
    uint8_t digest[TW_SHA256_BYTES];
    tw_sha256_state_end(&state, digest);
    if (total != source.size()) {
      return TW_ERR_FILE_OPEN;
    }
    uint8_t difference = 0;
    for (int i = 0; i < TW_SHA256_BYTES; i++) {
      difference |= static_cast<uint8_t>(digest[i] ^ expected_sha256[i]);
    }
    if (difference != 0) {
      tw_log_own(TW_LOG_WARN, "model SHA-256 differs from the expectation (%d)", TW_ERR_MODEL_MISMATCH);
      return TW_ERR_MODEL_MISMATCH;
    }
  }
  uint8_t magic[4] = {0, 0, 0, 0};
  if (!source.rewind()) {
    return TW_ERR_FILE_OPEN;
  }
  if (source.read(magic, sizeof(magic)) != sizeof(magic) ||
      std::memcmp(magic, kGgmlMagic, sizeof(magic)) != 0) {
    tw_log_own(TW_LOG_WARN, "model has no ggml magic (%d)", TW_ERR_MODEL_INVALID);
    return TW_ERR_MODEL_INVALID;
  }
  return source.rewind() ? TW_OK : TW_ERR_FILE_OPEN;
}
#endif  // TW_ENGINE

int32_t tw_check_open_options(const tw_context_options* options) {
  if (options == nullptr) {
    return TW_ERR_INVALID_ARGUMENT;
  }
  if (options->struct_size != sizeof(tw_context_options)) {
    return TW_ERR_ABI_MISMATCH;
  }
  if (options->use_gpu != 0) {
    return TW_ERR_INVALID_ARGUMENT;
  }
  return TW_OK;
}

// Shared front of every open: arguments, the engine and the CPU.
int32_t tw_open_preflight(const tw_context_options* options) {
  if (!TW_ENGINE) {
    return TW_ERR_ENGINE_NOT_BUILT;
  }
  const int32_t status = tw_check_open_options(options);
  if (status != TW_OK) {
    return status;
  }
  if (!tw_engine_supported()) {
    return TW_ERR_UNSUPPORTED_CPU;
  }
  tw_init();
  return TW_OK;
}

#if TW_ENGINE
whisper_model_loader tw_loader_over(tw_source* source) {
  whisper_model_loader loader;
  loader.context = source;
  loader.read = [](void* context, void* output, size_t n) -> size_t {
    return static_cast<tw_source*>(context)->read(output, n);
  };
  loader.eof = [](void* context) -> bool {
    return static_cast<tw_source*>(context)->at_end();
  };
  loader.close = [](void* context) { (void)context; };  // the shim closes the handle
  return loader;
}
#endif

// ---------------------------------------------------------------------------
// Languages: codes only, without whisper_lang_id's log line for unknown input.
// ---------------------------------------------------------------------------

int32_t tw_language_index(const char* code) {
#if TW_ENGINE
  if (code == nullptr || code[0] == '\0') {
    return -1;
  }
  for (int32_t id = 0; id <= whisper_lang_max_id(); id++) {
    const char* known = whisper_lang_str(id);
    if (known != nullptr && std::strcmp(known, code) == 0) {
      return id;
    }
  }
#else
  (void)code;
#endif
  return -1;
}

std::atomic<int32_t> g_debug_abort_after{0};

}  // namespace

// ---------------------------------------------------------------------------
// Opaque handles.
// ---------------------------------------------------------------------------

#if TW_ENGINE
struct tw_context {
  whisper_context* whisper = nullptr;
  whisper_state* state = nullptr;
  int32_t threads = 1;
  std::atomic<uint32_t> flags{0};
  bool poisoned = false;
  std::atomic<int32_t> last_rc{0};
  std::vector<float> pcm;
  tw_model_facts facts{};
};

struct tw_vad {
  whisper_vad_context* vad = nullptr;
  int32_t window = 0;
  std::atomic<uint32_t> flags{0};
  std::vector<float> pending;
  std::vector<float> pcm;
  std::vector<float> probs;
};
#else
struct tw_context {
  std::atomic<uint32_t> flags{0};
};

struct tw_vad {
  std::atomic<uint32_t> flags{0};
};
#endif

struct tw_result {
  std::vector<tw_segment> segments;
  std::vector<tw_token> tokens;
  std::vector<uint8_t> text;
  char language[TW_LANGUAGE_CAPACITY] = {0};
  int64_t wall_ms = 0;
};

struct tw_spans {
  std::vector<tw_span> spans;
};

struct tw_hasher {
  tw_sha256_state state;
};

namespace {

void tw_destroy(tw_context* context) {
#if TW_ENGINE
  if (context->state != nullptr) {
    whisper_free_state(context->state);
  }
  if (context->whisper != nullptr) {
    whisper_free(context->whisper);
  }
#endif
  delete context;
  tw_count(TW_OBJ_CONTEXT, -1);
}

void tw_destroy(tw_vad* vad) {
#if TW_ENGINE
  if (vad->vad != nullptr) {
    whisper_vad_free(vad->vad);
  }
#endif
  delete vad;
  tw_count(TW_OBJ_VAD, -1);
}

// Holds a handle's busy flag for one call, and destroys the handle on exit
// when a close arrived meanwhile.
template <typename T>
class tw_call {
 public:
  explicit tw_call(T* handle) : handle_(handle), entered_(handle != nullptr && tw_enter(handle)) {}
  tw_call(const tw_call&) = delete;
  tw_call& operator=(const tw_call&) = delete;
  ~tw_call() {
    if (entered_ && tw_leave(handle_)) {
      tw_destroy(handle_);
    }
  }
  bool entered() const { return entered_; }

 private:
  T* handle_;
  bool entered_;
};

#if TW_ENGINE
// The abort condition of one transcription: the shared cell reaching the job
// id, or the test hook's check budget running out.
struct tw_abort_job {
  const int32_t* cell = nullptr;
  int32_t job_id = 0;
  int32_t debug_limit = 0;
  std::atomic<int32_t> checks{0};
  std::atomic<bool> debug_fired{false};

  bool armed() const { return (cell != nullptr && job_id > 0) || debug_limit > 0; }
  bool aborted() const {
    return debug_fired.load(std::memory_order_acquire) || tw_cell_reached(cell, job_id);
  }
};

bool tw_abort_check(void* data) {
  auto* job = static_cast<tw_abort_job*>(data);
  if (job->debug_limit > 0 &&
      job->checks.fetch_add(1, std::memory_order_acq_rel) + 1 >= job->debug_limit) {
    job->debug_fired.store(true, std::memory_order_release);
  }
  return job->aborted();
}

int32_t tw_open_context(tw_source& source, int64_t expected_bytes,
                        const uint8_t* expected_sha256,
                        const tw_context_options* options, tw_context** out) {
  const int32_t status = tw_verify(source, expected_bytes, expected_sha256);
  if (status != TW_OK) {
    return status;
  }
  whisper_context_params params = whisper_context_default_params();
  params.use_gpu = false;
  params.flash_attn = options->flash_attn != 0;
  params.gpu_device = 0;
  params.dtw_token_timestamps = false;
  whisper_model_loader loader = tw_loader_over(&source);
  whisper_context* whisper = whisper_init_with_params_no_state(&loader, params);
  if (whisper == nullptr) {
    tw_log_own(TW_LOG_ERROR, "model failed to load (%d)", TW_ERR_MODEL_LOAD);
    return TW_ERR_MODEL_LOAD;
  }
  whisper_state* state = whisper_init_state(whisper);
  if (state == nullptr) {
    whisper_free(whisper);
    tw_log_own(TW_LOG_ERROR, "state allocation failed (%d)", TW_ERR_OUT_OF_MEMORY);
    return TW_ERR_OUT_OF_MEMORY;
  }
  auto* context = new (std::nothrow) tw_context();
  if (context == nullptr) {
    whisper_free_state(state);
    whisper_free(whisper);
    return TW_ERR_OUT_OF_MEMORY;
  }
  tw_count(TW_OBJ_CONTEXT, 1);
  context->whisper = whisper;
  context->state = state;
  context->threads = tw_clamp_threads(options->n_threads);
  tw_model_facts& facts = context->facts;
  facts.struct_size = sizeof(tw_model_facts);
  facts.n_vocab = whisper_model_n_vocab(whisper);
  facts.n_audio_ctx = whisper_model_n_audio_ctx(whisper);
  facts.n_audio_state = whisper_model_n_audio_state(whisper);
  facts.n_audio_head = whisper_model_n_audio_head(whisper);
  facts.n_audio_layer = whisper_model_n_audio_layer(whisper);
  facts.n_text_ctx = whisper_model_n_text_ctx(whisper);
  facts.n_text_state = whisper_model_n_text_state(whisper);
  facts.n_text_head = whisper_model_n_text_head(whisper);
  facts.n_text_layer = whisper_model_n_text_layer(whisper);
  facts.n_mels = whisper_model_n_mels(whisper);
  facts.ftype = whisper_model_ftype(whisper);
  facts.model_type = whisper_model_type(whisper);
  facts.multilingual = whisper_is_multilingual(whisper) ? 1 : 0;
  *out = context;
  return TW_OK;
}

// Reads n_window from a Silero header: magic, a length-prefixed type string,
// three version numbers, then n_window. Leaves the source rewound.
int32_t tw_vad_window_of(tw_source& source) {
  uint32_t magic = 0;
  int32_t type_length = 0;
  int32_t window = -1;
  bool ok = source.read(&magic, 4) == 4 && source.read(&type_length, 4) == 4 &&
            type_length >= 0 && type_length <= 4096;
  if (ok) {
    std::vector<uint8_t> skip(static_cast<size_t>(type_length) + 12u);
    ok = source.read(skip.data(), skip.size()) == skip.size() && source.read(&window, 4) == 4;
  }
  if (!source.rewind() || !ok || window <= 0 || window > 65536) {
    return -1;
  }
  return window;
}

int32_t tw_open_vad(tw_source& source, int64_t expected_bytes,
                    const uint8_t* expected_sha256,
                    const tw_context_options* options, tw_vad** out) {
  const int32_t status = tw_verify(source, expected_bytes, expected_sha256);
  if (status != TW_OK) {
    return status;
  }
  const int32_t window = tw_vad_window_of(source);
  if (window < 0) {
    tw_log_own(TW_LOG_WARN, "VAD header is invalid (%d)", TW_ERR_MODEL_INVALID);
    return TW_ERR_MODEL_INVALID;
  }
  whisper_vad_context_params params = whisper_vad_default_context_params();
  params.n_threads = tw_clamp_threads(options->n_threads);
  params.use_gpu = false;
  params.gpu_device = 0;
  whisper_model_loader loader = tw_loader_over(&source);
  whisper_vad_context* model = whisper_vad_init_with_params(&loader, params);
  if (model == nullptr) {
    tw_log_own(TW_LOG_ERROR, "VAD model failed to load (%d)", TW_ERR_MODEL_LOAD);
    return TW_ERR_MODEL_LOAD;
  }
  auto* vad = new (std::nothrow) tw_vad();
  if (vad == nullptr) {
    whisper_vad_free(model);
    return TW_ERR_OUT_OF_MEMORY;
  }
  tw_count(TW_OBJ_VAD, 1);
  vad->vad = model;
  vad->window = window;
  *out = vad;
  return TW_OK;
}

// Validates the options of one transcription and resolves its language into
// language_out. Returns TW_OK or the status to report.
int32_t tw_check_transcribe(const tw_context* context, int32_t n_samples,
                            const tw_transcribe_options* o,
                            bool has_prompt, const int32_t* prompt_tokens,
                            int32_t n_prompt_tokens, char* language_out) {
  if (o->struct_size != sizeof(tw_transcribe_options)) {
    return TW_ERR_ABI_MISMATCH;
  }
  if (n_samples < 1) {
    return TW_ERR_INVALID_ARGUMENT;
  }
  if (n_samples > TW_MAX_SAMPLES) {
    return TW_ERR_AUDIO_TOO_LONG;
  }
  if (o->strategy != TW_STRATEGY_GREEDY && o->strategy != TW_STRATEGY_BEAM) {
    return TW_ERR_INVALID_ARGUMENT;
  }
  if (o->best_of < 1 || o->best_of > 8 || o->beam_size < 1 || o->beam_size > 8 ||
      o->n_threads < 0 || o->max_tokens < 0 || o->n_max_text_ctx < 0) {
    return TW_ERR_INVALID_ARGUMENT;
  }
  if (o->audio_ctx != 0 && (o->audio_ctx < 64 || o->audio_ctx > context->facts.n_audio_ctx)) {
    return TW_ERR_INVALID_ARGUMENT;
  }
  const float floats[] = {o->temperature, o->temperature_inc, o->entropy_thold,
                          o->logprob_thold, o->no_speech_thold, o->length_penalty,
                          o->max_initial_ts, o->token_thold_pt, o->token_thold_ptsum};
  for (float value : floats) {
    if (!std::isfinite(value)) {
      return TW_ERR_INVALID_ARGUMENT;
    }
  }
  if (o->temperature < 0.0f || o->temperature_inc < 0.0f) {
    return TW_ERR_INVALID_ARGUMENT;
  }
  if (n_prompt_tokens < 0 || n_prompt_tokens > 16384 ||
      (n_prompt_tokens > 0 && prompt_tokens == nullptr)) {
    return TW_ERR_INVALID_ARGUMENT;
  }
  for (int32_t i = 0; i < n_prompt_tokens; i++) {
    if (prompt_tokens[i] < 0 || prompt_tokens[i] >= context->facts.n_vocab) {
      return TW_ERR_INVALID_ARGUMENT;
    }
  }
  if ((has_prompt || n_prompt_tokens > 0) && o->n_max_text_ctx <= 0) {
    return TW_ERR_INVALID_ARGUMENT;
  }
  // A known code only: "" and "auto" would start whisper's language
  // detection, a separate pass that no abort reaches.
  if (std::memchr(o->language, '\0', TW_LANGUAGE_CAPACITY) == nullptr) {
    return TW_ERR_INVALID_ARGUMENT;
  }
  if (tw_language_index(o->language) < 0) {
    return TW_ERR_INVALID_ARGUMENT;
  }
  if (context->facts.multilingual == 0) {
    std::strcpy(language_out, "en");
  } else {
    std::memcpy(language_out, o->language, TW_LANGUAGE_CAPACITY);
  }
  return TW_OK;
}

whisper_full_params tw_params_for(const tw_transcribe_options* o, int32_t threads,
                                  const char* language, const char* prompt,
                                  const int32_t* prompt_tokens, int32_t n_prompt_tokens,
                                  tw_abort_job* job) {
  whisper_full_params p = whisper_full_default_params(
      o->strategy == TW_STRATEGY_BEAM ? WHISPER_SAMPLING_BEAM_SEARCH : WHISPER_SAMPLING_GREEDY);
  p.n_threads = threads;
  p.n_max_text_ctx = o->n_max_text_ctx;
  p.offset_ms = 0;
  p.duration_ms = 0;
  p.translate = o->translate != 0;
  p.no_context = o->no_context != 0;
  p.no_timestamps = o->no_timestamps != 0;
  p.single_segment = o->single_segment != 0;
  p.print_special = false;
  p.print_progress = false;
  p.print_realtime = false;
  p.print_timestamps = false;
  p.token_timestamps = o->token_timestamps != 0;
  p.thold_pt = o->token_thold_pt;
  p.thold_ptsum = o->token_thold_ptsum;
  p.max_len = 0;
  p.split_on_word = false;
  p.max_tokens = o->max_tokens;
  p.debug_mode = false;
  p.audio_ctx = o->audio_ctx;
  p.tdrz_enable = false;
  p.suppress_regex = nullptr;
  p.initial_prompt = prompt;
  p.carry_initial_prompt = o->carry_initial_prompt != 0;
  p.prompt_tokens = n_prompt_tokens > 0 ? prompt_tokens : nullptr;
  p.prompt_n_tokens = n_prompt_tokens;
  p.language = language;
  p.detect_language = false;
  p.suppress_blank = o->suppress_blank != 0;
  p.suppress_nst = o->suppress_nst != 0;
  p.temperature = o->temperature;
  p.max_initial_ts = o->max_initial_ts;
  p.length_penalty = o->length_penalty;
  p.temperature_inc = o->temperature_inc;
  p.entropy_thold = o->entropy_thold;
  p.logprob_thold = o->logprob_thold;
  p.no_speech_thold = o->no_speech_thold;
  p.greedy.best_of = o->best_of;
  p.beam_search.beam_size = o->beam_size;
  p.new_segment_callback = nullptr;
  p.new_segment_callback_user_data = nullptr;
  p.progress_callback = nullptr;
  p.progress_callback_user_data = nullptr;
  p.encoder_begin_callback = nullptr;
  p.encoder_begin_callback_user_data = nullptr;
  p.abort_callback = job->armed() ? tw_abort_check : nullptr;
  p.abort_callback_user_data = job->armed() ? job : nullptr;
  p.logits_filter_callback = nullptr;
  p.logits_filter_callback_user_data = nullptr;
  p.grammar_rules = nullptr;
  p.n_grammar_rules = 0;
  p.i_start_rule = 0;
  p.vad = false;
  p.vad_model_path = nullptr;
  return p;
}

int32_t tw_blob_offset(const std::vector<uint8_t>& blob) {
  return static_cast<int32_t>(blob.size());
}

// Copies everything out of the state into an immutable result.
tw_result* tw_copy_result(tw_context* context, const char* language, bool token_timestamps,
                          int64_t wall_ms) {
  auto* result = new tw_result();
  whisper_state* state = context->state;
  const whisper_token eot = whisper_token_eot(context->whisper);
  const int n_segments = whisper_full_n_segments_from_state(state);
  result->segments.reserve(static_cast<size_t>(std::max(0, n_segments)));
  for (int i = 0; i < n_segments; i++) {
    tw_segment segment{};
    segment.t0_ms = whisper_full_get_segment_t0_from_state(state, i) * 10;
    segment.t1_ms = whisper_full_get_segment_t1_from_state(state, i) * 10;
    const char* text = whisper_full_get_segment_text_from_state(state, i);
    const size_t text_length = text != nullptr ? std::strlen(text) : 0;
    segment.text_offset = tw_blob_offset(result->text);
    segment.text_length = static_cast<int32_t>(text_length);
    result->text.insert(result->text.end(), text, text + text_length);
    segment.no_speech_prob = whisper_full_get_segment_no_speech_prob_from_state(state, i);
    segment.token_offset = static_cast<int32_t>(result->tokens.size());
    const int n_tokens = whisper_full_n_tokens_from_state(state, i);
    double sum_logprob = 0.0;
    double sum_p = 0.0;
    float min_p = 1.0f;
    int32_t text_tokens = 0;
    for (int j = 0; j < n_tokens; j++) {
      const whisper_token_data data = whisper_full_get_token_data_from_state(state, i, j);
      sum_logprob += data.plog;
      if (data.id >= eot) {
        continue;
      }
      const char* piece = whisper_full_get_token_text_from_state(context->whisper, state, i, j);
      const size_t piece_length = piece != nullptr ? std::strlen(piece) : 0;
      tw_token token{};
      token.id = data.id;
      token.bytes_offset = tw_blob_offset(result->text);
      token.bytes_length = static_cast<int32_t>(piece_length);
      token.p = data.p;
      token.t0_ms = token_timestamps ? data.t0 * 10 : -1;
      token.t1_ms = token_timestamps ? data.t1 * 10 : -1;
      result->text.insert(result->text.end(), piece, piece + piece_length);
      result->tokens.push_back(token);
      sum_p += data.p;
      min_p = std::min(min_p, data.p);
      text_tokens++;
    }
    segment.token_count = text_tokens;
    segment.avg_logprob = n_tokens > 0 ? static_cast<float>(sum_logprob / n_tokens) : 0.0f;
    segment.mean_p = text_tokens > 0 ? static_cast<float>(sum_p / text_tokens) : 0.0f;
    segment.min_p = text_tokens > 0 ? min_p : 0.0f;
    result->segments.push_back(segment);
  }
  const char* detected = context->facts.multilingual != 0
                             ? whisper_lang_str(whisper_full_lang_id_from_state(state))
                             : nullptr;
  std::snprintf(result->language, sizeof(result->language), "%s",
                detected != nullptr ? detected : language);
  result->wall_ms = wall_ms;
  return result;
}
#endif  // TW_ENGINE

}  // namespace

// ===========================================================================
// Exported ABI.
// ===========================================================================

extern "C" {

int32_t tw_abi_version(void) { return TW_ABI_VERSION; }

int32_t tw_struct_size(int32_t struct_id) {
  switch (struct_id) {
    case TW_STRUCT_CONTEXT_OPTIONS: return TW_SIZEOF_CONTEXT_OPTIONS;
    case TW_STRUCT_TRANSCRIBE_OPTIONS: return TW_SIZEOF_TRANSCRIBE_OPTIONS;
    case TW_STRUCT_CPU_INFO: return TW_SIZEOF_CPU_INFO;
    case TW_STRUCT_MEMORY_INFO: return TW_SIZEOF_MEMORY_INFO;
    case TW_STRUCT_MODEL_FACTS: return TW_SIZEOF_MODEL_FACTS;
    case TW_STRUCT_SEGMENT: return TW_SIZEOF_SEGMENT;
    case TW_STRUCT_TOKEN: return TW_SIZEOF_TOKEN;
    case TW_STRUCT_SPAN: return TW_SIZEOF_SPAN;
    case TW_STRUCT_LOG_ENTRY: return TW_SIZEOF_LOG_ENTRY;
    case TW_STRUCT_VAD_OPTIONS: return TW_SIZEOF_VAD_OPTIONS;
    default: return 0;
  }
}

const char* tw_version(void) {
#if TW_ENGINE
  return "tapture_whisper abi=1 whisper.cpp=1.9.4 commit=927cfce3 ggml=0.23.0 engine=1";
#else
  return "tapture_whisper abi=1 whisper.cpp=1.9.4 commit=927cfce3 ggml=0.23.0 engine=0";
#endif
}

const char* tw_system_info(void) {
#if TW_ENGINE
  static std::mutex mutex;
  static std::string copy;
  try {
    tw_init();
    std::lock_guard<std::mutex> lock(mutex);
    copy = whisper_print_system_info();
    return copy.c_str();
  } catch (...) {
    return "";
  }
#else
  return "engine=0";
#endif
}

int32_t tw_cpu_info_get(tw_cpu_info* out) {
  if (out == nullptr) {
    return TW_ERR_INVALID_ARGUMENT;
  }
  if (out->struct_size != sizeof(tw_cpu_info)) {
    return TW_ERR_ABI_MISMATCH;
  }
  try {
    out->n_logical = tw_logical_threads();
    out->n_performance = tw_performance_cores(out->n_logical);
    out->arch = tw_arch_now();
    out->runtime_features = tw_runtime_features();
    out->required_features = kRequiredFeatures;
    out->engine_built = TW_ENGINE ? 1 : 0;
    out->supported = tw_engine_supported() ? 1 : 0;
    std::memset(out->reserved, 0, sizeof(out->reserved));
    return TW_OK;
  } catch (const std::bad_alloc&) {
    return TW_ERR_OUT_OF_MEMORY;
  } catch (...) {
    return TW_ERR_INTERNAL;
  }
}

int32_t tw_memory_info_get(tw_memory_info* out) {
  if (out == nullptr) {
    return TW_ERR_INVALID_ARGUMENT;
  }
  if (out->struct_size != sizeof(tw_memory_info)) {
    return TW_ERR_ABI_MISMATCH;
  }
  try {
    tw_fill_memory(out);
    return TW_OK;
  } catch (...) {
    return TW_ERR_INTERNAL;
  }
}

void tw_debug_set_cpu_override(int32_t supported) {
  g_cpu_forced_unsupported.store(supported == 0);
}

void tw_debug_abort_after_checks(int32_t n) {
  g_debug_abort_after.store(n > 0 ? n : 0);
}

int32_t tw_live_objects(int32_t kind) {
  if (kind < 0 || kind >= kObjectKinds) {
    return -1;
  }
  return g_live[kind].load(std::memory_order_relaxed);
}

int32_t tw_lang_id(const char* code) {
  try {
#if TW_ENGINE
    tw_init();
#endif
    return tw_language_index(code);
  } catch (...) {
    return -1;
  }
}

// ---- SHA-256 ----

int32_t tw_sha256(const void* data, size_t n, uint8_t out[32]) {
  if (out == nullptr || (data == nullptr && n > 0)) {
    return TW_ERR_INVALID_ARGUMENT;
  }
  tw_sha256_state state;
  tw_sha256_state_begin(&state);
  tw_sha256_state_feed(&state, data, n);
  tw_sha256_state_end(&state, out);
  return TW_OK;
}

tw_hasher* tw_sha256_new(void) {
  auto* hasher = new (std::nothrow) tw_hasher();
  if (hasher == nullptr) {
    return nullptr;
  }
  tw_sha256_state_begin(&hasher->state);
  tw_count(TW_OBJ_HASHER, 1);
  return hasher;
}

void tw_sha256_update(tw_hasher* hasher, const void* data, size_t n) {
  if (hasher == nullptr || (data == nullptr && n > 0)) {
    return;
  }
  tw_sha256_state_feed(&hasher->state, data, n);
}

int32_t tw_sha256_finish(tw_hasher* hasher, uint8_t out[32]) {
  if (hasher == nullptr) {
    return TW_ERR_INVALID_ARGUMENT;
  }
  int32_t status = TW_ERR_INVALID_ARGUMENT;
  if (out != nullptr) {
    tw_sha256_state_end(&hasher->state, out);
    status = TW_OK;
  }
  delete hasher;
  tw_count(TW_OBJ_HASHER, -1);
  return status;
}

// ---- logging ----

void tw_log_set_min_level(int32_t level) {
  g_log_min_level.store(std::max<int32_t>(TW_LOG_DEBUG, std::min<int32_t>(level, TW_LOG_ERROR)));
}

int32_t tw_log_drain(tw_log_entry* out, int32_t capacity) {
  if (out == nullptr || capacity <= 0) {
    return 0;
  }
  std::lock_guard<std::mutex> lock(g_ring.mutex);
  const int32_t n = std::min(capacity, g_ring.count);
  for (int32_t i = 0; i < n; i++) {
    out[i] = g_ring.entries[(g_ring.head + i) % TW_LOG_RING_CAPACITY];
  }
  g_ring.head = (g_ring.head + n) % TW_LOG_RING_CAPACITY;
  g_ring.count -= n;
  return n;
}

uint32_t tw_log_dropped(void) { return g_log_dropped.load(std::memory_order_relaxed); }

int32_t tw_set_crash_file(const char* path_utf8) {
  try {
    tw_init();
    std::lock_guard<std::mutex> lock(g_crash_mutex);
    g_crash_path = path_utf8 != nullptr ? path_utf8 : "";
    return TW_OK;
  } catch (const std::bad_alloc&) {
    return TW_ERR_OUT_OF_MEMORY;
  } catch (...) {
    return TW_ERR_INTERNAL;
  }
}

// ---- cells ----

int32_t* tw_cell_new(void) {
  auto* block = new (std::nothrow) tw_cell_block();
  if (block == nullptr) {
    return nullptr;
  }
  tw_count(TW_OBJ_CELL, 1);
  return reinterpret_cast<int32_t*>(&block->value);
}

void tw_cell_retain(int32_t* cell) {
  if (cell != nullptr) {
    tw_cell_of(cell)->references.fetch_add(1, std::memory_order_relaxed);
  }
}

void tw_cell_release(int32_t* cell) {
  if (cell == nullptr) {
    return;
  }
  tw_cell_block* block = tw_cell_of(cell);
  if (block->references.fetch_sub(1, std::memory_order_acq_rel) == 1) {
    delete block;
    tw_count(TW_OBJ_CELL, -1);
  }
}

void tw_cell_store(int32_t* cell, int32_t value) {
  if (cell != nullptr) {
    tw_cell_of(cell)->value.store(value, std::memory_order_release);
  }
}

int32_t tw_cell_load(const int32_t* cell) {
  return cell != nullptr ? tw_cell_of(cell)->value.load(std::memory_order_acquire) : 0;
}

// ---- whisper context ----

void tw_context_options_init(tw_context_options* options) {
  if (options == nullptr) {
    return;
  }
  std::memset(options, 0, sizeof(*options));
  options->struct_size = sizeof(tw_context_options);
  options->n_threads = 4;
  options->use_gpu = 0;
  options->flash_attn = 1;
}

int32_t tw_context_open_file(const char* path_utf8, int64_t expected_bytes,
                             const uint8_t* expected_sha256,
                             const tw_context_options* options, tw_context** out) {
  if (out == nullptr) {
    return TW_ERR_INVALID_ARGUMENT;
  }
  *out = nullptr;
  try {
    int32_t status = tw_open_preflight(options);
    if (status != TW_OK) {
      return status;
    }
    if (path_utf8 == nullptr || path_utf8[0] == '\0' || expected_bytes <= 0 ||
        expected_sha256 == nullptr) {
      return TW_ERR_INVALID_ARGUMENT;
    }
#if TW_ENGINE
    tw_file_source source;
    status = source.open(path_utf8);
    if (status != TW_OK) {
      tw_log_own(TW_LOG_WARN, "model file could not be opened (%d)", status);
      return status;
    }
    return tw_open_context(source, expected_bytes, expected_sha256, options, out);
#else
    return TW_ERR_ENGINE_NOT_BUILT;
#endif
  } catch (const std::bad_alloc&) {
    return TW_ERR_OUT_OF_MEMORY;
  } catch (...) {
    return TW_ERR_INTERNAL;
  }
}

int32_t tw_context_open_buffer(const void* data, size_t size, const uint8_t* expected_sha256,
                               const tw_context_options* options, tw_context** out) {
  if (out == nullptr) {
    return TW_ERR_INVALID_ARGUMENT;
  }
  *out = nullptr;
  try {
    const int32_t status = tw_open_preflight(options);
    if (status != TW_OK) {
      return status;
    }
    if (data == nullptr || size == 0) {
      return TW_ERR_INVALID_ARGUMENT;
    }
#if TW_ENGINE
    tw_buffer_source source(data, size);
    return tw_open_context(source, -1, expected_sha256, options, out);
#else
    (void)expected_sha256;
    return TW_ERR_ENGINE_NOT_BUILT;
#endif
  } catch (const std::bad_alloc&) {
    return TW_ERR_OUT_OF_MEMORY;
  } catch (...) {
    return TW_ERR_INTERNAL;
  }
}

#if !defined(__EMSCRIPTEN__)
// File ids name sources registered by the WebAssembly worker; native builds
// have none (task 111 defines these for the WebAssembly library).
int32_t tw_context_open_js(int32_t file_id, int64_t expected_bytes,
                           const uint8_t* expected_sha256,
                           const tw_context_options* options, tw_context** out) {
  (void)file_id;
  (void)expected_bytes;
  (void)expected_sha256;
  (void)options;
  if (out != nullptr) {
    *out = nullptr;
  }
  return TW_ERR_ENGINE_NOT_BUILT;
}

int32_t tw_vad_open_js(int32_t file_id, int64_t expected_bytes,
                       const uint8_t* expected_sha256,
                       const tw_context_options* options, tw_vad** out) {
  (void)file_id;
  (void)expected_bytes;
  (void)expected_sha256;
  (void)options;
  if (out != nullptr) {
    *out = nullptr;
  }
  return TW_ERR_ENGINE_NOT_BUILT;
}
#endif

void tw_context_close(tw_context* context) {
  if (context != nullptr && tw_request_close(context)) {
    tw_destroy(context);
  }
}

int32_t tw_context_facts(tw_context* context, tw_model_facts* out) {
  if (context == nullptr || out == nullptr) {
    return TW_ERR_INVALID_ARGUMENT;
  }
  if (out->struct_size != sizeof(tw_model_facts)) {
    return TW_ERR_ABI_MISMATCH;
  }
#if TW_ENGINE
  *out = context->facts;
  return TW_OK;
#else
  return TW_ERR_ENGINE_NOT_BUILT;
#endif
}

float* tw_context_pcm_buffer(tw_context* context, int32_t n_samples) {
#if TW_ENGINE
  if (context == nullptr || n_samples < 1 || n_samples > TW_MAX_SAMPLES) {
    return nullptr;
  }
  tw_call<tw_context> call(context);
  if (!call.entered()) {
    return nullptr;
  }
  try {
    if (context->pcm.size() < static_cast<size_t>(n_samples)) {
      context->pcm.resize(static_cast<size_t>(n_samples));
    }
    return context->pcm.data();
  } catch (...) {
    return nullptr;
  }
#else
  (void)context;
  (void)n_samples;
  return nullptr;
#endif
}

int32_t tw_last_whisper_code(const tw_context* context) {
#if TW_ENGINE
  return context != nullptr ? context->last_rc.load() : 0;
#else
  (void)context;
  return 0;
#endif
}

void tw_transcribe_options_init(tw_transcribe_options* o) {
  if (o == nullptr) {
    return;
  }
  std::memset(o, 0, sizeof(*o));
  o->struct_size = sizeof(tw_transcribe_options);
  o->strategy = TW_STRATEGY_GREEDY;
  o->n_threads = 0;
  o->best_of = 5;
  o->beam_size = 5;
  o->max_tokens = 0;
  o->audio_ctx = 0;
  o->n_max_text_ctx = 16384;
  o->temperature = 0.0f;
  o->temperature_inc = 0.2f;
  o->entropy_thold = 2.4f;
  o->logprob_thold = -1.0f;
  o->no_speech_thold = 0.6f;
  o->length_penalty = -1.0f;
  o->max_initial_ts = 1.0f;
  o->token_thold_pt = 0.01f;
  o->token_thold_ptsum = 0.01f;
  o->translate = 0;
  o->no_context = 1;
  o->single_segment = 0;
  o->no_timestamps = 0;
  o->token_timestamps = 0;
  o->suppress_blank = 1;
  o->suppress_nst = 1;
  o->carry_initial_prompt = 0;
  std::strcpy(o->language, "en");
}

int32_t tw_transcribe(tw_context* context, const float* pcm, int32_t n_samples,
                      const tw_transcribe_options* options, const char* initial_prompt_utf8,
                      const int32_t* prompt_tokens, int32_t n_prompt_tokens,
                      const int32_t* abort_cell, int32_t job_id, tw_result** out) {
  if (out == nullptr) {
    return TW_ERR_INVALID_ARGUMENT;
  }
  *out = nullptr;
  if (context == nullptr || pcm == nullptr || options == nullptr) {
    return TW_ERR_INVALID_ARGUMENT;
  }
#if TW_ENGINE
  tw_call<tw_context> call(context);
  if (!call.entered()) {
    return TW_ERR_BUSY;
  }
  try {
    if (context->poisoned) {
      return TW_ERR_POISONED;
    }
    const char* prompt =
        initial_prompt_utf8 != nullptr && initial_prompt_utf8[0] != '\0' ? initial_prompt_utf8 : nullptr;
    char language[TW_LANGUAGE_CAPACITY] = {0};
    const int32_t status = tw_check_transcribe(context, n_samples, options, prompt != nullptr,
                                               prompt_tokens, n_prompt_tokens, language);
    if (status != TW_OK) {
      return status;
    }
    tw_abort_job job;
    job.cell = abort_cell;
    job.job_id = job_id;
    job.debug_limit = g_debug_abort_after.exchange(0);
    if (tw_cell_reached(abort_cell, job_id)) {
      return TW_ERR_ABORTED;
    }
    const int32_t threads =
        options->n_threads > 0 ? tw_clamp_threads(options->n_threads) : context->threads;
    const whisper_full_params params = tw_params_for(options, threads, language, prompt,
                                                     prompt_tokens, n_prompt_tokens, &job);
    const auto started = std::chrono::steady_clock::now();
    const int rc = whisper_full_with_state(context->whisper, context->state, params, pcm, n_samples);
    const int64_t wall_ms = std::chrono::duration_cast<std::chrono::milliseconds>(
                                std::chrono::steady_clock::now() - started)
                                .count();
    context->last_rc.store(rc);
    if (rc == -7) {
      // whisper.cpp freed the state itself when the KV cache failed.
      context->state = nullptr;
      context->poisoned = true;
      tw_log_own(TW_LOG_ERROR, "context poisoned by whisper code %d", rc);
      return TW_ERR_POISONED;
    }
    // Whatever whisper returned, an abort that holds now wins: an aborted job
    // is never reported as a (possibly empty) success.
    if (job.aborted()) {
      return TW_ERR_ABORTED;
    }
    if (rc != 0) {
      tw_log_own(TW_LOG_ERROR, "whisper failed with code %d", rc);
      return TW_ERR_INFERENCE;
    }
    tw_result* result = tw_copy_result(context, language, options->token_timestamps != 0, wall_ms);
    tw_count(TW_OBJ_RESULT, 1);
    *out = result;
    return TW_OK;
  } catch (const std::bad_alloc&) {
    return TW_ERR_OUT_OF_MEMORY;
  } catch (...) {
    return TW_ERR_INTERNAL;
  }
#else
  (void)n_samples;
  (void)initial_prompt_utf8;
  (void)prompt_tokens;
  (void)n_prompt_tokens;
  (void)abort_cell;
  (void)job_id;
  return TW_ERR_ENGINE_NOT_BUILT;
#endif
}

// ---- result ----

void tw_result_free(tw_result* result) {
  if (result != nullptr) {
    delete result;
    tw_count(TW_OBJ_RESULT, -1);
  }
}

const tw_segment* tw_result_segments(const tw_result* result, int32_t* count) {
  const int32_t n = result != nullptr ? static_cast<int32_t>(result->segments.size()) : 0;
  if (count != nullptr) {
    *count = n;
  }
  return n > 0 ? result->segments.data() : nullptr;
}

const tw_token* tw_result_tokens(const tw_result* result, int32_t* count) {
  const int32_t n = result != nullptr ? static_cast<int32_t>(result->tokens.size()) : 0;
  if (count != nullptr) {
    *count = n;
  }
  return n > 0 ? result->tokens.data() : nullptr;
}

const uint8_t* tw_result_text(const tw_result* result, int32_t* length) {
  const int32_t n = result != nullptr ? static_cast<int32_t>(result->text.size()) : 0;
  if (length != nullptr) {
    *length = n;
  }
  return n > 0 ? result->text.data() : nullptr;
}

const char* tw_result_language(const tw_result* result) {
  return result != nullptr ? result->language : "";
}

int64_t tw_result_wall_ms(const tw_result* result) {
  return result != nullptr ? result->wall_ms : 0;
}

// ---- Silero VAD ----

int32_t tw_vad_open_file(const char* path_utf8, int64_t expected_bytes,
                         const uint8_t* expected_sha256, const tw_context_options* options,
                         tw_vad** out) {
  if (out == nullptr) {
    return TW_ERR_INVALID_ARGUMENT;
  }
  *out = nullptr;
  try {
    int32_t status = tw_open_preflight(options);
    if (status != TW_OK) {
      return status;
    }
    if (path_utf8 == nullptr || path_utf8[0] == '\0' || expected_bytes <= 0 ||
        expected_sha256 == nullptr) {
      return TW_ERR_INVALID_ARGUMENT;
    }
#if TW_ENGINE
    tw_file_source source;
    status = source.open(path_utf8);
    if (status != TW_OK) {
      tw_log_own(TW_LOG_WARN, "VAD file could not be opened (%d)", status);
      return status;
    }
    return tw_open_vad(source, expected_bytes, expected_sha256, options, out);
#else
    return TW_ERR_ENGINE_NOT_BUILT;
#endif
  } catch (const std::bad_alloc&) {
    return TW_ERR_OUT_OF_MEMORY;
  } catch (...) {
    return TW_ERR_INTERNAL;
  }
}

int32_t tw_vad_open_buffer(const void* data, size_t size, const uint8_t* expected_sha256,
                           const tw_context_options* options, tw_vad** out) {
  if (out == nullptr) {
    return TW_ERR_INVALID_ARGUMENT;
  }
  *out = nullptr;
  try {
    const int32_t status = tw_open_preflight(options);
    if (status != TW_OK) {
      return status;
    }
    if (data == nullptr || size == 0) {
      return TW_ERR_INVALID_ARGUMENT;
    }
#if TW_ENGINE
    tw_buffer_source source(data, size);
    return tw_open_vad(source, -1, expected_sha256, options, out);
#else
    (void)expected_sha256;
    return TW_ERR_ENGINE_NOT_BUILT;
#endif
  } catch (const std::bad_alloc&) {
    return TW_ERR_OUT_OF_MEMORY;
  } catch (...) {
    return TW_ERR_INTERNAL;
  }
}

void tw_vad_close(tw_vad* vad) {
  if (vad != nullptr && tw_request_close(vad)) {
    tw_destroy(vad);
  }
}

int32_t tw_vad_window_samples(const tw_vad* vad) {
#if TW_ENGINE
  return vad != nullptr ? vad->window : 0;
#else
  (void)vad;
  return 0;
#endif
}

float* tw_vad_pcm_buffer(tw_vad* vad, int32_t n_samples) {
#if TW_ENGINE
  if (vad == nullptr || n_samples < 1 || n_samples > TW_MAX_SAMPLES) {
    return nullptr;
  }
  tw_call<tw_vad> call(vad);
  if (!call.entered()) {
    return nullptr;
  }
  try {
    if (vad->pcm.size() < static_cast<size_t>(n_samples)) {
      vad->pcm.resize(static_cast<size_t>(n_samples));
    }
    return vad->pcm.data();
  } catch (...) {
    return nullptr;
  }
#else
  (void)vad;
  (void)n_samples;
  return nullptr;
#endif
}

int32_t tw_vad_feed(tw_vad* vad, const float* pcm, int32_t n_samples, int32_t* out_n_probs) {
  if (out_n_probs != nullptr) {
    *out_n_probs = 0;
  }
  if (vad == nullptr || out_n_probs == nullptr || n_samples < 0 ||
      (n_samples > 0 && pcm == nullptr)) {
    return TW_ERR_INVALID_ARGUMENT;
  }
  if (n_samples > TW_MAX_SAMPLES) {
    return TW_ERR_AUDIO_TOO_LONG;
  }
#if TW_ENGINE
  tw_call<tw_vad> call(vad);
  if (!call.entered()) {
    return TW_ERR_BUSY;
  }
  try {
    vad->probs.clear();
    vad->pending.insert(vad->pending.end(), pcm, pcm + n_samples);
    const size_t window = static_cast<size_t>(vad->window);
    const size_t whole = vad->pending.size() / window;
    if (whole == 0) {
      return TW_OK;
    }
    // Only whole windows: whisper zero-pads a partial chunk, which would
    // corrupt the stream, so the remainder waits for the next feed.
    const size_t used = whole * window;
    if (!whisper_vad_detect_speech_no_reset(vad->vad, vad->pending.data(), static_cast<int>(used))) {
      tw_log_own(TW_LOG_ERROR, "VAD detection failed (%d)", TW_ERR_INFERENCE);
      return TW_ERR_INFERENCE;
    }
    const int n_probs = whisper_vad_n_probs(vad->vad);
    const float* probs = whisper_vad_probs(vad->vad);
    vad->probs.assign(probs, probs + n_probs);
    vad->pending.erase(vad->pending.begin(), vad->pending.begin() + static_cast<std::ptrdiff_t>(used));
    *out_n_probs = n_probs;
    return TW_OK;
  } catch (const std::bad_alloc&) {
    return TW_ERR_OUT_OF_MEMORY;
  } catch (...) {
    return TW_ERR_INTERNAL;
  }
#else
  return TW_ERR_ENGINE_NOT_BUILT;
#endif
}

const float* tw_vad_probs(const tw_vad* vad, int32_t* count) {
#if TW_ENGINE
  const int32_t n = vad != nullptr ? static_cast<int32_t>(vad->probs.size()) : 0;
  if (count != nullptr) {
    *count = n;
  }
  return n > 0 ? vad->probs.data() : nullptr;
#else
  (void)vad;
  if (count != nullptr) {
    *count = 0;
  }
  return nullptr;
#endif
}

int32_t tw_vad_pending_samples(const tw_vad* vad) {
#if TW_ENGINE
  return vad != nullptr ? static_cast<int32_t>(vad->pending.size()) : 0;
#else
  (void)vad;
  return 0;
#endif
}

void tw_vad_reset(tw_vad* vad) {
#if TW_ENGINE
  if (vad == nullptr) {
    return;
  }
  tw_call<tw_vad> call(vad);
  if (!call.entered()) {
    return;
  }
  whisper_vad_reset_state(vad->vad);
  vad->pending.clear();
  vad->probs.clear();
#else
  (void)vad;
#endif
}

void tw_vad_options_init(tw_vad_options* options) {
  if (options == nullptr) {
    return;
  }
  std::memset(options, 0, sizeof(*options));
  options->struct_size = sizeof(tw_vad_options);
  options->threshold = 0.5f;
  options->min_speech_ms = 250;
  options->min_silence_ms = 100;
  options->max_speech_s = FLT_MAX;
  options->speech_pad_ms = 30;
  options->samples_overlap_s = 0.1f;
}

int32_t tw_vad_segments(tw_vad* vad, const float* pcm, int32_t n_samples,
                        const tw_vad_options* options, tw_spans** out) {
  if (out == nullptr) {
    return TW_ERR_INVALID_ARGUMENT;
  }
  *out = nullptr;
  if (vad == nullptr || options == nullptr || n_samples < 0 || (n_samples > 0 && pcm == nullptr)) {
    return TW_ERR_INVALID_ARGUMENT;
  }
  if (options->struct_size != sizeof(tw_vad_options)) {
    return TW_ERR_ABI_MISMATCH;
  }
  if (n_samples > TW_MAX_SAMPLES) {
    return TW_ERR_AUDIO_TOO_LONG;
  }
  if (!(options->threshold > 0.0f && options->threshold < 1.0f) || options->min_speech_ms < 0 ||
      options->min_silence_ms < 0 || !(options->max_speech_s > 0.0f) ||
      options->speech_pad_ms < 0 || !(options->samples_overlap_s >= 0.0f)) {
    return TW_ERR_INVALID_ARGUMENT;
  }
#if TW_ENGINE
  tw_call<tw_vad> call(vad);
  if (!call.entered()) {
    return TW_ERR_BUSY;
  }
  try {
    // Batch segmentation starts from a clean state and leaves one behind.
    whisper_vad_reset_state(vad->vad);
    vad->pending.clear();
    vad->probs.clear();
    auto* spans = new tw_spans();
    if (n_samples > 0) {
      whisper_vad_params params = whisper_vad_default_params();
      params.threshold = options->threshold;
      params.min_speech_duration_ms = options->min_speech_ms;
      params.min_silence_duration_ms = options->min_silence_ms;
      params.max_speech_duration_s = options->max_speech_s;
      params.speech_pad_ms = options->speech_pad_ms;
      params.samples_overlap = options->samples_overlap_s;
      whisper_vad_segments* segments =
          whisper_vad_segments_from_samples(vad->vad, params, pcm, n_samples);
      whisper_vad_reset_state(vad->vad);
      if (segments == nullptr) {
        delete spans;
        tw_log_own(TW_LOG_ERROR, "VAD segmentation failed (%d)", TW_ERR_INFERENCE);
        return TW_ERR_INFERENCE;
      }
      const int n = whisper_vad_segments_n_segments(segments);
      for (int i = 0; i < n; i++) {
        // whisper stores centiseconds; the log line is what divides by 100.
        const float t0 = whisper_vad_segments_get_segment_t0(segments, i);
        const float t1 = whisper_vad_segments_get_segment_t1(segments, i);
        spans->spans.push_back({static_cast<int64_t>(std::llround(t0 * 10.0)),
                                static_cast<int64_t>(std::llround(t1 * 10.0))});
      }
      whisper_vad_free_segments(segments);
    }
    tw_count(TW_OBJ_SPANS, 1);
    *out = spans;
    return TW_OK;
  } catch (const std::bad_alloc&) {
    return TW_ERR_OUT_OF_MEMORY;
  } catch (...) {
    return TW_ERR_INTERNAL;
  }
#else
  return TW_ERR_ENGINE_NOT_BUILT;
#endif
}

const tw_span* tw_spans_data(const tw_spans* spans, int32_t* count) {
  const int32_t n = spans != nullptr ? static_cast<int32_t>(spans->spans.size()) : 0;
  if (count != nullptr) {
    *count = n;
  }
  return n > 0 ? spans->spans.data() : nullptr;
}

void tw_spans_free(tw_spans* spans) {
  if (spans != nullptr) {
    delete spans;
    tw_count(TW_OBJ_SPANS, -1);
  }
}

}  // extern "C"
