### Refined implementation requirements — additional feedback improvements

#### 1. Search/input styling

* Make the **search bar and text inputs use the same border radius as the application buttons**.
* Ensure the microphone control visually fits naturally inside the input.
* **Remove the border/outline from the speech-to-text microphone button** in all input fields.
* Keep the microphone icon compact and vertically centered.

#### 2. Speech-to-text behavior

* While recording, **transcribed text must appear directly inside the input field**, not below it.
* Preserve normal typing while STT is active.
* Clearly indicate when the microphone is listening, without adding unnecessary UI.

#### 3. Screenshot/photo handling

* In **Give Us Feedback**, size a single attached screenshot/photo to **fit the available width while preserving its aspect ratio**.
* Support **multiple screenshots/photos**.
* Present multiple images in a compact, balanced gallery/grid.
* Clicking/tapping an image should open a **larger preview**.
* Each attached image should have an obvious but minimal **Remove/Delete** action.
* Allow users to:

  * **Upload/select a photo from the device**
  * **Take a photo using the device camera**

#### 4. Continue feedback across screens

Implement feedback as a **persistent feedback draft/session**, rather than tying it exclusively to one screen.

The user should be able to:

* Start **Give Us Feedback**.
* Navigate to other screens.
* Continue typing or using STT.
* Capture/add screenshots from other parts of the application.
* Return to the feedback screen with all previously entered text and attachments preserved.
* Add additional screenshots/photos before submitting.

This should work reliably across the supported desktop, tablet, and mobile platforms.

#### 5. Compact controls

The current **Save Feedback** button and **Attach screenshot** control consume too much vertical space.

* Reduce their height, padding, and surrounding spacing.
* Replace **Attach screenshot** toggle with a **two-state checkbox**.
* Position the checkbox **on the left** and its label **on the right**.
* Keep the entire control compact and aligned with the surrounding form.
* Keep **Save Feedback** sticky while scrolling, but make it substantially more compact.

#### 6. Headers

* Reduce the height of **Feedback screen headers globally**.
* Avoid oversized title bars and excessive vertical padding.
* Apply the same compact header treatment consistently across **all feedback-related screens**.

#### 7. Apply consistently

Apply these improvements to **all feedback screens and related feedback components**, not only the Give Us Feedback screen.

**Overall objective:** make the feedback system feel like a lightweight, persistent overlay/workspace that users can interact with while moving through the application, while keeping the UI compact and unobtrusive.

Replace "Feedback" types options with radio buttons or checkboxes on all the feedback screens. Also improve the filters presentation, organization and accessbility on all screens.