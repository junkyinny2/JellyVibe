# JellyVibe

A feature-enhanced fork of the Jellyfin Roku client, rebranded as JellyVibe with significant UI/UX improvements, playback compatibility fixes, and new navigation features.

## Version

Current Release: **1.2.4** (2026-05-12)

---

## Key Features

### Focus System & Navigation
- **Safe Zone Padding System**: Every grid item uses 6px translation padding to prevent focus clipping
- **The +12 Rule**: Grid cells are 12px larger than posters, preventing focus outlines from being cut off
- **Reentry Guard**: Global guard system prevents auto-reentry after backing out from screens
- Fixed grid clipping, clock delay, and navigation responsiveness issues

### UI/UX Overhaul
- **Complete Black Theme**: Dark navy background (`#020B2A`) with violet accents
- **Redesigned Home Screen**: Top navigation with Home/Favorites tabs, user profile pill with circular mask
- **Presentation Mode**: Vertical scrolling with stable top-info view
- **Enhanced Grid Mode**: 4-line word-wrapped titles with improved spacing
- **Library Settings Sidebar**: Emby-style right-side icon sidebar with sort, filter, view toggle

### Movie Details
- **Enhanced Stream Selectors**: Rich labels showing video resolution/codec/HDR and audio language/codec/channels
- **Selectable Plot**: Full text dialog for long overviews
- **Tags Support**: Clickable tags for tag-filtered navigation
- **Info Button**: Additional movie information display
- **Fixed Resolution Detection**: Uses Width fallback when API coded height differs from display height

### Tags Navigation
- **Tag Scraping**: Automatically extracts tags from library items via `/Items?Fields=Tags` endpoint
- **Tag Filtering**: Click any tag to view a filtered movie list
- **Optimized Loading**: Fast tag discovery with 100-item sampling
- **Grid Default**: Tag-filtered results display in grid view by default

### Playback Compatibility
- **Triple Lie Playback Bypass** (Emby Mode): Stabilizes high-spec media playback
  - Server-Side Cap Inflation: Reports 200 Mbps and Level 6.2 support to prevent Error 500
  - Player-Side Bitrate Normalization: Tricks Roku into accepting high-spec streams (Fixes Code -5)
  - Forced HTTP Static Tunneling: Direct authenticated HTTP streams (Fixes Code -3)
- **Hardened Error Recovery**: Improved video player focus handling and failure dismissal

### Control Styling
- **Unified Focus Style**: Accent color `#7B2FBE` with dark navy focus background
- **Configurable Focus States**: Applied consistently across IconButton, TextButton, StandardButton, JFButtons
- **White/Inverse Focus**: Consistent styling across movie, TV, and music detail actions

### TV Series Details
- Inline extras panel opens below main content
- Unified button styling with resume button support
- Extras grid focused via escape key

### Person Details
- Dark surface extras tray matching bio card
- Video grid for person-related content

### Extras & Recommendations
- Restyled "More Like This" with grid-like poster behavior
- Fixed sizing and focus behavior across extras rows

---

## Playback Compatibility (Emby Mode)

Enable via Settings > Playback > Emby Mode toggle.

| Fix | Description |
|-----|-------------|
| Error 500 | Server-side cap inflation prevents crash-prone transcoding |
| Code -5 | Player-side bitrate normalization tricks Roku hardware |
| Code -3 | Forced HTTP tunneling bypasses incompatible containers |

---

## Deployment

### Quick Start
1. Copy `rokudeploy.example.json` to `rokudeploy.json`
2. Update with your Roku IP and password
3. Run `deploy_roku.bat` or `deploy_roku.ps1`

### Deployment Scripts
- `deploy_roku.bat` / `deploy_roku.ps1` - Standard deployment
- `deploy_roku_manual.bat` - Manual deployment
- `deploy-multi.ps1` - Multi-device deployment
- `deploy_other.ps1` - Alternative deployment

### Debug Tools
- `rokudebug.ps1` - Remote debugging
- `rokudebugother.ps1` - Debug other devices

---

## Upstream Difference

- **Baseline**: Jellyfin Roku 3.1.7
- **Total Changed Files**: 246
- **Line Delta**: +7108 / -1406
- **Status**: 21 Added, 225 Modified

---

## Documentation

- **Features**: See `features.md` for detailed feature list
- **Changelog**: See `changelog.md` for version history
- **Architecture**: See `UI_ARCHITECTURE.md` for focus padding system
- **Coding Standards**: See `rokusafe.md` for Roku-safe coding protocol
- **Development**: See `DEVELOPMENT_GOTCHAS.md` for common pitfalls

---

## Maintenance

Refresh diff documentation:
```bash
npm run docs:update-diff
```

Set different baseline:
```bash
DIFF_BASE=upstream/master npm run docs:update-diff
```

---

## License

GPL-2.0 (Same as upstream Jellyfin Roku)

## Credits

Based on [Jellyfin Roku](https://github.com/jellyfin/jellyfin-roku) with significant enhancements by the JellyVibe team.
