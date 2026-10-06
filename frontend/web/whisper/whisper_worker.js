// Tapture speech worker: the on-device whisper.cpp engine for the web
// (dev-plan task 111, app-write-up section 30.4.8).
//
// A module worker that loads tapture_whisper_st or tapture_whisper_mt from its
// own directory and serves the protocol below. Nothing here is fetched from
// another origin, and no model byte is copied whole into the WebAssembly heap:
// the shim pulls each model through Module.twSourceRead from an OPFS sync
// access handle (or, without OPFS, a fetched ArrayBuffer) and verifies its
// size and SHA-256 before whisper.cpp parses it, so crypto.subtle is never
// needed and plain-HTTP LAN serving works.
//
// Requests are {id, op, args}. Replies are {id, ok: true, result} or
// {id, ok: false, error: {code, status, whisperCode}}. Events are
// {event: 'log', entries: [{level, text}], dropped}.
//
//   init {variant: 'auto'|'st'|'mt'}
//     -> {abi, variant, maxThreads, logicalCores, deviceMemoryGb, version,
//         structSizes} and, on mt, {memory, abortCell: {byteOffset}}.
//     mt only when crossOriginIsolated and SharedArrayBuffer exist; otherwise
//     st runs without an error.
//   loadModel {kind: 'whisper'|'vad', url, cacheKey, sha256, bytes, threads,
//              flashAttn}
//     -> {handle, servedFrom, facts} (whisper) or {handle, servedFrom,
//        windowSamples} (vad). servedFrom is 'opfs', 'network' or 'memory'.
//   verify {cacheKey, sha256, bytes} -> {present, ok}
//   transcribe {handle, jobId, leaseId, pcm: Float32Array, options,
//               initialPrompt, promptPieces: Int32Array}
//     -> {segments, pieces, textBytes, language, wallMs}
//   vadFeed {handle, pcm: Float32Array} -> {probs, pendingSamples}
//   vadReset {handle} -> {}
//   abort {jobId, leaseId} -> {dropped}
//   memory {} -> {heapBytes, deviceMemoryGb}
//   liveObjects {} -> {contexts, results, vads, spans, cells, hashers}
//   close {handle} -> {closed}
//   dispose {} -> {}, then the worker closes itself.
//
// Abort. Requests run one at a time in arrival order. `abort` drops the
// queued transcriptions of that lease (every one when jobId is absent, else
// those up to jobId); each dropped request is answered with `aborted`. A
// running mt transcription is aborted by the page, which stores the running
// job's id into the shared abort cell with Atomics.store; it must store only
// the id of a job of the lease it aborts, because the shim aborts any job
// whose id is at most the cell's value. A running st transcription cannot
// be interrupted: the page terminates the worker.

const ABI_VERSION = 1;

// Most compute threads a web decode uses; the mt pool holds 8 workers.
const WEB_MAX_THREADS = 4;

// Bytes hashed per call when `verify` streams an OPFS entry.
const VERIFY_CHUNK = 256 * 1024;

// Log lines drained after each request.
const LOG_DRAIN_MAX = 64;

// tw_struct_id and TW_SIZEOF_* of tapture_whisper.h; tool/whisper_wasm.dart
// --check fails when this table drifts from the header.
// tw-struct-table:begin
const STRUCTS = Object.freeze({
  CONTEXT_OPTIONS: { id: 1, size: 16 },
  TRANSCRIBE_OPTIONS: { id: 2, size: 84 },
  CPU_INFO: { id: 3, size: 40 },
  MEMORY_INFO: { id: 4, size: 32 },
  MODEL_FACTS: { id: 5, size: 56 },
  SEGMENT: { id: 6, size: 48 },
  TOKEN: { id: 7, size: 32 },
  SPAN: { id: 8, size: 16 },
  LOG_ENTRY: { id: 9, size: 512 },
  VAD_OPTIONS: { id: 10, size: 28 },
});
// tw-struct-table:end

// tw_status names, indexed by status; checked against the header the same way.
// tw-status-table:begin
const STATUS_CODES = Object.freeze([
  'ok',
  'invalid_argument',
  'abi_mismatch',
  'unsupported_cpu',
  'file_open',
  'model_invalid',
  'model_load',
  'out_of_memory',
  'aborted',
  'inference',
  'poisoned',
  'busy',
  'audio_too_long',
  'engine_not_built',
  'internal',
  'model_mismatch',
]);
// tw-status-table:end

const STATUS = Object.freeze({
  OK: 0,
  INVALID_ARGUMENT: 1,
  ABI_MISMATCH: 2,
  OUT_OF_MEMORY: 7,
  ABORTED: 8,
  AUDIO_TOO_LONG: 12,
  INTERNAL: 14,
  MODEL_MISMATCH: 15,
});

// TW_MAX_SAMPLES: one transcription is at most 10 minutes of 16 kHz audio.
const MAX_SAMPLES = 16000 * 600;

// tw_object_kind.
const OBJECT_KINDS = Object.freeze({
  contexts: 0,
  results: 1,
  vads: 2,
  spans: 3,
  cells: 4,
  hashers: 5,
});

// tw_transcribe_options: wire name -> [byte offset, type]. Pieces are what
// the C header calls tokens.
const TRANSCRIBE_FIELDS = Object.freeze({
  strategy: [4, 'i32'],
  threads: [8, 'i32'],
  bestOf: [12, 'i32'],
  beamSize: [16, 'i32'],
  maxPieces: [20, 'i32'],
  audioCtx: [24, 'i32'],
  maxTextCtx: [28, 'i32'],
  temperature: [32, 'f32'],
  temperatureInc: [36, 'f32'],
  entropyThold: [40, 'f32'],
  logprobThold: [44, 'f32'],
  noSpeechThold: [48, 'f32'],
  lengthPenalty: [52, 'f32'],
  maxInitialTs: [56, 'f32'],
  pieceTholdPt: [60, 'f32'],
  pieceTholdPtsum: [64, 'f32'],
  translate: [68, 'u8'],
  noContext: [69, 'u8'],
  singleSegment: [70, 'u8'],
  noTimestamps: [71, 'u8'],
  pieceTimestamps: [72, 'u8'],
  suppressBlank: [73, 'u8'],
  suppressNst: [74, 'u8'],
  carryInitialPrompt: [75, 'u8'],
});
const TRANSCRIBE_LANGUAGE_OFFSET = 76;
const LANGUAGE_CAPACITY = 8;

// The smallest module using a v128 instruction: (func (result v128)
// i32.const 0 i8x16.splat i8x16.popcnt).
const SIMD_PROBE = new Uint8Array([
  0, 97, 115, 109, 1, 0, 0, 0, 1, 5, 1, 96, 0, 1, 123, 3, 2, 1, 0, 10, 10, 1, 8,
  0, 65, 0, 253, 15, 253, 98, 11,
]);

const OPFS_DIRECTORY = 'whisper-models';
const CACHE_KEY = /^[A-Za-z0-9._-]{1,128}$/;
const SHA256_HEX = /^[0-9a-f]{64}$/;

let wasm = null;
let info = null;
let abortCell = 0;
let broken = false;
const handles = new Map();
const sources = new Map();
let nextFileId = 1;
const queue = [];
let draining = false;
const printed = [];

let heapBuffer = null;
let heapViews = null;

// HEAPU8, HEAP32, HEAPU32, HEAPF32 and HEAP64 views of the current heap,
// re-derived from wasmMemory.buffer whenever it changed; 64-bit fields are
// read through the HEAP64 view. Never cache a view: growth replaces the
// buffer, and on mt another thread may grow it at any time.
function heap() {
  const buffer = wasm.wasmMemory.buffer;
  if (buffer !== heapBuffer) {
    heapBuffer = buffer;
    heapViews = {
      u8: new Uint8Array(buffer),
      i32: new Int32Array(buffer),
      u32: new Uint32Array(buffer),
      f32: new Float32Array(buffer),
      i64: new BigInt64Array(buffer),
    };
  }
  return heapViews;
}

class WorkerFailure extends Error {
  constructor(code, status = -1, whisperCode = 0) {
    super(code);
    this.code = code;
    this.status = status;
    this.whisperCode = whisperCode;
  }
}

function statusFailure(status, whisperCode = 0) {
  return new WorkerFailure(STATUS_CODES[status] ?? 'internal', status, whisperCode);
}

function invalid() {
  return new WorkerFailure('invalid_argument', STATUS.INVALID_ARGUMENT);
}

// Runs fn with scratch allocated by alloc() on the wasm stack, released after.
function withStack(fn) {
  const top = wasm.stackSave();
  try {
    return fn((bytes) => wasm.stackAlloc(bytes));
  } finally {
    wasm.stackRestore(top);
  }
}

function sameOriginUrl(url) {
  let parsed;
  try {
    parsed = new URL(String(url), self.location.href);
  } catch (_) {
    throw new WorkerFailure('cross_origin');
  }
  const web = parsed.protocol === 'http:' || parsed.protocol === 'https:';
  if (!web || parsed.origin !== self.location.origin) {
    throw new WorkerFailure('cross_origin');
  }
  return parsed;
}

function hexBytes(hex) {
  const bytes = new Uint8Array(32);
  for (let i = 0; i < 32; i++) {
    bytes[i] = parseInt(hex.substr(i * 2, 2), 16);
  }
  return bytes;
}

function requireInit() {
  if (wasm === null || broken) {
    throw broken ? new WorkerFailure('internal', STATUS.INTERNAL) : invalid();
  }
}

function requireHandle(handle, kind) {
  const entry = handles.get(handle);
  if (entry === undefined || entry.kind !== kind) {
    throw invalid();
  }
  return entry;
}

function requireSamples(pcm) {
  if (!(pcm instanceof Float32Array)) {
    throw invalid();
  }
  return pcm;
}

// ---------------------------------------------------------------------------
// Model sources: the shim reads them through Module.twSourceRead.
// ---------------------------------------------------------------------------

let copyScratch = null;

function sourceOverAccessHandle(access) {
  return {
    size: access.getSize(),
    read(offset, destination, count) {
      try {
        return access.read(new Uint8Array(heap().u8.buffer, destination, count), { at: offset });
      } catch (error) {
        if (!(error instanceof TypeError)) {
          throw error;
        }
        // A browser that refuses shared views reads through a private buffer.
        if (copyScratch === null || copyScratch.byteLength < count) {
          copyScratch = new ArrayBuffer(count);
        }
        const view = new Uint8Array(copyScratch, 0, count);
        const read = access.read(view, { at: offset });
        heap().u8.set(view.subarray(0, read), destination);
        return read;
      }
    },
  };
}

function sourceOverBuffer(buffer) {
  return {
    size: buffer.byteLength,
    read(offset, destination, count) {
      const take = Math.max(0, Math.min(count, buffer.byteLength - offset));
      heap().u8.set(new Uint8Array(buffer, offset, take), destination);
      return take;
    },
  };
}

function sourceSize(fileId) {
  const source = sources.get(fileId);
  return source === undefined ? -1 : source.size;
}

function sourceRead(fileId, offset, destination, count) {
  const source = sources.get(fileId);
  return source === undefined ? -1 : source.read(offset, destination, count);
}

// Registers source as a file id for the duration of open(fileId).
function withSource(source, open) {
  const fileId = nextFileId++;
  sources.set(fileId, source);
  try {
    return open(fileId);
  } finally {
    sources.delete(fileId);
  }
}

async function opfsDirectory() {
  const storage = globalThis.navigator?.storage;
  const syncAccess = globalThis.FileSystemFileHandle?.prototype?.createSyncAccessHandle;
  if (typeof storage?.getDirectory !== 'function' || typeof syncAccess !== 'function') {
    return null;
  }
  try {
    const root = await storage.getDirectory();
    return await root.getDirectoryHandle(OPFS_DIRECTORY, { create: true });
  } catch (_) {
    return null;
  }
}

async function openCached(directory, cacheKey, bytes) {
  let file;
  try {
    file = await directory.getFileHandle(cacheKey);
  } catch (_) {
    return null;
  }
  try {
    const access = await file.createSyncAccessHandle();
    if (access.getSize() === bytes) {
      return access;
    }
    access.close();
  } catch (_) {
    throw new WorkerFailure('storage');
  }
  await removeCached(directory, cacheKey);
  return null;
}

async function removeCached(directory, cacheKey) {
  try {
    await directory.removeEntry(cacheKey);
  } catch (_) {
    // Already gone, or locked by another worker; the next load re-checks it.
  }
}

async function fetchModel(url) {
  let response;
  try {
    response = await fetch(url.href, { credentials: 'same-origin', cache: 'no-store' });
  } catch (_) {
    throw new WorkerFailure('fetch_failed');
  }
  if (new URL(response.url || url.href).origin !== self.location.origin) {
    await response.body?.cancel();
    throw new WorkerFailure('cross_origin');
  }
  if (!response.ok || response.body === null) {
    await response.body?.cancel();
    throw new WorkerFailure('fetch_failed');
  }
  return response;
}

// Streams the response into the OPFS entry and returns its open sync handle.
// A response longer than the expected bytes is refused as model_mismatch
// before it can fill the origin's storage.
async function downloadToCache(directory, cacheKey, url, bytes) {
  const response = await fetchModel(url);
  let access;
  try {
    const file = await directory.getFileHandle(cacheKey, { create: true });
    access = await file.createSyncAccessHandle();
    access.truncate(0);
  } catch (_) {
    await response.body.cancel();
    throw new WorkerFailure('storage');
  }
  let offset = 0;
  const reader = response.body.getReader();
  try {
    for (;;) {
      let chunk;
      try {
        chunk = await reader.read();
      } catch (_) {
        throw new WorkerFailure('fetch_failed');
      }
      if (chunk.done) {
        break;
      }
      if (offset + chunk.value.byteLength > bytes) {
        await reader.cancel().catch(() => {});
        throw new WorkerFailure('model_mismatch', STATUS.MODEL_MISMATCH);
      }
      try {
        offset += access.write(chunk.value, { at: offset });
      } catch (_) {
        throw new WorkerFailure('storage');
      }
    }
    access.flush();
    return access;
  } catch (error) {
    access.close();
    await removeCached(directory, cacheKey);
    throw error;
  }
}

async function fetchToMemory(url) {
  const response = await fetchModel(url);
  try {
    return await response.arrayBuffer();
  } catch (_) {
    throw new WorkerFailure('fetch_failed');
  }
}

// ---------------------------------------------------------------------------
// Operations.
// ---------------------------------------------------------------------------

function simdSupported() {
  try {
    return WebAssembly.validate(SIMD_PROBE);
  } catch (_) {
    return false;
  }
}

async function init(args) {
  if (wasm !== null) {
    requireInit();
    return info;
  }
  if (!simdSupported()) {
    throw new WorkerFailure('no_simd');
  }
  const requested = args?.variant ?? 'auto';
  if (!['auto', 'st', 'mt'].includes(requested)) {
    throw invalid();
  }
  const threadsUsable =
    globalThis.crossOriginIsolated === true && typeof SharedArrayBuffer === 'function';
  const variant = requested !== 'st' && threadsUsable ? 'mt' : 'st';
  try {
    const { default: create } = await import(`./tapture_whisper_${variant}.js`);
    wasm = await create({
      twSourceSize: sourceSize,
      twSourceRead: sourceRead,
      print: (text) => printed.push({ level: 2, text: String(text) }),
      printErr: (text) => printed.push({ level: 4, text: String(text) }),
    });
  } catch (_) {
    wasm = null;
    throw new WorkerFailure('fetch_failed');
  }
  if (wasm._tw_abi_version() !== ABI_VERSION) {
    wasm = null;
    throw new WorkerFailure('abi_mismatch', STATUS.ABI_MISMATCH);
  }
  const structSizes = {};
  for (const [name, layout] of Object.entries(STRUCTS)) {
    structSizes[name] = wasm._tw_struct_size(layout.id);
    if (structSizes[name] !== layout.size) {
      wasm = null;
      throw new WorkerFailure('abi_mismatch', STATUS.ABI_MISMATCH);
    }
  }
  const logicalCores = globalThis.navigator?.hardwareConcurrency ?? 1;
  info = {
    abi: ABI_VERSION,
    variant,
    maxThreads: variant === 'mt' ? Math.max(1, Math.min(logicalCores, WEB_MAX_THREADS)) : 1,
    logicalCores,
    deviceMemoryGb: globalThis.navigator?.deviceMemory ?? null,
    version: wasm.UTF8ToString(wasm._tw_version()),
    structSizes,
  };
  if (variant === 'mt') {
    abortCell = wasm._tw_cell_new();
    if (abortCell === 0) {
      // Without the cell a later init would return an mt info with no abort.
      wasm = null;
      info = null;
      throw new WorkerFailure('out_of_memory', STATUS.OUT_OF_MEMORY);
    }
    info.memory = wasm.wasmMemory;
    info.abortCell = { byteOffset: abortCell };
  }
  return info;
}

function checkModelArgs(args) {
  const kind = args?.kind;
  const bytes = args?.bytes;
  if (
    (kind !== 'whisper' && kind !== 'vad') ||
    typeof args.cacheKey !== 'string' ||
    !CACHE_KEY.test(args.cacheKey) ||
    typeof args.sha256 !== 'string' ||
    !SHA256_HEX.test(args.sha256) ||
    !Number.isSafeInteger(bytes) ||
    bytes <= 0
  ) {
    throw invalid();
  }
}

function openNative(kind, fileId, bytes, sha256, threads, flashAttn) {
  return withStack((alloc) => {
    const sha = alloc(32);
    heap().u8.set(hexBytes(sha256), sha);
    const options = alloc(STRUCTS.CONTEXT_OPTIONS.size);
    wasm._tw_context_options_init(options);
    if (Number.isInteger(threads) && threads > 0) {
      heap().i32[(options + 4) >> 2] = threads;
    }
    if (typeof flashAttn === 'boolean') {
      heap().u8[options + 9] = flashAttn ? 1 : 0;
    }
    const out = alloc(4);
    heap().u32[out >> 2] = 0;
    const open = kind === 'whisper' ? wasm._tw_context_open_js : wasm._tw_vad_open_js;
    const status = open(fileId, BigInt(bytes), sha, options, out);
    return { status, handle: heap().u32[out >> 2] };
  });
}

function modelFacts(handle) {
  return withStack((alloc) => {
    const facts = alloc(STRUCTS.MODEL_FACTS.size);
    heap().u32[facts >> 2] = STRUCTS.MODEL_FACTS.size;
    const status = wasm._tw_context_facts(handle, facts);
    if (status !== STATUS.OK) {
      throw statusFailure(status);
    }
    const i32 = heap().i32;
    const at = (offset) => i32[(facts + offset) >> 2];
    return {
      nVocab: at(4),
      nAudioCtx: at(8),
      nAudioState: at(12),
      nAudioHead: at(16),
      nAudioLayer: at(20),
      nTextCtx: at(24),
      nTextState: at(28),
      nTextHead: at(32),
      nTextLayer: at(36),
      nMels: at(40),
      ftype: at(44),
      modelType: at(48),
      multilingual: at(52) === 1,
    };
  });
}

async function loadModel(args) {
  requireInit();
  checkModelArgs(args);
  const url = sameOriginUrl(args.url);
  const { kind, cacheKey, sha256, bytes } = args;
  const directory = await opfsDirectory();
  let access = null;
  let buffer = null;
  let servedFrom;
  if (directory !== null) {
    access = await openCached(directory, cacheKey, bytes);
    servedFrom = 'opfs';
    if (access === null) {
      access = await downloadToCache(directory, cacheKey, url, bytes);
      servedFrom = 'network';
    }
  } else {
    buffer = await fetchToMemory(url);
    servedFrom = 'memory';
  }
  let opened;
  try {
    const source = access !== null ? sourceOverAccessHandle(access) : sourceOverBuffer(buffer);
    opened = withSource(source, (fileId) =>
      openNative(kind, fileId, bytes, sha256, args.threads, args.flashAttn),
    );
  } finally {
    access?.close();
  }
  if (opened.status !== STATUS.OK) {
    if (opened.status === STATUS.MODEL_MISMATCH && directory !== null) {
      await removeCached(directory, cacheKey);
    }
    throw statusFailure(opened.status);
  }
  const handle = opened.handle;
  handles.set(handle, { kind });
  if (kind === 'vad') {
    return { handle, servedFrom, windowSamples: wasm._tw_vad_window_samples(handle) };
  }
  return { handle, servedFrom, facts: modelFacts(handle) };
}

async function verify(args) {
  requireInit();
  if (
    typeof args?.cacheKey !== 'string' ||
    !CACHE_KEY.test(args.cacheKey) ||
    typeof args.sha256 !== 'string' ||
    !SHA256_HEX.test(args.sha256) ||
    !Number.isSafeInteger(args.bytes)
  ) {
    throw invalid();
  }
  const directory = await opfsDirectory();
  if (directory === null) {
    return { present: false, ok: false };
  }
  let file;
  try {
    file = await directory.getFileHandle(args.cacheKey);
  } catch (_) {
    return { present: false, ok: false };
  }
  let access;
  try {
    access = await file.createSyncAccessHandle();
  } catch (_) {
    throw new WorkerFailure('storage');
  }
  try {
    if (access.getSize() !== args.bytes) {
      return { present: true, ok: false };
    }
    const digest = withStack((alloc) => {
      const chunk = alloc(VERIFY_CHUNK);
      const out = alloc(32);
      const hasher = wasm._tw_sha256_new();
      if (hasher === 0) {
        throw new WorkerFailure('out_of_memory', STATUS.OUT_OF_MEMORY);
      }
      // finish is the only call that frees the hasher, so a read that throws
      // still reaches it.
      try {
        const source = sourceOverAccessHandle(access);
        for (let offset = 0; offset < args.bytes; ) {
          const read = source.read(offset, chunk, Math.min(VERIFY_CHUNK, args.bytes - offset));
          if (read <= 0) {
            break;
          }
          wasm._tw_sha256_update(hasher, chunk, read);
          offset += read;
        }
      } finally {
        wasm._tw_sha256_finish(hasher, out);
      }
      return Array.from(heap().u8.subarray(out, out + 32), (b) =>
        b.toString(16).padStart(2, '0'),
      ).join('');
    });
    return { present: true, ok: digest === args.sha256 };
  } finally {
    access.close();
  }
}

function writeTranscribeOptions(pointer, options) {
  wasm._tw_transcribe_options_init(pointer);
  const views = heap();
  for (const [name, value] of Object.entries(options ?? {})) {
    if (name === 'language') {
      continue;
    }
    const field = TRANSCRIBE_FIELDS[name];
    if (field === undefined) {
      throw invalid();
    }
    const [offset, type] = field;
    if (type === 'f32') {
      if (typeof value !== 'number') throw invalid();
      views.f32[(pointer + offset) >> 2] = value;
    } else if (type === 'i32') {
      if (!Number.isInteger(value)) throw invalid();
      views.i32[(pointer + offset) >> 2] = value;
    } else {
      if (typeof value !== 'boolean') throw invalid();
      views.u8[pointer + offset] = value ? 1 : 0;
    }
  }
  const language = options?.language;
  if (typeof language !== 'string' || wasm.lengthBytesUTF8(language) >= LANGUAGE_CAPACITY) {
    throw invalid();
  }
  wasm.stringToUTF8(language, pointer + TRANSCRIBE_LANGUAGE_OFFSET, LANGUAGE_CAPACITY);
}

function readResult(result) {
  return withStack((alloc) => {
    const count = alloc(4);
    const segmentsAt = wasm._tw_result_segments(result, count);
    const segmentCount = heap().i32[count >> 2];
    const piecesAt = wasm._tw_result_tokens(result, count);
    const pieceCount = heap().i32[count >> 2];
    const textAt = wasm._tw_result_text(result, count);
    const textLength = heap().i32[count >> 2];
    const { i32, f32, i64, u8 } = heap();
    const segments = [];
    for (let i = 0; i < segmentCount; i++) {
      const p = segmentsAt + i * STRUCTS.SEGMENT.size;
      segments.push({
        t0Ms: Number(i64[p >> 3]),
        t1Ms: Number(i64[(p + 8) >> 3]),
        textOffset: i32[(p + 16) >> 2],
        textLength: i32[(p + 20) >> 2],
        pieceOffset: i32[(p + 24) >> 2],
        pieceCount: i32[(p + 28) >> 2],
        noSpeechProb: f32[(p + 32) >> 2],
        avgLogprob: f32[(p + 36) >> 2],
        meanP: f32[(p + 40) >> 2],
        minP: f32[(p + 44) >> 2],
      });
    }
    const pieces = [];
    for (let i = 0; i < pieceCount; i++) {
      const p = piecesAt + i * STRUCTS.TOKEN.size;
      pieces.push({
        id: i32[p >> 2],
        bytesOffset: i32[(p + 4) >> 2],
        bytesLength: i32[(p + 8) >> 2],
        p: f32[(p + 12) >> 2],
        t0Ms: Number(i64[(p + 16) >> 3]),
        t1Ms: Number(i64[(p + 24) >> 3]),
      });
    }
    return {
      segments,
      pieces,
      textBytes: u8.slice(textAt, textAt + textLength),
      language: wasm.UTF8ToString(wasm._tw_result_language(result)),
      wallMs: Number(wasm._tw_result_wall_ms(result)),
    };
  });
}

function transcribe(args) {
  requireInit();
  const handle = args?.handle;
  requireHandle(handle, 'whisper');
  const pcm = requireSamples(args.pcm);
  const jobId = args.jobId ?? 0;
  if (!Number.isInteger(jobId) || jobId < 0) {
    throw invalid();
  }
  const prompt = args.initialPrompt ?? null;
  const promptPieces = args.promptPieces ?? null;
  if (
    (prompt !== null && typeof prompt !== 'string') ||
    (promptPieces !== null && !(promptPieces instanceof Int32Array))
  ) {
    throw invalid();
  }
  const outcome = withStack((alloc) => {
    const options = alloc(STRUCTS.TRANSCRIBE_OPTIONS.size);
    writeTranscribeOptions(options, args.options);
    let samples = 0;
    if (pcm.length > 0) {
      samples = wasm._tw_context_pcm_buffer(handle, pcm.length);
      if (samples === 0) {
        throw statusFailure(
          pcm.length > MAX_SAMPLES ? STATUS.AUDIO_TOO_LONG : STATUS.INVALID_ARGUMENT,
        );
      }
      heap().f32.set(pcm, samples >> 2);
    }
    let promptAt = 0;
    if (prompt !== null) {
      const size = wasm.lengthBytesUTF8(prompt) + 1;
      promptAt = alloc(size);
      wasm.stringToUTF8(prompt, promptAt, size);
    }
    let piecesAt = 0;
    if (promptPieces !== null && promptPieces.length > 0) {
      piecesAt = alloc(promptPieces.byteLength);
      heap().i32.set(promptPieces, piecesAt >> 2);
    }
    const out = alloc(4);
    heap().u32[out >> 2] = 0;
    const status = wasm._tw_transcribe(
      handle,
      samples,
      pcm.length,
      options,
      promptAt,
      piecesAt,
      promptPieces?.length ?? 0,
      abortCell,
      jobId,
      out,
    );
    return { status, result: heap().u32[out >> 2] };
  });
  if (outcome.status !== STATUS.OK) {
    throw statusFailure(outcome.status, wasm._tw_last_whisper_code(handle));
  }
  try {
    return readResult(outcome.result);
  } finally {
    wasm._tw_result_free(outcome.result);
  }
}

function vadFeed(args) {
  requireInit();
  const handle = args?.handle;
  requireHandle(handle, 'vad');
  const pcm = requireSamples(args.pcm);
  return withStack((alloc) => {
    let samples = 0;
    if (pcm.length > 0) {
      samples = wasm._tw_vad_pcm_buffer(handle, pcm.length);
      if (samples === 0) {
        throw invalid();
      }
      heap().f32.set(pcm, samples >> 2);
    }
    const count = alloc(4);
    const status = wasm._tw_vad_feed(handle, samples, pcm.length, count);
    if (status !== STATUS.OK) {
      throw statusFailure(status);
    }
    const probsAt = wasm._tw_vad_probs(handle, count);
    const n = heap().i32[count >> 2];
    const probs = heap().f32.slice(probsAt >> 2, (probsAt >> 2) + n);
    return { probs, pendingSamples: wasm._tw_vad_pending_samples(handle) };
  });
}

function vadReset(args) {
  requireInit();
  requireHandle(args?.handle, 'vad');
  wasm._tw_vad_reset(args.handle);
  return {};
}

function closeHandle(handle) {
  const entry = handles.get(handle);
  if (entry === undefined) {
    return false;
  }
  handles.delete(handle);
  if (entry.kind === 'whisper') {
    wasm._tw_context_close(handle);
  } else {
    wasm._tw_vad_close(handle);
  }
  return true;
}

function close(args) {
  requireInit();
  return { closed: closeHandle(args?.handle) };
}

function memory() {
  requireInit();
  return {
    heapBytes: wasm.wasmMemory.buffer.byteLength,
    deviceMemoryGb: globalThis.navigator?.deviceMemory ?? null,
  };
}

function liveObjects() {
  requireInit();
  const counts = {};
  for (const [name, kind] of Object.entries(OBJECT_KINDS)) {
    counts[name] = wasm._tw_live_objects(kind);
  }
  return counts;
}

function dispose() {
  if (wasm !== null && !broken) {
    for (const handle of [...handles.keys()]) {
      closeHandle(handle);
    }
    if (abortCell !== 0) {
      wasm._tw_cell_release(abortCell);
      abortCell = 0;
    }
  }
  return {};
}

// Drops queued transcriptions of a lease: every one when jobId is absent,
// else those whose job id is at most jobId.
function abort(args) {
  const leaseId = args?.leaseId;
  const jobId = args?.jobId ?? null;
  const validLease = typeof leaseId === 'number' || typeof leaseId === 'string';
  if (!validLease || (jobId !== null && !Number.isInteger(jobId))) {
    throw invalid();
  }
  let dropped = 0;
  for (let i = queue.length - 1; i >= 0; i--) {
    const request = queue[i];
    const target = request.op === 'transcribe' && request.args?.leaseId === leaseId;
    if (target && (jobId === null || (request.args.jobId ?? 0) <= jobId)) {
      queue.splice(i, 1);
      replyFailure(request.id, new WorkerFailure('aborted', STATUS.ABORTED));
      dropped++;
    }
  }
  return { dropped };
}

const QUEUED = Object.freeze({
  init,
  loadModel,
  verify,
  transcribe,
  vadFeed,
  vadReset,
  close,
  dispose,
});

const IMMEDIATE = Object.freeze({ abort, memory, liveObjects });

// ---------------------------------------------------------------------------
// Messaging.
// ---------------------------------------------------------------------------

function transferablesOf(result) {
  const transfer = [];
  for (const value of Object.values(result ?? {})) {
    if (ArrayBuffer.isView(value) && value.buffer instanceof ArrayBuffer) {
      transfer.push(value.buffer);
    }
  }
  return transfer;
}

function reply(id, result) {
  self.postMessage({ id, ok: true, result }, transferablesOf(result));
}

function replyFailure(id, error) {
  const failure =
    error instanceof WorkerFailure ? error : new WorkerFailure('internal', STATUS.INTERNAL);
  self.postMessage({
    id,
    ok: false,
    error: { code: failure.code, status: failure.status, whisperCode: failure.whisperCode },
  });
}

function postLog() {
  const entries = printed.splice(0, printed.length);
  let dropped = 0;
  if (wasm !== null && !broken) {
    withStack((alloc) => {
      const size = STRUCTS.LOG_ENTRY.size;
      const ring = alloc(size * LOG_DRAIN_MAX);
      const n = wasm._tw_log_drain(ring, LOG_DRAIN_MAX);
      for (let i = 0; i < n; i++) {
        const entry = ring + i * size;
        const level = heap().i32[entry >> 2];
        const length = heap().i32[(entry + 4) >> 2];
        entries.push({ level, text: wasm.UTF8ToString(entry + 8, length) });
      }
    });
    dropped = wasm._tw_log_dropped();
  }
  if (entries.length > 0) {
    self.postMessage({ event: 'log', entries, dropped });
  }
}

async function run(request) {
  try {
    const result = await QUEUED[request.op](request.args);
    reply(request.id, result);
  } catch (error) {
    if (error instanceof WebAssembly.RuntimeError) {
      // A trap leaves the module unusable; every later request fails.
      broken = true;
    }
    replyFailure(request.id, error);
  }
  try {
    postLog();
  } catch (_) {
    broken = true;
  }
  if (request.op === 'dispose') {
    self.close();
  }
}

async function drain() {
  if (draining) {
    return;
  }
  draining = true;
  try {
    while (queue.length > 0) {
      await run(queue.shift());
      // Yield, so an abort that arrived during the request is seen before
      // the next one starts.
      await new Promise((resolve) => setTimeout(resolve, 0));
    }
  } finally {
    draining = false;
  }
}

function receive(message) {
  const id = message?.id;
  const op = message?.op;
  if (typeof op !== 'string' || (typeof id !== 'number' && typeof id !== 'string')) {
    return;
  }
  const request = { id, op, args: message.args ?? {} };
  if (Object.hasOwn(IMMEDIATE, op)) {
    try {
      reply(id, IMMEDIATE[op](request.args));
    } catch (error) {
      replyFailure(id, error);
    }
    return;
  }
  if (!Object.hasOwn(QUEUED, op)) {
    replyFailure(id, invalid());
    return;
  }
  if (op === 'dispose') {
    for (const pending of queue.splice(0, queue.length)) {
      replyFailure(pending.id, new WorkerFailure('aborted', STATUS.ABORTED));
    }
  }
  queue.push(request);
  void drain();
}

self.onmessage = (event) => receive(event.data);
