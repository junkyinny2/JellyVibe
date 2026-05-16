'import "pkg:/source/enums/ColorPalette.bs"
'import "pkg:/source/utils/misc.bs"

sub init()
    m.poster = m.top.findNode("poster")
    m.background = m.top.findNode("background")
    m.name = m.top.findNode("name")
    m.trashContainer = m.top.findNode("trashContainer")
    m.baseUrl = m.top.findNode("baseUrl")
    m.labels = m.top.findNode("labels")
    if m.top.itemHasFocus then
        m.background.color = "#7B2FBE"
    else
        m.background.color = "#020B2A"
    end if
    setTextColor()
end sub

sub itemContentChanged()
    server = m.top.itemContent
    m.poster.uri = server.iconUrl
    m.name.text = server.name
    m.baseUrl.text = server.baseUrl
    setTrashIconVisibility()
    setBackground()
    setDeleteFocus()
end sub

sub setTrashIconVisibility()
    if not isValid(m.top.itemContent) then
        return
    end if
    if not isValid(m.top.itemContent.isSavedServer) then
        return
    end if
    m.trashContainer.visible = m.top.itemContent.isSavedServer
end sub

sub onItemHasFocusChange()
    if not m.top.itemHasFocus
        m.top.itemContent.itemHasDeleteFocus = false
    end if
    setBackground()
    setDeleteFocus()
end sub

sub setBackground()
    if not isValid(m.top.itemContent) then
        return
    end if
    if not isValid(m.top.itemContent.itemHasDeleteFocus) then
        return
    end if
    if m.top.itemContent.itemHasDeleteFocus
        m.background.color = "#777777"
        return
    end if
    if m.top.itemHasFocus then
        m.background.color = "#7B2FBE"
    else
        m.background.color = "#020B2A"
    end if
end sub

sub setDeleteFocus()
    if not isValid(m.top.itemContent) then
        return
    end if
    if not isValid(m.top.itemContent.itemHasDeleteFocus) then
        return
    end if
    if m.top.itemHasFocus
        if m.top.itemContent.itemHasDeleteFocus
            trashContainerColor = "#7B2FBE"
        else
            trashContainerColor = "0x00000077"
        end if
    else
        trashContainerColor = "0x00000077"
    end if
    m.trashContainer.color = trashContainerColor
end sub

sub setTextColor()
    textColor = "#ffffff"
    children = m.labels.getChildren(-1, 0)
    for each child in children
        child.color = textColor
    end for
end sub
'//# sourceMappingURL=./JFServer.brs.map