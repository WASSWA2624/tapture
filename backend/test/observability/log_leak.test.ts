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
      caption: 'a safe caption',
    });
    const line = lines.join('\n');
    assert.equal(lines.length, 1);
    assert.equal(line.includes('correct-horse'), false);
    assert.equal(line.includes('sk-abcdefghijklmnop'), false);
    assert.equal(line.includes('AKIAIOSFODNN7EXAMPLE'), false);
    assert.match(line, /\[redacted\]/);
    assert.match(line, /a safe caption/);
  });
});
