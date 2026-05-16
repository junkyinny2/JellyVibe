'import "pkg:/source/api/baserequest.bs"
'import "pkg:/source/api/Image.bs"
'import "pkg:/source/enums/AnimationControl.bs"
'import "pkg:/source/enums/AnimationState.bs"
'import "pkg:/source/enums/ColorPalette.bs"
'import "pkg:/source/enums/ItemType.bs"
'import "pkg:/source/enums/KeyCode.bs"
'import "pkg:/source/enums/PosterLoadStatus.bs"
'import "pkg:/source/enums/String.bs"
'import "pkg:/source/enums/TaskControl.bs"
'import "pkg:/source/utils/config.bs"
'import "pkg:/source/utils/deviceCapabilities.bs"
'import "pkg:/source/utils/misc.bs"

sub init()
    m.isFirstRun = true
    m.top.overhangTitle = ""
    m.top.optionsAvailable = false
    m.postTask = createObject("roSGNode", "PostTask")
    m.favoritesOptionText = tr("Add To Favorites")
    m.loadItemsTask1 = createObject("roSGNode", "LoadItemsTask")
    m.loadItemsTask1.observeField("content", "onMyListLoaded")
    m.loadItemsTask1.itemsToLoad = "isInMyList"
    m.loadMetaDataTask = CreateObject("roSGNode", "LoadItemsTask")
    m.loadMetaDataTask.itemsToLoad = "metaData"
    m.loadMetaDataTask.observeField("content", "onMetaDataLoaded")
    m.homeRows = m.top.findNode("homeRows")
    m.homeRows.observeFieldScoped("rowItemFocused", "onHomeRowItemFocused")
    m.homeRows.observeFieldScoped("hasFocus", "onHomeRowsHasFocusChange")
    m.homeBackdrop = m.top.findNode("backdrop")
    m.homeBackdropTransition = m.top.findNode("backdropTransition")
    m.homeBackdropSwapAnimation = m.top.findNode("homeBackdropSwapAnimation")
    m.homeBackdropSwapAnimation.observeField("state", "homeBackdropSwapDone")
    m.homeBackdropTransition.observeField("loadStatus", "homeBackdropTransitionLoaded")
    m.queuedHomeBackdropUri = ""
    m.topBar = m.top.findNode("topBar")
    m.homeTab = m.top.findNode("homeTab")
    m.favoritesTab = m.top.findNode("favoritesTab")
    m.profileGroup = m.top.findNode("profileGroup")
    m.profileHighlight = m.top.findNode("profileHighlight")
    m.userName = m.top.findNode("userName")
    m.profileIcon = m.top.findNode("profileIcon")
    m.userIcon = m.top.findNode("userIcon")
    m.searchButton = m.top.findNode("searchButton")
    m.settingsButton = m.top.findNode("settingsButton")
    m.homeUnderline = m.top.findNode("homeUnderline")
    m.favoritesUnderline = m.top.findNode("favoritesUnderline")
    m.options = m.top.findNode("options")
    ' m.topBar serves as the top-nav container for focus-chain checks
    m.topNav = m.topBar
    m.topRightGroup = m.profileGroup
    ' Track which view is active (home or favorites)
    m.activeViewMode = "home"
    m.top.observeField("focusedChild", "onFocusChange")
    setButtonColors()
end sub

sub onFocusChange()
    updateTabHighlights()
end sub

' Explicitly highlight/unhighlight the profile pill — called from nav code, not from focus chain checks.
sub highlightProfile(on as boolean)
    if on
        m.profileHighlight.blendColor = "#7B2FBE"
        m.userName.color = "#101010"
        if isValid(m.userIcon)
            m.userIcon.blendColor = "#101010"
        end if
    else
        m.profileHighlight.blendColor = "#00000000"
        m.userName.color = "#ffffff"
        if isValid(m.userIcon)
            m.userIcon.blendColor = "#ffffff"
        end if
    end if
end sub

sub updateTabHighlights()
    m.homeTab.background = "#00000000"
    m.favoritesTab.background = "#00000000"
    m.homeTab.focusTextColor = "#ffffff"
    m.favoritesTab.focusTextColor = "#ffffff"
    if m.activeViewMode = "favorites"
        m.homeTab.textColor = "#ffffff"
        m.favoritesTab.textColor = "#ffffff"
    else
        m.homeTab.textColor = "#ffffff"
        m.favoritesTab.textColor = "#ffffff"
    end if
end sub

sub refresh()
    m.homeRows.callFunc("updateHomeRows")
    onHomeRowItemFocused()
end sub

sub setButtonColors()
    m.homeTab.textColor = "#ffffff"
    m.homeTab.background = "#00000000"
    m.homeTab.focusTextColor = "#ffffff"
    m.homeTab.focusBackground = "#7B2FBE"
    m.favoritesTab.textColor = "#ffffff"
    m.favoritesTab.background = "#00000000"
    m.favoritesTab.focusTextColor = "#ffffff"
    m.favoritesTab.focusBackground = "#7B2FBE"
    m.searchButton.textColor = "#ffffff"
    m.searchButton.background = "#00000000"
    m.searchButton.focusBackground = "#7B2FBE"
    m.searchButton.iconBlendColor = "#ffffff"
    m.searchButton.focusIconBlendColor = "#101010"
    m.settingsButton.textColor = "#ffffff"
    m.settingsButton.background = "#00000000"
    m.settingsButton.focusBackground = "#7B2FBE"
    m.settingsButton.iconBlendColor = "#ffffff"
    m.settingsButton.focusIconBlendColor = "#101010"
    updateTabHighlights()
end sub

sub loadLibraries()
    m.homeRows.callFunc("loadLibraries")
end sub

' JFScreen hook called when the screen is displayed by the screen manager
sub OnScreenShown()
    m.homeRows.rowLabelColor = chainLookupReturn(m.global.session, "user.settings.colorHomeRowHeaders", "#ffffff")
    scene = m.top.getScene()
    overhang = scene.findNode("overhang")
    if isValid(overhang)
        overhang.visible = false
    end if
    ' Populate top bar
    m.userName.text = m.global.session.user.name
    m.profileIcon.uri = UserImageURL(m.global.session.user.id)
    if isValid(m.top.lastFocus)
        if LCase(m.top.lastFocus.id) = "overhang"
            overhang.callFunc("highlightUser")
        end if
        m.top.lastFocus.setFocus(true)
    else
        m.top.setFocus(true)
        group = m.global.sceneManager.callFunc("getActiveScene")
        group.lastFocus = m.top
    end if
    if not m.isFirstRun
        refresh()
    end if
    onHomeRowItemFocused()
    ' post the device profile the first time this screen is loaded
    if m.isFirstRun
        m.isFirstRun = false
        m.postTask.arrayData = getDeviceCapabilities()
        m.postTask.apiUrl = "/Sessions/Capabilities/Full"
        m.postTask.control = "RUN"
        m.postTask.observeField("responseCode", "postFinished")
    end if
end sub

' JFScreen hook called when the screen is hidden by the screen manager
sub OnScreenHidden()
    clearHomeBackdrop()
    scene = m.top.getScene()
    overhang = scene.findNode("overhang")
    if isValid(overhang)
        overhang.callFunc("dehighlightUser")
        overhang.currentUser = ""
        overhang.title = ""
    end if
end sub

' Triggered by m.postTask after completing a post.
' Empty the task data when finished.
sub postFinished()
    m.postTask.unobserveField("responseCode")
    m.postTask.callFunc("empty")
end sub

function getHomeItemBackdropUri(homeItem as object) as string
    if not isChainValid(homeItem, "json") then
        return ""
    end if
    datum = homeItem.json
    itemId = homeItem.LookupCI("id")
    if not isValidAndNotEmpty(itemId) then
        return ""
    end if
    ' No backdrop for library/collection tiles (Movies, Shows, Playlists rows)
    itemType = LCase(datum.LookupCI("type"))
    if inArray([
        "collectionfolder"
        "userview"
        "folder"
        "playlist"
    ], itemType) then
        return ""
    end if
    imgQ = {
        "maxWidth": 1920
        "maxHeight": 1080
        "quality": "90"
    }
    if isChainValid(datum, "BackdropImageTags") and isValidAndNotEmpty(datum.BackdropImageTags)
        imgQ["Tag"] = datum.BackdropImageTags[0]
        return ImageURL(itemId, "Backdrop", imgQ)
    end if
    if itemType = "episode" or itemType = "recording" or itemType = "musicvideo"
        if isChainValid(datum, "ParentBackdropImageTags") and isValidAndNotEmpty(datum.ParentBackdropImageTags)
            parentId = datum.LookupCI("ParentBackdropItemId")
            if isValidAndNotEmpty(parentId)
                p = {
                    "maxWidth": 1920
                    "maxHeight": 1080
                    "quality": "90"
                    "Tag": datum.ParentBackdropImageTags[0]
                }
                return ImageURL(parentId, "Backdrop", p)
            end if
        end if
    end if
    if isChainValid(datum, "ImageTags") and isValid(datum.ImageTags.Primary)
        imgQ["Tag"] = datum.ImageTags.Primary
        return ImageURL(itemId, "Primary", imgQ)
    end if
    if isValidAndNotEmpty(homeItem.LookupCI("widePosterUrl"))
        return homeItem.LookupCI("widePosterUrl")
    end if
    if isValidAndNotEmpty(homeItem.LookupCI("thumbnailURL"))
        return homeItem.LookupCI("thumbnailURL")
    end if
    return ""
end function

sub clearHomeBackdrop()
    if not isValid(m.homeBackdrop) then
        return
    end if
    m.homeBackdrop.opacity = 0
    m.homeBackdropTransition.opacity = 0
    m.queuedHomeBackdropUri = ""
end sub

sub setHomeBackdrop(backgroundUri as string)
    if not isValid(backgroundUri) or isStringEqual(backgroundUri, "")
        clearHomeBackdrop()
        return
    end if
    if not isStringEqual(m.homeBackdropSwapAnimation.state, "stopped") or isStringEqual(m.homeBackdropTransition.loadStatus, "loading")
        m.queuedHomeBackdropUri = backgroundUri
        return
    end if
    m.homeBackdropTransition.uri = backgroundUri
end sub

sub onHomeRowsHasFocusChange()
    if m.homeRows.hasFocus
        onHomeRowItemFocused()
        return
    end if
    if libraryFocusBackdropEnabled()
        clearHomeBackdrop()
    end if
end sub

sub onHomeRowItemFocused()
    if not libraryFocusBackdropEnabled()
        clearHomeBackdrop()
        return
    end if
    if not m.homeRows.isInFocusChain()
        clearHomeBackdrop()
        return
    end if
    ri = m.homeRows.rowItemFocused
    if not isValid(ri) or ri.count() < 2 then
        return
    end if
    if ri[0] < 0 or ri[1] < 0 then
        return
    end if
    rowNode = m.homeRows.content.getChild(ri[0])
    if not isValid(rowNode) then
        return
    end if
    if ri[1] >= rowNode.getChildCount() then
        return
    end if
    item = rowNode.getChild(ri[1])
    if not isValid(item) then
        return
    end if
    uri = getHomeItemBackdropUri(item)
    if not isValidAndNotEmpty(uri)
        clearHomeBackdrop()
        return
    end if
    setHomeBackdrop(uri)
end sub

sub homeBackdropTransitionLoaded()
    if not libraryFocusBackdropEnabled() then
        return
    end if
    if isStringEqual(m.homeBackdropTransition.loadStatus, "ready")
        m.homeBackdropSwapAnimation.control = "start"
    end if
end sub

sub homeBackdropSwapDone()
    if not isValid(m.homeBackdropSwapAnimation) then
        return
    end if
    if not isStringEqual(m.homeBackdropSwapAnimation.state, "stopped") then
        return
    end if
    if libraryFocusBackdropEnabled() and m.homeRows.isInFocusChain()
        m.homeBackdrop.uri = m.homeBackdropTransition.uri
        m.homeBackdrop.opacity = 0.35
        m.homeBackdropTransition.opacity = 0
        if not isStringEqual(m.homeBackdropTransition.uri, m.queuedHomeBackdropUri) and not isStringEqual(m.queuedHomeBackdropUri, "")
            setHomeBackdrop(m.queuedHomeBackdropUri)
            m.queuedHomeBackdropUri = ""
        end if
    else
        clearHomeBackdrop()
    end if
end sub

sub onRowFocusedChange()
    ' Top row should always remain on screen
    return
end sub

sub onMyListLoaded()
    isInMyListData = m.loadItemsTask1.content
    m.loadItemsTask1.content = []
    if not isValidAndNotEmpty(isInMyListData) then
        return
    end if
    focusedItem = m.homeRows.content.getChild(m.homeRows.rowItemFocused[0]).getChild(m.homeRows.rowItemFocused[1])
    if not isValid(focusedItem) then
        return
    end if
    dialogData = []
    paramData = {
        id: focusedItem.LookupCI("id")
    }
    if isInMyListData[0]
        dialogData.push(tr("Remove From My List"))
    else
        if inArray([
            "episode"
            "movie"
            "season"
            "series"
            "video"
            "musicvideo"
            "recording"
            "boxset"
        ], focusedItem.LookupCI("type"))
            dialogData.push(tr("Add To My List"))
        end if
    end if
    dialogData.push(m.favoritesOptionText)
    if not inArray([
        "collectionfolder"
        "channel"
        "folder"
        "playlist"
        "program"
        "tvchannel"
        "userview"
    ], focusedItem.LookupCI("type"))
        dialogData.push(tr("Add To Playlist"))
    end if
    if inArray([
        "episode"
        "movie"
        "season"
        "series"
        "video"
        "musicvideo"
        "recording"
        "boxset"
        "audiobook"
        "book"
    ], focusedItem.LookupCI("type"))
        showBothOptions = false
        if isChainValid(focusedItem, "PlayedPercentage")
            if focusedItem.PlayedPercentage > 0
                showBothOptions = true
            end if
        end if
        if showBothOptions
            dialogData.push(tr("Mark As Unplayed"))
            dialogData.push(tr("Mark As Played"))
        else
            if isChainValid(focusedItem, "isWatched")
                if focusedItem.isWatched
                    dialogData.push(tr("Mark As Unplayed"))
                else
                    dialogData.push(tr("Mark As Played"))
                end if
            end if
        end if
    end if
    if inArray([
        "episode"
        "season"
    ], focusedItem.LookupCI("type"))
        dialogData.push(tr("Go To Series"))
        dialogData.push(tr("Go To Season"))
        paramData.SeasonId = focusedItem.json.LookupCI("SeasonId")
        paramData.SeriesId = focusedItem.json.LookupCI("SeriesId")
    end if
    if inArray([
        "musicalbum"
    ], focusedItem.LookupCI("type"))
        dialogData.push(tr("Play Instant Mix"))
        dialogData.push(tr("Go To Artist"))
        genreData = focusedItem.json.LookupCI("Genre")
        if isValidAndNotEmpty(genreData)
            if isValidAndNotEmpty(genreData[0])
                if isValidAndNotEmpty(genreData[0].Name)
                    dialogData.push(tr("Go To Genre") + (": " + bslib_toString(genreData[0].LookupCI("Name"))))
                    paramData.GenreName = genreData[0].LookupCI("Name")
                    paramData.GenreId = genreData[0].LookupCI("Id")
                    paramData.LibraryId = chainLookup(focusedItem, "json.LibraryId")
                end if
            end if
        end if
        paramData.ArtistId = focusedItem.json.LookupCI("AlbumArtistId")
        paramData.ArtistName = focusedItem.json.LookupCI("albumartist")
        paramData.AlbumId = focusedItem.LookupCI("id")
    end if
    m.global.sceneManager.callFunc("optionDialog", "libraryitem", (function(focusedItem, tr)
            __bsConsequent = focusedItem.LookupCI("title")
            if __bsConsequent <> invalid then
                return __bsConsequent
            else
                return tr("Options")
            end if
        end function)(focusedItem, tr), [], dialogData, paramData)
end sub

sub setLastFocus(lastFocusElement)
    group = m.global.sceneManager.callFunc("getActiveScene")
    if isValid(group)
        group.lastFocus = lastFocusElement
    end if
end sub

function audioMiniPlayerIsVisibleInScene()
    scene = m.top.getScene()
    audioMiniPlayer = scene.findNode("audioMiniPlayer")
    if not isValid(audioMiniPlayer) then
        return false
    end if
    return audioMiniPlayer.callFunc("isVisible")
end function

' Special handling for key presses on the home screen.
function onKeyEvent(key as string, press as boolean) as boolean
    if not press then
        return false
    end if
    if m.topNav.isInFocusChain() or m.topRightGroup.isInFocusChain()
        if isStringEqual(key, "replay")
            if not audioMiniPlayerIsVisibleInScene() then
                return true
            end if
            m.profileGroup.setFocus(false)
            m.searchButton.focus = false
            m.settingsButton.focus = false
        end if
        if isStringEqual(key, "OK")
            if m.homeTab.hasFocus()
                m.activeViewMode = "home"
                updateTabHighlights()
                if m.homeRows.viewMode <> "home"
                    m.homeRows.viewMode = "home"
                    m.homeRows.callFunc("updateHomeRows")
                end if
                return true
            end if
            if m.favoritesTab.hasFocus()
                m.activeViewMode = "favorites"
                updateTabHighlights()
                if m.homeRows.viewMode <> "favorites"
                    m.homeRows.viewMode = "favorites"
                    m.homeRows.callFunc("updateHomeRows")
                end if
                return true
            end if
            if m.profileGroup.hasFocus()
                optionsPanel = m.global.sceneManager.callFunc("getActiveScene").findNode("options")
                optionsPanel.visible = true
                optionsPanel.setFocus(true)
                optionsList = optionsPanel.findNode("panelList")
                if isValid(optionsList)
                    optionsList.setFocus(true)
                    if not isValid(optionsList.itemFocused) or optionsList.itemFocused < 0
                        optionsList.jumpToItem = 0
                    end if
                end if
                setLastFocus(m.profileGroup)
                return true
            end if
            if m.searchButton.hasFocus()
                m.top.getScene().jumpTo = {
                    selectionType: "search"
                }
                return true
            end if
            if m.settingsButton.hasFocus()
                m.top.getScene().jumpTo = {
                    selectionType: "settings"
                }
                return true
            end if
        end if
        if isStringEqual(key, "down")
            m.homeRows.setfocus(true)
            setLastFocus(m.homeRows)
            return true
        end if
        if isStringEqual(key, "right")
            if m.homeTab.hasFocus()
                m.favoritesTab.setfocus(true)
                setLastFocus(m.favoritesTab)
                return true
            end if
            if m.favoritesTab.hasFocus()
                highlightProfile(true)
                m.profileGroup.setFocus(true)
                setLastFocus(m.profileGroup)
                return true
            end if
            if m.profileGroup.hasFocus()
                highlightProfile(false)
                m.searchButton.setfocus(true)
                setLastFocus(m.searchButton)
                return true
            end if
            if m.searchButton.hasFocus()
                m.settingsButton.setfocus(true)
                setLastFocus(m.settingsButton)
                return true
            end if
        end if
        if isStringEqual(key, "left")
            if m.settingsButton.hasFocus()
                m.searchButton.setfocus(true)
                setLastFocus(m.searchButton)
                return true
            end if
            if m.searchButton.hasFocus()
                highlightProfile(true)
                m.profileGroup.setFocus(true)
                setLastFocus(m.profileGroup)
                return true
            end if
            if m.profileGroup.hasFocus()
                highlightProfile(false)
                m.favoritesTab.setfocus(true)
                setLastFocus(m.favoritesTab)
                return true
            end if
            if m.favoritesTab.hasFocus()
                m.homeTab.setfocus(true)
                setLastFocus(m.homeTab)
                return true
            end if
        end if
        return false
    end if
    ' If the user hit back and is not on the first item of the row,
    ' assume they want to go to the first item of the row.
    ' Otherwise, they are exiting the app.
    if isStringEqual(key, "back") and m.homeRows.rowItemFocused[1] > 0
        m.homeRows.jumpToRowItem = [
            m.homeRows.rowItemFocused[0]
            0
        ]
        return true
    end if
    if isStringEqual(key, "options")
        if m.homeRows.hasFocus()
            focusedItem = m.homeRows.content.getChild(m.homeRows.rowItemFocused[0]).getChild(m.homeRows.rowItemFocused[1])
            if not isValidAndNotEmpty(focusedItem) then
                return false
            end if
            m.loadMetaDataTask.itemId = focusedItem.LookupCI("id")
            m.loadMetaDataTask.control = "RUN"
            return true
        end if
    end if
    if isStringEqual(key, "up")
        m.homeTab.setfocus(true)
        setLastFocus(m.homeTab)
        return true
    end if
    if isStringEqual(key, "left")
        if m.homeRows.hasFocus() and m.homeRows.rowItemFocused[1] = 0
            m.top.getScene().callFunc("toggleSideMenu", true)
            return true
        end if
    end if
    return false
end function

sub onMetaDataLoaded()
    data = m.loadMetaDataTask.content[0]
    if chainLookupReturn(data, "json.UserData.IsFavorite", false) then
        m.favoritesOptionText = tr("Remove From Favorites")
    else
        m.favoritesOptionText = tr("Add To Favorites")
    end if
    focusedItem = m.homeRows.content.getChild(m.homeRows.rowItemFocused[0]).getChild(m.homeRows.rowItemFocused[1])
    m.loadItemsTask1.itemId = focusedItem.LookupCI("id")
    m.loadItemsTask1.control = "RUN"
end sub
'//# sourceMappingURL=./Home.brs.map