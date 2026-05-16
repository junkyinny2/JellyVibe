'import "pkg:/source/utils/misc.bs"

sub init()
    m.photo = m.top.findNode("photo")
    m.name = m.top.findNode("name")
    m.role = m.top.findNode("role")
    m.focusRing = m.top.findNode("focusRing")
end sub

sub itemContentChanged()
    item = m.top.itemContent
    if not isValid(item) then
        return
    end if
    m.name.text = item.title
    m.role.text = item.description
    imgUrl = item.HDGRIDPOSTERURL
    if isValid(imgUrl) and imgUrl <> ""
        m.photo.uri = imgUrl
    else
        m.photo.uri = "pkg:/images/baseline_person_white_48dp.png"
    end if
end sub

sub focusChanged()
    if not isValid(m.focusRing) then
        return
    end if
    m.focusRing.visible = m.top.itemHasFocus
end sub
'//# sourceMappingURL=./CastItem.brs.map