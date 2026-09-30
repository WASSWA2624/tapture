import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { createLogger } from '../../src/observability/logger.js';

describe('log redaction', () => {
  it('redacts secret fields and secret-shaped values', () => {
    const lines: string[] = [];
    const log = createLogger((line) => lines.push(line));
    log.info('attempt', {
      password: 'correct-horse',
      token: 'header',
      note: 'prefix sk-abcdefghijklmnop suffix',
      accessKey: 'AKIAIOSFODNN7EXAMPLE',
      caption: 'private caption',
      transcript: 'private transcript',
      filename: 'private evidence.jpg',
      payload: { instructions: 'private instruction' },
      unexpected: 'private unknown field',
    });
    const line = lines.join('\n');
    assert.equal(lines.length, 1);
    assert.equal(line.includes('correct-horse'), false);
    assert.equal(line.includes('sk-abcdefghijklmnop'), false);
    assert.equal(line.includes('AKIAIOSFODNN7EXAMPLE'), false);
    assert.match(line, /\[redacted\]/);
    for (const value of [
      'private caption',
      'private transcript',
      'private evidence.jpg',
      'private instruction',
      'private unknown field',
    ])
      assert.equal(line.includes(value), false);
    const row = JSON.parse(lines[0] ?? '{}') as {
      at: string;
      level: string;
      requestId: unknown;
    };
    assert.ok(Number.isFinite(Date.parse(row.at)));
    assert.equal(row.level, 'info');
  });

  it('does not let supplied fields replace authoritative log context', () => {
    const lines: string[] = [];
    createLogger((line) => lines.push(line)).warn('declared_event', {
      level: 'fabricated',
      event: 'fabricated',
      requestId: 'fabricated',
      at: 'fabricated',
      outcome: 'failed',
      byteSize: 123,
    });
    const row = JSON.parse(lines[0] ?? '{}') as Record<string, unknown>;
    assert.equal(row['event'], 'declared_event');
    assert.equal(row['level'], 'warn');
    assert.equal(row['requestId'], null);
    assert.equal(row['outcome'], 'failed');
    assert.equal(row['byteSize'], 123);
  });
});
