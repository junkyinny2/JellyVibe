sub init()
    m.bg = m.top.findNode("bg")
    m.check = m.top.findNode("check")
    m.title = m.top.findNode("title")
    m.subtitle = m.top.findNode("subtitle")
    m.top.observeField("itemContent", "itemContentChanged")
    m.top.observeField("focusPercent", "onFocusPercentChanged")
    m.top.observeField("width", "onWidthHeightChanged")
    m.top.observeField("height", "onWidthHeightChanged")
end sub

function isValid(obj) as boolean
    return obj <> invalid
end function

sub itemContentChanged()
    itemData = m.top.itemContent
    if not isValid(itemData) then
        return
    end if
    m.title.text = itemData.title
    if isValid(itemData.description) and itemData.description <> ""
        m.subtitle.text = itemData.description
        m.subtitle.visible = true
        m.title.translation = [
            30
            8
        ]
    else
        m.subtitle.visible = false
        m.title.translation = [
            30
            20
        ]
    end if
    updateCheckState()
    updateColors()
end sub

sub updateCheckState()
    itemData = m.top.itemContent
    if not isValid(itemData) then
        return
    end if
    m.check.visible = (itemData.selected = true)
end sub

sub onFocusPercentChanged()
    updateColors()
end sub

sub updateColors()
    itemData = m.top.itemContent
    if not isValid(itemData) then
        return
    end if
    isSelected = (itemData.selected = true)
    isFocused = (m.top.focusPercent > 0.5)
    if isFocused
        m.bg.color = "#4520a0"
        m.title.color = "#ffffff"
        m.subtitle.color = "#ffffff"
        m.check.blendColor = "#ffffff"
    else if isSelected
        m.bg.color = "#12082a"
        m.title.color = "#d0c0f0"
        m.subtitle.color = "#a080d0"
        m.check.blendColor = "#ffffff"
    else
        m.bg.color = "#0a0518"
        m.title.color = "#e8e8ee"
        m.subtitle.color = "#a080d0"
        m.check.blendColor = "#ffffff"
    end if
end sub

sub onWidthHeightChanged()
    m.bg.width = m.top.width
    m.bg.height = m.top.height
    itemW = m.top.width - 40
    if itemW < 50 then
        itemW = 50
    end if
    m.title.width = itemW
    m.subtitle.width = itemW
end sub
'//# sourceMappingURL=./StreamDropdownItem.brs.map