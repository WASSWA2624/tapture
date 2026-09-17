# 154 — Match to a predefined row

**Phase** 13 · Processing  |  **Depends on** [103](../09-templates/103-predefined-rows-import.md), [153](153-normalise-units.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Extracted text resolved to one predefined row by exact, alias, normalised, fuzzy and then model classification, in
that order, stopping at the first confident match and recording which strategy matched and with what score.

## Files

- `frontend/lib/features/processing/domain/row_matching.dart` (new)

## Steps

1. Try the strategies in order; return as soon as one clears its confidence threshold.
2. Return the matched row, the strategy name and the score, so review can show why the row was chosen.
3. Return no match rather than a weak one when every strategy falls short.

## Constraints

- Model classification runs only after all four local strategies have failed; local matching never calls out.

## Definition of done

- [ ] "Sphygmomanometer" reaches "Blood Pressure Machine" without a model call.
- [ ] Every match records its strategy and score, and a weak match becomes no match.
- [ ] Tests: unit tests for each strategy in order, plus the no-match path, with no Flutter binding.
