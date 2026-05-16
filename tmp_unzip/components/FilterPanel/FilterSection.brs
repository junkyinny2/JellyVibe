'import "pkg:/source/enums/ColorPalette.bs"
'import "pkg:/source/enums/KeyCode.bs"
'import "pkg:/source/utils/misc.bs"

' ──────────────────────────────────────────────
' FilterSection  –  collapsible filter group
' ──────────────────────────────────────────────
sub init()
    m.sectionHeaderBg = m.top.findNode("sectionHeaderBg")
    m.sectionLabel = m.top.findNode("sectionLabel")
    m.countBadge = m.top.findNode("countBadge")
    m.collapseIndicator = m.top.findNode("collapseIndicator")
    m.itemsList = m.top.findNode("itemsList")
    ' Colors
    m.sectionHeaderBg.color = "#101010"
    m.sectionLabel.color = "#ffffff"
    m.countBadge.color = "#c8fafa"
    m.collapseIndicator.color = "#ffffff"
    m.itemsList.focusBitmapBlendColor = chainLookupReturn(m.global.session, "user.settings.colorCursor", "#7B2FBE")
    m.itemsList.focusFootprintBlendColor = "#7B2FBE88"
    m.itemsList.focusedColor = "#ffffff"
    m.itemsList.color = "#CCCCCCFF"
    m.itemsList.observeField("itemSelected", "onItemSelected")
    m.isCollapsed = false
    m.itemCount = 0
end sub

' ──────────────────────────────────────────────
' Property handlers
' ──────────────────────────────────────────────
sub onTitleChanged()
    m.sectionLabel.text = m.top.sectionTitle
end sub

sub onItemsChanged()
    items = m.top.items
    if not isValid(items) or items.count() = 0
        m.itemsList.visible = false
        m.top.sectionHeight = 55
        return
    end if
    content = CreateObject("roSGNode", "ContentNode")
    for each item in items
        child = content.CreateChild("ContentNode")
        ' Handle both string items and associative array items (with name and imageUrl)
        if type(item) = "roString" or type(item) = "String"
            child.title = item
            child.HDPosterUrl = ""
            child.SDPosterUrl = ""
        else if type(item) = "roAssociativeArray" or type(item) = "AssociativeArray"
            if isValid(item.name)
                child.title = item.name
            else if isValid(item.Name)
                child.title = item.Name
            end if
            ' Set thumbnail image if available
            if isValid(item.imageUrl) and item.imageUrl <> ""
                child.HDPosterUrl = item.imageUrl
                child.SDPosterUrl = item.imageUrl
            else
                child.HDPosterUrl = ""
                child.SDPosterUrl = ""
            end if
        end if
    end for
    m.itemsList.content = content
    m.itemsList.visible = not m.isCollapsed
    m.itemCount = items.count()
    ' Initialize empty checked state
    checkedState = []
    for i = 0 to m.itemCount - 1
        checkedState.push(false)
    end for
    m.itemsList.checkedState = checkedState
    recalcHeight()
end sub

sub recalcHeight()
    if m.isCollapsed or m.itemCount = 0
        m.top.sectionHeight = 55
    else
        ' Header (50) + padding (5) + items × (52 + 4 spacing)
        visibleRows = m.itemCount
        if visibleRows > 8 then
            visibleRows = 8
        end if ' matches numRows
        m.top.sectionHeight = 55 + (visibleRows * 56)
    end if
end sub

' ──────────────────────────────────────────────
' Selection handling
' ──────────────────────────────────────────────
sub onItemSelected()
    gatherSelectedItems()
end sub

sub gatherSelectedItems()
    selected = []
    if isValid(m.itemsList.checkedState) and isValid(m.itemsList.content)
        for i = 0 to m.itemsList.checkedState.count() - 1
            if m.itemsList.checkedState[i]
                child = m.itemsList.content.getChild(i)
                if isValid(child) and isValid(child.title)
                    selected.push(child.title)
                end if
            end if
        end for
    end if
    m.top.selectedItems = selected
    ' Update count badge
    if selected.count() > 0
        m.countBadge.text = ("(" + bslib_toString(selected.count()) + ")")
    else
        m.countBadge.text = ""
    end if
    ' Signal change to parent
    m.top.sectionChanged = not m.top.sectionChanged
end sub

sub onClearSelections()
    if m.top.clearSelections and isValid(m.itemsList.checkedState)
        cleared = []
        for i = 0 to m.itemsList.checkedState.count() - 1
            cleared.push(false)
        end for
        m.itemsList.checkedState = cleared
        m.top.selectedItems = []
        m.countBadge.text = ""
        m.top.clearSelections = false
    end if
end sub

' ──────────────────────────────────────────────
' Collapse / expand
' ──────────────────────────────────────────────
sub toggleCollapse()
    m.isCollapsed = not m.isCollapsed
    m.itemsList.visible = not m.isCollapsed
    if m.isCollapsed
        m.collapseIndicator.text = "►"
    else
        m.collapseIndicator.text = "▼"
    end if
    recalcHeight()
end sub

' ──────────────────────────────────────────────
' Focus helpers  (called by parent FilterPanel)
' ──────────────────────────────────────────────
sub focusTop()
    m.itemsList.jumpToItem = 0
    m.itemsList.setFocus(true)
end sub

sub focusBottom()
    if isValid(m.itemsList.content)
        lastIdx = m.itemsList.content.getChildCount() - 1
        if lastIdx >= 0
            m.itemsList.jumpToItem = lastIdx
        end if
    end if
    m.itemsList.setFocus(true)
end sub

function isAtTop() as boolean
    return m.itemsList.itemFocused = 0
end function

function isAtBottom() as boolean
    if not isValid(m.itemsList.content) then
        return true
    end if
    lastIdx = m.itemsList.content.getChildCount() - 1
    return m.itemsList.itemFocused >= lastIdx
end function

' ──────────────────────────────────────────────
' Key handling
' ──────────────────────────────────────────────
function onKeyEvent(key as string, press as boolean) as boolean
    if not press then
        return false
    end if
    ' OK on the section header area → toggle collapse
    ' (The CheckList handles its own OK for toggling checkmarks)
    return false ' let parent handle cross-section navigation
end function
'//# sourceMappingURL=./FilterSection.brs.map