'import "pkg:/source/enums/ColorPalette.bs"
'import "pkg:/source/utils/config.bs"
'import "pkg:/source/utils/controlStyle.bs"
'import "pkg:/source/utils/misc.bs"

sub init()
    m.itemPoster = m.top.findNode("itemPoster")
    m.postTextBackground = m.top.findNode("postTextBackground")
    m.posterText = m.top.findNode("posterText")
    m.posterText.font.size = 30
    m.backdrop = m.top.findNode("backdrop")
    m.focusOutline = m.top.findNode("focusOutline")
    m.itemShadow = m.top.findNode("itemShadow")
    m.posterGroup = m.top.findNode("posterGroup")
    m.focusAnimation = m.top.findNode("focusAnimation")
    if isValid(m.focusOutline)
        m.focusOutline.blendColor = getControlAccentColor("#7B2FBE")
    end if
    m.itemPoster.observeField("loadStatus", "onPosterLoadStatusChanged")
    'Parent is MarkupGrid and it's parent is the ItemGrid
    m.topParent = m.top.GetParent().GetParent()
    'Get the imageDisplayMode for these grid items
    if m.topParent.imageDisplayMode <> invalid
        m.itemPoster.loadDisplayMode = m.topParent.imageDisplayMode
    end if
    m.gridTitles = m.global.session.user.settings["itemgrid.gridTitles"]
    m.posterText.visible = false
    m.postTextBackground.visible = false
end sub

sub onHeightChanged()
    m.backdrop.height = m.top.height - 12
    m.itemPoster.height = m.top.height - 12
    m.postTextBackground.translation = [
        5
        (m.top.height - 12) - 40
    ]
    if isValid(m.focusOutline)
        m.focusOutline.height = m.top.height
        m.focusOutline.width = m.top.width
        m.focusOutline.translation = [
            -6
            -6
        ]
    end if
    updateAnimationOffsets()
end sub

sub onWidthChanged()
    m.backdrop.width = m.top.width - 12
    m.itemPoster.width = m.top.width - 12
    m.posterText.maxwidth = m.top.width - 12
    m.postTextBackground.width = (m.top.width - 12) - 10
    if isValid(m.focusOutline)
        m.focusOutline.width = m.top.width
        m.focusOutline.translation = [
            -6
            -6
        ]
    end if
    updateAnimationOffsets()
end sub

sub itemContentChanged()
    m.posterText.visible = false
    m.postTextBackground.visible = false
    if isValid(m.topParent.showItemTitles)
        if LCase(m.topParent.showItemTitles) = "showalways"
            m.posterText.visible = true
            m.postTextBackground.visible = true
        end if
    end if
    itemData = m.top.itemContent
    if not isValid(itemData) then
        return
    end if
    if LCase(itemData.type) = "musicalbum"
        m.backdrop.uri = "pkg:/images/icons/album.png"
    else if LCase(itemData.type) = "musicartist"
        m.backdrop.uri = "pkg:/images/missingArtist.png"
    else if LCase(itemData.json.type) = "musicgenre"
        m.backdrop.uri = "pkg:/images/icons/musicFolder.png"
    end if
    m.itemPoster.uri = itemData.PosterUrl
    m.posterText.text = itemData.title
    'If Poster not loaded, ensure "blue box" is shown until loaded
    if m.itemPoster.loadStatus <> "ready"
        m.backdrop.visible = true
    end if
    if m.top.itemHasFocus then
        focusChanged()
    end if
end sub

'Display or hide title Visibility on focus change
sub focusChanged()
    if m.top.itemHasFocus = true
        m.posterText.repeatCount = -1
    else
        m.posterText.repeatCount = 0
        if isValid(m.focusOutline) then
            m.focusOutline.opacity = 0
        end if
        m.itemShadow.opacity = 0
    end if
    if isValid(m.topParent.showItemTitles)
        if LCase(m.topParent.showItemTitles) = "showonhover"
            m.posterText.visible = m.top.itemHasFocus
            m.postTextBackground.visible = m.posterText.visible
        end if
    end if
end sub

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
        m.focusOutline.width = m.itemPoster.width + 12
        m.focusOutline.height = m.itemPoster.height + 12
        m.focusOutline.translation = [
            -6
            -6
        ]
    end if
    if isValid(m.itemShadow) then
        m.itemShadow.opacity = 0.6 * clampedPercent
    end if
end sub

sub updateAnimationOffsets()
    contentWidth = m.top.width - 12
    contentHeight = m.itemPoster.height
    if isValid(m.itemShadow)
        m.itemShadow.width = contentWidth
        m.itemShadow.height = contentHeight
    end if
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
    end if
end sub
'//# sourceMappingURL=./MusicArtistGridItem.brs.map