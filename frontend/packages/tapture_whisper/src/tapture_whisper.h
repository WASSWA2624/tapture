/*
 * tapture_whisper: on-device speech-to-text for Tapture, ABI v1.
 *
 * The only public header of the plugin (app-write-up section 30.4.1). It wraps the
 * vendored whisper.cpp 1.9.4 / ggml 0.23.0 CPU engine behind plain C calls,
 * POD structs with fixed layouts and opaque handles, so Dart FFI and a
 * WebAssembly worker can bind it without a generator.
 *
 * Every struct below has the same layout on 64-bit targets and on wasm32;
 * each size is published as TW_SIZEOF_* and static_assert-ed in the
 * implementation. Every function that frees, closes or releases has the shape
 * void f(T*) and is NULL-safe, so it can serve as a NativeFinalizer callback.
 * All memory is owned by the library: callers never free a returned pointer
 * with their own allocator.
 */
#ifndef TAPTURE_WHISPER_H
#define TAPTURE_WHISPER_H

#include <stddef.h>
#include <stdint.h>

#if defined(_WIN32)
#  if defined(TW_BUILD)
#    define TW_API __declspec(dllexport)
#  else
#    define TW_API __declspec(dllimport)
#  endif
#elif defined(__EMSCRIPTEN__)
#  include <emscripten/emscripten.h>
#  define TW_API EMSCRIPTEN_KEEPALIVE __attribute__((visibility("default")))
#else
#  define TW_API __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

#define TW_ABI_VERSION       1
#define TW_SAMPLE_RATE       16000                /* mono float PCM, Hz */
#define TW_MAX_SAMPLES       (16000 * 600)        /* one call: at most 10 min */
#define TW_VAD_MAX_MS        60000                /* each VAD ms option: at most 60 s */
#define TW_MAX_THREADS       8
#define TW_LANGUAGE_CAPACITY 8
#define TW_LOG_TEXT_CAPACITY 504
#define TW_LOG_RING_CAPACITY 256
#define TW_SHA256_BYTES      32

/* Struct sizes in bytes, identical on 64-bit and wasm32. Bindings read these
 * from this header instead of copying them by hand. */
#define TW_SIZEOF_CONTEXT_OPTIONS    16
#define TW_SIZEOF_TRANSCRIBE_OPTIONS 84
#define TW_SIZEOF_CPU_INFO           40
#define TW_SIZEOF_MEMORY_INFO        32
#define TW_SIZEOF_MODEL_FACTS        56
#define TW_SIZEOF_SEGMENT            48
#define TW_SIZEOF_TOKEN              32
#define TW_SIZEOF_SPAN               16
#define TW_SIZEOF_LOG_ENTRY          512
#define TW_SIZEOF_VAD_OPTIONS        28

typedef enum tw_status {
  TW_OK = 0,
  TW_ERR_INVALID_ARGUMENT = 1,  /* null or out-of-range argument; an empty or
                                   "auto" language; an unknown language */
  TW_ERR_ABI_MISMATCH = 2,      /* struct_size differs from this header */
  TW_ERR_UNSUPPORTED_CPU = 3,   /* the CPU lacks a feature the engine needs */
  TW_ERR_FILE_OPEN = 4,         /* the model file is missing or unreadable */
  TW_ERR_MODEL_INVALID = 5,     /* bad magic or header */
  TW_ERR_MODEL_LOAD = 6,        /* the verified file failed to load */
  TW_ERR_OUT_OF_MEMORY = 7,     /* an allocation failed */
  TW_ERR_ABORTED = 8,           /* the abort cell reached the job id */
  TW_ERR_INFERENCE = 9,         /* whisper failed; see tw_last_whisper_code */
  TW_ERR_POISONED = 10,         /* the context lost its state; close it */
  TW_ERR_BUSY = 11,             /* another call is running on this handle */
  TW_ERR_AUDIO_TOO_LONG = 12,   /* more than TW_MAX_SAMPLES samples */
  TW_ERR_ENGINE_NOT_BUILT = 13, /* stub library for this architecture */
  TW_ERR_INTERNAL = 14,         /* an unexpected C++ exception */
  TW_ERR_MODEL_MISMATCH = 15    /* size or SHA-256 differs from the expectation */
} tw_status;

typedef enum tw_struct_id {
  TW_STRUCT_CONTEXT_OPTIONS = 1,
  TW_STRUCT_TRANSCRIBE_OPTIONS = 2,
  TW_STRUCT_CPU_INFO = 3,
  TW_STRUCT_MEMORY_INFO = 4,
  TW_STRUCT_MODEL_FACTS = 5,
  TW_STRUCT_SEGMENT = 6,
  TW_STRUCT_TOKEN = 7,
  TW_STRUCT_SPAN = 8,
  TW_STRUCT_LOG_ENTRY = 9,
  TW_STRUCT_VAD_OPTIONS = 10
} tw_struct_id;

typedef enum tw_object_kind {
  TW_OBJ_CONTEXT = 0,
  TW_OBJ_RESULT = 1,
  TW_OBJ_VAD = 2,
  TW_OBJ_SPANS = 3,
  TW_OBJ_CELL = 4,
  TW_OBJ_HASHER = 5
} tw_object_kind;

typedef enum tw_arch {
  TW_ARCH_UNKNOWN = 0,
  TW_ARCH_X86_64 = 1,
  TW_ARCH_ARM64 = 2,
  TW_ARCH_ARM32 = 3,
  TW_ARCH_WASM32 = 4,
  TW_ARCH_X86 = 5
} tw_arch;

/* Equal to ggml_log_level 1..4. */
typedef enum tw_log_level {
  TW_LOG_DEBUG = 1,
  TW_LOG_INFO = 2,
  TW_LOG_WARN = 3,
  TW_LOG_ERROR = 4
} tw_log_level;

typedef enum tw_strategy {
  TW_STRATEGY_GREEDY = 0,
  TW_STRATEGY_BEAM = 1
} tw_strategy;

/* CPU feature bits of tw_cpu_info.runtime_features and required_features. */
#define TW_CPU_SSE3      (1ull << 0)
#define TW_CPU_SSSE3     (1ull << 1)
#define TW_CPU_SSE42     (1ull << 2)
#define TW_CPU_AVX       (1ull << 3)
#define TW_CPU_AVX2      (1ull << 4)
#define TW_CPU_FMA       (1ull << 5)
#define TW_CPU_F16C      (1ull << 6)
#define TW_CPU_BMI2      (1ull << 7)
#define TW_CPU_AVX512F   (1ull << 8)
#define TW_CPU_AVX_VNNI  (1ull << 9)
#define TW_CPU_NEON      (1ull << 16)
#define TW_CPU_ARM_FMA   (1ull << 17)
#define TW_CPU_FP16_VA   (1ull << 18)
#define TW_CPU_DOTPROD   (1ull << 19)
#define TW_CPU_I8MM      (1ull << 20)
#define TW_CPU_SVE       (1ull << 21)
#define TW_CPU_SME       (1ull << 22)
#define TW_CPU_WASM_SIMD (1ull << 32)

/* Options of a whisper context or a VAD handle; defaults from
 * tw_context_options_init. */
typedef struct tw_context_options {
  uint32_t struct_size; /*  0 = TW_SIZEOF_CONTEXT_OPTIONS */
  int32_t n_threads;    /*  4 default threads, clamped to [1, min(hw, 8)] */
  uint8_t use_gpu;      /*  8 must be 0: the engine is CPU-only */
  uint8_t flash_attn;   /*  9 1 = whisper's default; ignored by VAD */
  uint8_t reserved[6];  /* 10 zero */
} tw_context_options;

/* Decoding options of one tw_transcribe call; defaults from
 * tw_transcribe_options_init. */
typedef struct tw_transcribe_options {
  uint32_t struct_size;         /*  0 = TW_SIZEOF_TRANSCRIBE_OPTIONS */
  int32_t strategy;             /*  4 tw_strategy, GREEDY */
  int32_t n_threads;            /*  8 0 = the context's default */
  int32_t best_of;              /* 12 1..8, 5 */
  int32_t beam_size;            /* 16 1..8, 5 */
  int32_t max_tokens;           /* 20 per segment, 0 = unlimited */
  int32_t audio_ctx;            /* 24 0 = the model's, else 64..n_audio_ctx */
  int32_t n_max_text_ctx;       /* 28 16384; > 0 when a prompt is passed */
  float temperature;            /* 32 0.0 */
  float temperature_inc;        /* 36 0.2; 0 disables the fallback */
  float entropy_thold;          /* 40 2.4 */
  float logprob_thold;          /* 44 -1.0 */
  float no_speech_thold;        /* 48 0.6 */
  float length_penalty;         /* 52 -1.0 */
  float max_initial_ts;         /* 56 1.0 */
  float token_thold_pt;         /* 60 0.01 */
  float token_thold_ptsum;      /* 64 0.01 */
  uint8_t translate;            /* 68 0 */
  uint8_t no_context;           /* 69 1 */
  uint8_t single_segment;       /* 70 0 */
  uint8_t no_timestamps;        /* 71 0 */
  uint8_t token_timestamps;     /* 72 0 */
  uint8_t suppress_blank;       /* 73 1 */
  uint8_t suppress_nst;         /* 74 1 */
  uint8_t carry_initial_prompt; /* 75 0 */
  char language[TW_LANGUAGE_CAPACITY]; /* 76 NUL-terminated ISO 639-1 code; never
                                          "" or "auto" (no detection pass) */
} tw_transcribe_options;

/* What the CPU offers and what this library needs. */
typedef struct tw_cpu_info {
  uint32_t struct_size;       /*  0 = TW_SIZEOF_CPU_INFO */
  int32_t n_logical;          /*  4 hardware threads */
  int32_t n_performance;      /*  8 cores worth computing on */
  uint32_t arch;              /* 12 tw_arch */
  uint64_t runtime_features;  /* 16 detected now */
  uint64_t required_features; /* 24 what the engine was compiled for */
  uint8_t supported;          /* 32 engine_built and every required feature */
  uint8_t engine_built;       /* 33 0 in a stub library */
  uint8_t reserved[6];        /* 34 zero */
} tw_cpu_info;

/* Memory of the device; -1 means unknown. */
typedef struct tw_memory_info {
  uint32_t struct_size;        /*  0 = TW_SIZEOF_MEMORY_INFO */
  uint32_t reserved;           /*  4 zero */
  int64_t total_bytes;         /*  8 physical memory */
  int64_t available_bytes;     /* 16 available to a new allocation */
  int64_t process_limit_bytes; /* 24 iOS per-process limit, else -1 */
} tw_memory_info;

/* Hyper-parameters of a loaded whisper model. */
typedef struct tw_model_facts {
  uint32_t struct_size; /*  0 = TW_SIZEOF_MODEL_FACTS */
  int32_t n_vocab;      /*  4 */
  int32_t n_audio_ctx;  /*  8 */
  int32_t n_audio_state; /* 12 */
  int32_t n_audio_head; /* 16 */
  int32_t n_audio_layer; /* 20 */
  int32_t n_text_ctx;   /* 24 */
  int32_t n_text_state; /* 28 */
  int32_t n_text_head;  /* 32 */
  int32_t n_text_layer; /* 36 */
  int32_t n_mels;       /* 40 */
  int32_t ftype;        /* 44 whisper ftype, 9 = Q5_1 */
  int32_t model_type;   /* 48 0 unknown, 1 tiny, 2 base, 3 small, 4 medium, 5 large */
  int32_t multilingual; /* 52 0 or 1 */
} tw_model_facts;

/* One decoded segment of a tw_result. */
typedef struct tw_segment {
  int64_t t0_ms;          /*  0 */
  int64_t t1_ms;          /*  8 */
  int32_t text_offset;    /* 16 into tw_result_text; UTF-8 bytes */
  int32_t text_length;    /* 20 */
  int32_t token_offset;   /* 24 into tw_result_tokens */
  int32_t token_count;    /* 28 text tokens only (id < eot) */
  float no_speech_prob;   /* 32 */
  float avg_logprob;      /* 36 mean log probability over every token */
  float mean_p;           /* 40 mean probability over text tokens, else 0 */
  float min_p;            /* 44 lowest probability over text tokens, else 0 */
} tw_segment;

/* One text token of a tw_result; its bytes may be a partial UTF-8 sequence. */
typedef struct tw_token {
  int32_t id;           /*  0 */
  int32_t bytes_offset; /*  4 into tw_result_text */
  int32_t bytes_length; /*  8 */
  float p;              /* 12 */
  int64_t t0_ms;        /* 16 -1 unless token_timestamps */
  int64_t t1_ms;        /* 24 -1 unless token_timestamps */
} tw_token;

/* One speech span of tw_vad_segments. */
typedef struct tw_span {
  int64_t t0_ms; /* 0 */
  int64_t t1_ms; /* 8 */
} tw_span;

/* One drained log line; text is NUL-terminated and length excludes the NUL. */
typedef struct tw_log_entry {
  int32_t level;                   /* 0 tw_log_level */
  int32_t length;                  /* 4 */
  char text[TW_LOG_TEXT_CAPACITY]; /* 8 */
} tw_log_entry;

/* Options of tw_vad_segments; defaults from tw_vad_options_init. The three
 * millisecond options lie in [0, TW_VAD_MAX_MS]; whisper.cpp scales them to
 * samples in 32-bit int arithmetic. */
typedef struct tw_vad_options {
  uint32_t struct_size;    /*  0 = TW_SIZEOF_VAD_OPTIONS */
  float threshold;         /*  4 0.5 */
  int32_t min_speech_ms;   /*  8 250 */
  int32_t min_silence_ms;  /* 12 100 */
  float max_speech_s;      /* 16 FLT_MAX */
  int32_t speech_pad_ms;   /* 20 30 */
  float samples_overlap_s; /* 24 0.1 */
} tw_vad_options;

typedef struct tw_context tw_context;
typedef struct tw_result tw_result;
typedef struct tw_vad tw_vad;
typedef struct tw_spans tw_spans;
typedef struct tw_hasher tw_hasher;

/* ---- library: any thread; the first two never initialise ggml ---- */
TW_API int32_t tw_abi_version(void);
TW_API int32_t tw_struct_size(int32_t struct_id); /* 0 for an unknown id */
TW_API const char* tw_version(void);              /* static string */
TW_API const char* tw_system_info(void); /* valid until the next call */
TW_API int32_t tw_cpu_info_get(tw_cpu_info* out);       /* caller sets struct_size */
TW_API int32_t tw_memory_info_get(tw_memory_info* out); /* caller sets struct_size */
TW_API void tw_debug_set_cpu_override(int32_t supported); /* tests: 0 forces
                                                             unsupported, any
                                                             other value clears */
TW_API void tw_debug_abort_after_checks(int32_t n); /* tests: the next
                                                       transcription aborts
                                                       after n abort checks;
                                                       0 = off */
TW_API int32_t tw_live_objects(int32_t kind);       /* tw_object_kind */
TW_API int32_t tw_lang_id(const char* code);        /* -1 when unknown */

/* ---- SHA-256 ---- */
TW_API int32_t tw_sha256(const void* data, size_t n, uint8_t out[32]);
TW_API tw_hasher* tw_sha256_new(void);
TW_API void tw_sha256_update(tw_hasher* hasher, const void* data, size_t n);
TW_API int32_t tw_sha256_finish(tw_hasher* hasher, uint8_t out[32]); /* frees */

/* ---- logging: any thread ---- */
TW_API void tw_log_set_min_level(int32_t level); /* default TW_LOG_WARN */
TW_API int32_t tw_log_drain(tw_log_entry* out, int32_t capacity);
TW_API uint32_t tw_log_dropped(void);
TW_API int32_t tw_set_crash_file(const char* path_utf8); /* NULL disables */

/* ---- reference-counted atomic abort cells: any thread or isolate ---- */
TW_API int32_t* tw_cell_new(void); /* value 0, reference count 1 */
TW_API void tw_cell_retain(int32_t* cell);
TW_API void tw_cell_release(int32_t* cell); /* frees at count 0 */
TW_API void tw_cell_store(int32_t* cell, int32_t value);
TW_API int32_t tw_cell_load(const int32_t* cell);

/* ---- whisper context: one call at a time per handle ---- */
TW_API void tw_context_options_init(tw_context_options* options);
TW_API int32_t tw_context_open_file(const char* path_utf8,
                                    int64_t expected_bytes,
                                    const uint8_t* expected_sha256,
                                    const tw_context_options* options,
                                    tw_context** out);
TW_API int32_t tw_context_open_buffer(const void* data, size_t size,
                                      const uint8_t* expected_sha256,
                                      const tw_context_options* options,
                                      tw_context** out);
TW_API int32_t tw_context_open_js(int32_t file_id, int64_t expected_bytes,
                                  const uint8_t* expected_sha256,
                                  const tw_context_options* options,
                                  tw_context** out); /* WebAssembly only */
TW_API void tw_context_close(tw_context* context); /* deferred while busy */
TW_API int32_t tw_context_facts(tw_context* context, tw_model_facts* out);
TW_API float* tw_context_pcm_buffer(tw_context* context, int32_t n_samples);
TW_API int32_t tw_last_whisper_code(const tw_context* context);
TW_API void tw_transcribe_options_init(tw_transcribe_options* options);
TW_API int32_t tw_transcribe(tw_context* context, const float* pcm,
                             int32_t n_samples,
                             const tw_transcribe_options* options,
                             const char* initial_prompt_utf8,
                             const int32_t* prompt_tokens,
                             int32_t n_prompt_tokens,
                             const int32_t* abort_cell, int32_t job_id,
                             tw_result** out);

/* ---- result: an immutable copy, independent of the context ---- */
TW_API void tw_result_free(tw_result* result);
TW_API const tw_segment* tw_result_segments(const tw_result* result,
                                            int32_t* count);
TW_API const tw_token* tw_result_tokens(const tw_result* result,
                                        int32_t* count);
TW_API const uint8_t* tw_result_text(const tw_result* result, int32_t* length);
TW_API const char* tw_result_language(const tw_result* result);
TW_API int64_t tw_result_wall_ms(const tw_result* result);

/* ---- Silero VAD: one call at a time per handle ---- */
TW_API int32_t tw_vad_open_file(const char* path_utf8, int64_t expected_bytes,
                                const uint8_t* expected_sha256,
                                const tw_context_options* options,
                                tw_vad** out);
TW_API int32_t tw_vad_open_buffer(const void* data, size_t size,
                                  const uint8_t* expected_sha256,
                                  const tw_context_options* options,
                                  tw_vad** out);
TW_API int32_t tw_vad_open_js(int32_t file_id, int64_t expected_bytes,
                              const uint8_t* expected_sha256,
                              const tw_context_options* options,
                              tw_vad** out); /* WebAssembly only */
TW_API void tw_vad_close(tw_vad* vad); /* deferred while busy */
TW_API int32_t tw_vad_window_samples(const tw_vad* vad);
TW_API float* tw_vad_pcm_buffer(tw_vad* vad, int32_t n_samples);
TW_API int32_t tw_vad_feed(tw_vad* vad, const float* pcm, int32_t n_samples,
                           int32_t* out_n_probs);
TW_API const float* tw_vad_probs(const tw_vad* vad, int32_t* count);
TW_API int32_t tw_vad_pending_samples(const tw_vad* vad);
TW_API void tw_vad_reset(tw_vad* vad);
TW_API void tw_vad_options_init(tw_vad_options* options);
TW_API int32_t tw_vad_segments(tw_vad* vad, const float* pcm,
                               int32_t n_samples,
                               const tw_vad_options* options, tw_spans** out);
TW_API const tw_span* tw_spans_data(const tw_spans* spans, int32_t* count);
TW_API void tw_spans_free(tw_spans* spans);

#ifdef __cplusplus
}
#endif

#endif /* TAPTURE_WHISPER_H */
