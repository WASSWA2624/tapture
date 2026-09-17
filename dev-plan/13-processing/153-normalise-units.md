# 153 — Normalise units, choices, dates and numbers

**Phase** 13 · Processing  |  **Depends on** [089](../09-templates/089-field-type-registry.md), [095](../09-templates/095-field-add-basic.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

"13 litre", "13L" and "13 Litre Capacity" become one stored value in the field's configured unit; free language maps
onto the option list without discarding the sentence; the date forms field workers actually type parse against the
project locale; and identifiers stay text. The original phrasing always survives in the raw value.

## Files

- `frontend/lib/core/normalise/units.dart` (new)
- `frontend/lib/core/normalise/choices.dart` (new)
- `frontend/lib/core/normalise/dates.dart` (new)

## Steps

1. Units: parse value plus unit, convert to the unit configured on the field, keep the original text beside it.
2. Choices: match on option label, code and alias from the options editor of task 095; leave the descriptive sentence
   in its own field.
3. Dates and numbers: parse common day-month-year forms with the project locale; never coerce an identifier to a
   number.

## Constraints

- `core/normalise/` is pure Dart — no Flutter, Drift or HTTP import (FE-STR-05).
- One parser per concept; features call these and never reimplement them (FE-CONS-09).

## Definition of done

- [ ] "Gauge damaged and requires repair" maps to Faulty while the sentence remains.
- [ ] Leading zeros in asset numbers are preserved, and the original phrasing survives in the raw value.
- [ ] Tests: unit tests over the specification examples for each of the three, including ambiguous dates,
      zero-prefixed identifiers and text matching no option.
