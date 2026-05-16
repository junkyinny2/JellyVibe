# Features

Functional additions and UX changes in this fork versus upstream Jellyfin Roku source.

## Version History

- **1.2.6** (2026-05-15) - Version bump
- **1.2.5** (2026-05-13) - Dropdown fixes, Tags menu improvements
- **1.2.4** (2026-05-12) - Video resolution detection fix
- **1.2.3** (2026-05-12) - Focus padding system, navigation reentry fixes, UI polish
- **1.2.2** (2026-05-12) - Info button, dialog fixes, profile icon
- **1.2.1** (2026-04-27) - Tags navigation and navigation improvements
- **1.2.0** (2026-04-19) - Complete black theme, rebranding, UI/UX overhaul

---

## 1.2.5 - Dropdown Fixes & Tags Menu Improvements (2026-05-13)

### Stream Dropdown Component
- Created new `StreamDropdown.bs` / `.xml` component for video/audio stream selectors
- Created `StreamDropdownItem.bs` / `.xml` for individual dropdown items
- Purple theme styling matching JellyVibe branding
- Dynamic width based on content
- Scrollable list for long option lists

### Movie Details Dropdown Fixes
- Fixed purple theme on movie detail dropdowns
- Added text centering for better readability
- Dynamic width calculation based on content
- Scrollable list for many options
- Applied to VideoTrackListItem and AudioTrackListItem

### Tags Menu Improvements
- Added loading spinner and status text for Tags view
- Added `includeItemTypes` filter to API query (Movie, Series, BoxSet)
- Replaced O(n²) bubble sort with faster insertion sort
- Removed debug print statements from tags processing
- Clear cache on `loadTagsItems` to force fresh API calls
- Show spinner in `reloadCategoryResults` for Tags view
- Loading text shows "Loading tags..." during fetch

---

## 1.2.4 - Video Resolution Detection Fix (2026-05-12)

### Fixed Video Resolution Labels
- Movies now display correct resolution labels (1080p/1440p/4K) on the MovieDetails screen
- Jellyfin API returns coded height that differs from display height due to encoding padding
- Added **Width fallback** using dual Width/Height thresholds:
  - 4K: Height >= 2160 OR Width >= 3800
  - 1440p: Height >= 1440 OR Width >= 2500
  - 1080p: Height >= 1080 OR Width >= 1800
  - 720p: Height >= 720 OR Width >= 1200
  - 480p: Height >= 480 OR Width >= 700
- Fixed in: `getDisplayResolution()`, `itemContentChanged`, `SetUpVideoOptions()`, `videoOptionsClosed()`

---

## 1.2.3 - Focus System & Navigation (2026-05-12)

### Focus Padding System
- Implemented **Safe Zone Padding System** across all grid items to prevent focus clipping
- Every grid item wraps visual children in `<Group translation="[6, 6]">`
- Grid cell size is 12px larger than visual poster (the "+12 Rule")
- Applied to: GridItem, GridItemSmall, GridItemMedium, MusicArtistGridItem, HomeItem
- Prevents focus outlines from being cut off by MarkupGrid boundaries

### Navigation Reentry Guard
- Added global reentry guard to prevent auto-reentry after popping scenes
- Guards use `m.global.addOn.mainEventHandlers` for cross-component state sharing
- Fixed reentry guard to properly check the global state instead of local state
- Added debug prints for diagnosing reentry guard behavior
- Fixed auto-reentry bug after video playback

### UI Polish
- Removed scaling animation from grid items for smoother performance
- Fixed grid clipping issues
- Improved clock delay handling
- Fixed dialog text color encoding

---

## 1.2.2 - UI Improvements (2026-05-12)

### Movie Details Enhancements
- Added Info button to movie details for additional information display
- Fixed dialog text color for proper readability
- Added person icon to profile display

---

## 1.2.1 - Tags Navigation (2026-04-27)

### Tag Scraping & Navigation
- Implemented tag scraping from library items via `/Items?Fields=Tags` endpoint
- Fixed type checking for String vs roString to properly extract tags from Jellyfin responses
- Added crash protection for tag items lacking image metadata (ImageTags, ParentThumbImageTag)
- Fixed navigation to push new scene for tag-filtered results instead of in-place view change
- Optimized tag loading speed (100 items instead of 200, sorted by SortName)
- Set default view to grid mode for tag-filtered movie lists
- Fixed parentFolder propagation for nested tag navigation
- Fixed itemId assignment to use library ID instead of tag name for API queries

### Navigation Improvements
- Removed overly broad MainEventHandlers reentry guard that was blocking legitimate selections
- Fixed home screen movie listing tile requiring multiple enter presses
- Fixed home screen navigation responsiveness

---

## 1.2.0 - Complete Black Theme & Rebranding (2026-04-19)

### JellyVibe Rebranding
- Renamed application to **JellyVibe** across manifest, package, and translations
- Updated all branding assets including logos, posters, and splash screens
- New brand colors: JellyVibe Violet (`#7B2FBE`), JellyBackground (`#020B2A`)

### Complete Black Theme
- Dark navy background (`#020B2A`) replacing original dark gray
- Violet accent color (`#9C63B8`) and highlight (`#7B2FBE`)
- Cyan accent (`#1F8DBA`) and mid-tone periwinkle (`#6F7FB7`)
- Applied consistently across all screens

### Home Screen Redesign
- **Redesigned Top Navigation Bar** with dedicated "Home" and "Favorites" tabs
- **User Profile pill** with circular mask and server-side profile photo
- **Quick-access icon buttons** for Search and Settings with consistent focus highlights
- **Redesigned Presentation Mode**: vertical scrolling with stable top-info view
- **Enhanced Grid Mode**: 4-line word-wrapped titles and improved item spacing
- Improved HomeRows layout and spacing for better vertical balance

### Library Settings Sidebar
- Migrated library settings to new right-side icon sidebar (Emby-style)
- Includes: Voice search, Sort (ascending/descending toggle), Filter, View toggle (grid/list), Library settings
- Quick-access for filtering and sorting without entering sub-menus

### Movie Details Redesign
- **Enhanced Stream Selectors**: Richer labels showing video resolution/codec/HDR info and audio language/codec/channels
- **Selectable Plot Behavior**: Full text dialog for long overviews
- **Refined Metadata Layout**: Single text row under title, improved Date Added placement
- **Tags Support**: Tags displayed in extras section, clickable for tag-filtered navigation
- **Info Button**: Added to show additional movie information

### Control Styling System
- New **JellyRock Control Style**: Unified focus style with accent color `#7B2FBE`
- Focus background: Dark navy with transparency (`#020B2AE6`)
- Focus text: White (`#ffffff`), Focus icon: Black (`#000000`)
- Configurable focus states applied to IconButton, TextButton, StandardButton, JFButtons
- Consistent white/inverse focus across movie, TV, and music detail actions

---

## Playback Compatibility

### Triple Lie Playback Bypass
**Module**: `source/utils/CompatibilityBypass.bs`

Enabled via user setting `playback.embyMode` (Emby Mode toggle).

#### Level 1: Server-Side Cap Inflation ("The Super-Roku Lie")
- Reports 200 Mbps max bitrate to server
- Reports Level 6.2 support for H.264/HEVC
- **Fixes**: Error 500 (crash-prone transcoding)

#### Level 2: Player-Side Bitrate Normalization
- Forces integer division for bitrates
- Tricks Roku hardware into accepting high-spec streams
- **Fixes**: Code -5 errors

#### Level 3: Forced HTTP Static Tunneling
- Bypasses server transcoding recommendations
- Forces direct authenticated HTTP stream for incompatible containers
- **Fixes**: Code -3 errors

### Other Playback Improvements
- Hardened Video Player error recovery and focus handling
- Improved playback failure dismissal
- Fixed sceneManager observation for delete/resume/play functionality

---

## Filter System

### Filter Panel Component
**Files**: `components/FilterPanel/FilterPanel.bs`, `components/FilterPanel/FilterSection.bs`, `source/FilterManager.bs`

- Left-side sliding filter drawer with animations
- Sections: Genres, Tags
- Clear All button to reset filters
- Scrim overlay during filter panel open

### Filter Menu
**File**: `components/Libraries/EmbyFilterMenu.bs`
- Emby-style filter menu integrated into sidebar

---

## TV Series Details

### Inline Extras Panel
- Extras open below main content area
- Extras grid focused via escape key

### Button Styling
- Unified white/inverse focus styling via `applyControlButtonStyle` function
- Resume button dynamically added when content is resumable

---

## Person Details

### Extras Tray
- Dark surface matching person bio card (`#121212E6`)
- Video grid loads person-related videos

### Favorite Button
- Proper focus styling for favorite button

---

## Extras & Recommendations

- **Restyled "More Like This"**: Grid-like poster behavior with improved readability
- **Fixed Extras Sizing/Focus Behavior**: Regression fixes and row sizing consistency
- Added tag thumbnails support

---

## Architecture & Coding Standards

### Roku-Safe Coding Protocol
**File**: `rokusafe.md`

- Never mutate global state
- Never modify existing SceneGraph nodes (sandbox new features)
- Fail loudly - never silently
- Never block render thread (use tasks)
- Treat AAs as immutable (clone before editing)
- Every new field must be namespaced

### Development Gotchas
**File**: `DEVELOPMENT_GOTCHAS.md`

- **Reentry Guard**: Use local boolean guards to prevent rapid multi-push
- **Type Mismatch**: Use `.toStr()` when comparing mixed types (true vs "true")
- **ScrollingText**: Use `maxWidth` instead of `width`
- **String Comparisons**: Use `isStringEqual()` for reliable comparisons

### UI Architecture
**File**: `UI_ARCHITECTURE.md`

- Focus padding system documentation
- The "+12 Rule" for grid cell sizing

---

## New Components

- `components/CastItem.bs` / `.xml` - Cast member display
- `components/Libraries/LibrarySideIcon.bs` / `.xml` - Library sidebar icons
- `components/Libraries/EmbyFilterMenu.bs` / `.xml` - Filter menu
- `components/FilterPanel/FilterPanel.bs` / `.xml` - Filter drawer
- `components/FilterPanel/FilterSection.bs` / `.xml` - Filter section
- `components/FilterPanel/LoadFilterDataTask.bs` / `.xml` - Filter data loading
- `components/FilterPanel/FilterCheckItem.bs` / `.xml` - Individual filter item
- `components/navigation/EmbySidebar.bs` / `.xml` - Emby-style navigation sidebar
- `components/movies/StreamSelectorItem.xml` - Stream selector row item
- `components/ItemGrid/TextButtonRowItem.bs` / `.xml` - Text button row item
- `source/utils/CompatibilityBypass.bs` - Playback compatibility module
- `source/utils/controlStyle.bs` - Unified control styling
- `source/FilterManager.bs` - Filter state management

---

## Deployment

### Manual Deployment Scripts
- `deploy_roku_manual.bat` - Manual deployment
- `deploy_roku.bat` - Standard deployment
- `deploy_roku.ps1` - PowerShell deployment with curl sideload
- `deploy-multi.ps1` - Multi-device deployment
- `deploy_other.ps1` - Alternative deployment
- `rokudeploy.example.json` - Example configuration

### Debug Tools
- `rokudebug.ps1` - Remote debugging
- `rokudebugother.ps1` - Debug other devices
- `publish.bat` - Publishing script

---

## Upstream Difference

- **Baseline**: Jellyfin Roku 3.1.7
- **Total Changed Files**: 246
- **Line Delta**: +7108 / -1406

---

## Maintenance

- Refresh diff docs: `npm run docs:update-diff`
- Set different baseline: `DIFF_BASE=upstream/master npm run docs:update-diff`
