'import "pkg:/source/enums/ColorPalette.bs"
'import "pkg:/source/enums/ItemType.bs"
'import "pkg:/source/enums/PosterLoadStatus.bs"
'import "pkg:/source/enums/String.bs"
'import "pkg:/source/utils/config.bs"
'import "pkg:/source/utils/controlStyle.bs"
'import "pkg:/source/utils/misc.bs"

sub init()
    m.itemPoster = m.top.findNode("itemPoster")
    m.itemIcon = m.top.findNode("itemIcon")
    m.posterText = m.top.findNode("posterText")
    m.posterText.font.size = 30
    m.backdrop = m.top.findNode("backdrop")
    m.playedIndicator = m.top.findNode("playedIndicator")
    m.title = m.top.findNode("title")
    m.title.font.size = 26
    m.itemTextExtra = m.top.findNode("itemTextExtra")
    m.itemTextExtra.font.size = 23
    m.posterGroup = m.top.findNode("posterGroup")
    m.itemShadow = m.top.findNode("itemShadow")
    m.focusOutline = m.top.findNode("focusOutline")
    m.focusAnimation = m.top.findNode("focusAnimation")
    m.translationInterpolator = m.top.findNode("translationInterpolator")
    m.shadowTranslationInterpolator = m.top.findNode("shadowTranslationInterpolator")
    m.itemPoster.observeField("loadStatus", "onPosterLoadStatusChanged")
    m.itemIconBackground = m.top.findNode("itemIconBackground")
    m.itemIconBackground.color = chainLookupReturn(m.global.session, "user.settings.colorBackground", "#020B2A")
    'Parent is MarkupGrid and it's parent is the ItemGrid
    m.topParent = m.top.GetParent().GetParent()
    if not isValid(m.topParent.showItemTitles)
        ' Search items need to only look 1 level above
        if m.topParent.GetParent().isSubType("SearchRow")
            m.topParent = m.topParent.GetParent()
        else
            m.topParent = m.topParent.GetParent().GetParent()
        end if
    end if
    'Get the imageDisplayMode for these grid items
    if m.topParent.imageDisplayMode <> invalid
        m.itemPoster.loadDisplayMode = m.topParent.imageDisplayMode
    end if
    if isValid(m.focusOutline)
        m.focusOutline.blendColor = getControlAccentColor("#7B2FBE")
    end if
end sub

sub onHeightChanged()
    calculatedHeight = m.top.height - 12
    showItemTitles = chainLookupReturn(m.topParent, "showItemTitles", "showonhover")
    if not isStringEqual(showItemTitles, "hidealways")
        calculatedHeight -= 60
    end if
    ' If we have a second line of text, further reduce the image height to make room
    if not isStringEqual(m.itemTextExtra.text, "")
        calculatedHeight -= 12
    end if
    m.itemPoster.width = m.top.width - 12
    m.itemPoster.height = calculatedHeight
    m.backdrop.width = m.top.width - 12
    m.backdrop.height = calculatedHeight
    m.posterText.height = calculatedHeight
    if isValid(m.focusOutline)
        m.focusOutline.height = calculatedHeight + 12
        m.focusOutline.width = m.top.width
        m.focusOutline.translation = [
            -6
            -6
        ]
    end if
    m.title.translation = [
        0
        calculatedHeight + 35
    ]
    m.itemTextExtra.translation = [
        0
        calculatedHeight + 65
    ]
    m.itemIconBackground.translation = [
        m.itemIconBackground.translation[0]
        calculatedHeight - 65
    ]
    updateAnimationOffsets()
end sub

sub onWidthChanged()
    m.backdrop.width = m.top.width - 12
    m.itemPoster.width = m.top.width - 12
    m.posterText.width = m.top.width - 12
    m.title.maxWidth = m.top.width - 12
    m.itemTextExtra.maxWidth = m.top.width - 12
    if isValid(m.focusOutline) then
        m.focusOutline.width = m.top.width
    end if
    m.playedIndicator.translation = [
        (m.top.width - 12) - m.playedIndicator.width
        0
    ]
    m.itemIconBackground.translation = [
        (m.top.width - 12) - m.itemIconBackground.width
        m.itemIconBackground.translation[1]
    ]
    if isValid(m.focusOutline) then
        m.focusOutline.translation = [
            -6
            -6
        ]
    end if
    updateAnimationOffsets()
end sub

sub itemContentChanged()
    m.backdrop.blendColor = "#020B2A"
    m.title.visible = false
    m.itemTextExtra.visible = false
    if isValid(m.topParent.showItemTitles)
        if LCase(m.topParent.showItemTitles) = "showalways"
            m.title.visible = true
            m.itemTextExtra.visible = true
        end if
    end if
    itemData = m.top.itemContent
    if not isValid(itemData) then
        return
    end if
    m.playedIndicator.data = {
        played: chainLookupReturn(itemData, "json.UserData.Played", false)
        unplayedCount: chainLookupReturn(itemData, "json.UserData.UnplayedItemCount", 0)
    }
    ' Set Series and Episode Number for Extra Text
    extraPrefix = ""
    if isValid(itemData.json.ParentIndexNumber)
        extraPrefix = "S" + StrI(itemData.json.ParentIndexNumber).trim()
    end if
    if isValid(itemData.json.IndexNumber)
        extraPrefix = extraPrefix + "E" + StrI(itemData.json.IndexNumber).trim()
    end if
    if extraPrefix.len() > 0
        extraPrefix = extraPrefix + " - "
    end if
    m.itemTextExtra.text = extraPrefix + itemData.title
    if isValidAndNotEmpty(itemData.json.Type)
        if isStringEqual(itemData.json.Type, "studio")
            m.itemTextExtra.text = (bslib_toString(itemData.json.SeriesCount) + " " + bslib_toString(tr("Series")))
        end if
        if inArray([
            "movie"
            "series"
            "musicalbum"
            "audio"
            "playlist"
            "program"
            "musicvideo"
        ], itemData.json.Type)
            m.itemTextExtra.text = itemData.SubTitle
        end if
    end if
    m.itemIcon.uri = ""
    if isValidAndNotEmpty(itemData.LookupCI("type"))
        if isStringEqual(itemData.LookupCI("type"), "photo")
            m.itemIcon.uri = "pkg:/images/media_type_icons/photo.png"
        end if
        if isStringEqual(itemData.LookupCI("type"), "folder")
            m.itemIcon.uri = "pkg:/images/media_type_icons/photoFolder.png"
        end if
        if isStringEqual(itemData.LookupCI("type"), "video")
            m.itemIcon.uri = "pkg:/images/media_type_icons/movie.png"
        end if
    end if
    m.itemIconBackground.visible = m.itemIcon.uri <> ""
    if isChainValid(itemData, "imageDimensions")
        imageDimensions = itemData.imageDimensions
        m.itemPoster.width = imageDimensions[0]
        m.backdrop.width = imageDimensions[0]
        m.posterText.width = imageDimensions[0]
        m.title.maxWidth = imageDimensions[0] - 16
        m.itemTextExtra.maxWidth = imageDimensions[0] - 16
        m.itemPoster.height = imageDimensions[1]
        m.backdrop.height = imageDimensions[1]
        m.posterText.height = imageDimensions[1] + 40
        m.playedIndicator.translation = [
            imageDimensions[0] - 60
            m.playedIndicator.translation[1]
        ]
        m.title.translation = [
            m.title.translation[0]
            imageDimensions[1] + 30
        ]
        m.itemTextExtra.translation = [
            m.itemTextExtra.translation[0]
            imageDimensions[1] + 65
        ]
    end if
    m.itemPoster.uri = itemData.PosterUrl
    m.posterText.text = itemData.title
    if isValidAndNotEmpty(itemData.json.SeriesName) then
        m.title.text = itemData.json.SeriesName
    else
        m.title.text = itemData.title
    end if
    ' Don't show the same text for both the title and subtitle
    if isStringEqual(m.itemTextExtra.text, m.title.text)
        m.itemTextExtra.text = ""
    end if
    'If Poster not loaded, ensure backdrop is shown until loaded
    if m.itemPoster.loadStatus <> "ready"
        m.backdrop.visible = true
        m.posterText.visible = true
    end if
    if not isStringEqual(m.itemTextExtra.text, "")
        onHeightChanged()
    end if
end sub

sub focusChanged()
    showItemTitles = chainLookupReturn(m.topParent, "showItemTitles", "showonhover")
    if LCase(showItemTitles) = "showonhover"
        m.title.visible = m.top.itemHasFocus
        m.itemTextExtra.visible = m.top.itemHasFocus
    end if
    if m.top.itemHasFocus
        m.title.repeatCount = -1
        m.itemTextExtra.repeatCount = -1
        ' Set outline immediately
    else
        m.title.repeatCount = 0
        m.itemTextExtra.repeatCount = 0
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
    if isValid(m.topParent.showItemTitles)
        if LCase(m.topParent.showItemTitles) = "showonhover"
            m.title.visible = m.top.itemHasFocus
            m.itemTextExtra.visible = m.top.itemHasFocus
        end if
    end if
end sub

' focusPercent 0.0 to 1.0 — shadow + ring (no poster scale: MarkupGrid clips each cell, zoom was cutting edges)
sub onFocusPercentChange()
    applyFocusVisual(m.top.focusPercent)
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
        m.title.visible = true
    else
        m.title.visible = false
    end if
end sub

sub updateAnimationOffsets()
    contentWidth = m.top.width
    contentHeight = m.itemPoster.height
    m.itemShadow.width = contentWidth
    m.itemShadow.height = contentHeight
    m.itemShadow.translation = [
        0
        0
    ]
    m.itemShadow.scale = [
        1.0
        1.0
    ]
    m.posterGroup.scale = [
        1.0
        1.0
    ]
    m.posterGroup.translation = [
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
'//# sourceMappingURL=./GridItemMedium.brs.map