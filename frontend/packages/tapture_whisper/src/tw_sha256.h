/*
 * SHA-256 (FIPS 180-4) for tapture_whisper: the shim verifies every model
 * before whisper.cpp parses a byte of it (app-write-up §30.4.1).
 *
 * Internal to the library. The exported ABI wraps it as tw_sha256,
 * tw_sha256_new, tw_sha256_update and tw_sha256_finish in tapture_whisper.h.
 */
#ifndef TW_SHA256_H
#define TW_SHA256_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Running state of one digest. Plain data: copy, embed or allocate freely. */
typedef struct tw_sha256_state {
  uint32_t h[8];        /* chaining value H(i) */
  uint64_t total_bytes; /* message length so far */
  uint8_t block[64];    /* pending partial block */
  uint32_t used;        /* bytes pending in block, 0..63 */
} tw_sha256_state;

/* Starts a digest with the FIPS 180-4 initial hash value. */
void tw_sha256_state_begin(tw_sha256_state* state);

/* Absorbs n bytes. data may be NULL only when n is 0. */
void tw_sha256_state_feed(tw_sha256_state* state, const void* data, size_t n);

/* Pads, writes the 32-byte digest to out and wipes the state. */
void tw_sha256_state_end(tw_sha256_state* state, uint8_t out[32]);

#ifdef __cplusplus
}
#endif

#endif /* TW_SHA256_H */
