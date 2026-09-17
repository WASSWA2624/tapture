# 08 — Localisation

The app is built in Uganda for multilingual field work. Translation may arrive after release; the code must never be
the reason it cannot.

*Built by dev-plan task 238 (localisation scaffold); strings routed through the copy helper from task 046.*

## FE-L10N-01 — No user-facing string in a widget
Every visible string comes from the generated localisations or the copy helper. A literal in a widget is a defect.

## FE-L10N-02 — Keys name meaning, not location
`captureSaveRaw`, not `screen3Button2`. A key survives a redesign; a position does not.

## FE-L10N-03 — Never assemble a sentence
No concatenation, no counting words built by hand. Use placeholders with descriptions, and ICU plurals and selects.
Word order differs between languages.

## FE-L10N-04 — Formats come from `intl`
Dates, times, numbers, currency and percentages are formatted with the active locale. Never a hand-built
day-slash-month-slash-year string.

## FE-L10N-05 — Direction-neutral layout
`start` and `end`, never `left` and `right`. Padding, alignment, icons and animations all mirror correctly.

## FE-L10N-06 — Room to grow
Layouts survive a 35 percent expansion. The pseudo-locale run is part of the responsive matrix, not an afterthought.

## FE-L10N-07 — Template content is user data, not UI text
Field labels, option lists and template names come from the user's template and are **never** translated, matched or
normalised against a translation. Confusing the two corrupts data.

## FE-L10N-08 — Voice language is a setting
The speech language is chosen by the user, defaults to the app locale, and degrades with a plain message when the
device cannot offer it offline. Never hardcode a locale in a speech call.

## FE-L10N-09 — Missing translations fail the release build
A key without a translation is caught by the build, not by a user in the field.

## FE-L10N-10 — Locale changes apply live
Switching language or region rebuilds the interface without a restart and without losing in-progress capture.

## FE-L10N-11 — Filenames and paths stay ASCII
Context values may be in any script; the sanitiser transliterates for the file system while the database keeps the
original text.
