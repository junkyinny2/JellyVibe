'import "pkg:/source/enums/String.bs"
'import "pkg:/source/utils/misc.bs"

sub init()
    m.highlightedColor = m.top.findNode("highlightedColor")
    m.highlightedColor.font.size = 20
    m.selectedColor = m.top.findNode("selectedColor")
    m.selectedColor.font.size = 20
    m.top.observeField("itemFocused", "onItemFocused")
    m.top.observeField("itemSelected", "onItemSelected")
end sub

sub onItemFocused()
    if not isValid(m.top.itemFocused)
        setHighlightedColor("")
        return
    end if
    focusedColor = m.top.content.getChild(m.top.itemFocused)
    if not isChainValid(focusedColor, "colorCode")
        setHighlightedColor("")
        return
    end if
    setHighlightedColor(focusedColor.colorCode)
end sub

sub setHighlightedColor(colorCode as string)
    m.highlightedColor.text = (bslib_toString(tr("Highlighted Color")) + ": " + bslib_toString(colorCode))
end sub

sub onSettingChange()
    m.top.selectedColor = chainLookupReturn(m.global.session, ("user.settings." + bslib_toString(m.top.setting.settingName)), m.top.setting.default)
end sub

sub onSelectedColorChange()
    selectedColor = m.top.selectedColor
    if not m.top.isInFocusChain()
        setHighlightedColor("")
    end if
    m.selectedColor.text = (bslib_toString(tr("Selected Color")) + ": " + bslib_toString(selectedColor))
    for each color in m.top.content.getChildren(-1, 0)
        if color.isChecked then
            color.isChecked = false
        end if
        if isStringEqual(chainLookup(color, "colorCode"), selectedColor)
            color.isChecked = true
        end if
    end for
end sub
'//# sourceMappingURL=./ColorGrid.brs.map