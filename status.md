# JellyVibe Tags Implementation Status

## Summary of Progress
**TAGS FEATURE IS NOW WORKING!** The Tags view successfully displays all unique tags scraped from library items. Users can click a tag to see filtered movies, and backing out returns to the Tags list.

## What has been tried
1.  **Endpoint: `/Items?IncludeItemTypes=Tag`**
    *   Result: "No items found."
    *   Conclusion: The server does not store tags as first-class "Tag" items.
2.  **Endpoint: `/Tags`**
    *   Result: `[]` (Empty list).
3.  **Endpoint: `/Items/Filters`**
    *   Result: "No tags found on this server."
4.  **Tag Scraping via `/Items?Fields=Tags`** ✅ **WORKING**
    *   Initial: API returned 200 items with Tags arrays, but 0 tags extracted
    *   **Root Cause**: Type check used `roString` but Jellyfin returns `String` (literal strings vs component types)
    *   **Fix**: Changed `type(tag) = "roString"` to `(type(tag) = "String" or type(tag) = "roString")`
    *   **Result**: Successfully extracts 684 unique tags from 50 library items

## UI State
- **Backdrop**: Works normally for Tags view.
- **Casing**: All view name checks are case-insensitive.
- **Auto-re-entry bug**: **FIXED** - Removed MainEventHandlers reentry guard (too broad), relying on VisualLibraryScene guard
- **Red tint**: **REMOVED**
- **Navigation**: **FIXED** - backing out from tag-filtered movies returns to Tags list
- **Loading Speed**: **OPTIMIZED** - reduced from 200 to 100 items, sorted by SortName
- **Home screen tile**: **FIXED** - Removed MainEventHandlers reentry guard that was blocking legitimate selections

## Where we left off
Tags are **fully functional**. The console shows successful extraction:
- `[TAGS] Querying Tags with ParentId=f137a2dd21bbc1b99aa5c0f6bf02a805`
- `[TAGS] data.Items count= 50`
- `[TAGS] sample item 1 Tags array count= 62`
- `[TAGS] sample item 1 first tag type=String`
- `[TAGS] Items with Tags= 50 Unique tags= 684`

## Next Steps (COMPLETED) ✅
All issues resolved:
1. ✅ Fixed type check for String vs roString
2. ✅ Fixed FolderData crash by adding isValid checks for ImageTags and ParentThumbImageTag
3. ✅ Fixed navigation to push new scene instead of changing view in-place
4. ✅ Optimized loading speed (50 items instead of 200)

## Files Modified
- `components/ItemGrid/LoadItemsTask2.bs` - Type check fix (String vs roString), speed optimization (50 items), diagnostic prints
- `components/Libraries/VisualLibraryScene.bs` - Navigation fix (push new scene for tags), reentry guard fix, tag subfolder itemId fix, default view to grid for subfolders
- `components/data/FolderData.bs` - Crash fix with isValid checks for ImageTags, ParentThumbImageTag, Type
- `source/MainEventHandlers.bs` - Tag type handling, parentFolder fix
- `rokudebug.ps1` - Fixed connection (removed auth header), added log file path on exit

---

## Session History

### 2026-04-27 ~09:30 UTC-04:00 - Previous Work
**Diagnostic: "Red Tint" Test**
- Result: **Success.** The Tags view correctly turns red, confirming the `VisualLibraryScene` logic is properly identifying and switching to the Tags category.

**Diagnostic: "UI TEST" Dummy Item**
- Result: **Success.** A hard-coded tile appeared in the grid, confirming the `MarkupGrid` and `FolderData` components are correctly configured to display content once data is received.

### 2026-04-27 ~10:00 UTC-04:00 - Current Session (You)
**Console Output Retrieved**
- `[TAGS] Querying Tags with ParentId=f137a2dd21bbc1b99aa5c0f6bf02a805`
- `[TAGS] data type=roAssociativeArray`
- `[TAGS] data.Items count= 200`
- `[TAGS] Items with Tags= 200 Unique tags= 0`
- Added deeper diagnostic prints to inspect actual tag structure
- Fixed rokudebug.ps1 connection issue (removed auth header)

### 2026-04-27 ~13:00 UTC-04:00 - Final Session (You)
**Tags Feature COMPLETED**

**Fix 1: Type Check Bug in `LoadItemsTask2.bs`**
- Problem: `type(tag) = "roString"` returned false because Jellyfin returns literal `String` type
- Solution: Changed to `(type(tag) = "String" or type(tag) = "roString")`
- Result: Successfully extracts 684 unique tags

**Fix 2: FolderData Crash in `FolderData.bs`**
- Problem: Tag items lack image metadata, causing crash when accessing `ImageTags.Primary`
- Solution: Added `isValid()` checks for `ImageTags`, `ParentThumbImageTag`, and `Type` fields
- Result: Tags display without posters (text-only), no crash

**Fix 3: Navigation Bug in `VisualLibraryScene.bs`**
- Problem: Selecting tag changed view in-place, backing out went to home instead of Tags list
- Solution: Set `m.top.selectedItem = item` with `parentFolder` and `tagName` properties to push new scene
- Result: Backing out from tag-filtered movies returns to Tags list

**Fix 4: Loading Speed in `LoadItemsTask2.bs`**
- Problem: 200 items took too long to load
- Solution: Reduced to 50 items, sorted by `DateCreated Descending`
- Result: Much faster loading, still shows recent tags

### 2026-04-27 ~13:30-14:10 UTC-04:00 - Tag Filtering Fixes
**Fix 5: Tag Item Type Detection in `VisualLibraryScene.bs`**
- Problem: Tag items had `type=Folder` instead of `type=Tag`, so tag selection wasn't recognized
- Solution: Changed condition from `item.type = "Tag"` to `isStringEqual(m.view, "Tags")` and override `item.type = "tag"`
- Result: Tag selection now correctly triggers tag subfolder creation

**Fix 6: Crash in `MainEventHandlers.bs`**
- Problem: `m.library.id` was invalid when setting `json.parentFolder`
- Solution: Use `selectedItem.parentFolder` (set by VisualLibraryScene) instead of `m.library.id`
- Result: No crash when clicking a tag

**Fix 7: itemId Bug in `VisualLibraryScene.bs`**
- Problem: When in tag subfolder, `itemId` was set to tag name instead of library ID, causing wrong API query
- Solution: Check if in tag subfolder before setting `itemId` - use `parentFolder` for subfolders, `Id` for tag list
- Result: API queries the correct library ID for filtering

**Fix 8: parentFolder Propagation in `VisualLibraryScene.bs`**
- Problem: When clicking a tag in a tag subfolder, `parentFolder` was set to previous tag's name instead of library ID
- Solution: Use `m.top.parentItem.parentFolder` when available, otherwise fall back to `Id`
- Result: Nested tag navigation works correctly

**Fix 9: Default View for Subfolders in `VisualLibraryScene.bs`**
- Problem: Tag subfolders defaulted to "presentation" mode instead of "grid"
- Solution: Changed default from `presentation` to `grid` for subfolders
- Result: Tag-filtered movies now display in grid view by default

### 2026-04-27 ~14:30-14:40 UTC-04:00 - Auto-Reentry and Home Screen Fixes
**Fix 10: Auto-Reentry Bug**
- Problem: MainEventHandlers reentry guard was too broad, blocking legitimate selections
- Solution: Removed MainEventHandlers reentry guard, relying on VisualLibraryScene guard instead
- Result: VisualLibraryScene guard prevents reentry without blocking normal navigation

**Fix 11: Home Screen Tile Multiple Presses**
- Problem: Home screen movie listing tile required multiple enter presses to enter
- Solution: Removed MainEventHandlers reentry guard that was blocking selections
- Result: Home screen navigation works normally with single press

**Version Update**
- Updated manifest build_version from 0 to 1
- Updated package.json version from 1.2.0 to 1.2.1

**Files Modified:**
- `components/ItemGrid/LoadItemsTask2.bs` - Type check fix, speed optimization
- `components/Libraries/VisualLibraryScene.bs` - Navigation fix, tag type detection, itemId fix, parentFolder fix, default view to grid
- `components/data/FolderData.bs` - Crash fix with isValid checks
- `source/MainEventHandlers.bs` - Tag type handling, parentFolder fix, removed reentry guard
- `manifest` - build_version 0 → 1
- `package.json` - version 1.2.0 → 1.2.1
