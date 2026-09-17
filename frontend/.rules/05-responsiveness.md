# 05 — Responsiveness

*Enforced by dev-plan task 013 (responsive boundary test); built by task 032, audited by 236.*

## FE-RESP-01 — Three size classes, one definition
`compact` under 600dp, `medium` 600-1023dp, `expanded` 1024dp and above. `SizeClass` is the only place these numbers
exist.

## FE-RESP-02 — Features never measure the screen
No `MediaQuery` width comparison outside `core/widgets/responsive/`. Screens ask for a value per size class, or use
`ResponsiveBuilder`.

## FE-RESP-03 — Navigation adapts, state does not
Bottom bar on compact, rail on medium, rail plus list pane on expanded. Switching size class never loses navigation
state or in-progress input.

## FE-RESP-04 — Readable width is capped
Text and forms are constrained and centred. Nothing stretches edge to edge on a tablet because the window allows it.

## FE-RESP-05 — Lists become two-pane when there is room
On expanded, list and detail sit side by side; the same screens, not a second implementation.

## FE-RESP-06 — Everything scrolls
No fixed-height container that clips at 200 percent text scale. No layout that assumes the keyboard is closed.

## FE-RESP-07 — Both orientations, everywhere
Landscape is supported on every screen. Capture, review and the camera preview must survive rotation without losing a
photo, a caption or a field.

## FE-RESP-08 — Safe areas and insets are respected
Notches, gesture bars and the keyboard are accounted for by the page scaffold, not by each screen.

## FE-RESP-09 — Images use ratios, not pixels
Aspect ratios and `BoxFit`, never fixed pixel sizes, so photos behave on every density.

## FE-RESP-10 — The matrix is tested
Every screen: three widths, two orientations, default and 200 percent text scale. Golden tests capture the corners.
