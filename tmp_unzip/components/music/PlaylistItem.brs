'import "pkg:/source/enums/ColorPalette.bs"
'import "pkg:/source/enums/ItemType.bs"
'import "pkg:/source/enums/String.bs"
'import "pkg:/source/utils/misc.bs"

sub init()
    m.title = m.top.findNode("title")
    m.subtitle = m.top.findNode("subtitle")
    m.subtitle.color = "#aaaaaa"
    m.subtitle.font.size = 27
end sub

sub itemContentChanged()
    itemData = m.top.itemContent
    if not isValidAndNotEmpty(itemData) then
        return
    end if
    m.title.text = itemData.LookupCI("title")
    m.subtitle.text = getSubtitleText(itemData)
    itemIconData = m.global.queueManager.callFunc("getItemTitleAndIcon", itemData)
    if isValidAndNotEmpty(itemIconData)
        mediaTypeIcon = m.top.findNode("mediaTypeIcon")
        mediaTypeIcon.uri = itemIconData[0]
    end if
    if isValid(itemData.LookupCI("RunTimeTicks"))
        tracklength = m.top.findNode("tracklength")
        tracklength.text = ticksToHuman(itemData.LookupCI("RunTimeTicks"))
    end if
    ' Only apply the played checkmark to specific item types
    playlistItemType = chainLookupReturn(itemData, "type", "")
    if inArray([
        "movie"
        "musicvideo"
        "episode"
        "recording"
        "video"
        "program"
    ], playlistItemType)
        playedIndicator = m.top.findNode("playedIndicator")
        playedIndicator.data = {
            played: chainLookupReturn(itemData, "played", false)
        }
    end if
end sub

function getSubtitleText(itemData as object) as string
    playlistItemType = itemData.LookupCI("type")
    if not isValid(playlistItemType) then
        return ""
    end if
    if isStringEqual(playlistItemType, "audio")
        subtitleText = ""
        if isValid(itemData.LookupCI("artists"))
            subtitleText += itemData.LookupCI("artists").join(", ")
            if isValid(itemData.LookupCI("album"))
                subtitleText += " • "
            end if
        end if
        if isValid(itemData.LookupCI("album"))
            subtitleText += itemData.LookupCI("album")
        end if
        return subtitleText
    end if
    if isStringEqual(playlistItemType, "movie")
        subtitleText = ""
        if isValid(itemData.LookupCI("ProductionYear"))
            subtitleText += (bslib_toString(itemData.LookupCI("ProductionYear")))
            if isValid(itemData.LookupCI("ProductionYear"))
                subtitleText += " - "
            end if
        end if
        if isValid(itemData.LookupCI("OfficialRating"))
            subtitleText += (bslib_toString(itemData.LookupCI("OfficialRating")))
        end if
        return subtitleText
    end if
    if isStringEqual(playlistItemType, "episode")
        subtitleText = ""
        if isValid(itemData.LookupCI("seriesname"))
            subtitleText += itemData.LookupCI("seriesname")
        end if
        if isValid(itemData.LookupCI("ParentIndexNumber"))
            if itemData.LookupCI("ParentIndexNumber") <> 0
                subtitleText += (" S" + bslib_toString(itemData.LookupCI("ParentIndexNumber")))
            end if
        end if
        if isValid(itemData.LookupCI("IndexNumber"))
            subtitleText += (":E" + bslib_toString(itemData.LookupCI("IndexNumber")))
            if isValid(itemData.LookupCI("IndexNumberEnd"))
                if itemData.LookupCI("IndexNumberEnd") <> 0
                    subtitleText += ("-" + bslib_toString(itemData.LookupCI("IndexNumberEnd")))
                end if
            end if
        end if
        return subtitleText
    end if
    return ""
end function
'//# sourceMappingURL=./PlaylistItem.brs.map