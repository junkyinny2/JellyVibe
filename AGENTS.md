# Agent Context

## Dropdown OK re-open bug (May 2026)

### Problem
After selecting an item from the subtitle/audio/video dropdown (pressing OK), the
same OK key event propagated to `MovieDetails.onKeyEvent` where it hit the
`focusRow = 1` → `openSelectorOptionsByIndex()` path and re-opened the dropdown.
The user saw the dropdown close briefly then immediately reappear.

### Root cause
`closeAllDropdowns()` unconditionally reset `m.activeSelectorIndex = -1`.  When
the `selectedIndex` field observer fired synchronously inside
`StreamDropdown.onItemSelected()`, it called `closeAllDropdowns()` which
wiped `activeSelectorIndex`.  By the time the same OK key arrived at
`MovieDetails.onKeyEvent`, `dropdownOpen` was already `false` (from `hide()`
in the observer), and `activeSelectorIndex` was `-1`, so
`openSelectorOptionsByIndex()` saw index `2 ≠ -1` and re-opened the dropdown.

### Fix
- Split into `closeAllDropdowns()` (hides only) and
  `closeAllDropdownsAndReset()` (hides + resets `activeSelectorIndex`).
- **Observers** (`onSubtitleDropdownSelect`, `onVideoDropdownSelect`,
  `onAudioDropdownSelect`) call `closeAllDropdowns()` — they intentionally
  leave `activeSelectorIndex` at the dropdown's index (e.g. `2` for subtitle).
- When the same OK key reaches `onKeyEvent`, `openSelectorOptionsByIndex(2)`
  sees `activeSelectorIndex = 2` → matches → toggles off (no re-open).
- **BACK key** and **explicit toggle-off** call `closeAllDropdownsAndReset()`
  to clear state properly.

### Why not to merge these back together
If someone later inlines `closeAllDropdownsAndReset` back into
`closeAllDropdowns`, this bug will return.  The two callers have different
semantic needs: observers must preserve `activeSelectorIndex` to prevent the
re-open race, while user-initiated closes (BACK, toggle) must reset it.

See `components/movies/MovieDetails.bs` lines 530-548.

## Tile collage library display (May 2026)

### Problem
Library tiles on the home screen showed a generic icon + poster with an overlaid
title.  Wanted a 4-image collage (Emby-style folder tile) with reflection effects.

### Fix
Added `tileImageURL1-4` fields to `HomeData.xml`, a `tileCollageGroup` in
`HomeItem.xml` with 4 Poster nodes + fading reflection rectangles, and
`LoadItemsTask.bs` logic to fetch 4 latest items per library via
`api.items.GetLatest()`.

### Files
- `components/data/HomeData.xml` — `tileImageURL1-4` fields
- `components/home/HomeItem.xml` — `tileCollageGroup` XML
- `components/home/HomeItem.bs` — `displayCollectionInfo()`, `getTileImageURLs()`
- `components/home/LoadItemsTask.bs` — `loadLibraries()` tile fetch
