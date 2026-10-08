// A miniature worker: only the tables the check compares.
// tw-struct-table:begin
const STRUCTS = Object.freeze({
  CONTEXT_OPTIONS: { id: 1, size: 16 },
  SPAN: { id: 2, size: 16 },
});
// tw-struct-table:end

// tw-status-table:begin
const STATUS_CODES = Object.freeze([
  'ok',
  'invalid_argument',
  'model_mismatch',
]);
// tw-status-table:end
