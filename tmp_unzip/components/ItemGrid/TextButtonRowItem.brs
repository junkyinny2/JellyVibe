'import "pkg:/source/enums/ColorPalette.bs"
'import "pkg:/source/utils/misc.bs"

sub init()
    m.label = m.top.findNode("label")
    m.underline = m.top.findNode("underline")
    m.icon = m.top.findNode("icon")
    m.focusBackground = m.top.findNode("focusBackground")
    m.backArrow = m.top.findNode("backArrow")
    m.isSelected = false
    applyTabState()
end sub

sub onFocusPercentChange()
    applyTabState()
end sub

sub onFocusChanged()
    applyTabState()
end sub

sub onContentChange()
    if isValid(m.top.itemContent)
        title = m.top.itemContent.title
        m.label.text = title
        m.isSelected = chainLookupReturn(m.top.itemContent, "selected", false) = true
        id = m.top.itemContent.id
        if id = "Search"
            m.icon.uri = "pkg:/images/icons/search-light.png"
            m.icon.visible = true
            m.label.visible = false
            m.underline.visible = false
            m.backArrow.visible = false
        else if id = "Settings"
            m.icon.uri = "pkg:/images/icons/settings.png"
            m.icon.visible = true
            m.label.visible = false
            m.underline.visible = false
            m.backArrow.visible = false
        else if id = "Back"
            m.backArrow.visible = true
            m.label.visible = false
            m.icon.visible = false
            m.underline.visible = false
        else
            m.icon.visible = false
            m.label.visible = true
            m.backArrow.visible = false
            m.underline.visible = (id <> "Movies")
        end if
    end if
    applyTabState()
end sub

sub onIsRowFocusedChanged()
    applyTabState()
end sub

sub applyTabState()
    focused = m.top.focusPercent > 0.5 and m.top.isRowFocused
    if focused
        m.label.color = "#ffffff"
        if isValid(m.focusBackground)
            m.focusBackground.blendColor = "#7B2FBE"
            m.focusBackground.opacity = 1
        end if
    else if m.isSelected
        m.label.color = "#ffffff"
        if isValid(m.focusBackground)
            m.focusBackground.opacity = 0
        end if
    else
        m.label.color = "#ffffff"
        if isValid(m.focusBackground)
            m.focusBackground.opacity = 0
        end if
    end if
    if isValid(m.underline)
        if m.isSelected and not focused
            m.underline.opacity = 0.5
        else
            m.underline.opacity = 0
        end if
        m.underline.color = "#FFFFFF"
    end if
    if m.icon.visible
        if (focused) then
            m.icon.blendColor = "#000000"
        else
            m.icon.blendColor = "#FFFFFF"
        end if
    end if
    if m.backArrow.visible
        if (focused) then
            m.backArrow.blendColor = "#000000"
        else
            m.backArrow.blendColor = "#FFFFFF"
        end if
    end if
end sub
'//# sourceMappingURL=./TextButtonRowItem.brs.map