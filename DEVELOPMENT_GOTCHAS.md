# JellyVibe Development Gotchas & Recurring Issues

This document tracks recurring bugs and "gotchas" that have historically plagued the JellyVibe codebase. Refer to this before making changes to navigation or UI logic.

## 1. Navigation "Re-entry" Bug
**Symptoms**: Rapidly clicking a tile causes multiple scenes to push, or the app to freeze/crash when backing out.
**The Fix**: Use a local boolean guard (e.g., `m.applyMovieGuard`) in the event handler.
**Critical Rule**: Always set the guard to `true` at the *start* of the function and `false` only after the navigation logic is complete (or if an early return occurs).
**Files to Watch**: `VisualLibraryScene.bs`, `MainEventHandlers.bs`.

## 2. Focus Highlight Clipping (MarkupGrid)
**Symptoms**: Focus borders are cut off on the top/left/right/bottom of tiles.
**The Fix**: The "Safe Zone" Padding System.
- Wrap children in `<Group translation="[6, 6]">`.
- Set `itemSize` to `PosterSize + 12px`.
- See `UI_ARCHITECTURE.md` for full details.

## 3. Type Mismatch in Settings/JSON
**Symptoms**: App crashes with `Type Mismatch` when comparing values from `m.global.session.user.settings`.
**The Cause**: Jellyfin/JSON sometimes returns "true" (string) and sometimes `true` (boolean). BrightScript crashes if you compare `true = "true"`.
**The Fix**: Always use `.toStr()` when comparing values that might be mixed types.
**Example**: `if settings.someValue.toStr() = "true"`

## 4. ScrollingText Field Errors
**Symptoms**: Log warnings: `Tried to set nonexistent field "width" of a "ScrollingText" node`.
**The Cause**: `ScrollingText` nodes do not have a `width` field; they use `maxWidth`.
**The Fix**: Use `node.maxWidth = ...` instead of `node.width`.

## 5. Case Sensitivity in String Comparisons
**Symptoms**: Conditionals failing unexpectedly (e.g., `item.type = "Movie"` returning false).
**The Fix**: Always use `isStringEqual(val1, val2)` or `LCase(val1) = "movie"` for reliable comparisons.

## 6. Tags/Folder Navigation Persistence
**Symptoms**: Backing out from a filtered view goes to the Home screen instead of the Tags/Folder list.
**The Fix**: Ensure the navigation logic uses `m.top.selectedItem` to push a new scene instance rather than just updating the view in place.
