# Changelog

All notable changes to Sweepe will be documented in this file.

## Upcoming Fixes & Features

- **Execution Visual Cues** — Implementing a strikethrough effect on group titles (week, month, year) once a group has been 100% processed.
- **Enhanced Progress Feedback** — Adding a "00:00:00" time-elapsed counter at the bottom of the deletion dialog for better process monitoring.
- **UI Layout Fixes** — Fixing a layout bug where the bottom dialog width expands excessively, ensuring it stays contained and readable.

# Releases
## [0.2.0] - 2026-04-11

### Added
- **Deletion Progress Dialog** — Added a pop-up loading dialog ("Deleting...") during file removal, featuring a progress bar and time elapsed indicator to provide clear feedback during large batch operations.
- **Confirmation Dialog** — Added a safety prompt requiring user confirmation before executing the deletion process.
- **Date Range Labels** — Added clear start and end date labels within the Weekly Group mode for easier chronological navigation.
- **Grouped Summary** — The list of deleted photos in the Summary view is now grouped chronologically (by week/month) and includes collapsible sections for better readability.
- **MTP Folder Picker** — The "Pick Folder" button now supports opening folders directly from devices connected via USB cable, such as smartphones and cameras (previously restricted to local drives).
- **Arrows Mark** — Added directional arrow overlays to the "current picture" carousel to improve navigational UX.

### Changed
- **Color-Coded Progress Bar** — Upgraded the global progress bar to visually represent actions using color codes (blue for kept photos, red for deleted photos) proportionate to the total count.

### Fixed
- **State Inconsistency Bug** — Fixed a complex bug where photos initially marked as "skip" and later flagged as "keep/delete" still falsely incremented the skipped counter, causing downstream logic errors.
- **Skip Counter Bug** — Photos that were skipped and later decided (keep/delete) are no longer double-counted in the "Skipped" metric.
- **Summary Count Bug** — Fixed an issue where the total photo count in the summary exceeded the actual number of loaded photos (e.g., 100 photos displaying as 102).

### Internal
- **Batch Deletion Engine** — Reworked the "move to Recycle Bin" operation to process files in bulk rather than one by one, significantly improving execution speed.

## [0.1.1] - 2026-04-01

### Added
- **Flat Mode** — Review all photos sequentially with keep, delete, skip, and undo actions.
- **Group Mode** — View and manage photos grouped hierarchically by date (year → month → week).
- **Sort Options** — Sort galleries by name, size, or date.
- **Session Persistence** — Automatically saves state to resume progress after closing the app.
- **Safety First** — Files are moved to the system Recycle Bin rather than permanently deleted.
- **Dark Luxury UI** — Custom Obsidian & Amber color scheme for a premium viewing experience.

### Internal
- Added `toSkip` set in `AppState` for accurate skip tracking and state management.
- Refactored folder picker, migrating from the `file_picker` package to the native Windows Shell API (`IFileOpenDialog`).

## [0.1.0] - 2026-03-10

### Added
- **Initial Port release** - Ported the barebone features and core logic from the original Python prototype.
- **Codebase Migration** - Completely rewritten from the legacy Python script, establishing the new foundational architecture. 
