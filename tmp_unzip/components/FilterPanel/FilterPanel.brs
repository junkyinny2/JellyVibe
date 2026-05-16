'import "pkg:/source/enums/AnimationControl.bs"
'import "pkg:/source/enums/AnimationState.bs"
'import "pkg:/source/enums/ColorPalette.bs"
'import "pkg:/source/enums/KeyCode.bs"
'import "pkg:/source/enums/TaskControl.bs"
'import "pkg:/source/utils/misc.bs"
'import "pkg:/source/FilterManager.bs"

' ──────────────────────────────────────────────
' FilterPanel  –  left-side sliding filter drawer
' ──────────────────────────────────────────────
sub init()
    ' ── Node references ────────────────────────
    m.scrim = m.top.findNode("scrim")
    m.panelGroup = m.top.findNode("panelGroup")
    m.clearAllBtn = m.top.findNode("clearAllBtn")
    m.genresSection = m.top.findNode("genresSection")
    m.tagsSection = m.top.findNode("tagsSection")
    m.slideInAnim = m.top.findNode("slideInAnim")
    m.slideOutAnim = m.top.findNode("slideOutAnim")
    ' ── Colors (match Jellyfin palette) ────────
    panelBg = m.top.findNode("panelBg")
    panelBg.color = "#303030"
    edgeStripe = m.top.findNode("edgeStripe")
    edgeStripe.color = "#c8fafa"
    headerLabel = m.top.findNode("headerLabel")
    headerLabel.color = "#ffffff"
    headerDivider = m.top.findNode("headerDivider")
    headerDivider.color = "#aaaaaa"
    m.clearAllBtn.background = "#aaaaaa"
    m.clearAllBtn.color = "#ffffff"
    m.clearAllBtn.focusBackground = chainLookupReturn(m.global.session, "user.settings.colorCursor", "#7B2FBE")
    m.clearAllBtn.focusColor = "#ffffff"
    ' ── Section observers ──────────────────────
    m.genresSection.observeField("sectionChanged", "onSectionChanged")
    m.tagsSection.observeField("sectionChanged", "onSectionChanged")
    m.genresSection.observeField("sectionHeight", "onGenresSectionResized")
    ' ── Clear All button ───────────────────────
    m.clearAllBtn.observeField("buttonSelected", "onClearAll")
    ' ── Slide-out callback to hide scrim ───────
    m.slideOutAnim.observeField("state", "onSlideOutFinished")
    ' ── Track whether data was loaded ──────────
    m.dataLoaded = false
end sub

' ──────────────────────────────────────────────
' Open / Close
' ──────────────────────────────────────────────
sub onIsOpenChanged()
    if m.top.isOpen
        openPanel()
    else
        closePanel()
    end if
end sub

sub openPanel()
    m.scrim.visible = true
    m.top.visible = true
    ' Fetch filter data on first open (or when parentId changes)
    if not m.dataLoaded or m.lastParentId <> m.top.parentId
        loadFilterData()
    end if
    if m.slideInAnim.state <> "running"
        m.slideInAnim.control = "start"
    end if
    ' Give focus to genres section (first focusable child)
    m.genresSection.setFocus(true)
    setActiveSceneLastFocus(m.genresSection)
end sub

sub closePanel()
    if m.slideOutAnim.state <> "running"
        m.slideOutAnim.control = "start"
    end if
end sub

sub onSlideOutFinished()
    if m.slideOutAnim.state = "stopped"
        m.scrim.visible = false
        m.top.visible = false
    end if
end sub

' ──────────────────────────────────────────────
' Data loading
' ──────────────────────────────────────────────
sub loadFilterData()
    m.loadTask = createObject("roSGNode", "LoadFilterDataTask")
    m.loadTask.parentId = m.top.parentId
    m.loadTask.itemType = m.top.itemType
    m.loadTask.observeField("dataLoaded", "onFilterDataLoaded")
    m.loadTask.control = "RUN"
end sub

sub onFilterDataLoaded()
    if not isValid(m.loadTask) then
        return
    end if
    m.genresSection.items = m.loadTask.genres
    m.tagsSection.items = m.loadTask.tags
    ' Position tags section below genres
    repositionTagsSection()
    m.dataLoaded = true
    m.lastParentId = m.top.parentId
end sub

sub repositionTagsSection()
    genreBottom = 130 + m.genresSection.sectionHeight
    m.tagsSection.translation = [
        0
        genreBottom + 10
    ]
end sub

sub onGenresSectionResized()
    repositionTagsSection()
end sub

' ──────────────────────────────────────────────
' Selection aggregation
' ──────────────────────────────────────────────
sub onSectionChanged()
    m.top.selectedGenres = m.genresSection.selectedItems
    m.top.selectedTags = m.tagsSection.selectedItems
    m.top.filterChanged = buildFilterParams(m.top.selectedGenres, m.top.selectedTags)
end sub

sub onClearAll()
    m.genresSection.clearSelections = true
    m.tagsSection.clearSelections = true
    m.top.selectedGenres = []
    m.top.selectedTags = []
    m.top.filterChanged = buildFilterParams([], [])
end sub

' ──────────────────────────────────────────────
' Focus helper
' ──────────────────────────────────────────────
sub setActiveSceneLastFocus(node as object)
    group = m.global.sceneManager.callFunc("getActiveScene")
    if isValid(group)
        group.lastFocus = node
    end if
end sub

' ──────────────────────────────────────────────
' Key handling
' ──────────────────────────────────────────────
function onKeyEvent(key as string, press as boolean) as boolean
    if not press then
        return false
    end if
    if not m.top.isOpen then
        return false
    end if
    ' ── BACK or LEFT → close panel ─────────────
    if key = "back" or key = "left"
        m.top.isOpen = false
        return true
    end if
    ' ── UP → move focus upward through sections ─
    if key = "up"
        if m.tagsSection.isInFocusChain()
            if m.tagsSection.isAtTop()
                m.genresSection.focusBottom()
                setActiveSceneLastFocus(m.genresSection)
                return true
            end if
        end if
        if m.genresSection.isInFocusChain()
            if m.genresSection.isAtTop()
                m.clearAllBtn.setFocus(true)
                m.clearAllBtn.focus = true
                setActiveSceneLastFocus(m.clearAllBtn)
                return true
            end if
        end if
        if m.clearAllBtn.isInFocusChain()
            ' Already at top – consume key
            return true
        end if
    end if
    ' ── DOWN → move focus downward ─────────────
    if key = "down"
        if m.clearAllBtn.isInFocusChain()
            m.clearAllBtn.focus = false
            m.genresSection.focusTop()
            setActiveSceneLastFocus(m.genresSection)
            return true
        end if
        if m.genresSection.isInFocusChain()
            if m.genresSection.isAtBottom()
                m.tagsSection.focusTop()
                setActiveSceneLastFocus(m.tagsSection)
                return true
            end if
        end if
        if m.tagsSection.isInFocusChain()
            if m.tagsSection.isAtBottom()
                ' Already at bottom – consume key
                return true
            end if
        end if
    end if
    ' ── OPTIONS key → close panel (matches app pattern) ─
    if key = "options"
        m.top.isOpen = false
        return false ' let parent also handle OPTIONS dismiss
    end if
    return false
end function
'//# sourceMappingURL=./FilterPanel.brs.map