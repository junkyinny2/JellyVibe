'import "pkg:/source/enums/AnimationControl.bs"
'import "pkg:/source/enums/AnimationState.bs"
'import "pkg:/source/enums/ColorPalette.bs"
'import "pkg:/source/enums/KeyCode.bs"
'import "pkg:/source/utils/controlStyle.bs"
'import "pkg:/source/utils/misc.bs"

sub init()
    m.display = true
    m.top.setFocus(false)
    m.alphaText = m.top.findNode("alphaText")
    m.alphaMenu = m.top.findNode("alphaMenu")
    m.toggleDisplayAnimation = m.top.findNode("toggleDisplayAnimation")
    m.displayOpacity = m.top.findNode("displayOpacity")
    m.displayTranslation = m.top.findNode("displayTranslation")
    m.alphaMenu.focusBitmapBlendColor = getControlAccentColor("#7B2FBE")
    m.alphaMenu.focusFootprintBlendColor = "0x00000000"
    m.alphaMenu.setFocus(false)
end sub

function getDisplay() as boolean
    return m.display
end function

sub setDisplay(show = true as boolean)
    m.display = show
    m.displayOpacity.reverse = show
    m.displayTranslation.reverse = show
    if not isStringEqual(m.toggleDisplayAnimation.state, "running")
        m.toggleDisplayAnimation.control = "start"
    end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then
        return false
    end if
    if not m.alphaMenu.isInFocusChain() then
        return false
    end if
    if key = "OK"
        child = m.alphaText.getChild(m.alphaMenu.itemFocused)
        m.top.letterSelected = child.title
        return true
    end if
    if key = "up"
        if m.alphaMenu.itemFocused = 0
            if m.top.wrap
                m.alphaMenu.jumpToItem = m.alphaMenu.numRows - 1
            end if
            return false
        end if
    end if
    if key = "down"
        if m.alphaMenu.itemFocused = m.alphaMenu.numRows - 1
            if m.top.wrap
                m.alphaMenu.jumpToItem = 0
            end if
            return false
        end if
    end if
    return false
end function
'//# sourceMappingURL=./Alpha.brs.map