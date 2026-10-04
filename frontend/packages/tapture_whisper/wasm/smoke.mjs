// Node smoke of the WebAssembly speech engine (dev-plan task 111,
// app-write-up section 30.4.8).
//
//   node packages/tapture_whisper/wasm/smoke.mjs --variant st|mt [--decodes N]
//
// Runs the committed frontend/web/whisper/whisper_worker.js in a worker
// thread that stands in for a browser module worker: `self`, `location` (an
// http://127.0.0.1 origin this script serves the models from), postMessage
// and crossOriginIsolated (true for mt). Node has no OPFS, so the worker
// takes its fetch-into-memory path. It checks, for the variant:
//   - init selects the variant, and every tw_struct_size equals TW_SIZEOF_*
//     of src/tapture_whisper.h;
//   - a cross-origin model URL is refused with cross_origin;
//   - a wrong SHA-256 and a wrong size are refused with model_mismatch;
//   - jfk.wav with tiny-q5_1 contains the phrase;
//   - Silero gives floor(n / 512) probabilities for n samples;
//   - mt: an Atomics.store abort, then N consecutive decodes at 4 threads
//     (default 50) with liveObjects unchanged after each;
//   - close and dispose leave no live object.
// Prints one line per check and exits 1 on the first failure.

import { readFileSync } from 'node:fs';
import { createServer } from 'node:http';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { Worker, isMainThread, parentPort, workerData } from 'node:worker_threads';

const HOST_ROLE = 'tapture-whisper-worker-host';

// The worker thread: the browser globals whisper_worker.js uses, then the
// worker itself.
async function hostWorker({ origin, isolated, workerPath }) {
  globalThis.self = globalThis;
  globalThis.location = new URL('/whisper/whisper_worker.js', origin);
  globalThis.crossOriginIsolated = isolated;
  globalThis.postMessage = (message, transfer) => parentPort.postMessage(message, transfer);
  globalThis.close = () => process.exit(0);
  parentPort.on('message', (data) => globalThis.onmessage?.({ data }));
  await import(pathToFileURL(workerPath).href);
}

async function main(args) {
  const variant = option(args, '--variant');
  const decodes = Number(option(args, '--decodes') ?? 50);
  if ((variant !== 'st' && variant !== 'mt') || !Number.isInteger(decodes) || decodes < 1) {
    process.stderr.write('usage: node smoke.mjs --variant st|mt [--decodes N]\n');
    return 64;
  }
  const here = dirname(fileURLToPath(import.meta.url));
  const frontend = resolve(here, '../../..');
  const paths = {
    worker: join(frontend, 'web/whisper/whisper_worker.js'),
    header: join(frontend, 'packages/tapture_whisper/src/tapture_whisper.h'),
    wav: join(frontend, 'packages/tapture_whisper/third_party/whisper.cpp/samples/jfk.wav'),
    models: join(frontend, 'assets/speech'),
  };
  const manifest = JSON.parse(readFileSync(join(paths.models, 'manifest.json'), 'utf8'));
  const model = (id) => {
    const entry = manifest.models.find((m) => m.id === id);
    if (entry === undefined) throw new Error(`assets/speech/manifest.json has no ${id}`);
    return { ...entry, file: entry.asset.split('/').pop() };
  };
  const tiny = model('tiny-q5_1');
  const silero = model('silero-v6.2.0');
  const pcm = readWav(readFileSync(paths.wav));
  const server = await serve(paths.models);
  const origin = `http://127.0.0.1:${server.address().port}`;
  const worker = new WorkerClient(paths.worker, origin, variant === 'mt');
  const report = (line) => process.stdout.write(`[${variant}] ${line}\n`);
  try {
    await smoke({ variant, decodes, worker, origin, tiny, silero, pcm, paths, report });
    report('ok');
    return 0;
  } catch (error) {
    process.stderr.write(`[${variant}] FAILED: ${error.message}\n`);
    return 1;
  } finally {
    await worker.terminate();
    server.close();
  }
}

async function smoke({ variant, decodes, worker, origin, tiny, silero, pcm, paths, report }) {
  const info = await worker.call('init', { variant });
  expect(info.variant === variant, `init chose ${info.variant}, not ${variant}`);
  const header = headerSizes(readFileSync(paths.header, 'utf8'));
  for (const [name, size] of Object.entries(header)) {
    expect(info.structSizes[name] === size, `tw_struct_size ${name} ${info.structSizes[name]} != TW_SIZEOF_${name} ${size}`);
  }
  expect(Object.keys(info.structSizes).length === Object.keys(header).length, 'struct table size differs from the header');
  report(`init: abi ${info.abi}, ${info.version}, ${Object.keys(header).length} struct sizes match the header`);

  const url = (entry) => `${origin}/models/${entry.file}`;
  const load = (entry, overrides = {}) =>
    worker.call('loadModel', {
      kind: entry.kind,
      url: url(entry),
      cacheKey: `${entry.id}-${entry.sha256.slice(0, 12)}`,
      sha256: entry.sha256,
      bytes: entry.bytes,
      threads: variant === 'mt' ? 4 : 1,
      flashAttn: true,
      ...overrides,
    });

  await expectFailure(load(tiny, { url: url(tiny).replace('127.0.0.1', 'localhost') }), 'cross_origin');
  await expectFailure(load(tiny, { url: 'https://example.com/ggml-tiny-q5_1.bin' }), 'cross_origin');
  await expectFailure(load(tiny, { sha256: 'f'.repeat(64) }), 'model_mismatch', 15);
  await expectFailure(load(tiny, { bytes: tiny.bytes - 1 }), 'model_mismatch', 15);
  expectEqual(await worker.call('liveObjects'), baseline(variant, 0, 0), 'live objects after refused loads');
  report('cross-origin URLs refused; wrong SHA-256 and size give model_mismatch without a load');

  const whisper = await load(tiny);
  expect(whisper.facts.nVocab === 51865 && whisper.facts.nAudioCtx === 1500, 'tiny facts');
  const vad = await load(silero);
  expect(vad.windowSamples === 512, `Silero window ${vad.windowSamples}`);
  const loaded = baseline(variant, 1, 1);
  expectEqual(await worker.call('liveObjects'), loaded, 'live objects after loading');

  let jobId = 1;
  const decode = (id) =>
    worker.call('transcribe', {
      handle: whisper.handle,
      jobId: id,
      leaseId: 1,
      pcm: pcm.slice(),
      options: { language: 'en', threads: info.maxThreads },
    });
  const started = Date.now();
  const first = await decode(jobId++);
  const text = new TextDecoder().decode(first.textBytes);
  const words = text.toLowerCase().replace(/[^a-z ]+/g, ' ').replace(/\s+/g, ' ');
  expect(words.includes('ask not what your country can do for you'), 'jfk phrase missing');
  expect(first.segments.length > 0 && first.pieces.length > 0, 'no segments or pieces');
  report(`jfk with tiny in ${Date.now() - started} ms at ${info.maxThreads} thread(s): phrase found`);

  const vadResult = await worker.call('vadFeed', { handle: vad.handle, pcm: pcm.slice() });
  const expected = Math.floor(pcm.length / 512);
  expect(vadResult.probs.length === expected, `${vadResult.probs.length} probabilities, expected ${expected}`);
  expect(vadResult.pendingSamples === pcm.length % 512, 'pending samples');
  report(`VAD: ${vadResult.probs.length} probabilities = floor(${pcm.length} / 512)`);

  if (variant === 'mt') {
    const cells = new Int32Array(info.memory.buffer);
    const aborted = jobId++;
    const pending = decode(aborted);
    setTimeout(() => Atomics.store(cells, info.abortCell.byteOffset >> 2, aborted), 300);
    await expectFailure(pending, 'aborted', 8);
    report('Atomics.store on the shared abort cell aborts the running decode');
    const loopStart = Date.now();
    for (let i = 0; i < decodes; i++) {
      await decode(jobId++);
      expectEqual(await worker.call('liveObjects'), loaded, `live objects after decode ${i + 1}`);
    }
    report(`${decodes} consecutive decodes at ${info.maxThreads} threads in ${Date.now() - loopStart} ms, live objects stable`);
  }

  const memory = await worker.call('memory');
  report(`heap ${(memory.heapBytes / 1048576).toFixed(1)} MiB with tiny and Silero loaded`);
  await worker.call('close', { handle: whisper.handle });
  await worker.call('close', { handle: vad.handle });
  expectEqual(await worker.call('liveObjects'), baseline(variant, 0, 0), 'live objects after close');
  await worker.call('dispose');
  await worker.exited;
  report('close and dispose leave no live object');
}

// The live objects with `contexts` and `vads` open: mt holds one abort cell.
function baseline(variant, contexts, vads) {
  return { contexts, results: 0, vads, spans: 0, cells: variant === 'mt' ? 1 : 0, hashers: 0 };
}

// TW_SIZEOF_* of the header, keyed by struct name.
function headerSizes(source) {
  const sizes = {};
  for (const match of source.matchAll(/^#define TW_SIZEOF_([A-Z_]+)\s+(\d+)/gm)) {
    sizes[match[1]] = Number(match[2]);
  }
  return sizes;
}

// 16-bit mono 16 kHz PCM from a RIFF WAVE file, as floats.
function readWav(bytes) {
  const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  let offset = 12;
  let format = null;
  while (offset + 8 <= bytes.length) {
    const id = bytes.toString('ascii', offset, offset + 4);
    const size = view.getUint32(offset + 4, true);
    const body = offset + 8;
    if (id === 'fmt ') {
      format = { channels: view.getUint16(body + 2, true), rate: view.getUint32(body + 4, true), bits: view.getUint16(body + 14, true) };
    } else if (id === 'data') {
      if (format?.channels !== 1 || format.rate !== 16000 || format.bits !== 16) {
        throw new Error('jfk.wav is not 16-bit mono 16 kHz');
      }
      const samples = new Float32Array(size / 2);
      for (let i = 0; i < samples.length; i++) {
        samples[i] = view.getInt16(body + i * 2, true) / 32768;
      }
      return samples;
    }
    offset = body + size + (size & 1);
  }
  throw new Error('jfk.wav has no data chunk');
}

// Serves the speech models at /models/<file> on 127.0.0.1.
function serve(directory) {
  const server = createServer((request, response) => {
    const name = decodeURIComponent(new URL(request.url, 'http://x').pathname.replace(/^\/models\//, ''));
    if (!/^[A-Za-z0-9._-]+\.bin$/.test(name)) {
      response.writeHead(404).end();
      return;
    }
    try {
      const body = readFileSync(join(directory, name));
      response.writeHead(200, { 'content-type': 'application/octet-stream', 'content-length': body.length });
      response.end(body);
    } catch (_) {
      response.writeHead(404).end();
    }
  });
  return new Promise((done) => server.listen(0, '127.0.0.1', () => done(server)));
}

// The page side of the protocol: numbered requests and their replies.
class WorkerClient {
  constructor(workerPath, origin, isolated) {
    this.nextId = 1;
    this.pending = new Map();
    this.worker = new Worker(new URL(import.meta.url), {
      workerData: { role: HOST_ROLE, origin, isolated, workerPath },
    });
    this.exited = new Promise((done) => this.worker.once('exit', done));
    this.worker.on('message', (message) => {
      if (message.event === 'log') {
        for (const entry of message.entries) process.stdout.write(`  log ${entry.level}: ${entry.text.trim()}\n`);
        return;
      }
      const waiter = this.pending.get(message.id);
      this.pending.delete(message.id);
      waiter?.(message);
    });
    this.worker.on('error', (error) => {
      for (const waiter of this.pending.values()) waiter({ ok: false, error: { code: `worker error: ${error.message}` } });
      this.pending.clear();
    });
  }

  call(op, args = {}) {
    const id = this.nextId++;
    const transfer = Object.values(args).filter((v) => ArrayBuffer.isView(v)).map((v) => v.buffer);
    return new Promise((done, fail) => {
      this.pending.set(id, (message) => {
        if (message.ok) done(message.result);
        else fail(Object.assign(new Error(`${op}: ${message.error.code}`), { failure: message.error }));
      });
      this.worker.postMessage({ id, op, args }, transfer);
    });
  }

  terminate() {
    return this.worker.terminate();
  }
}

async function expectFailure(promise, code, status) {
  try {
    await promise;
  } catch (error) {
    expect(error.failure?.code === code, `${error.message}, expected ${code}`);
    if (status !== undefined) expect(error.failure.status === status, `status ${error.failure.status}, expected ${status}`);
    return;
  }
  throw new Error(`succeeded, expected ${code}`);
}

function expectEqual(actual, expected, what) {
  expect(JSON.stringify(actual) === JSON.stringify(expected), `${what}: ${JSON.stringify(actual)}, expected ${JSON.stringify(expected)}`);
}

function expect(condition, message) {
  if (!condition) throw new Error(message);
}

function option(args, name) {
  const index = args.indexOf(name);
  return index >= 0 ? args[index + 1] : undefined;
}

// Last, so every declaration above is initialised before it runs.
if (!isMainThread && workerData?.role === HOST_ROLE) {
  await hostWorker(workerData);
} else if (isMainThread) {
  process.exitCode = await main(process.argv.slice(2));
}
