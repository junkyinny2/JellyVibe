'import "pkg:/source/enums/ColorPalette.bs"
'import "pkg:/source/utils/controlStyle.bs"
'import "pkg:/source/utils/misc.bs"

sub init()
    m.buttonBackground = m.top.findNode("buttonBackground")
    m.buttonBorder = m.top.findNode("buttonBorder")
    m.buttonText = m.top.findNode("buttonText")
    m.top.observeField("background", "onBackgroundChanged")
    m.top.observeField("color", "onColorChanged")
    m.top.observeField("text", "onTextChanged")
    m.top.observeField("height", "onHeightChanged")
    m.top.observeField("width", "onWidthChanged")
    m.top.observeField("focus", "onFocusChanged")
    m.top.observeField("focusedChild", "onFocusChanged")
    m.top.observeField("fontSize", "onFontSizeChanged")
    m.top.observeField("enableBorder", "onBorderSettingChanged")
    applyButtonTheme()
    m.buttonText.text = m.top.text
    onFontSizeChanged()
    syncButtonSize()
    applyVisualState()
end sub

sub applyButtonTheme()
    if isValid(m.buttonBorder)
        m.buttonBorder.visible = isJellyRockControlStyle() and m.top.enableBorder
    end if
end sub

function hasButtonFocus() as boolean
    if m.top.focus = true then
        return true
    end if
    if m.top.hasFocus() then
        return true
    end if
    return m.top.isInFocusChain()
end function

function getResolvedFocusFill() as dynamic
    if isJellyRockControlStyle()
        return getControlFocusBackground(m.top.focusBackground)
    end if
    return m.top.focusBackground
end function

function getResolvedFocusBorder() as dynamic
    if isJellyRockControlStyle()
        return getControlAccentColor(m.top.focusBorder)
    end if
    if m.top.focusBorder <> invalid and m.top.focusBorder <> "" then
        return m.top.focusBorder
    end if
    return m.top.focusBackground
end function

function getResolvedFocusColor() as dynamic
    if isJellyRockControlStyle()
        return "#ffffff"
    end if
    return m.top.focusColor
end function

sub onFontSizeChanged()
    if m.top.fontSize > 0
        m.buttonText.font.size = m.top.fontSize
    end if
end sub

sub onFocusChanged()
    applyVisualState()
end sub

sub applyVisualState()
    if m.buttonBackground = invalid or m.buttonText = invalid then
        return
    end if
    applyButtonTheme()
    focused = hasButtonFocus()
    if focused
        m.buttonBackground.blendColor = getResolvedFocusFill()
        m.buttonText.color = getResolvedFocusColor()
        m.buttonText.font = "font:SmallBoldSystemFont"
        if m.top.fontSize > 0
            m.buttonText.font.size = m.top.fontSize
        end if
    else
        m.buttonBackground.blendColor = m.top.background
        m.buttonText.color = m.top.color
        m.buttonText.font = "font:SmallSystemFont"
        if m.top.fontSize > 0
            m.buttonText.font.size = m.top.fontSize
        end if
    end if
    if isValid(m.buttonBorder)
        if m.buttonBorder.visible and focused
            m.buttonBorder.blendColor = getResolvedFocusBorder()
        else
            m.buttonBorder.blendColor = m.top.background
        end if
    end if
end sub

sub onBackgroundChanged()
    applyVisualState()
end sub

sub onBorderSettingChanged()
    applyButtonTheme()
    applyVisualState()
end sub

sub onColorChanged()
    applyVisualState()
end sub

sub onTextChanged()
    m.buttonText.text = m.top.text
end sub

sub syncButtonSize()
    buttonWidth = m.top.width
    buttonHeight = m.top.height
    if not isValid(buttonWidth) or buttonWidth <= 0
        buttonWidth = m.buttonBackground.width
    end if
    if not isValid(buttonHeight) or buttonHeight <= 0
        buttonHeight = m.buttonBackground.height
    end if
    if buttonWidth > 0
        ' JellyRock port: keep the border poster locked to the same dimensions as the filled background.
        m.buttonBackground.width = buttonWidth
        if isValid(m.buttonBorder) then
            m.buttonBorder.width = buttonWidth
        end if
        m.buttonText.width = buttonWidth
    end if
    if buttonHeight > 0
        m.buttonBackground.height = buttonHeight
        if isValid(m.buttonBorder) then
            m.buttonBorder.height = buttonHeight
        end if
        m.buttonText.height = buttonHeight
    end if
end sub

sub onHeightChanged()
    syncButtonSize()
end sub

sub onWidthChanged()
    syncButtonSize()
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then
        return false
    end if
    if key = "right" and hasButtonFocus()
        m.top.escape = "right"
    end if
    if key = "left" and hasButtonFocus()
        m.top.escape = "left"
    end if
    return false
end function
'//# sourceMappingURL=./StandardButton.brs.map