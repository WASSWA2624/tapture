/* A miniature of the shim header: what the WebAssembly check reads. */
#define TW_ABI_VERSION 1

#define TW_SIZEOF_CONTEXT_OPTIONS 16
#define TW_SIZEOF_SPAN            16

typedef enum tw_status {
  TW_OK = 0,
  TW_ERR_INVALID_ARGUMENT = 1,
  TW_ERR_MODEL_MISMATCH = 2
} tw_status;

typedef enum tw_struct_id {
  TW_STRUCT_CONTEXT_OPTIONS = 1,
  TW_STRUCT_SPAN = 2
} tw_struct_id;

TW_API int32_t tw_abi_version(void);
TW_API const char* tw_version(void);
TW_API int32_t tw_context_open_js(int32_t file_id, int64_t expected_bytes,
                                  const uint8_t* expected_sha256);
