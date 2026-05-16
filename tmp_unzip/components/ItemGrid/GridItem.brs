'import "pkg:/source/utils/config.bs"
'import "pkg:/source/utils/controlStyle.bs"
'import "pkg:/source/utils/misc.bs"

sub init()
    m.itemPoster = m.top.findNode("itemPoster")
    m.itemIcon = m.top.findNode("itemIcon")
    m.posterText = m.top.findNode("posterText")
    m.itemText = m.top.findNode("itemText")
    m.backdrop = m.top.findNode("backdrop")
    m.itemPoster.observeField("loadStatus", "onPosterLoadStatusChanged")
    m.unplayedCount = m.top.findNode("unplayedCount")
    m.unplayedEpisodeCount = m.top.findNode("unplayedEpisodeCount")
    m.playedIndicator = m.top.findNode("playedIndicator")
    m.posterGroup = m.top.findNode("posterGroup")
    m.itemShadow = m.top.findNode("itemShadow")
    m.focusOutline = m.top.findNode("focusOutline")
    m.focusAnimation = m.top.findNode("focusAnimation")
    m.translationInterpolator = m.top.findNode("translationInterpolator")
    m.shadowTranslationInterpolator = m.top.findNode("shadowTranslationInterpolator")
    m.itemText.translation = [
        0
        m.itemPoster.height + 7
    ]
    m.itemText.visible = m.gridTitles = "showalways"
    ' Add some padding space when Item Titles are always showing
    if m.itemText.visible then
        m.itemText.maxWidth = 250
    end if
    ' grab data from ItemGrid node
    m.itemGrid = m.top.GetParent().GetParent() 'Parent is MarkupGrid and it's parent is the ItemGrid
    if isValid(m.itemGrid)
        if isValid(m.itemGrid.imageDisplayMode)
            m.itemPoster.loadDisplayMode = m.itemGrid.imageDisplayMode
        end if
        if isValid(m.itemGrid.gridTitles)
            m.gridTitles = m.itemGrid.gridTitles
        end if
    end if
    if isValid(m.focusOutline)
        m.focusOutline.blendColor = getControlAccentColor("#7B2FBE")
    end if
end sub

sub itemContentChanged()
    m.backdrop.blendColor = "#00a4db" ' set default in case global var is invalid
    localGlobal = m.global
    if isValid(localGlobal) and isValid(localGlobal.constants) and isValid(localGlobal.constants.poster_bg_pallet)
        posterBackgrounds = localGlobal.constants.poster_bg_pallet
        m.backdrop.blendColor = posterBackgrounds[rnd(posterBackgrounds.count()) - 1]
    end if
    itemData = m.top.itemContent
    if itemData = invalid then
        return
    end if
    if itemData.type = "Movie"
        if isValid(itemData.json) and isValid(itemData.json.UserData) and isValid(itemData.json.UserData.Played) and itemData.json.UserData.Played
            m.playedIndicator.visible = true
        end if
        m.itemPoster.uri = itemData.PosterUrl
        m.itemIcon.uri = itemData.iconUrl
        m.itemText.text = itemData.Title
    else if itemData.type = "Series"
        if isValid(localGlobal) and isValid(localGlobal.session) and isValid(localGlobal.session.user) and isValid(localGlobal.session.user.settings)
            if localGlobal.session.user.settings["ui.tvshows.disableUnwatchedEpisodeCount"] = false
                if isValid(itemData.json) and isValid(itemData.json.UserData) and isValid(itemData.json.UserData.UnplayedItemCount)
                    if itemData.json.UserData.UnplayedItemCount > 0
                        m.unplayedCount.visible = true
                        m.unplayedEpisodeCount.text = itemData.json.UserData.UnplayedItemCount
                    else
                        m.unplayedCount.visible = false
                        m.unplayedEpisodeCount.text = ""
                    end if
                end if
            end if
        end if
        if isValid(itemData.json) and isValid(itemData.json.UserData) and isValid(itemData.json.UserData.Played) and itemData.json.UserData.Played = true
            m.playedIndicator.visible = true
        end if
        m.itemPoster.uri = itemData.PosterUrl
        m.itemIcon.uri = itemData.iconUrl
        m.itemText.text = itemData.Title
    else if itemData.type = "Boxset"
        m.itemPoster.uri = itemData.PosterUrl
        m.itemIcon.uri = itemData.iconUrl
        m.itemText.text = itemData.Title
    else if itemData.type = "TvChannel"
        m.itemPoster.uri = itemData.PosterUrl
        m.itemIcon.uri = itemData.iconUrl
        m.itemText.text = itemData.Title
    else if itemData.type = "Folder"
        m.itemPoster.uri = itemData.PosterUrl
        'm.itemIcon.uri = itemData.iconUrl
        m.itemText.text = itemData.Title
        m.itemPoster.loadDisplayMode = m.itemGrid.imageDisplayMode
    else if itemData.type = "Video"
        m.itemPoster.uri = itemData.PosterUrl
        m.itemIcon.uri = itemData.iconUrl
        m.itemText.text = itemData.Title
    else if itemData.type = "Playlist"
        m.itemPoster.uri = itemData.PosterUrl
        m.itemIcon.uri = itemData.iconUrl
        m.itemText.text = itemData.Title
    else if itemData.type = "Photo"
        m.itemPoster.uri = itemData.PosterUrl
        m.itemIcon.uri = itemData.iconUrl
        m.itemText.text = itemData.Title
    else if itemData.type = "Episode"
        m.itemPoster.uri = itemData.PosterUrl
        m.itemIcon.uri = itemData.iconUrl
        if isValid(itemData.json) and isValid(itemData.json.SeriesName)
            m.itemText.text = itemData.json.SeriesName + " - " + itemData.Title
        else
            m.itemText.text = itemData.Title
        end if
        if not isValid(m.topParent)
            m.topParent = m.top.GetParent().GetParent()
        end if
        ' Adjust to wide posters for "View All Next Up"
        if m.topParent.overhangTitle = tr("View All Next Up")
            m.itemPoster.height = 300
            m.itemPoster.width = 400
            m.itemPoster.loadDisplayMode = "scaleToFit"
            m.backdrop.height = 300
            m.backdrop.width = 400
            m.backdrop.loadDisplayMode = "scaleToFit"
            m.itemText.translation = [
                0
                m.itemPoster.height + 7
            ]
            m.itemText.maxWidth = 400
        end if
    else if itemData.type = "MusicArtist"
        m.itemPoster.uri = itemData.PosterUrl
        m.itemText.text = itemData.Title
        m.itemPoster.height = 290
        m.itemPoster.width = 290
        m.itemText.translation = [
            0
            m.itemPoster.height + 7
        ]
        m.backdrop.height = 290
        m.backdrop.width = 290
        m.posterText.height = 200
        m.posterText.width = 280
    else if isValid(itemData.json.type) and itemData.json.type = "MusicAlbum"
        m.itemPoster.uri = itemData.PosterUrl
        m.itemText.text = itemData.Title
        m.itemPoster.height = 290
        m.itemPoster.width = 290
        m.itemText.translation = [
            0
            m.itemPoster.height + 7
        ]
        m.backdrop.height = 290
        m.backdrop.width = 290
        m.posterText.height = 200
        m.posterText.width = 280
    else
        print ("Unhandled Grid Item Type " + bslib_toString(itemData.type))
    end if
    'If Poster not loaded, ensure "blue box" is shown until loaded
    if m.itemPoster.loadStatus <> "ready"
        m.backdrop.visible = true
        m.posterText.visible = true
    end if
    m.posterText.text = m.itemText.text
end sub

'
'Display or hide title Visibility on focus change
sub focusChanged()
    if m.gridTitles = "showonhover"
        m.itemText.visible = m.top.itemHasFocus
    end if
    if m.top.itemHasFocus
        m.itemText.repeatCount = -1
        ' Set outline immediately
    else
        m.itemText.repeatCount = 0
        m.focusOutline.opacity = 0.0
        m.posterGroup.scale = [
            1
            1
        ]
        m.posterGroup.translation = [
            0
            0
        ]
        m.itemShadow.scale = [
            1
            1
        ]
        m.itemShadow.opacity = 0
        m.itemShadow.translation = [
            0
            23
        ]
    end if
    if m.gridTitles = "showonhover"
        m.itemText.visible = m.top.itemHasFocus
    end if
end sub

' focusPercent 0.0 to 1.0 — shadow + ring (no poster scale: MarkupGrid clips each cell, zoom was cutting edges)
sub onFocusPercentChange()
    applyFocusVisual(m.top.focusPercent)
end sub

sub onWidthChanged()
    if isValid(m.focusOutline) and m.top.focusPercent > 0
        m.focusOutline.width = m.top.width
    end if
end sub

sub onHeightChanged()
    if isValid(m.focusOutline) and m.top.focusPercent > 0
        m.focusOutline.height = m.itemPoster.height + 12
    end if
end sub

sub applyFocusVisual(percent as float)
    clampedPercent = percent
    if clampedPercent < 0 then
        clampedPercent = 0
    end if
    if clampedPercent > 1 then
        clampedPercent = 1
    end if
    if isValid(m.focusOutline)
        m.focusOutline.opacity = clampedPercent
        ' Tighten focus ring to only surround the poster, not the title text
        m.focusOutline.width = m.itemPoster.width + 12
        m.focusOutline.height = m.itemPoster.height + 12
        m.focusOutline.translation = [
            -6
            -6
        ]
    end if
    m.itemShadow.opacity = 0.6 * clampedPercent
    if m.top.itemHasFocus
        m.itemText.visible = true
    else
        if m.gridTitles = "showalways"
            m.itemText.visible = true
        else
            m.itemText.visible = false
        end if
    end if
end sub

sub updateAnimationOffsets()
    contentWidth = m.top.width - 12
    contentHeight = m.itemPoster.height
    m.itemShadow.width = contentWidth
    m.itemShadow.height = contentHeight
    m.itemShadow.translation = [
        0
        0
    ]
    ' Focus outline exactly covers the poster area - 9-patch draws border inward
    if isValid(m.focusOutline)
        m.focusOutline.width = contentWidth + 12
        m.focusOutline.height = contentHeight + 12
        m.focusOutline.translation = [
            -6
            -6
        ]
    end if
    applyFocusVisual(m.top.focusPercent)
end sub

'Hide backdrop and text when poster loaded
sub onPosterLoadStatusChanged()
    if m.itemPoster.loadStatus = "ready"
        m.backdrop.visible = false
        m.posterText.visible = false
    end if
end sub
'//# sourceMappingURL=./GridItem.brs.map