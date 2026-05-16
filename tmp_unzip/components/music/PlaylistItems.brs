'import "pkg:/source/enums/KeyCode.bs"
'import "pkg:/source/utils/misc.bs"

sub init()
    m.top.setfocus(true)
    group = m.global.sceneManager.callFunc("getActiveScene")
    group.lastFocus = m.top
end sub

sub getData()
    m.top.content = m.top.PlaylistData
    m.top.doneLoading = true
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then
        return false
    end if
    if isStringEqual(key, "play")
        m.top.itemSelected = m.top.itemFocused
        return true
    end if
    return false
end function
'//# sourceMappingURL=./PlaylistItems.brs.map