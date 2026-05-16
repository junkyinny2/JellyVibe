'import "pkg:/source/utils/misc.bs"
' ══════════════════════════════════════════════
' FilterManager  –  stateless helper module
' ══════════════════════════════════════════════

' ------------------------------------------------------------------
' buildFilterParams
' ------------------------------------------------------------------
function buildFilterParams(selectedGenres as object, selectedTags as object) as object
    params = {}
    if isValid(selectedGenres) and selectedGenres.count() > 0
        params.Genres = joinArray(selectedGenres, ",")
    end if
    if isValid(selectedTags) and selectedTags.count() > 0
        params.Tags = joinArray(selectedTags, ",")
    end if
    return params
end function

' ------------------------------------------------------------------
' mergeFilterState
' ------------------------------------------------------------------
function mergeFilterState(existingParams as object, filterPanelParams as object) as object
    merged = {}
    ' Copy all existing keys
    if isValid(existingParams)
        for each key in existingParams
            merged[key] = existingParams[key]
        end for
    end if
    ' Remove stale filter keys before merging
    if merged.doesExist("Genres") then
        merged.delete("Genres")
    end if
    if merged.doesExist("Tags") then
        merged.delete("Tags")
    end if
    ' Apply new filter selections
    if isValid(filterPanelParams)
        for each k in filterPanelParams
            merged[k] = filterPanelParams[k]
        end for
    end if
    return merged
end function

' ------------------------------------------------------------------
' joinArray
' ------------------------------------------------------------------
function joinArray(arr as object, delimiter as string) as string
    result = ""
    if not isValid(arr) then
        return result
    end if
    count = arr.count()
    for i = 0 to count - 1
        if i > 0
            result = result + delimiter
        end if
        result = result + arr[i]
    end for
    return result
end function

' ------------------------------------------------------------------
' hasActiveFilters
' ------------------------------------------------------------------
function hasActiveFilters(selectedGenres as object, selectedTags as object) as boolean
    if isValid(selectedGenres) and selectedGenres.count() > 0
        return true
    end if
    if isValid(selectedTags) and selectedTags.count() > 0
        return true
    end if
    return false
end function
'//# sourceMappingURL=./FilterManager.brs.map