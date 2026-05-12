# JellyVibe UI Architecture: Safe Zone Padding System

> [!IMPORTANT]
> For a list of other recurring bugs and navigation issues, see [DEVELOPMENT_GOTCHAS.md](file:///d:/VibeCode/JellyVibe/DEVELOPMENT_GOTCHAS.md).

This document describes the standardized UI architecture used to achieve high-quality, non-clipped focus highlights across all grid views in JellyVibe.

## The Problem
Roku's `MarkupGrid` and `RowList` components clip their child cells exactly to their `itemSize` or `rowItemSize`. If a focus highlight border is drawn outside the poster area (to give it that "premium" floating look), it will be cut off at the edge of the cell.

## The Solution: The "Safe Zone" Padding System
To prevent clipping, we use a internal padding system within every grid item component.

### 1. Internal Translation Group
Every grid item component MUST wrap its visual children in a `Group` node with a `6px` translation:
```xml
<children>
  <Group translation="[6, 6]">
    <!-- Poster and Focus Outline go here -->
  </Group>
</children>
```
This creates a **6px Safe Zone** on all four sides of the cell boundaries.

### 2. Sizing Logic (The +12 Rule)
Because the internal content is translated by `[6, 6]`, the root component's `width` and `height` (the cell size) must be **12px larger** than the visual poster size.

- **Visual Poster Width**: `W`
- **Grid Cell Width (`itemSize`)**: `W + 12`
- **Internal Content Translation**: `[6, 6]`
- **Focus Outline Width**: `W + 12` (starts at `[-6, -6]` relative to the `[6, 6]` group, resulting in world `[0, 0]`)

### 3. Focus Highlight Implementation
The focus outline is placed at `[-6, -6]` relative to the poster's local `[0, 0]`. Since the poster's parent group is translated by `[6, 6]`, the focus outline renders exactly at world `[0, 0]` of the cell, filling the entire safe zone without crossing the clipping boundary.

## Maintenance Rules (DO NOT CHANGE)
1. **DO NOT** remove the `translation="[6, 6]"` from the root Group in `GridItem.xml`, `HomeItem.xml`, etc.
2. **DO NOT** subtract the 12px padding in the `rowItemSize` or `itemSize` configurations in `HomeRows.bs`, `VisualLibraryScene.bs`, etc.
3. **DO NOT** use `m.top.width` for child elements (Posters, Backdrops) without subtracting 12 first.
4. **ALWAYS** use `m.top.width` (or `itemPoster.width + 12`) for the `focusOutline` size.

## Files Implementing this Pattern
- `components/ItemGrid/GridItem.xml` / `.bs`
- `components/ItemGrid/GridItemSmall.xml` / `.bs`
- `components/ItemGrid/GridItemMedium.xml` / `.bs`
- `components/ItemGrid/MusicArtistGridItem.xml` / `.bs`
- `components/ItemGrid/AudioBookGridItem.xml` / `.bs`
- `components/home/HomeItem.xml` / `.bs`
- `components/home/HomeRows.bs` (Grid sizing logic)
- `components/Libraries/VisualLibraryScene.bs` (Grid sizing logic)
