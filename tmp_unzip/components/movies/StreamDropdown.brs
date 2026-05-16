sub init()
    m.wrapper = m.top.findNode("wrapper")
    m.list = m.top.findNode("list")
    m.bg = m.top.findNode("bg")
    m.border = m.top.findNode("border")
    m.slideAnim = m.top.findNode("slideAnim")
    m.fadeInterp = m.top.findNode("fadeInterp")
    m.moveInterp = m.top.findNode("moveInterp")
    m.animStartY = 0
    m.animEndY = 0
    m.list.observeField("itemSelected", "onItemSelected")
end sub

function isValid(obj) as boolean
    return obj <> invalid
end function

sub contentChanged()
    content = m.top.content
    if not isValid(content) then
        return
    end if
    m.list.content = content
    totalCount = content.getChildCount()
    visibleRows = totalCount
    if visibleRows > 8 then
        visibleRows = 8
    end if
    m.list.numRows = visibleRows
    ' Calculate dynamic width from longest text
    w = calculateWidth(content)
    dims = getDropdownDimensions(w, visibleRows)
    x = m.top.anchorX
    ' Ensure dropdown doesn't go off right edge of screen
    if x + dims.w > 1920
        dims = {
            w: 1920 - x
            h: dims.h
        }
    end if
    ' Always position below the button
    y = m.top.anchorY + 52
    m.animStartY = -20
    m.animEndY = 0
    m.top.translation = [
        x
        y
    ]
    m.wrapper.translation = [
        0
        0
    ]
    ' Size the dropdown
    m.bg.width = dims.w
    m.bg.height = dims.h + 2
    m.border.width = dims.w
    m.border.height = dims.h + 2
    m.list.itemSize = [
        dims.w
        64
    ]
    ' Jump to selected item
    idx = 0
    for i = 0 to totalCount - 1
        child = content.getChild(i)
        if isValid(child) and child.selected = true
            idx = i
            exit for
        end if
    end for
    m.list.jumpToItem = idx
end sub

function calculateWidth(content as object) as integer
    if not isValid(content) then
        return m.top.itemWidth
    end if
    longest = 0
    for i = 0 to content.getChildCount() - 1
        child = content.getChild(i)
        if isValid(child)
            title = child.title
            if isValid(title) then
                l = Len(title)
                if l > longest then
                    longest = l
                end if
            end if
            desc = child.description
            if isValid(desc) then
                l = Len(desc)
                if l > longest then
                    longest = l
                end if
            end if
        end if
    end for
    ' ~11px per char for SmallestSystemFont + 40px for checkmark/padding
    w = longest * 11 + 40
    if w < m.top.itemWidth then
        w = m.top.itemWidth
    end if
    if w > 1000 then
        w = 1000
    end if
    return w
end function

function getDropdownDimensions(width as integer, visibleRows as integer) as object
    content = m.top.content
    if not isValid(content) then
        return {
            w: width
            h: 100
        }
    end if
    h = visibleRows * 64
    return {
        w: width
        h: h
    }
end function

sub onItemSelected()
    selected = m.list.itemSelected
    if selected >= 0
        m.top.selectedIndex = selected
    end if
end sub

sub show()
    content = m.top.content
    if not isValid(content) or content.getChildCount() = 0 then
        return
    end if
    m.top.visible = true
    m.wrapper.opacity = 0
    m.wrapper.translation = [
        0
        m.animStartY
    ]
    m.moveInterp.keyValue = [
        [
            0
            m.animStartY
        ]
        [
            0
            m.animEndY
        ]
    ]
    m.fadeInterp.keyValue = [
        0.0
        1.0
    ]
    m.slideAnim.control = "start"
    m.list.setFocus(true)
end sub

sub hide()
    m.top.visible = false
    m.list.setFocus(false)
    m.top.selectedIndex = -1
end sub
'//# sourceMappingURL=./StreamDropdown.brs.map