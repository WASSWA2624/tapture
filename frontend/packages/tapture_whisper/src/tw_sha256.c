/*
 * SHA-256 as specified in FIPS 180-4 sections 4.1.2, 5.1.1, 5.3.3 and 6.2.
 *
 * Written for tapture_whisper so that model verification needs no platform
 * crypto: it runs the same on Windows, Android, Linux, Apple and in a
 * WebAssembly worker without a secure context. tw_smoke --self-test checks it
 * against the NIST CAVP vectors.
 */
#include "tw_sha256.h"

#include <string.h>

/* FIPS 180-4 section 4.2.2: the first 32 bits of the fractional parts of the cube
 * roots of the first 64 primes. */
static const uint32_t tw_sha256_k[64] = {
    0x428a2f98u, 0x71374491u, 0xb5c0fbcfu, 0xe9b5dba5u, 0x3956c25bu,
    0x59f111f1u, 0x923f82a4u, 0xab1c5ed5u, 0xd807aa98u, 0x12835b01u,
    0x243185beu, 0x550c7dc3u, 0x72be5d74u, 0x80deb1feu, 0x9bdc06a7u,
    0xc19bf174u, 0xe49b69c1u, 0xefbe4786u, 0x0fc19dc6u, 0x240ca1ccu,
    0x2de92c6fu, 0x4a7484aau, 0x5cb0a9dcu, 0x76f988dau, 0x983e5152u,
    0xa831c66du, 0xb00327c8u, 0xbf597fc7u, 0xc6e00bf3u, 0xd5a79147u,
    0x06ca6351u, 0x14292967u, 0x27b70a85u, 0x2e1b2138u, 0x4d2c6dfcu,
    0x53380d13u, 0x650a7354u, 0x766a0abbu, 0x81c2c92eu, 0x92722c85u,
    0xa2bfe8a1u, 0xa81a664bu, 0xc24b8b70u, 0xc76c51a3u, 0xd192e819u,
    0xd6990624u, 0xf40e3585u, 0x106aa070u, 0x19a4c116u, 0x1e376c08u,
    0x2748774cu, 0x34b0bcb5u, 0x391c0cb3u, 0x4ed8aa4au, 0x5b9cca4fu,
    0x682e6ff3u, 0x748f82eeu, 0x78a5636fu, 0x84c87814u, 0x8cc70208u,
    0x90befffau, 0xa4506cebu, 0xbef9a3f7u, 0xc67178f2u};

static uint32_t tw_rotr(uint32_t x, unsigned n) {
  return (x >> n) | (x << (32u - n));
}

static uint32_t tw_load_be32(const uint8_t* p) {
  return ((uint32_t)p[0] << 24) | ((uint32_t)p[1] << 16) |
         ((uint32_t)p[2] << 8) | (uint32_t)p[3];
}

static void tw_store_be32(uint8_t* p, uint32_t v) {
  p[0] = (uint8_t)(v >> 24);
  p[1] = (uint8_t)(v >> 16);
  p[2] = (uint8_t)(v >> 8);
  p[3] = (uint8_t)v;
}

/* FIPS 180-4 section 6.2.2: one 512-bit block. */
static void tw_sha256_compress(uint32_t h[8], const uint8_t block[64]) {
  uint32_t w[64];
  uint32_t a, b, c, d, e, f, g, hh;
  int t;

  for (t = 0; t < 16; t++) {
    w[t] = tw_load_be32(block + 4 * t);
  }
  for (t = 16; t < 64; t++) {
    const uint32_t s0 =
        tw_rotr(w[t - 15], 7) ^ tw_rotr(w[t - 15], 18) ^ (w[t - 15] >> 3);
    const uint32_t s1 =
        tw_rotr(w[t - 2], 17) ^ tw_rotr(w[t - 2], 19) ^ (w[t - 2] >> 10);
    w[t] = w[t - 16] + s0 + w[t - 7] + s1;
  }

  a = h[0];
  b = h[1];
  c = h[2];
  d = h[3];
  e = h[4];
  f = h[5];
  g = h[6];
  hh = h[7];
  for (t = 0; t < 64; t++) {
    const uint32_t big_s1 = tw_rotr(e, 6) ^ tw_rotr(e, 11) ^ tw_rotr(e, 25);
    const uint32_t ch = (e & f) ^ (~e & g);
    const uint32_t t1 = hh + big_s1 + ch + tw_sha256_k[t] + w[t];
    const uint32_t big_s0 = tw_rotr(a, 2) ^ tw_rotr(a, 13) ^ tw_rotr(a, 22);
    const uint32_t maj = (a & b) ^ (a & c) ^ (b & c);
    const uint32_t t2 = big_s0 + maj;
    hh = g;
    g = f;
    f = e;
    e = d + t1;
    d = c;
    c = b;
    b = a;
    a = t1 + t2;
  }
  h[0] += a;
  h[1] += b;
  h[2] += c;
  h[3] += d;
  h[4] += e;
  h[5] += f;
  h[6] += g;
  h[7] += hh;
}

void tw_sha256_state_begin(tw_sha256_state* state) {
  /* FIPS 180-4 section 5.3.3. */
  state->h[0] = 0x6a09e667u;
  state->h[1] = 0xbb67ae85u;
  state->h[2] = 0x3c6ef372u;
  state->h[3] = 0xa54ff53au;
  state->h[4] = 0x510e527fu;
  state->h[5] = 0x9b05688cu;
  state->h[6] = 0x1f83d9abu;
  state->h[7] = 0x5be0cd19u;
  state->total_bytes = 0;
  state->used = 0;
}

void tw_sha256_state_feed(tw_sha256_state* state, const void* data, size_t n) {
  const uint8_t* p = (const uint8_t*)data;
  if (n == 0) {
    return;
  }
  state->total_bytes += (uint64_t)n;
  if (state->used > 0) {
    const size_t room = 64u - state->used;
    const size_t take = n < room ? n : room;
    memcpy(state->block + state->used, p, take);
    state->used += (uint32_t)take;
    p += take;
    n -= take;
    if (state->used < 64u) {
      return;
    }
    tw_sha256_compress(state->h, state->block);
    state->used = 0;
  }
  while (n >= 64u) {
    tw_sha256_compress(state->h, p);
    p += 64;
    n -= 64;
  }
  if (n > 0) {
    memcpy(state->block, p, n);
    state->used = (uint32_t)n;
  }
}

void tw_sha256_state_end(tw_sha256_state* state, uint8_t out[32]) {
  /* FIPS 180-4 section 5.1.1: a 1 bit, zeros to 448 mod 512, the 64-bit length. */
  const uint64_t bits = state->total_bytes * 8u;
  int i;
  state->block[state->used++] = 0x80u;
  if (state->used > 56u) {
    memset(state->block + state->used, 0, 64u - state->used);
    tw_sha256_compress(state->h, state->block);
    state->used = 0;
  }
  memset(state->block + state->used, 0, 56u - state->used);
  for (i = 0; i < 8; i++) {
    state->block[56 + i] = (uint8_t)(bits >> (56 - 8 * i));
  }
  tw_sha256_compress(state->h, state->block);
  for (i = 0; i < 8; i++) {
    tw_store_be32(out + 4 * i, state->h[i]);
  }
  memset(state, 0, sizeof(*state));
}
