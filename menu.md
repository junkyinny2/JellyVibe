# Embyold Menu - Full Video Analysis

## Tab Sequence
`Movies` → `Suggestions` → `Trailers` → `Playlists` → `Collections` → `Favorites` → `Genres` → `Tags` → `Folders`

Total: 9 tabs. The first 6 are visible on initial load. "Genres" is **partially cut off** at the right edge of the clipping area, showing only ~3-4 letters ("Gen") to provide a visual cue that more items exist off-screen.

## Layout & Sizing
- **Component**: `MarkupGrid` with `numRows="1"` and `numColumns="9"`
- **Item size**: `[220, 60]` (each tab is 220px wide, 60px tall)
- **Item spacing**: `[20, 0]` (20px gap between items horizontally)
- **Total step per item**: 240px (220 + 20)
- **Clipping rectangle**: The tabs are inside a `tabsClip` Group with a `clippingRect` that prevents overflow past the search/settings icons

## Scrolling Behavior (Shift-Based, NOT Continuous)
The menu does **not** scroll continuously pixel-by-pixel. Instead, it uses a **discrete shift** system:

| Focus Index | Tab Name    | Shift | Behavior |
|-------------|-------------|-------|----------|
| 0-5         | Movies → Favorites | 0 | No scroll — all 6 tabs visible, "Genres" peeking at edge |
| 6           | Genres      | 1     | Shift left by 1 item (240px) — "Movies" goes off-screen left |
| 7-8         | Tags, Folders | 2   | Shift left by 2 items (480px) — "Movies" and "Suggestions" go off-screen left |

This is implemented via: `m.categoryTabs.translation = [-shift * itemWidth, 0]`

## Selection Behavior
- **OK press**: Calls `onCategorySelected()` which reads `m.categoryTabs.itemSelected`, gets the ContentNode child at that index, and calls `applyMovieCategory(tabName)` for movie libraries
- **Focus highlight**: The `TextButtonRowItem` component shows a rounded-corner highlight behind the focused tab text, using the theme's accent color (`ColorPalette.HIGHLIGHT`)
- **Selected underline**: When a tab is selected but not focused, a subtle white underline appears below the text (except for the "Movies" tab which has no underline)

## Color Scheme
- **Original Embyold**: Used a vibrant green highlight (`#52B54B`)
- **JellyVibe**: Uses the violet-cyan scheme per user request:
  - Highlight: `#7B2FBE` (violet)
  - Gradient accents from violet → cyan
  - Background: `#020B2A` (deep navy)

## Typography
- Font: `font:SmallestSystemFont` (Roku system font)
- Labels are centered horizontally and vertically within the 220×60 container
- No truncation occurs because 220px is wide enough for all tab names including "Suggestions" and "Collections"

## Right-Side Icons
- **Search icon** (magnifying glass) and **Settings icon** (gear) positioned after the last visible tab
- Navigation flows: last tab → RIGHT → search → RIGHT → settings
- LEFT from search → jumps to last tab in the grid

## Focus Navigation
- **DOWN from any tab**: Moves focus to the content grid below
- **UP from content grid**: Returns focus to the category tabs (or overview in presentation mode)
- **RIGHT past last tab**: Moves to search button
- **LEFT from search**: Jumps to the last tab (Folders)
