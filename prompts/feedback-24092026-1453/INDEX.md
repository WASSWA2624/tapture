# Feedback prompts — TAPTURE-24092026-1453.xlsx

2 entries → 1 prompt, 1 work item. Generated 2026-09-24. Repository commit: 3985421.

## Run order
| Prompt | Item | Title | Feedback | Type | Priority | After |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 001-place-audio-record-in-caption.md | W1 | Place the audio record control in the caption field | FBK0000090 | Improvement | P3 | — |

## Coverage
| Feedback ID | Category | Screen | Outcome |
| :--- | :--- | :--- | :--- |
| FBK0000090 | General feedback | Projects › Capture | 001 W1 |
| FBK0000091 | General feedback | Projects › Capture | Already resolved (`CaptureController.setCaption` with a null id writes only the record caption at `frontend/lib/features/capture/presentation/capture_controller.dart`; an empty photo selection opens the photo-caption sheet on `CaptionScope.thisPhoto` for the latest photo in `CaptureScreen._caption`; stopping audio does not choose `All photos` unless that row is tapped, in `CaptureScreen._audioStopped`) |

## Open questions
None.
