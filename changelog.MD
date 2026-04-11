\# Changelog



All notable changes to Sweepe will be documented in this file.



\## \[0.2.0] - 2026-04-11



\### Fixed

\- Skip counter bug — photos that were skipped and later decided (keep/delete) are no longer double-counted in the "Skipped" counter

\- Total photo count in summary no longer exceeds the actual number of photos (e.g. 100 photos showing as 102)



\### Added

\- MTP folder picker — the "Pick Folder" button now supports opening folders from phones connected via USB cable (previously only local drives were shown)



\### Internal

\- Added `toSkip` set in `AppState` for accurate skip tracking

\- Refactored folder picker from `file\_picker` package to Windows Shell API (`IFileOpenDialog`)



\## \[0.1.0] - 2026-03-10



\### Added

\- Initial release

\- Flat mode — review all photos one by one with keep/delete/skip/undo

\- Group mode — photos grouped by date (year → month → week)

\- Sort options — by name, size, or date

\- Session persistence — resume progress after closing the app

\- Files moved to Recycle Bin (not permanently deleted)

\- Dark luxury UI (Obsidian + Amber)

