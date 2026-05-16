'import "pkg:/source/utils/misc.bs"

sub init()
    m.bg = m.top.findNode("bg")
    m.icon = m.top.findNode("icon")
    m.top.observeField("iconUri", "onIconUriChanged")
    m.top.observeField("focusedChild", "onFocusChanged")
    m.top.observeField("focus", "onFocusChanged")
    m.top.observeField("disabled", "onDisabledChanged")
    onDisabledChanged()
end sub

sub onDisabledChanged()
    if m.top.disabled
        m.top.focusable = false
        if m.icon <> invalid then
            m.icon.opacity = 0.35
        end if
        if m.bg <> invalid then
            m.bg.color = "#00000000"
        end if
    else
        m.top.focusable = true
        if m.icon <> invalid then
            m.icon.opacity = 1
        end if
    end if
end sub

sub onIconUriChanged()
    if m.icon <> invalid then
        m.icon.uri = m.top.iconUri
    end if
end sub

sub onFocusChanged()
    if m.bg = invalid then
        return
    end if
    focused = m.top.hasFocus() or m.top.isInFocusChain()
    if focused then
        m.bg.color = m.top.focusColor
    else
        m.bg.color = "#00000000"
    end if
end sub

' Match IconButton: do not consume keys so the parent screen can handle OK (search, sort dialogs, etc.).
function onKeyEvent(key as string, press as boolean) as boolean
    return false
end function
'//# sourceMappingURL=./LibrarySideIcon.brs.map