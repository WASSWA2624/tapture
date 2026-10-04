/*
 * tw_smoke: a command-line smoke test of the tapture_whisper library, built
 * when CMake is configured with -DTW_BUILD_SMOKE=ON (dev-plan task 103).
 *
 *   tw_smoke --model <bin> --sha256 <hex> --wav <16 kHz s16 mono wav>
 *            --expect "<phrase>" [--abort-after-checks N] [--bytes N]
 *            [--threads N] [--language CODE]
 *   tw_smoke --self-test
 *
 * Exit codes: 0 on success; the tw_status code (1..15) of a failed call;
 * 20 when the phrase is missing; 21 when an abort run is not ABORTED or its
 * retry fails; 22 when a live object is left behind; 23 when the SHA-256
 * self-test fails; 64 on a usage error.
 */
#include <ctype.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "../tapture_whisper.h"

#define EXIT_PHRASE_MISSING 20
#define EXIT_ABORT_CONTRACT 21
#define EXIT_LEAK 22
#define EXIT_SELF_TEST 23
#define EXIT_USAGE 64

static const char* status_name(int32_t status) {
  static const char* const names[] = {
      "OK",           "INVALID_ARGUMENT", "ABI_MISMATCH",    "UNSUPPORTED_CPU",
      "FILE_OPEN",    "MODEL_INVALID",    "MODEL_LOAD",      "OUT_OF_MEMORY",
      "ABORTED",      "INFERENCE",        "POISONED",        "BUSY",
      "AUDIO_TOO_LONG", "ENGINE_NOT_BUILT", "INTERNAL",      "MODEL_MISMATCH"};
  if (status < 0 || status > 15) {
    return "UNKNOWN";
  }
  return names[status];
}

static int hex_value(char c) {
  if (c >= '0' && c <= '9') return c - '0';
  if (c >= 'a' && c <= 'f') return c - 'a' + 10;
  if (c >= 'A' && c <= 'F') return c - 'A' + 10;
  return -1;
}

static int parse_sha(const char* hex, uint8_t out[TW_SHA256_BYTES]) {
  int i;
  if (hex == NULL || strlen(hex) != 2 * TW_SHA256_BYTES) {
    return 0;
  }
  for (i = 0; i < TW_SHA256_BYTES; i++) {
    const int high = hex_value(hex[2 * i]);
    const int low = hex_value(hex[2 * i + 1]);
    if (high < 0 || low < 0) {
      return 0;
    }
    out[i] = (uint8_t)(high * 16 + low);
  }
  return 1;
}

static void to_hex(const uint8_t digest[TW_SHA256_BYTES], char out[2 * TW_SHA256_BYTES + 1]) {
  static const char digits[] = "0123456789abcdef";
  int i;
  for (i = 0; i < TW_SHA256_BYTES; i++) {
    out[2 * i] = digits[digest[i] >> 4];
    out[2 * i + 1] = digits[digest[i] & 15];
  }
  out[2 * TW_SHA256_BYTES] = '\0';
}

/* ---- SHA-256 self-test against the NIST CAVP / FIPS 180-4 examples ---- */

static int check_vector(const char* label, const uint8_t* data, size_t n, const char* expected) {
  uint8_t digest[TW_SHA256_BYTES];
  char hex[2 * TW_SHA256_BYTES + 1];
  tw_hasher* hasher;
  size_t offset = 0;
  size_t step = 1;
  int ok = 1;

  tw_sha256(data, n, digest);
  to_hex(digest, hex);
  if (strcmp(hex, expected) != 0) {
    printf("sha256 %s one-shot: got %s want %s\n", label, hex, expected);
    ok = 0;
  }
  /* The incremental hasher, fed in growing odd-sized pieces across block
   * boundaries. */
  hasher = tw_sha256_new();
  while (offset < n) {
    const size_t take = n - offset < step ? n - offset : step;
    tw_sha256_update(hasher, data + offset, take);
    offset += take;
    step = step * 3 + 1;
  }
  tw_sha256_finish(hasher, digest);
  to_hex(digest, hex);
  if (strcmp(hex, expected) != 0) {
    printf("sha256 %s incremental: got %s want %s\n", label, hex, expected);
    ok = 0;
  }
  printf("sha256 %-12s %s\n", label, ok ? "ok" : "FAILED");
  return ok;
}

static int self_test(void) {
  static const char abc[] = "abc";
  static const char two_blocks[] = "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq";
  /* The 896-bit message, in two literals: one 112-letter run reads as a key
   * to tool/check_secrets.dart. */
  static const char four_blocks[] =
      "abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmn"
      "hijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu";
  uint8_t* million;
  int ok = 1;

  ok &= check_vector("empty", (const uint8_t*)"", 0,
                     "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855");
  ok &= check_vector("abc", (const uint8_t*)abc, 3,
                     "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad");
  ok &= check_vector("448-bit", (const uint8_t*)two_blocks, strlen(two_blocks),
                     "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1");
  ok &= check_vector("896-bit", (const uint8_t*)four_blocks, strlen(four_blocks),
                     "cf5b16a778af8380036ce59e7b0492370b249b11e8f07a51afac45037afee9d1");
  million = (uint8_t*)malloc(1000000);
  if (million == NULL) {
    return EXIT_SELF_TEST;
  }
  memset(million, 'a', 1000000);
  ok &= check_vector("million-a", million, 1000000,
                     "cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0");
  free(million);
  if (tw_live_objects(TW_OBJ_HASHER) != 0) {
    printf("sha256 hashers left alive: %d\n", tw_live_objects(TW_OBJ_HASHER));
    ok = 0;
  }
  printf("self-test %s\n", ok ? "ok" : "FAILED");
  return ok ? 0 : EXIT_SELF_TEST;
}

/* ---- WAV: 16 kHz, 16-bit PCM, mono ---- */

static uint32_t le32(const uint8_t* p) {
  return (uint32_t)p[0] | ((uint32_t)p[1] << 8) | ((uint32_t)p[2] << 16) | ((uint32_t)p[3] << 24);
}

static uint16_t le16(const uint8_t* p) { return (uint16_t)(p[0] | (p[1] << 8)); }

static float* read_wav(const char* path, int32_t* n_samples) {
  FILE* file = fopen(path, "rb");
  uint8_t* bytes = NULL;
  long size;
  size_t at = 12;
  int format_ok = 0;
  float* pcm = NULL;

  *n_samples = 0;
  if (file == NULL) {
    return NULL;
  }
  fseek(file, 0, SEEK_END);
  size = ftell(file);
  fseek(file, 0, SEEK_SET);
  if (size < 44) {
    fclose(file);
    return NULL;
  }
  bytes = (uint8_t*)malloc((size_t)size);
  if (bytes == NULL || fread(bytes, 1, (size_t)size, file) != (size_t)size) {
    fclose(file);
    free(bytes);
    return NULL;
  }
  fclose(file);
  if (memcmp(bytes, "RIFF", 4) != 0 || memcmp(bytes + 8, "WAVE", 4) != 0) {
    free(bytes);
    return NULL;
  }
  while (at + 8 <= (size_t)size) {
    const uint32_t chunk = le32(bytes + at + 4);
    const uint8_t* body = bytes + at + 8;
    if (at + 8 + chunk > (size_t)size) {
      break;
    }
    if (memcmp(bytes + at, "fmt ", 4) == 0 && chunk >= 16) {
      format_ok = le16(body) == 1 && le16(body + 2) == 1 && le32(body + 4) == TW_SAMPLE_RATE &&
                  le16(body + 14) == 16;
    } else if (memcmp(bytes + at, "data", 4) == 0 && format_ok) {
      const int32_t n = (int32_t)(chunk / 2);
      int32_t i;
      pcm = (float*)malloc(sizeof(float) * (size_t)(n > 0 ? n : 1));
      if (pcm != NULL) {
        for (i = 0; i < n; i++) {
          pcm[i] = (float)(int16_t)le16(body + 2 * i) / 32768.0f;
        }
        *n_samples = n;
      }
      break;
    }
    at += 8 + chunk + (chunk & 1u);
  }
  free(bytes);
  return pcm;
}

static long long file_size(const char* path) {
  FILE* file = fopen(path, "rb");
  long long size;
  if (file == NULL) {
    return -1;
  }
  fseek(file, 0, SEEK_END);
  size = (long long)ftell(file);
  fclose(file);
  return size;
}

/* Prints the drained log lines and counts those not written by the shim,
 * which is how whisper's loader shows that it parsed anything. */
static int drain_log(void) {
  tw_log_entry entries[64];
  int foreign = 0;
  int32_t n;
  int32_t i;
  while ((n = tw_log_drain(entries, 64)) > 0) {
    for (i = 0; i < n; i++) {
      printf("  log[%d] %s\n", entries[i].level, entries[i].text);
      if (strncmp(entries[i].text, "tapture_whisper:", 16) != 0) {
        foreign++;
      }
    }
  }
  return foreign;
}

static int contains_folded(const char* haystack, const char* needle) {
  const size_t n = strlen(needle);
  size_t i, j;
  if (n == 0) {
    return 1;
  }
  for (i = 0; haystack[i] != '\0'; i++) {
    for (j = 0; j < n && haystack[i + j] != '\0'; j++) {
      if (tolower((unsigned char)haystack[i + j]) != tolower((unsigned char)needle[j])) {
        break;
      }
    }
    if (j == n) {
      return 1;
    }
  }
  return 0;
}

/* Runs one transcription and returns its status; on OK, *text holds the
 * concatenated segment text (caller frees). */
static int32_t run(tw_context* context, const float* pcm, int32_t n, const char* language,
                   int32_t threads, char** text) {
  tw_transcribe_options options;
  tw_result* result = NULL;
  int32_t status;
  int32_t length = 0;
  int32_t n_segments = 0;
  const uint8_t* blob;
  const tw_segment* segments;
  size_t used = 0;
  int32_t i;

  *text = NULL;
  tw_transcribe_options_init(&options);
  snprintf(options.language, sizeof(options.language), "%s", language);
  options.n_threads = threads;
  status = tw_transcribe(context, pcm, n, &options, NULL, NULL, 0, NULL, 0, &result);
  if (status != TW_OK) {
    if (result != NULL) {
      printf("  a result came back with status %s\n", status_name(status));
      tw_result_free(result);
    }
    return status;
  }
  blob = tw_result_text(result, &length);
  segments = tw_result_segments(result, &n_segments);
  *text = (char*)calloc((size_t)length + 1, 1);
  for (i = 0; i < n_segments; i++) {
    memcpy(*text + used, blob + segments[i].text_offset, (size_t)segments[i].text_length);
    used += (size_t)segments[i].text_length;
  }
  printf("  segments=%d language=%s wall_ms=%lld\n", n_segments, tw_result_language(result),
         (long long)tw_result_wall_ms(result));
  tw_result_free(result);
  return TW_OK;
}

static int usage(void) {
  fprintf(stderr,
          "usage: tw_smoke --model <bin> --sha256 <hex> --wav <wav> --expect <phrase>\n"
          "                [--abort-after-checks N] [--bytes N] [--threads N] [--language CODE]\n"
          "       tw_smoke --self-test\n");
  return EXIT_USAGE;
}

int main(int argc, char** argv) {
  const char* model = NULL;
  const char* sha_hex = NULL;
  const char* wav = NULL;
  const char* expect = NULL;
  const char* language = "en";
  long long bytes = -1;
  int32_t abort_after = 0;
  int32_t threads = 4;
  uint8_t sha[TW_SHA256_BYTES];
  tw_cpu_info cpu;
  tw_context_options context_options;
  tw_context* context = NULL;
  float* pcm;
  int32_t n_samples = 0;
  int32_t status;
  char* text = NULL;
  int exit_code = 0;
  int i;

  for (i = 1; i < argc; i++) {
    const char* arg = argv[i];
    const char* value = i + 1 < argc ? argv[i + 1] : NULL;
    if (strcmp(arg, "--self-test") == 0) {
      return self_test();
    }
    if (value == NULL) {
      return usage();
    }
    if (strcmp(arg, "--model") == 0) model = value;
    else if (strcmp(arg, "--sha256") == 0) sha_hex = value;
    else if (strcmp(arg, "--wav") == 0) wav = value;
    else if (strcmp(arg, "--expect") == 0) expect = value;
    else if (strcmp(arg, "--language") == 0) language = value;
    else if (strcmp(arg, "--abort-after-checks") == 0) abort_after = atoi(value);
    else if (strcmp(arg, "--bytes") == 0) bytes = atoll(value);
    else if (strcmp(arg, "--threads") == 0) threads = atoi(value);
    else return usage();
    i++;
  }
  if (model == NULL || wav == NULL || expect == NULL || !parse_sha(sha_hex, sha)) {
    return usage();
  }
  if (bytes < 0) {
    bytes = file_size(model);
  }

  printf("%s\n", tw_version());
  cpu.struct_size = sizeof(cpu);
  tw_cpu_info_get(&cpu);
  printf("cpu: arch=%u logical=%d performance=%d supported=%d engine=%d runtime=0x%llx "
         "required=0x%llx\n",
         cpu.arch, cpu.n_logical, cpu.n_performance, cpu.supported, cpu.engine_built,
         (unsigned long long)cpu.runtime_features, (unsigned long long)cpu.required_features);

  pcm = read_wav(wav, &n_samples);
  if (pcm == NULL || n_samples == 0) {
    fprintf(stderr, "wav: not 16 kHz 16-bit mono PCM\n");
    return EXIT_USAGE;
  }
  printf("wav: %d samples\n", n_samples);

  tw_log_set_min_level(TW_LOG_INFO);
  tw_context_options_init(&context_options);
  context_options.n_threads = threads;
  status = tw_context_open_file(model, bytes, sha, &context_options, &context);
  if (status != TW_OK) {
    const int foreign = drain_log();
    printf("open: %s (%d); loader lines after verification: %d; live contexts: %d\n",
           status_name(status), status, foreign, tw_live_objects(TW_OBJ_CONTEXT));
    free(pcm);
    return status;
  }
  drain_log();
  tw_log_set_min_level(TW_LOG_WARN);
  printf("open: OK\n");

  if (abort_after > 0) {
    tw_debug_abort_after_checks(abort_after);
    status = run(context, pcm, n_samples, language, threads, &text);
    printf("abort run: %s (%d), whisper code %d\n", status_name(status), status,
           tw_last_whisper_code(context));
    drain_log();
    free(text);
    text = NULL;
    if (status != TW_ERR_ABORTED) {
      exit_code = EXIT_ABORT_CONTRACT;
    }
  }

  if (exit_code == 0) {
    status = run(context, pcm, n_samples, language, threads, &text);
    printf("%s: %s (%d)\n", abort_after > 0 ? "retry" : "run", status_name(status), status);
    if (status != TW_OK) {
      exit_code = abort_after > 0 ? EXIT_ABORT_CONTRACT : status;
    } else {
      printf("text:%s\n", text);
      if (!contains_folded(text, expect)) {
        printf("phrase missing: \"%s\"\n", expect);
        exit_code = EXIT_PHRASE_MISSING;
      }
    }
    free(text);
  }

  tw_context_close(context);
  free(pcm);
  for (i = 0; i <= TW_OBJ_HASHER; i++) {
    if (tw_live_objects(i) != 0) {
      printf("live objects of kind %d: %d\n", i, tw_live_objects(i));
      if (exit_code == 0) {
        exit_code = EXIT_LEAK;
      }
    }
  }
  printf("exit %d\n", exit_code);
  return exit_code;
}
