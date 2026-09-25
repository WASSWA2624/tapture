import 'package:flutter/material.dart';

/// The one icon for each concept (FE-CONS-08, FE-THEME-08).
///
/// Glyphs are the widely recognised Material symbols, so a person who has
/// used any phone reads them without a label: a magnifier searches, a pencil
/// edits, a bin deletes, a box archives. Features and the shell name a
/// concept here and never pick an `Icons` glyph of their own.
abstract final class AppIcons {
  // Navigation and chrome.

  /// Returns to the previous page.
  static const IconData back = Icons.arrow_back;

  /// Closes a sheet, panel, banner or dialog.
  static const IconData close = Icons.close;

  /// Clears the text in a field.
  static const IconData clear = Icons.close;

  /// Opens the labelled commands behind a row or the title bar.
  static const IconData more = Icons.more_vert;

  /// Opens the row's detail. Mirrors in right-to-left layouts.
  static const IconData open = Icons.chevron_right;

  /// Opens a list of choices below the control.
  static const IconData expand = Icons.expand_more;

  /// Moves an item up one place.
  static const IconData moveUp = Icons.keyboard_arrow_up;

  /// Moves an item down one place.
  static const IconData moveDown = Icons.keyboard_arrow_down;

  /// Drag to reorder.
  static const IconData reorder = Icons.drag_handle;

  /// Opens the file in another app.
  static const IconData openExternal = Icons.open_in_new;

  /// Expands a docked panel to full size.
  static const IconData expandPanel = Icons.open_in_full;

  /// Collapses a full-size panel.
  static const IconData collapsePanel = Icons.close_fullscreen;

  // The four destinations.

  /// A project, and the Projects destination.
  static const IconData project = Icons.folder_outlined;

  /// The selected Projects destination.
  static const IconData projectSelected = Icons.folder;

  /// Capture, the camera, and the Capture destination.
  static const IconData camera = Icons.photo_camera_outlined;

  /// The selected Capture destination.
  static const IconData cameraSelected = Icons.photo_camera;

  /// Records, and the Records destination.
  static const IconData records = Icons.list_alt_outlined;

  /// The selected Records destination.
  static const IconData recordsSelected = Icons.list_alt;

  /// Settings, and the Settings destination.
  static const IconData settings = Icons.settings_outlined;

  /// The selected Settings destination.
  static const IconData settingsSelected = Icons.settings;

  // Common actions.

  /// Adds a new item.
  static const IconData add = Icons.add;

  /// Edits an item.
  static const IconData edit = Icons.edit_outlined;

  /// A value that cannot be edited.
  static const IconData editLocked = Icons.edit_off_outlined;

  /// Removes an entry from a list without deleting anything stored.
  static const IconData remove = Icons.remove_circle_outline;

  /// Deletes an item, always behind a confirmation.
  static const IconData delete = Icons.delete_outline;

  /// Archives an item.
  static const IconData archive = Icons.archive_outlined;

  /// Returns an archived item to the active list.
  static const IconData unarchive = Icons.unarchive_outlined;

  /// Makes a copy.
  static const IconData duplicate = Icons.content_copy_outlined;

  /// Saves a file to the device: exports and downloads.
  static const IconData download = Icons.download_outlined;

  /// Exports a project or template to a file.
  static const IconData export = Icons.download_outlined;

  /// Reads a file into the app.
  static const IconData import = Icons.upload_file_outlined;

  /// Shares through the platform's share sheet, in each platform's own glyph.
  static IconData get share => Icons.adaptive.share;

  /// Saves the current entry.
  static const IconData save = Icons.save_outlined;

  /// Undoes the last change.
  static const IconData undo = Icons.undo;

  /// Searches.
  static const IconData search = Icons.search;

  /// A search that matched nothing.
  static const IconData searchEmpty = Icons.search_off;

  /// Narrows a list.
  static const IconData filter = Icons.filter_list;

  /// Pins an item to the top, and a pinned value.
  static const IconData pin = Icons.push_pin_outlined;

  /// An item that is pinned.
  static const IconData pinned = Icons.push_pin;

  /// A confirmed choice.
  static const IconData check = Icons.check;

  /// Shows a hidden value.
  static const IconData show = Icons.visibility_outlined;

  /// Hides a shown value.
  static const IconData hide = Icons.visibility_off_outlined;

  /// Something recently used.
  static const IconData history = Icons.history;

  // Messages and states.

  /// Neutral information.
  static const IconData info = Icons.info_outline;

  /// A warning the person can proceed past.
  static const IconData warning = Icons.warning_amber_outlined;

  /// A failure.
  static const IconData error = Icons.error_outline;

  /// Success.
  static const IconData success = Icons.check_circle_outline;

  /// A finished step.
  static const IconData done = Icons.check_circle;

  /// Something stopped before it finished.
  static const IconData stopped = Icons.stop_circle_outlined;

  /// Nothing here yet.
  static const IconData empty = Icons.inbox_outlined;

  /// Working without a connection.
  static const IconData offline = Icons.cloud_off_outlined;

  /// Locked behind the app lock.
  static const IconData lock = Icons.lock_outline;

  /// A file that is missing or unreadable.
  static const IconData brokenFile = Icons.broken_image_outlined;

  /// Waiting for a result.
  static const IconData waiting = Icons.hourglass_top;

  /// A storage folder.
  static const IconData folder = Icons.folder_outlined;

  /// Light, dark and outdoor appearance.
  static const IconData theme = Icons.contrast;

  /// A provider key.
  static const IconData key = Icons.vpn_key_outlined;

  // Record lifecycle, shared by status pills and the project home.

  /// A draft record.
  static const IconData draft = Icons.edit_note;

  /// Captured, not yet processed.
  static const IconData captured = Icons.photo_camera;

  /// Waiting in the processing queue.
  static const IconData queued = Icons.schedule;

  /// Being processed, and syncing.
  static const IconData processing = Icons.sync;

  /// Proposed by AI; refine.
  static const IconData ai = Icons.auto_awesome;

  /// Needs a person to review it.
  static const IconData review = Icons.flag_outlined;

  /// Approved and verified.
  static const IconData verified = Icons.verified;

  // Capture.

  /// Adds a photo.
  static const IconData addPhoto = Icons.add_a_photo_outlined;

  /// Chooses photos already on the device.
  static const IconData photoLibrary = Icons.photo_library_outlined;

  /// Speech to text.
  static const IconData dictate = Icons.mic_none;

  /// Speech to text while listening.
  static const IconData dictating = Icons.mic;

  /// Records an audio clip.
  static const IconData recordAudio = Icons.graphic_eq;

  /// Stops a recording.
  static const IconData stop = Icons.stop;

  /// Takes the photo.
  static const IconData shutter = Icons.camera;

  /// Flash on.
  static const IconData flashOn = Icons.flash_on;

  /// Flash off.
  static const IconData flashOff = Icons.flash_off;

  /// Flash chosen by the camera.
  static const IconData flashAuto = Icons.flash_auto;

  /// Framing grid shown.
  static const IconData gridOn = Icons.grid_on;

  /// Framing grid hidden.
  static const IconData gridOff = Icons.grid_off;

  /// Zooms in.
  static const IconData zoomIn = Icons.zoom_in;

  /// Zooms out.
  static const IconData zoomOut = Icons.zoom_out;

  /// Crops a photo.
  static const IconData crop = Icons.crop;

  /// Rotates a photo.
  static const IconData rotate = Icons.rotate_right;

  /// Draws on a photo.
  static const IconData draw = Icons.gesture;

  /// Types text onto a photo.
  static const IconData typeText = Icons.title;

  /// A photo's caption.
  static const IconData caption = Icons.notes;

  /// A screenshot of the app.
  static const IconData screenshot = Icons.screenshot_monitor_outlined;

  /// Stops sharing a window.
  static const IconData stopSharing = Icons.stop_screen_share_outlined;

  /// Another window on the desktop.
  static const IconData window = Icons.desktop_windows_outlined;

  // Templates, context and data.

  /// A template.
  static const IconData template = Icons.article_outlined;

  /// A template's fields.
  static const IconData fields = Icons.view_list_outlined;

  /// Output columns of an export.
  static const IconData columns = Icons.view_column_outlined;

  /// Requiredness and validation rules.
  static const IconData rules = Icons.rule;

  /// Fields that identify a record.
  static const IconData identity = Icons.fingerprint;

  /// Moves records to a newer template version.
  static const IconData migrate = Icons.upgrade;

  /// Other names a column is known by.
  static const IconData aliases = Icons.label_outline;

  /// What the camera looks for.
  static const IconData detection = Icons.center_focus_strong;

  /// A checklist.
  static const IconData checklist = Icons.checklist;

  /// A kind of thing, when the template is unknown.
  static const IconData category = Icons.category_outlined;

  /// Hides an option.
  static const IconData hideOption = Icons.hide_source;

  /// Removes a link to a dataset.
  static const IconData unlink = Icons.link_off_outlined;

  /// Context levels.
  static const IconData context = Icons.account_tree_outlined;

  /// A saved context preset.
  static const IconData preset = Icons.bookmark_outline;

  /// A reference dataset, and a spreadsheet.
  static const IconData dataset = Icons.table_chart_outlined;

  /// One row of a dataset.
  static const IconData datasetRow = Icons.table_rows_outlined;

  /// Feedback about the app.
  static const IconData feedback = Icons.feedback_outlined;

  // Photo types.

  /// Front view.
  static const IconData photoFront = Icons.crop_portrait;

  /// Back view.
  static const IconData photoBack = Icons.flip_to_back;

  /// Serial number.
  static const IconData photoSerial = Icons.pin_outlined;

  /// Rating plate.
  static const IconData photoRatingPlate = Icons.badge_outlined;

  /// Damage.
  static const IconData photoDamage = Icons.report_outlined;

  /// Control panel.
  static const IconData photoPanel = Icons.grid_view_outlined;

  /// Location.
  static const IconData photoLocation = Icons.place_outlined;

  /// Attendance.
  static const IconData photoAttendance = Icons.groups_outlined;

  /// A document.
  static const IconData photoDocument = Icons.description_outlined;

  /// Any other photo.
  static const IconData photoOther = Icons.image_outlined;
}
