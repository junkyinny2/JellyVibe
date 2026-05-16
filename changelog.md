# Changelog

Difference tracker between this fork and upstream Jellyfin Roku source.

- Baseline: 3.1.7
- Generated: 2026-05-12T13:19:00.000Z
- Refresh command: `npm run docs:update-diff`

---

## Version 1.2.6 (2026-05-15)

### Version Bump
- Version bump to 1.2.6

---

## Version 1.2.5 (2026-05-13)

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

### Tags Menu Improvements
- Added loading spinner and status text for Tags view
- Added `includeItemTypes` filter to API query (Movie, Series, BoxSet)
- Replaced O(n²) bubble sort with faster insertion sort
- Removed debug print statements from tags processing
- Clear cache on `loadTagsItems` to force fresh API calls
- Show spinner in `reloadCategoryResults` for Tags view

---

## Version 1.2.4 (2026-05-12)

### Bug Fixes
- **Video Resolution Detection**: Fixed movies showing wrong resolution labels (e.g., 720p instead of 1080p) on the MovieDetails screen
- Jellyfin API returns coded height that can differ from display height due to encoding padding
- Added Width fallback using dual Width/Height thresholds for accurate resolution detection
- Fixed in: `getDisplayResolution()`, `itemContentChanged`, `SetUpVideoOptions()`, `videoOptionsClosed()`

---

## Version 1.2.3 (2026-05-12)

### Focus System & Navigation
- **Standardized UI architecture** with focus padding system (the "+12 Rule")
- Fixed grid clipping issues across all grid items (GridItem, GridItemSmall, GridItemMedium, MusicArtistGridItem, HomeItem)
- Removed scaling animation from grid items for smoother performance
- Added global reentry guard to prevent auto-reentry after popping scenes
- Fixed reentry guard to properly check `m.global.addOn.mainEventHandlers` instead of local state
- Added debug prints for diagnosing reentry guard behavior
- Fixed clock delay
- Improved deploy scripts

### UI Fixes
- Fixed background color consistency
- Fixed menu navigation issues
- Fixed metadata separator encoding

---

## Version 1.2.2 (2026-05-12)

### UI Improvements
- Added Info button to movie details
- Fixed dialog text color
- Added person icon to profile display
- Version bump

---

## Version 1.2.1 (2026-04-27)

### Tags Navigation
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
- Fixed auto-reentry bug when backing out from movie details screen
- Fixed home screen navigation responsiveness
- Rely on VisualLibraryScene reentry guard for auto-reentry prevention

### Bug Fixes
- Fixed delete and resume/play functionality - moved sceneManager observation to correct port
- Added tag thumbnails support

---

## Version 1.2.0 (2026-04-19)

### JellyVibe Rebranding
- Full application rebranding from Jellyfin Roku to JellyVibe
- Updated manifest, package name, and all translations
- New branding assets: logos, posters, splash screens
- Complete black theme with dark navy background (`#020B2A`)
- New brand colors: JellyVibe Violet (`#7B2FBE`), JellyBackground (`#020B2A`), JellyViolet (`#9C63B8`), JellyCyan (`#1F8DBA`), JellyPeriwinkle (`#6F7FB7`)

### UI/UX Overhaul
- **Home Screen**: Redesigned top navigation with Home/Favorites tabs, user profile pill with circular mask
- **Library Settings Sidebar**: Emby-style right-side icon sidebar with voice search, sort, filter, view toggle
- **Presentation Mode**: Vertical scrolling with stable top-info view
- **Grid Mode**: 4-line word-wrapped titles with improved spacing
- Restored 2-line title wrapping for movie listings

### Movie Details
- Enhanced stream selectors with richer labels (video resolution/codec/HDR, audio language/codec/channels)
- Selectable plot with full text dialog for long overviews
- Improved metadata layout and Date Added placement
- Tags support integrated into extras section

### Playback Compatibility
- **Triple Lie Playback Bypass** modularized into `CompatibilityBypass.bs`
- Server-side Cap Inflation: Reports 200 Mbps and Level 6.2 to prevent Error 500
- Player-side Bitrate Normalization: Fixes Code -5
- Forced HTTP Static Tunneling: Fixes Code -3
- UI focus fixes and active states
- Type-mismatch crash fixes on Home screen

### Control Styling
- Unified focus style with accent color `#7B2FBE`
- Focus background: Dark navy (`#020B2AE6`), Focus text: White, Focus icon: Black
- Configurable focus states for IconButton, TextButton, StandardButton, JFButtons
- Consistent white/inverse focus across movie, TV, and music detail actions

---

## Recent Highlights

- **May 2026**: Fixed video resolution detection using Width fallback for coded height discrepancies
- **April 2026**: Complete black theme, rebranding to JellyVibe, UI/UX overhaul
- **JellyVibe Rebranding**: Full application rebranding across all assets and code
- **Triple Lie Playback Bypass**: Modularized into `CompatibilityBypass.bs` to fix Roku lockup issues
- **Deployment**: Added manual deployment scripts, PowerShell deployment, multi-device deployment

---

## Summary

- Total changed files: 246
- Total line delta: +7108 / -1406

| Status | Count |
| --- | ---: |
| Added | 21 |
| Modified | 225 |
| Deleted | 0 |
| Renamed | 0 |
| Copied | 0 |

## Changed Areas

| Area | Files Changed |
| --- | ---: |
| components | 196 |
| images | 17 |
| (root) | 15 |
| source | 10 |
| .github | 2 |
| locale | 2 |
| scripts | 2 |
| .vscode | 1 |
| settings | 1 |

## Added Files (21)

- .github/workflows/pages.yml
- beledarian_info.md
- bsconfig.deploy.json
- bslint_output.txt
- changelog.md
- components/CastItem.bs
- components/CastItem.xml
- components/Libraries/LibrarySideIcon.bs
- components/Libraries/LibrarySideIcon.xml
- deploy_roku_manual.bat
- deploy_roku.bat
- features.md
- images/9patch/border-6px.9.png
- images/9patch/filled-rounded.9.png
- manual_deployment_guide.txt
- prepare_roku.mjs
- rokudeploy.example.json
- scripts/build-pages-site.mjs
- scripts/update-diff-docs.mjs
- source/utils/CompatibilityBypass.bs
- source/utils/controlStyle.bs

## Modified Files (225)

- .github/pull_request_template.md
- .gitignore
- .vscode/settings.json
- components/AudioMiniPlayer.xml
- components/BaseScene.bs
- components/BaseScene.xml
- components/ButtonGroupHoriz.bs
- components/ButtonGroupHoriz.xml
- components/ButtonGroupVert.xml
- components/Buttons/ButtonData.xml
- components/Buttons/ExpandingLabel.xml
- components/Buttons/JFButtons.bs
- components/Buttons/JFButtons.xml
- components/Buttons/SlideOutButton.xml
- components/Buttons/TextSizeTask.xml
- components/captionTask.xml
- components/Clock.xml
- components/config/ConfigData.xml
- components/config/FormElement.xml
- components/config/FormList.xml
- components/config/JFServer.xml
- components/config/ServerDiscoveryTask.xml
- components/config/SetServerScreen.xml
- components/config/SigninScene.xml
- components/data/AlbumData.xml
- components/data/ChannelData.xml
- components/data/CollectionData.xml
- components/data/ExtrasData.xml
- components/data/FolderData.xml
- components/data/GetFiltersTask.xml
- components/data/GetPlaylistDataTask.xml
- components/data/HomeData.xml
- components/data/ImageData.xml
- components/data/JFContentItem.xml
- components/data/MovieData.xml
- components/data/MusicAlbumData.xml
- components/data/MusicAlbumSongListData.xml
- components/data/MusicArtistData.xml
- components/data/MusicSongData.xml
- components/data/OptionsButton.xml
- components/data/OptionsData.xml
- components/data/PersonData.xml
- components/data/PhotoData.xml
- components/data/PlaylistData.xml
- components/data/PlaylistItemData.xml
- components/data/PublicUserData.xml
- components/data/RecordingData.bs
- components/data/RecordingData.xml
- components/data/SceneManager.bs
- components/data/SceneManager.xml
- components/data/ScheduleProgramData.xml
- components/data/SearchData.xml
- components/data/SeriesData.xml
- components/data/ServerData.xml
- components/data/TVEpisode.xml
- components/data/TVEpisodeData.xml
- components/data/TVSeasonData.xml
- components/data/UserData.xml
- components/data/VideoData.xml
- components/extras/ExtrasItem.bs
- components/extras/ExtrasItem.xml
- components/extras/ExtrasRowList.bs
- components/extras/ExtrasRowList.xml
- components/extras/ExtrasSlider.xml
- components/GetNextEpisodeTask.xml
- components/GetPlaybackInfoTask.xml
- components/GetShuffleEpisodesTask.xml
- components/home/Home.bs
- components/home/Home.xml
- components/home/HomeItem.bs
- components/home/HomeItem.xml
- components/home/HomeRows.bs
- components/home/HomeRows.xml
- components/home/LoadItemsTask.bs
- components/home/LoadItemsTask.xml
- components/IconButton.bs
- components/IconButton.xml
- components/ItemGrid/Alpha.xml
- components/ItemGrid/AlphaItem.xml
- components/ItemGrid/AudioBookGridItem.xml
- components/ItemGrid/ColorOption.xml
- components/ItemGrid/FavoriteItemsTask.xml
- components/ItemGrid/GridItem.xml
- components/ItemGrid/GridItemMedium.xml
- components/ItemGrid/GridItemSmall.bs
- components/ItemGrid/GridItemSmall.xml
- components/ItemGrid/ItemGridOptions.xml
- components/ItemGrid/LibraryFilterDialog.xml
- components/ItemGrid/LoadItemsTask2.bs
- components/ItemGrid/LoadItemsTask2.xml
- components/ItemGrid/LoadVideoContentTask.bs
- components/ItemGrid/LoadVideoContentTask.xml
- components/ItemGrid/MusicArtistGridItem.xml
- components/JFButton.xml
- components/JFGroup.xml
- components/JFMessageDialog.xml
- components/JFOverhang.xml
- components/JFScreen.xml
- components/keyboards/IntegerKeyboard.xml
- components/labels/MultiStyleText.xml
- components/labels/Text.xml
- components/Libraries/AudioBookLibraryView.bs
- components/Libraries/AudioBookLibraryView.xml
- components/Libraries/LiveTVLibraryView.xml
- components/Libraries/MusicLibraryView.bs
- components/Libraries/MusicLibraryView.xml
- components/Libraries/OtherLibrary.bs
- components/Libraries/OtherLibrary.xml
- components/Libraries/VisualLibraryScene.bs
- components/Libraries/VisualLibraryScene.xml
- components/LibrarySettingDialog.xml
- components/ListPoster.xml
- components/liveTv/ChannelInfo.xml
- components/liveTv/LoadChannelsTask.xml
- components/liveTv/LoadProgramDetailsTask.xml
- components/liveTv/LoadSheduleTask.xml
- components/liveTv/ProgramDetails.xml
- components/liveTv/RecordProgramTask.xml
- components/liveTv/schedule.xml
- components/login/UserItem.xml
- components/login/UserRow.xml
- components/login/UserSelect.xml
- components/manager/QueueManager.bs
- components/manager/QueueManager.xml
- components/mediaPlayers/AudioPlayer.xml
- components/MovieDetailButton.xml
- components/movies/AudioTrackListItem.xml
- components/movies/MovieDetails.bs
- components/movies/MovieDetails.xml
- components/movies/MovieOptions.bs
- components/movies/MovieOptions.xml
- components/movies/VideoTrackListItem.bs
- components/movies/VideoTrackListItem.xml
- components/music/AlbumGrid.xml
- components/music/AlbumTrackList.xml
- components/music/AlbumView.bs
- components/music/AlbumView.xml
- components/music/ArtistView.bs
- components/music/ArtistView.xml
- components/music/AudioPlayerView.xml
- components/music/LoadScreenSaverTimeoutTask.xml
- components/music/Lyrics.xml
- components/music/PlaylistItem.xml
- components/music/PlaylistItems.xml
- components/music/PlaylistView.xml
- components/music/SimilarArtistGrid.xml
- components/music/SongItem.xml
- components/music/task/LoadAlbumTask.xml
- components/options/OptionNode.xml
- components/options/OptionsSlider.xml
- components/PersonDetails.bs
- components/PersonDetails.xml
- components/photos/LoadPhotoTask.xml
- components/photos/PhotoDetails.xml
- components/PlayedCheckmark.xml
- components/PlaystateTask.xml
- components/quickConnect/QuickConnect.xml
- components/quickConnect/QuickConnectDialog.xml
- components/RadioDialog.xml
- components/RemoteSubtitleDialog.xml
- components/search/SearchResults.xml
- components/search/SearchRow.xml
- components/search/SearchTask.xml
- components/SearchBox.xml
- components/section/section.xml
- components/section/sectionScroller.xml
- components/settings/ColorGrid.xml
- components/settings/settings.xml
- components/settings/Slider.xml
- components/Spinner.xml
- components/StandardButton.bs
- components/StandardButton.xml
- components/StandardDialog.xml
- components/subtitle/SubtitleItem.xml
- components/subtitle/SubtitleSearchView.xml
- components/tasks/GetFirstEpisodeImageTask.xml
- components/tasks/PostTask.xml
- components/TextButton.bs
- components/TextButton.xml
- components/tvshows/ScreenSettings.xml
- components/tvshows/TVEpisodeList.xml
- components/tvshows/TVEpisodeListItem.xml
- components/tvshows/TVExtrasTask.xml
- components/tvshows/TVListOptions.xml
- components/tvshows/TVSeasonDetails.bs
- components/tvshows/TVSeasonDetails.xml
- components/tvshows/TVSeasonGrid.xml
- components/tvshows/TVSeasonGridItem.xml
- components/tvshows/TVSeriesDetails.bs
- components/tvshows/TVSeriesDetails.xml
- components/video/OSD.xml
- components/video/PreloadTrickplayImagesTask.xml
- components/video/VideoPlayerView.bs
- components/video/VideoPlayerView.xml
- components/WhatsNewDialog.xml
- images/channel-poster_fhd_dev.png
- images/channel-poster_fhd.png
- images/channel-poster_hd_dev.png
- images/channel-poster_hd.png
- images/channel-poster_sd_dev.png
- images/channel-poster_sd.png
- images/icons/loopindicator-off.png
- images/icons/loopindicator-on.png
- images/icons/loopindicator1-on.png
- images/icons/shuffleIndicator-off.png
- images/icons/shuffleIndicator-on.png
- images/logo-icon120.jpg
- images/splash-screen_fhd.png
- images/splash-screen_hd.png
- images/splash-screen_sd.png
- locale/en_US/translations.ts
- locale/zh_Hans/translations.ts
- manifest
- package-lock.json
- package.json
- README.md
- settings/settings.json
- source/api/Items.bs
- source/enums/ColorPalette.bs
- source/Main.bs
- source/MainActions.bs
- source/MainEventHandlers.bs
- source/ShowScenes.bs
- source/utils/deviceCapabilities.bs
- source/utils/misc.bs

## Deleted Files (0)

- None

## Renamed Files (0)

- None

## Copied Files (0)

- None
