'import "pkg:/components/manager/ViewCreator.bs"
'import "pkg:/source/enums/CollectionType.bs"
'import "pkg:/source/enums/ItemType.bs"
'import "pkg:/source/enums/PlaybackMethod.bs"
'import "pkg:/source/enums/ResumePopupAction.bs"
'import "pkg:/source/enums/String.bs"
'import "pkg:/source/enums/SubtitleSelection.bs"
'import "pkg:/source/utils/misc.bs"

sub onQuickPlayEvent(msg)
    m.global.queueManager.callFunc("setForceTranscode", "playNormally")
    reportingNode = msg.getRoSGNode()
    itemNode = invalid
    ' Prevent double fire bug
    if isChainValid(reportingNode, "quickPlayNode")
        itemNode = reportingNode.quickPlayNode.clone(false)
        reportingNode.quickPlayNode = invalid
    end if
    if not isValid(itemNode) then
        return
    end if
    if not isValidAndNotEmpty(itemNode.id) then
        return
    end if
    ' Get item type
    selectedItemType = invalid
    if isValidAndNotEmpty(itemNode.type)
        selectedItemType = itemNode.type
    else
        ' Grab type from json
        if isChainValid(itemNode, "json.type")
            selectedItemType = itemNode.json.type
        end if
    end if
    ' Can't play the item without knowing what type it is
    if not isValidAndNotEmpty(selectedItemType) then
        return
    end if
    startLoadingSpinner()
    m.global.queueManager.callFunc("clear") ' empty queue/playlist
    m.global.queueManager.callFunc("resetShuffle") ' turn shuffle off
    if inArray([
        "episode"
        "recording"
        "movie"
        "video"
    ], selectedItemType)
        quickplay_video(itemNode)
        ' Restore focus
        group = m.global.sceneManager.callFunc("getActiveScene")
        if isValid(group)
            if isStringEqual(group.subtype(), "TVSeasonDetails")
                if isValid(group.lastFocus)
                    group.lastFocus.setFocus(true)
                end if
            end if
        end if
        m.global.queueManager.callFunc("playQueue")
        return
    end if
    if isStringEqual(selectedItemType, "audio")
        quickplay_audio(itemNode)
        m.global.queueManager.callFunc("playQueue")
        return
    end if
    if isStringEqual(selectedItemType, "audiobook")
        quickplay_audioBook(itemNode)
        m.global.queueManager.callFunc("playQueue")
        return
    end if
    if isStringEqual(selectedItemType, "musicalbum")
        quickplay_album(itemNode)
        m.global.queueManager.callFunc("playQueue")
        return
    end if
    if isStringEqual(selectedItemType, "musicartist")
        quickplay_artist(itemNode)
        m.global.queueManager.callFunc("playQueue")
        return
    end if
    if isStringEqual(selectedItemType, "series")
        quickplay_series(itemNode)
        m.global.queueManager.callFunc("playQueue")
        return
    end if
    if isStringEqual(selectedItemType, "season")
        quickplay_season(itemNode)
        m.global.queueManager.callFunc("playQueue")
        return
    end if
    if isStringEqual(selectedItemType, "boxset")
        quickplay_boxset(itemNode)
        m.global.queueManager.callFunc("playQueue")
        return
    end if
    if isStringEqual(selectedItemType, "collectionfolder")
        quickplay_collectionFolder(itemNode)
        m.global.queueManager.callFunc("playQueue")
        return
    end if
    if isStringEqual(selectedItemType, "playlist")
        quickplay_playlist(itemNode)
        m.global.queueManager.callFunc("playQueue")
        return
    end if
    if isStringEqual(selectedItemType, "userview")
        quickplay_userView(itemNode)
        m.global.queueManager.callFunc("playQueue")
        return
    end if
    if isStringEqual(selectedItemType, "folder")
        quickplay_folder(itemNode)
        m.global.queueManager.callFunc("playQueue")
        return
    end if
    if isStringEqual(selectedItemType, "musicvideo")
        quickplay_musicVideo(itemNode)
        m.global.queueManager.callFunc("playQueue")
        return
    end if
    if isStringEqual(selectedItemType, "person")
        quickplay_person(itemNode)
        m.global.queueManager.callFunc("playQueue")
        return
    end if
    if isStringEqual(selectedItemType, "tvchannel")
        quickplay_tvChannel(itemNode)
        m.global.queueManager.callFunc("playQueue")
        return
    end if
    if isStringEqual(selectedItemType, "program")
        quickplay_program(itemNode)
        m.global.queueManager.callFunc("playQueue")
        return
    end if
    if isStringEqual(selectedItemType, "photo")
        quickplay_photo(itemNode)
        m.global.queueManager.callFunc("playQueue")
        return
    end if
    if isStringEqual(selectedItemType, "photoalbum")
        quickplay_photoAlbum(itemNode)
        m.global.queueManager.callFunc("playQueue")
        return
    end if
end sub

sub onCloseSidePanelEvent()
    group = m.global.sceneManager.callFunc("getActiveScene")
    if isValid(group.lastFocus)
        group.lastFocus.setFocus(true)
        if group.lastFocus.isSubType("JFOverhang")
            group.lastFocus.callFunc("highlightUser")
        end if
        return
    end if
    group.setFocus(true)
    group.lastFocus = group
end sub

sub onJumpToEvent(msg)
    if isValid(m.global.reentryGuardActive) and m.global.reentryGuardActive = true then
        return
    end if
    jumpToData = msg.getData()
    if not isValid(jumpToData) then
        return
    end if
    currentView = m.global.sceneManager.callFunc("getActiveScene")
    ' If current view is audio player, remove it from the scene stack so users can't press back to return to it
    if isStringEqual(currentView.subType(), "audioplayerview")
        m.global.sceneManager.callFunc("clearPreviousScene")
    end if
    if isStringEqual(jumpToData.selectiontype, "search")
        startLoadingSpinner()
        group = CreateSearchPage()
        if not isValid(group)
            stopLoadingSpinner()
        end if
        m.global.sceneManager.callFunc("pushScene", group)
        group.findNode("SearchBox").findNode("search_Key").setFocus(true)
        group = m.global.sceneManager.callFunc("getActiveScene")
        group.lastFocus = group.findNode("SearchBox").findNode("search_Key")
        group.findNode("SearchBox").findNode("search_Key").active = true
        stopLoadingSpinner()
    end if
    if isStringEqual(jumpToData.selectiontype, "settings")
        startLoadingSpinner()
        m.global.sceneManager.callFunc("settings")
        stopLoadingSpinner()
    end if
    if isStringEqual(jumpToData.selectiontype, "nowplaying")
        JumpIntoAudioPlayerView()
    end if
    if isStringEqual(jumpToData.selectiontype, "artist")
        startLoadingSpinner()
        group = CreateArtistView(jumpToData)
        if not isValid(group)
            stopLoadingSpinner()
            message_dialog(tr("Unable to find any albums or songs belonging to this artist"))
        end if
    end if
    if isStringEqual(jumpToData.selectiontype, "album")
        startLoadingSpinner()
        group = CreateAlbumView(jumpToData)
        if not isValid(group)
            stopLoadingSpinner()
        end if
    end if
    if isStringEqual(jumpToData.selectiontype, "genre")
        ' Set filter settings so library loads with selected genre as selected filter
        set_user_setting("display.jumpToFilter.landing", "albums")
        set_user_setting("display.jumpToFilter.filter", "Genres")
        set_user_setting("display.jumpToFilter.filterOptions", ("{" + chr(34) + "Genres" + chr(34) + ": " + chr(34) + bslib_toString(jumpToData.LookupCI("Name")) + chr(34) + "}"))
        libraryContent = CreateObject("roSGNode", "JFContentItem")
        libraryContent.type = "Music"
        libraryContent.json = {
            type: "collectionfolder"
            jumpToFilter: true
        }
        group = CreateMusicLibraryView(libraryContent)
        m.global.sceneManager.callFunc("pushScene", group)
    end if
    if isStringEqual(jumpToData.selectiontype, "releaseDate")
        ' Set filter settings so library loads with selected releaseDate as selected filter
        set_user_setting("display.jumpToFilter.landing", "albums")
        set_user_setting("display.jumpToFilter.filter", "Years")
        set_user_setting("display.jumpToFilter.filterOptions", ("{" + chr(34) + "Years" + chr(34) + ": " + chr(34) + bslib_toString(jumpToData.LookupCI("Name")) + chr(34) + "}"))
        libraryContent = CreateObject("roSGNode", "JFContentItem")
        libraryContent.type = "Music"
        libraryContent.json = {
            type: "collectionfolder"
            jumpToFilter: true
        }
        group = CreateMusicLibraryView(libraryContent)
        m.global.sceneManager.callFunc("pushScene", group)
    end if
end sub

sub onDeepLinkingEvent(args)
    if isValid(m.global.reentryGuardActive) and m.global.reentryGuardActive = true then
        return
    end if
    if not isValidAndNotEmpty(args) then
        return
    end if
    if not isValidAndNotEmpty(args.mediaType) then
        return
    end if
    if not isValidAndNotEmpty(args.contentId) then
        return
    end if
    startLoadingSpinner()
    m.global.queueManager.callFunc("clear") ' empty queue/playlist
    m.global.queueManager.callFunc("resetShuffle") ' turn shuffle off
    mediaType = LCase(args.mediaType)
    if inArray([
        "episode"
        "recording"
        "movie"
        "video"
    ], mediaType)
        quickplay_video({
            id: args.contentId
            type: mediaType
            json: {}
        })
        m.global.queueManager.callFunc("playQueue")
        return
    end if
    if mediaType = "audio"
        quickplay_audio({
            id: args.contentId
            type: mediaType
        })
        m.global.queueManager.callFunc("playQueue")
        return
    end if
    if mediaType = "audiobook"
        quickplay_audioBook({
            id: args.contentId
            type: mediaType
            json: {}
        })
        m.global.queueManager.callFunc("playQueue")
        return
    end if
    if mediaType = "musicalbum"
        quickplay_album({
            id: args.contentId
            type: mediaType
        })
        m.global.queueManager.callFunc("playQueue")
        return
    end if
    if mediaType = "musicartist"
        quickplay_artist({
            id: args.contentId
            type: mediaType
        })
        m.global.queueManager.callFunc("playQueue")
        return
    end if
    if mediaType = "series"
        quickplay_series({
            id: args.contentId
            type: mediaType
        })
        m.global.queueManager.callFunc("playQueue")
        return
    end if
    if mediaType = "season"
        if isValidAndNotEmpty(args.seriesID)
            quickplay_season({
                id: args.contentId
                type: mediaType
                json: {
                    SeriesId: args.seriesID
                }
            })
            m.global.queueManager.callFunc("playQueue")
            return
        else
            stopLoadingSpinner()
            dialog = createObject("roSGNode", "Dialog")
            dialog.id = "OKDialog"
            dialog.title = tr("Missing deep link argument")
            dialog.buttons = [
                tr("OK")
            ]
            dialog.message = "To play a season you must provide the seriesID"
            m.scene.dialog = dialog
            m.scene.dialog.observeField("buttonSelected", m.port)
        end if
    end if
    if mediaType = "boxset"
        quickplay_boxset({
            id: args.contentId
            type: mediaType
        })
        m.global.queueManager.callFunc("playQueue")
        return
    end if
    if mediaType = "collectionfolder"
        if isValidAndNotEmpty(args.collectionType)
            quickplay_collectionFolder({
                id: args.contentId
                type: mediaType
                collectionType: LCase(args.collectionType)
            })
            m.global.queueManager.callFunc("playQueue")
            return
        else
            stopLoadingSpinner()
            dialog = createObject("roSGNode", "Dialog")
            dialog.id = "OKDialog"
            dialog.title = tr("Missing deep link argument")
            dialog.buttons = [
                tr("OK")
            ]
            dialog.message = "To play a collection folder you must provide the collectionType"
            m.scene.dialog = dialog
            m.scene.dialog.observeField("buttonSelected", m.port)
        end if
    end if
    if mediaType = "playlist"
        quickplay_playlist({
            id: args.contentId
            type: mediaType
        })
        m.global.queueManager.callFunc("playQueue")
        return
    end if
    if mediaType = "userview"
        if isValidAndNotEmpty(args.collectionType)
            quickplay_userView({
                id: args.contentId
                type: mediaType
                collectionType: args.collectionType
            })
            m.global.queueManager.callFunc("playQueue")
            return
        else
            stopLoadingSpinner()
            dialog = createObject("roSGNode", "Dialog")
            dialog.id = "OKDialog"
            dialog.title = tr("Missing deep link argument")
            dialog.buttons = [
                tr("OK")
            ]
            dialog.message = "To play a userview you must provide the collectionType"
            m.scene.dialog = dialog
            m.scene.dialog.observeField("buttonSelected", m.port)
        end if
    end if
    if mediaType = "folder"
        quickplay_folder({
            id: args.contentId
            type: mediaType
        })
        m.global.queueManager.callFunc("playQueue")
        return
    end if
    if mediaType = "musicvideo"
        quickplay_musicVideo({
            id: args.contentId
            type: mediaType
            json: {}
        })
        m.global.queueManager.callFunc("playQueue")
        return
    end if
    if mediaType = "person"
        quickplay_person({
            id: args.contentId
            type: mediaType
        })
        m.global.queueManager.callFunc("playQueue")
        return
    end if
    if mediaType = "tvchannel"
        quickplay_tvChannel({
            id: args.contentId
            type: mediaType
        })
        m.global.queueManager.callFunc("playQueue")
        return
    end if
    if mediaType = "program"
        quickplay_program({
            id: args.contentId
            type: mediaType
            json: {
                ChannelId: ""
            }
        })
        m.global.queueManager.callFunc("playQueue")
        return
    end if
    if mediaType = "photo"
        photoContent = CreateObject("roSGNode", "ContentNode")
        photoContent.id = args.contentId
        quickplay_photo(photoContent)
        m.global.queueManager.callFunc("playQueue")
        return
    end if
    if mediaType = "photoalbum"
        quickplay_photoAlbum({
            id: args.contentId
            type: mediaType
        })
        m.global.queueManager.callFunc("playQueue")
        return
    end if
    stopLoadingSpinner()
    dialog = createObject("roSGNode", "Dialog")
    dialog.id = "OKDialog"
    dialog.title = tr("Media Type not supported")
    dialog.buttons = [
        tr("OK")
    ]
    dialog.message = "The passed media type is not supported"
    m.scene.dialog = dialog
    m.scene.dialog.observeField("buttonSelected", m.port)
end sub

sub onLibrarySelection(selectedItem)
    if isStringEqual(selectedItem.collectionType, "movies")
        group = CreateVisualLibraryScene(selectedItem, "movie")
        m.global.sceneManager.callFunc("pushScene", group)
        return
    end if
    if isStringEqual(selectedItem.collectionType, "tvshows")
        group = CreateVisualLibraryScene(selectedItem, "series")
        m.global.sceneManager.callFunc("pushScene", group)
        return
    end if
    if isStringEqual(selectedItem.collectionType, "musicvideos")
        group = CreateVisualLibraryScene(selectedItem, "musicvideo")
        m.global.sceneManager.callFunc("pushScene", group)
        return
    end if
    if isStringEqual(selectedItem.collectionType, "homevideos")
        group = CreateVisualLibraryScene(selectedItem, "photo")
        m.global.sceneManager.callFunc("pushScene", group)
        return
    end if
    if isStringEqual(selectedItem.collectionType, "boxsets")
        group = CreateVisualLibraryScene(selectedItem, "boxset")
        m.global.sceneManager.callFunc("pushScene", group)
        return
    end if
    if isStringEqual(selectedItem.collectionType, "music")
        group = CreateMusicLibraryView(selectedItem)
        m.global.sceneManager.callFunc("pushScene", group)
        return
    end if
    if isStringEqual(selectedItem.collectionType, "books")
        group = CreateBookLibraryView(selectedItem)
        m.global.sceneManager.callFunc("pushScene", group)
        return
    end if
    if isStringEqual(selectedItem.collectionType, "nextup")
        group = CreateOtherLibrary(selectedItem)
        group.optionsAvailable = false
        m.global.sceneManager.callFunc("pushScene", group)
        return
    end if
    if isStringEqual(selectedItem.collectionType, "mylist")
        group = CreateVisualLibraryScene(selectedItem, "mylist")
        m.global.sceneManager.callFunc("pushScene", group)
        return
    end if
    group = CreateOtherLibrary(selectedItem)
    m.global.sceneManager.callFunc("pushScene", group)
end sub

sub onRefreshSeasonDetailsDataEvent()
    startLoadingSpinner()
    currentScene = m.global.sceneManager.callFunc("getActiveScene")
    ' Refresh data over poster on TV Series Detail screen
    if currentScene.isSubType("TVSeriesDetails")
        seriesID = chainLookup(currentScene, "itemContent.id")
        if isValid(seriesID)
            ' Determine if the resume button needs to be shown
            resummableItem = getResummableItem(seriesID)
            displayResumeButton = isValid(resummableItem)
            currentScene.displayResumeButton = displayResumeButton
            if displayResumeButton
                currentScene.resumeTicks = resummableItem.UserData.PlaybackPositionTicks
            end if
            currentScene.itemContent = ItemMetaData(seriesID)
        end if
    else if currentScene.isSubType("TVSeasonDetails")
        seriesID = chainLookupReturn(currentScene, "seasonData.json.SeriesId", invalid)
        seasonID = chainLookupReturn(currentScene, "seasonData.id", invalid)
        if isAllValid([
            seasonID
            seriesID
        ])
            resummableItem = getResummableItem(seasonID)
            displayResumeButton = isValid(resummableItem)
            currentScene.displayResumeButton = displayResumeButton
            if displayResumeButton
                currentScene.resumeTicks = resummableItem.UserData.PlaybackPositionTicks
            end if
            episodeList = currentScene.findNode("picker")
            focusedItem = 0
            if isValid(episodeList)
                focusedItem = chainLookupReturn(episodeList, "itemFocused", 0)
            end if
            currentScene.objects = TVEpisodes(seriesID, seasonID)
            currentScene.episodeObjects = currentScene.objects
            if isValid(episodeList)
                episodeList.jumpToItem = focusedItem
            end if
        end if
    end if
    ' Update data over item user clicked on
    if isValid(currentScene)
        focusedItem = currentScene.callFunc("getFocusedItem")
        if isValid(focusedItem)
            focusedItem.json = api_items_GetByID(focusedItem.id, {
                userId: m.global.session.user.id
            })
        end if
    end if
    ' Update screen data if user started playing an item
    if isChainValid(currentScene, "objects") and isValid(currentScene.seasonData)
        currentEpisode = m.global.queueManager.callFunc("getCurrentItem")
        if isChainValid(currentScene, "objects.Items") and isChainValid(currentEpisode, "id")
            ' Find the object in the scene's data and update its json data
            for i = 0 to currentScene.objects.Items.count() - 1
                if isStringEqual(currentScene.objects.Items[i].id, currentEpisode.id)
                    currentScene.objects.Items[i].json = api_items_GetByID(currentEpisode.id, {
                        userId: m.global.session.user.id
                    })
                    m.global.queueManager.callFunc("setTopStartingPoint", currentScene.objects.Items[i].json.UserData.PlaybackPositionTicks)
                    exit for
                end if
            end for
        end if
        seasonMetaData = ItemMetaData(currentScene.seasonData.id)
        if isValid(seasonMetaData) then
            currentScene.seasonData = seasonMetaData.json
        end if
        currentScene.callFunc("updateObjects")
        currentScene.callFunc("updateSeason")
    end if
    stopLoadingSpinner()
end sub

sub onRefreshMovieDetailsDataEvent()
    ' Keep remote active during metadata refresh so a slow API call cannot hard-lock controls.
    startLoadingSpinner(false)
    canContinue = true
    currentScene = m.global.sceneManager.callFunc("getActiveScene")
    if isChainValid(currentScene, "itemContent")
        ' Check if the content ID has changed since we last rendered the movie detail view
        contentIDChanged = false
        lastKnownItemExtraType = m.global.queueManager.callFunc("getLastKnownItemExtraType")
        if isValid(lastKnownItemExtraType)
            canContinue = lastKnownItemExtraType = ""
        end if
        currentItem = m.global.queueManager.callFunc("getLastKnownItemID")
        if canContinue
            if isValid(currentItem)
                canContinue = currentItem <> ""
            end if
        end if
        if canContinue
            if isChainValid(currentScene, "itemContent.id") and currentScene.itemContent.id <> currentItem
                currentItemID = currentItem
                contentIDChanged = true
            else
                currentItemID = currentScene.itemContent.id
            end if
            itemData = ItemMetaData(currentItemID, false)
            ' Can't continue if invalid data was returned
            if not isChainValid(itemData, "json.MediaSources")
                stopLoadingSpinner()
                return
            end if
            if contentIDChanged
                currentScene.selectedVideoStreamId = itemData.json.MediaSources[0].id
                ' Refresh extras based on new content ID
                extrasGrid = currentScene.findNode("extrasGrid")
                if isValid(extrasGrid)
                    reloadExtras = true
                    ' If this is a multipart video, keep the original extras
                    additionalPartItemCount = chainLookup(currentScene, "additionalParts.parts.TotalRecordCount")
                    if isValid(additionalPartItemCount)
                        if additionalPartItemCount <> 0
                            reloadExtras = false
                        end if
                    end if
                    if reloadExtras
                        extrasGrid.callFunc("loadParts", itemData.json)
                    end if
                end if
            end if
            currentScene.itemContent = itemData
            ' Set updated starting point for the queue item
            m.global.queueManager.callFunc("setTopStartingPoint", itemData.json.UserData.PlaybackPositionTicks)
        end if
    end if
    stopLoadingSpinner()
end sub

' Queue movie metadata loading on a task so all entry points avoid render-thread stalls.
sub queueMovieDetailsLoad(movie as object)
    if not isValid(movie) or not isValid(movie.id)
        traceStep("MOVIE_TRACE", "queueMovieDetailsLoad invalid movie payload")
        stopLoadingSpinner()
        return
    end if
    traceStep("MOVIE_TRACE", "queueMovieDetailsLoad start id=" + movie.id)
    ' Ensure movie loading never keeps remote input disabled.
    if isValid(m.scene) and m.scene.isLoading and m.scene.disableRemote
        traceStep("MOVIE_TRACE", "queueMovieDetailsLoad clearing stale disableRemote lock")
        stopLoadingSpinner()
    end if
    startLoadingSpinner(false)
    if isValid(m.pendingMovieMetadataTask)
        traceStep("MOVIE_TRACE", "queueMovieDetailsLoad cancel previous metadata task")
        m.pendingMovieMetadataTask.unobserveField("content")
        m.pendingMovieMetadataTask.control = "STOP"
        m.pendingMovieMetadataTask = invalid
    end if
    m.pendingMovie = movie
    m.pendingMovieMetadataTask = CreateObject("roSGNode", "LoadItemsTask")
    if not isValid(m.pendingMovieMetadataTask)
        traceStep("MOVIE_TRACE", "queueMovieDetailsLoad failed to create LoadItemsTask")
        stopLoadingSpinner()
        return
    end if
    m.pendingMovieLoadTimer = CreateObject("roTimespan")
    if isValid(m.pendingMovieLoadTimer)
        m.pendingMovieLoadTimer.Mark()
    end if
    m.pendingMovieMetadataTask.itemsToLoad = "metaData"
    m.pendingMovieMetadataTask.itemId = movie.id
    m.pendingMovieMetadataTask.observeField("content", m.port)
    m.pendingMovieMetadataTask.control = "RUN"
    traceStep("MOVIE_TRACE", "queueMovieDetailsLoad metadata task RUN id=" + movie.id)
end sub

sub onSelectedItemEvent(msg)
    print "[REENTRY_GUARD] onSelectedItemEvent called"
    ' Check reentry guard to prevent auto-reentry after backing out
    if isValid(m.global.reentryGuardActive) and m.global.reentryGuardActive = true
        print "[REENTRY_GUARD] Guard is active, blocking selection"
        return
    end if
    print "[REENTRY_GUARD] Guard is not active, allowing selection"
    ' If you select a library from ANYWHERE, follow this flow
    selectedItem = msg.getData()
    if isValid(selectedItem)
        selectedItemType = selectedItem.type
        if isValid(selectedItemType)
            ' If button selected is a string, lcase it
            if isStringEqual(type(selectedItemType), "rostring") then
                selectedItemType = LCase(selectedItemType)
            end if
        end if
        if shouldSuppressDuplicateSelection(selectedItemType, selectedItem)
            print "[REENTRY_GUARD] Suppressing duplicate selectedItem event type=" + selectedItemType + " id=" + chainLookupReturn(selectedItem, "id", "invalid")
            return
        end if
        startLoadingSpinner(false)
        if isStringEqual(selectedItemType, "collectionfolder")
            onLibrarySelection(selectedItem)
        else if isStringEqual(selectedItemType, "boxset")
            group = CreateVisualLibraryScene(selectedItem, "boxset")
            m.global.sceneManager.callFunc("pushScene", group)
        else if isStringEqual(selectedItemType, "folder") and isStringEqual(selectedItem.json.type, "genre")
            ' User clicked on a genre folder
            if isStringEqual(selectedItem.itemType, "movie")
                group = CreateVisualLibraryScene(selectedItem, "movie")
            else if isStringEqual(selectedItem.itemType, "series")
                group = CreateVisualLibraryScene(selectedItem, "series")
            else if isStringEqual(selectedItem.itemType, "musicvideo")
                group = CreateVisualLibraryScene(selectedItem, "musicvideo")
            else if isStringEqual(selectedItem.itemType, (bslib_toString("musicvideo") + "," + bslib_toString("folder")))
                group = CreateVisualLibraryScene(selectedItem, "musicvideo")
            else
                group = CreateOtherLibrary(selectedItem)
            end if
            m.global.sceneManager.callFunc("pushScene", group)
        else if isStringEqual(selectedItemType, "folder") and isStringEqual(selectedItem.json.LookupCI("type"), "photoalbum")
            group = CreateVisualLibraryScene(selectedItem, "photoalbum")
            m.global.sceneManager.callFunc("pushScene", group)
        else if isStringEqual(selectedItemType, "tag")
            if not isValidAndNotEmpty(selectedItem.tagName)
                selectedItem.tagName = chainLookupReturn(selectedItem, "json.name", "")
            end if
            ' Set type so VisualLibraryScene recognizes this as a tag subfolder
            selectedItem.type = "tag"
            ' VisualLibraryScene looks for type in json.type first
            if not isValid(selectedItem.json)
                selectedItem.json = {}
            end if
            selectedItem.json.type = "tag"
            ' Use parentFolder that was set by VisualLibraryScene
            if isValidAndNotEmpty(selectedItem.parentFolder)
                selectedItem.json.parentFolder = selectedItem.parentFolder
            else
                selectedItem.json.parentFolder = " "
            end if
            group = CreateVisualLibraryScene(selectedItem, "movie")
            m.global.sceneManager.callFunc("pushScene", group)
        else if isStringEqual(selectedItemType, "folder") and isStringEqual(chainLookup(selectedItem, "json.passedData.collectiontype"), "musicvideo")
            group = CreateVisualLibraryScene(selectedItem, "musicvideo")
            m.global.sceneManager.callFunc("pushScene", group)
        else if selectedItemType = "folder" and LCase(type(selectedItem.json.type)) = "rostring" and isStringEqual(selectedItem.json.type, "musicgenre")
            group = CreateMusicLibraryView(selectedItem)
            m.global.sceneManager.callFunc("pushScene", group)
        else if selectedItemType = "userview" and isStringEqual(selectedItem.json.collectiontype, "livetv")
            group = CreateLiveTVLibraryView(selectedItem)
            m.global.sceneManager.callFunc("pushScene", group)
        else if selectedItemType = "userview" or selectedItemType = "folder" or selectedItemType = "channel"
            group = CreateOtherLibrary(selectedItem)
            m.global.sceneManager.callFunc("pushScene", group)
        else if selectedItemType = "episode" or selectedItemType = "recording"
            traceStep("MOVIE_TRACE", "onSelectedItemEvent video detail path type=" + selectedItemType + " id=" + selectedItem.id)
            queueMovieDetailsLoad(selectedItem)
        else if selectedItemType = "series"
            group = CreateSeriesDetailsGroup(selectedItem.json.id)
        else if selectedItemType = "season"
            if isValid(selectedItem.json) and isValid(selectedItem.json.SeriesId) and isValid(selectedItem.id)
                group = CreateSeasonDetailsGroupByID(selectedItem.json.SeriesId, selectedItem.id)
            else
                stopLoadingSpinner()
                message_dialog(tr("Error loading Season"))
            end if
        else if selectedItemType = "movie"
            traceStep("MOVIE_TRACE", "onSelectedItemEvent movie path id=" + selectedItem.id)
            queueMovieDetailsLoad(selectedItem)
        else if selectedItemType = "person"
            CreatePersonView(selectedItem)
        else if selectedItemType = "tvchannel" or selectedItemType = "video" or selectedItemType = "program"
            ' User selected a Live TV channel / program
            ' Show Channel Loading spinner
            dialog = createObject("roSGNode", "ProgressDialog")
            dialog.title = tr("Loading Channel Data")
            m.scene.dialog = dialog
            ' User selected a program. Play the channel the program is on
            if selectedItemType = "program"
                selectedItem.id = selectedItem.json.LookupCI("ChannelId")
            end if
            ' Display playback options dialog
            showPlaybackOptionDialog = false
            if isValid(selectedItem.json)
                if isValid(selectedItem.json.userdata)
                    if isValid(selectedItem.json.userdata.PlaybackPositionTicks)
                        if selectedItem.json.userdata.PlaybackPositionTicks > 0
                            showPlaybackOptionDialog = true
                        end if
                    end if
                end if
            end if
            if showPlaybackOptionDialog
                dialog.close = true
                m.global.queueManager.callFunc("hold", selectedItem)
                playbackOptionDialog(selectedItem.json.userdata.PlaybackPositionTicks, selectedItem.json)
            else
                m.global.queueManager.callFunc("clear")
                m.global.queueManager.callFunc("push", selectedItem)
                m.global.queueManager.callFunc("playQueue")
                dialog.close = true
            end if
        else if selectedItemType = "photo"
            sceneNode = msg.getRoSGNode()
            if sceneNode.isSubType("VisualLibraryScene")
                photoPlayer = CreateObject("roSgNode", "PhotoDetails")
                photoPlayer.itemsNode = sceneNode.lastFocus
                photoPlayer.itemIndex = sceneNode.lastFocus.itemFocused
                m.global.sceneManager.callfunc("pushScene", photoPlayer)
            end if
            ' only handle selection if it's from the home screen
            if selectedItem.isSubType("HomeData")
                quickplay_photo(selectedItem)
            end if
        else if selectedItemType = "photoalbum"
            ' grab all photos inside photo album
            photoAlbumData = api_items_Get({
                "userid": m.global.session.user.id
                "parentId": selectedItem.id
                "includeItemTypes": "Photo"
                "Recursive": true
            })
            if isValid(photoAlbumData) and isValidAndNotEmpty(photoAlbumData.items)
                photoPlayer = CreateObject("roSgNode", "PhotoDetails")
                photoPlayer.itemsArray = photoAlbumData.items
                photoPlayer.itemIndex = 0
                m.global.sceneManager.callfunc("pushScene", photoPlayer)
            end if
        else if selectedItemType = "musicartist"
            group = CreateArtistView(selectedItem.json)
            if not isValid(group)
                stopLoadingSpinner()
                message_dialog(tr("Unable to find any albums or songs belonging to this artist"))
            end if
        else if selectedItemType = "musicalbum"
            CreateAlbumView(selectedItem.json)
        else if selectedItemType = "musicvideo"
            traceStep("MOVIE_TRACE", "onSelectedItemEvent musicvideo path id=" + selectedItem.id)
            queueMovieDetailsLoad(selectedItem)
        else if selectedItemType = "playlist"
            CreatePlaylistView(selectedItem.json)
        else if selectedItemType = "audio"
            m.global.queueManager.callFunc("clear")
            m.global.queueManager.callFunc("resetShuffle")
            m.global.queueManager.callFunc("push", selectedItem.json)
            m.global.queueManager.callFunc("playQueue")
        else if selectedItemType = "audiobook"
            ' Display playback options dialog
            showPlaybackOptionDialog = false
            if isValid(selectedItem.json)
                if isValid(selectedItem.json.userdata)
                    if isValid(selectedItem.json.userdata.PlaybackPositionTicks)
                        if selectedItem.json.userdata.PlaybackPositionTicks > 0
                            showPlaybackOptionDialog = true
                        end if
                    end if
                end if
            end if
            if showPlaybackOptionDialog
                m.global.queueManager.callFunc("hold", selectedItem)
                playbackOptionDialog(selectedItem.json.userdata.PlaybackPositionTicks, selectedItem.json)
            else
                m.global.queueManager.callFunc("clear")
                m.global.queueManager.callFunc("push", selectedItem.json)
                m.global.queueManager.callFunc("playQueue")
            end if
        else
            ' TODO - switch on more node types
            stopLoadingSpinner()
            message_dialog("This type is not yet supported: " + selectedItemType)
        end if
    end if
end sub

function shouldSuppressDuplicateSelection(selectedItemType as dynamic, selectedItem as dynamic) as boolean
    if not isValidAndNotEmpty(selectedItemType) then
        return false
    end if
    selectedId = chainLookupReturn(selectedItem, "id", "")
    if not isValidAndNotEmpty(selectedId) then
        return false
    end if
    if not isValid(m.selectedItemDedupeClock)
        m.selectedItemDedupeClock = CreateObject("roTimespan")
        m.selectedItemDedupeClock.Mark()
        m.lastSelectedItemType = selectedItemType
        m.lastSelectedItemId = selectedId
        m.lastSelectedItemMs = 0
        return false
    end if
    nowMs = m.selectedItemDedupeClock.TotalMilliseconds()
    lastMs = chainLookupReturn(m, "lastSelectedItemMs", -1000000)
    isDuplicate = isStringEqual(chainLookupReturn(m, "lastSelectedItemType", ""), selectedItemType) and isStringEqual(chainLookupReturn(m, "lastSelectedItemId", ""), selectedId) and ((nowMs - lastMs) <= 750)
    m.lastSelectedItemType = selectedItemType
    m.lastSelectedItemId = selectedId
    m.lastSelectedItemMs = nowMs
    return isDuplicate
end function

' Called when the preloaded movie metadata task finishes.
sub onMovieMetadataPreloaded()
    if not isValid(m.pendingMovieMetadataTask)
        traceStep("MOVIE_TRACE", "onMovieMetadataPreloaded called with invalid pending task")
        return
    end if
    elapsedMs = "n/a"
    if isValid(m.pendingMovieLoadTimer)
        elapsedMs = stri(m.pendingMovieLoadTimer.TotalMilliseconds()).trim()
    end if
    result = m.pendingMovieMetadataTask.content
    m.pendingMovieMetadataTask.unobserveField("content")
    m.pendingMovieMetadataTask = invalid
    movie = m.pendingMovie
    m.pendingMovie = invalid
    movieId = "invalid"
    if isValid(movie) and isValid(movie.id)
        movieId = movie.id
    end if
    resultCount = 0
    if isValid(result)
        resultCount = result.Count()
    end if
    traceStep("MOVIE_TRACE", "onMovieMetadataPreloaded received id=" + movieId + " resultCount=" + stri(resultCount).trim() + " elapsedMs=" + elapsedMs)
    if not isValidAndNotEmpty(result) or not isValid(result[0])
        traceStep("MOVIE_TRACE", "onMovieMetadataPreloaded invalid result id=" + movieId)
        stopLoadingSpinner()
        return
    end if
    stopLoadingSpinner()
    traceStep("MOVIE_TRACE", "onMovieMetadataPreloaded creating MovieDetails scene id=" + movieId)
    CreateMovieDetailsGroup(movie, result[0])
    traceStep("MOVIE_TRACE", "onMovieMetadataPreloaded scene create returned id=" + movieId)
end sub

sub onMovieSelectedEvent(msg)
    if isValid(m.global.reentryGuardActive) and m.global.reentryGuardActive = true then
        return
    end if
    node = getMsgPicker(msg, "picker")
    queueMovieDetailsLoad(node)
end sub

sub onSeriesSelectedEvent(msg)
    if isValid(m.global.reentryGuardActive) and m.global.reentryGuardActive = true then
        return
    end if
    startLoadingSpinner()
    node = getMsgPicker(msg, "picker")
    CreateSeriesDetailsGroup(node.id)
end sub

sub onSeasonSelectedEvent(msg)
    if isValid(m.global.reentryGuardActive) and m.global.reentryGuardActive = true then
        return
    end if
    startLoadingSpinner()
    ptr = msg.getData()
    series = msg.getRoSGNode()
    if not isValid(series.seasonData)
        stopLoadingSpinner()
        return
    end if
    if series.seasonData.getChildCount() = 0
        stopLoadingSpinner()
        return
    end if
    node = series.seasonData.getChild(ptr)
    CreateSeasonDetailsGroup(series.itemContent, node)
end sub

' Find the 1st episode in the series and start playback
sub onPlaySeriesFromStartEvent(msg)
    series = msg.getRoSGNode()
    if not isChainValid(series, "itemContent.id") then
        return
    end if
    if not isValid(series.seasonData) then
        return
    end if
    seasons = series.seasonData.getChildren(-1, 0)
    if seasons.count() = 0 then
        return
    end if
    ' Fall back to playing specials if that's all that is available
    firstSeasonIndex = 0
    ' Loop through the season data and find the first season with a season number greater than 0
    for i = 0 to seasons.count() - 1
        if seasons[i].json.IndexNumber > 0
            firstSeasonIndex = i
            exit for
        end if
    end for
    firstSeasonData = seasons[firstSeasonIndex]
    if not isChainValid(firstSeasonData, "json.id") then
        return
    end if
    startLoadingSpinner()
    firstEpisode = api_shows_GetEpisodes(series.itemContent.id, {
        "seasonId": firstSeasonData.json.id
        "userid": m.global.session.user.id
        "limit": 1
        "EnableTotalRecordCount": false
        "isMissing": false
    })
    if not isChainValid(firstEpisode, "items")
        stopLoadingSpinner()
        return
    end if
    m.global.queueManager.callFunc("clear")
    m.global.queueManager.callFunc("push", firstEpisode.items[0])
    m.global.queueManager.callFunc("playQueue")
end sub

' Find the 1st episode in the series and start playback
sub onPlaySeasonFromStartEvent(msg)
    season = msg.getRoSGNode()
    seriesID = chainLookupReturn(season, "seasonData.json.SeriesId", invalid)
    seasonID = chainLookupReturn(season, "seasonData.id", invalid)
    shufflePlay = chainLookupReturn(season, "shufflePlay", false)
    if not isAllValid([
        seriesID
        seasonID
    ]) then
        return
    end if
    startLoadingSpinner()
    listOfEpisodes = api_shows_GetEpisodes(seriesID, {
        "seasonId": seasonID
        "userid": m.global.session.user.id
        "EnableTotalRecordCount": false
        "SortBy": bslib_ternary(shufflePlay, "Random", "SortName")
        "isMissing": false
    })
    if not isChainValid(listOfEpisodes, "items")
        stopLoadingSpinner()
        return
    end if
    m.global.queueManager.callFunc("clear")
    m.global.queueManager.callFunc("set", listOfEpisodes.items)
    m.global.queueManager.callFunc("playQueue")
end sub

sub onMusicAlbumSelectedEvent(msg)
    if isValid(m.global.reentryGuardActive) and m.global.reentryGuardActive = true then
        return
    end if
    startLoadingSpinner()
    ptr = msg.getData()
    albums = msg.getRoSGNode()
    node = albums.musicArtistAlbumData.getChild(ptr)
    group = CreateAlbumView(node)
    if not isValid(group)
        stopLoadingSpinner()
    end if
end sub

sub onAppearsOnSelectedEvent(msg)
    if isValid(m.global.reentryGuardActive) and m.global.reentryGuardActive = true then
        return
    end if
    startLoadingSpinner()
    ptr = msg.getData()
    albums = msg.getRoSGNode()
    node = albums.musicArtistAppearsOnData.getChild(ptr)
    group = CreateAlbumView(node)
    if not isValid(group)
        stopLoadingSpinner()
    end if
end sub

sub onSimilarArtistSelectedEvent(msg)
    startLoadingSpinner()
    ptr = msg.getData()
    group = CreateArtistView(ptr.json)
    if not isValid(group)
        stopLoadingSpinner()
    end if
end sub

sub onPlayAlbumEvent(msg)
    if isValid(m.global.reentryGuardActive) and m.global.reentryGuardActive = true then
        return
    end if
    startLoadingSpinner()
    screenContent = msg.getRoSGNode()
    m.global.queueManager.callFunc("resetShuffle")
    m.global.queueManager.callFunc("set", screenContent.albumData.getChildren(-1, 0))
    m.global.queueManager.callFunc("playQueue")
end sub

sub onShuffleAlbumEvent(msg)
    if isValid(m.global.reentryGuardActive) and m.global.reentryGuardActive = true then
        return
    end if
    startLoadingSpinner()
    screenContent = msg.getRoSGNode()
    m.global.queueManager.callFunc("set", screenContent.albumData.getChildren(-1, 0))
    m.global.queueManager.callFunc("setShuffle", true)
    m.global.queueManager.callFunc("playQueue")
end sub

sub onPlaySongEvent(msg)
    if isValid(m.global.reentryGuardActive) and m.global.reentryGuardActive = true then
        return
    end if
    ' User has selected audio they want us to play
    startLoadingSpinner()
    selectedIndex = msg.getData()
    screenContent = msg.getRoSGNode()
    m.global.queueManager.callFunc("resetShuffle")
    m.global.queueManager.callFunc("set", screenContent.albumData.getChildren(-1, 0))
    m.global.queueManager.callFunc("setPosition", selectedIndex)
    m.global.queueManager.callFunc("playQueue")
end sub

sub onSubtitleToDeleteEvent(msg)
    subtitleData = msg.getData()
    screenContent = msg.getRoSGNode()
    mySubtitleList = screenContent.findNode("mySubtitleList")
    if isAllValid([
        subtitleData
        screenContent
        mySubtitleList
    ])
        if isAllValid([
            screenContent.itemContent.id
            subtitleData.index
            mySubtitleList.content
        ])
            ' Ask the user for confirmation before deleting subtitle file
            returnValue = show_dialog(tr("Are you sure you want to delete this subtitle?"), [
                tr("Yes")
                tr("No, Cancel")
            ], 1)
            ' User chose Yes from confirmation dialog
            if returnValue = 0
                ' Call delete subtitle API
                api_videos_DeleteSubtitle(screenContent.itemContent.id, subtitleData.index)
                ' We now need to remove the deleted subtitle from the My Subtitles list
                ' and subtract 1 from all indexs higher than the one we deleted
                subtitleListContent = mySubtitleList.content.getChildren(-1, 0)
                i = 0
                for each subtitle in subtitleListContent
                    ' Remove subtitle from My Subtitles list
                    if subtitle.index = subtitleData.index
                        mySubtitleList.content.removeChild(subtitle)
                    end if
                    ' Subtract 1 from indexes higher than deleted subtitle's index
                    if subtitle.index > subtitleData.index
                        subtitle.index--
                        mySubtitleList.content.replaceChild(subtitle, i)
                    end if
                    i++
                end for
            end if
            ' If there remain subtitles in My Subtitles list, set focus back to list
            ' Otherwise, set focus back to Search button
            if mySubtitleList.content.getChildCount() > 0
                mySubtitleList.setFocus(true)
                group = m.global.sceneManager.callFunc("getActiveScene")
                group.lastFocus = mySubtitleList
            else
                searchButton = screenContent.findNode("searchButton")
                if isValid(searchButton)
                    searchButton.focus = true
                    searchButton.setFocus(true)
                    group = m.global.sceneManager.callFunc("getActiveScene")
                    group.lastFocus = searchButton
                end if
            end if
        end if
    end if
end sub

sub onSubtitleSearchButtonSelectedEvent()
    group = m.global.sceneManager.callFunc("getActiveScene")
    if isValid(group)
        if isAllValid([
            group.itemContent
            group.selectedCulture
        ])
            if isAllValid([
                group.itemContent.id
                group.selectedCulture.ThreeLetterISOLanguageName
            ])
                ' Get remote subtitles from API
                remoteSubtitles = api_items_SearchRemoteSubtitles(group.itemContent.id, group.selectedCulture.ThreeLetterISOLanguageName)
                if isValid(remoteSubtitles)
                    remoteSubtitleData = {
                        data: []
                    }
                    ' Populate data for remote subtitle dialog
                    for each remoteSubtitle in remoteSubtitles
                        remoteSubtitle.type = "remotesubtitleselect"
                        remoteSubtitle.track = {}
                        remoteSubtitle.track.description = remoteSubtitle.Name
                        remoteSubtitleData.data.push(remoteSubtitle)
                    end for
                    m.global.sceneManager.callFunc("remoteSubtitleDialog", tr("Download Subtitle"), remoteSubtitleData)
                    m.global.sceneManager.observeField("returnData", m.port)
                end if
            end if
        end if
    end if
end sub

sub onSubtitleLanguageButtonSelectedEvent()
    languageData = {
        data: []
    }
    ' Default to user's default subtitle language
    selectedCulture = "eng"
    group = m.global.sceneManager.callFunc("getActiveScene")
    if isValid(group)
        if isValid(group.selectedCulture)
            if isValidAndNotEmpty(group.selectedCulture.ThreeLetterISOLanguageName)
                selectedCulture = LCase(group.selectedCulture.ThreeLetterISOLanguageName)
            end if
        end if
    end if
    for each culture in group.cultures
        culture.type = "cultureselect"
        culture.Track = {}
        culture.Track.description = culture.displayname
        ' Put preferred subtitle language at the top of the language list
        if isValidAndNotEmpty(culture.ThreeLetterISOLanguageName)
            if LCase(culture.ThreeLetterISOLanguageName) = selectedCulture
                culture.selected = true
                languageData.data.unshift(culture)
            else
                languageData.data.push(culture)
            end if
        else
            languageData.data.push(culture)
        end if
    end for
    m.global.sceneManager.callFunc("radioDialog", tr("Select Language"), languageData)
    m.global.sceneManager.observeField("returnData", m.port)
end sub

' User clicked on an item from a playlist
sub onPlaylistItemSelectedEvent(msg)
    if isValid(m.global.reentryGuardActive) and m.global.reentryGuardActive = true then
        return
    end if
    startLoadingSpinner()
    selectedIndex = msg.getData()
    screenContent = msg.getRoSGNode()
    MainAction_playItem(screenContent.listData.getChildren(-1, 0), {
        method: "set"
        resetShuffle: true
        position: selectedIndex
    })
end sub

sub onPlayArtistSelectedEvent(msg)
    if isValid(m.global.reentryGuardActive) and m.global.reentryGuardActive = true then
        return
    end if
    ' User has selected playlist of of audio they want us to play
    startLoadingSpinner()
    screenContent = msg.getRoSGNode()
    artistMixList = CreateArtistMix(chainLookup(screenContent, "pageContent.id"))
    if isChainValid(artistMixList, "items")
        MainAction_playItem(artistMixList.LookupCI("Items"), {
            method: "set"
            resetShuffle: true
        })
    else
        stopLoadingSpinner()
    end if
end sub

' User has selected instant mix
sub onInstantMixSelectedEvent(msg)
    if isValid(m.global.reentryGuardActive) and m.global.reentryGuardActive = true then
        return
    end if
    screenContent = msg.getRoSGNode()
    startLoadingSpinner()
    ' Create instant mix based on selected album
    if isValid(screenContent.albumData)
        if screenContent.albumData.getChildCount() > 0
            instantMixList = CreateInstantMix(screenContent.albumData.getChild(0).id)
            if isChainValid(instantMixList, "items")
                MainAction_playItem(instantMixList.LookupCI("Items"), {
                    method: "set"
                    resetShuffle: true
                })
            else
                stopLoadingSpinner()
            end if
            return
        end if
    end if
    ' Create instant mix based on selected artist
    instantMixList = CreateInstantMix(chainLookup(screenContent, "pageContent.id"))
    if isChainValid(instantMixList, "items")
        MainAction_playItem(instantMixList.LookupCI("Items"), {
            method: "set"
            resetShuffle: true
        })
    else
        stopLoadingSpinner()
    end if
end sub

sub onSearch_valueEvent(msg)
    query = msg.getRoSGNode().search_value
    group = m.global.sceneManager.callFunc("getActiveScene")
    group.findNode("SearchBox").visible = false
    options = group.findNode("searchRow")
    options.visible = true
    options.setFocus(true)
    dialog = createObject("roSGNode", "ProgressDialog")
    dialog.title = tr("Loading Search Data")
    m.scene.dialog = dialog
    results = SearchMedia(query)
    dialog.close = true
    options.itemData = results
    options.query = query
end sub

' Search item selected
sub onItemSelectedEvent(msg)
    if isValid(m.global.reentryGuardActive) and m.global.reentryGuardActive = true then
        return
    end if
    startLoadingSpinner(false)
    node = getMsgPicker(msg)
    if isStringEqual(node.type, "series")
        CreateSeriesDetailsGroup(node.id)
    else if isStringEqual(node.type, "movie")
        queueMovieDetailsLoad(node)
    else if isStringEqual(node.type, "musicartist")
        CreateArtistView(node.json)
    else if isStringEqual(node.type, "musicalbum")
        CreateAlbumView(node.json)
    else if isStringEqual(node.type, "playlist")
        CreatePlaylistView(node.json)
    else if isStringEqual(node.type, "musicvideo")
        queueMovieDetailsLoad(node)
    else if isStringEqual(node.type, "audio")
        MainAction_playItem(node.json, {
            resetShuffle: true
        })
    else if isStringEqual(node.type, "person")
        CreatePersonView(node)
    else if isStringEqual(node.type, "tvchannel") or isStringEqual(node.type, "program")
        thisItem = {
            id: node.id
            type: "video"
        }
        MainAction_playItem(thisItem, {
            resetShuffle: true
        })
    else if isStringEqual(node.type, "episode")
        queueMovieDetailsLoad(node)
    else if isStringEqual(node.type, "recording")
        thisItem = {
            id: node.id
            type: "Episode"
        }
        MainAction_playItem(thisItem, {
            resetShuffle: true
        })
    else if isStringEqual(node.type, "audiobook")
        MainAction_playItem(node.json, {
            resetShuffle: true
        })
    else
        stopLoadingSpinner()
        message_dialog("This type is not yet supported: " + node.type + ".")
    end if
end sub

sub onContentEvent(msg)
    node = msg.getRoSGNode()
    if not isValid(node) then
        return
    end if
    m.playlistData = msg.getData()
    popupData = []
    if isValidAndNotEmpty(m.playlistData)
        popupData.push(tr("Existing Playlist"))
    end if
    popupData.push(tr("New Playlist"))
    stopLoadingSpinner()
    m.global.sceneManager.callFunc("optionDialog", "playlist", tr("Add To Playlist"), [], popupData, {
        id: node.itemId
    })
end sub

sub onButtonSelectedEvent(msg)
    ' If a button is selected, we have some determining to do
    btn = msg.getData()
    activeScene = m.global.sceneManager.callFunc("getActiveScene")
    if not isValid(btn) or isStringEqual(type(btn), "roInt")
        MainAction_closeOKDialog(msg)
        return
    end if
    traceStep("PLAY_TRACE", "MainEventHandlers.onButtonSelectedEvent btn=" + btn)
    ' User chose Play button from movie detail view
    if isStringEqual(btn, "play-button")
        traceStep("PLAY_TRACE", "MainEventHandlers.onButtonSelectedEvent routing to onPlayButtonClicked")
        MainAction_onPlayButtonClicked(activeScene)
        return
    end if
    ' User chose Resume button from movie detail view
    if isStringEqual(btn, "resume-button")
        traceStep("PLAY_TRACE", "MainEventHandlers.onButtonSelectedEvent routing to onPlayButtonClicked with resume=true")
        if isChainValid(activeScene, "resumePlayback")
            activeScene.resumePlayback = true
        end if
        MainAction_onPlayButtonClicked(activeScene)
        return
    end if
    if isStringEqual(btn, "part-button")
        MainAction_onPartButtonClicked(activeScene)
        return
    end if
    ' User chose to play a trailer from the movie detail view
    if isStringEqual(btn, "trailer-button")
        MainAction_onTrailerButtonClicked(activeScene)
        return
    end if
    ' Toggle watched state
    if isStringEqual(btn, "watched-button")
        MainAction_onWatchedButtonClicked(activeScene)
        return
    end if
    ' Toggle item in My List
    if isStringEqual(btn, "mylist-button")
        MainAction_onMyListButtonClicked(activeScene)
        return
    end if
    ' Add to playlist button was clicked
    if isStringEqual(btn, "playlist-button")
        MainAction_onPlaylistButtonClicked(activeScene)
        return
    end if
    ' Toggle favorite state
    if isStringEqual(btn, "favorite-button")
        MainAction_onFavoriteButtonClicked(activeScene)
        return
    end if
    if isStringEqual(btn, "editsubtitlesbutton")
        MainAction_onEditSubtitlesButtonClicked(activeScene)
        return
    end if
    if isStringEqual(btn, "goToSeasonButton")
        MainAction_onGoToSeasonButtonClicked(activeScene)
        return
    end if
    if isStringEqual(btn, "goToSeriesButton")
        MainAction_onGoToSeriesButtonClicked(activeScene)
        return
    end if
    MainAction_closeOKDialog(msg)
end sub

sub onStateEvent(msg)
    node = msg.getRoSGNode()
    if not isChainValid(node, "state") then
        return
    end if
    if isStringEqual(node.state, "finished")
        if isStringEqual(node.selectedItemType, "tvchannel")
            thisItem = {
                id: node.id
                type: "recording"
            }
            MainAction_playItem(thisItem, {
                resetShuffle: true
            })
            return
        end if
        node.control = "STOP"
        ' If node allows retrying using Transcode Url, give that shot
        if isValid(node.retryWithTranscoding) and node.retryWithTranscoding
            thisItem = {
                id: node.id
                type: m.global.queueManager.callFunc("getCurrentItem").type
            }
            ' Force server-side transcoding so the retry does not loop back into
            ' direct play (which already failed) and trigger the compatibility
            ' warning dialog a second time, causing the 0% loading spinner stall.
            m.global.queueManager.callFunc("setForceTranscode", "forceTranscodeDisableRemux")
            MainAction_playItem(thisItem, {
                resetShuffle: true
            })
            return
        end if
        if not isValid(node.showID)
            m.global.sceneManager.callFunc("popScene")
        end if
    end if
end sub

' https://developer.roku.com/en-ca/docs/references/brightscript/events/rodeviceinfoevent.md
sub onRoDeviceInfoEvent(msg)
    event = msg.GetInfo()
    if event.exitedScreensaver = true
        group = m.global.sceneManager.callFunc("getActiveScene")
        if isValid(group)
            ' refresh the current view
            if group.isSubType("JFScreen")
                group.callFunc("OnScreenShown")
            end if
        end if
        return
    end if
    if isValid(event.audioGuideEnabled)
        tmpGlobalDevice = m.global.device
        tmpGlobalDevice.AddReplace("isaudioguideenabled", event.audioGuideEnabled)
        ' update global device array
        m.global.setFields({
            device: tmpGlobalDevice
        })
        return
    end if
    if isValid(event.generalMemoryLevel)
        print "event.generalMemoryLevel = ", event.generalMemoryLevel
        return
    end if
    if isValid(event.audioCodecCapabilityChanged)
        print "event.audioCodecCapabilityChanged = ", event.audioCodecCapabilityChanged
        postTask = createObject("roSGNode", "PostTask")
        postTask.arrayData = getDeviceCapabilities()
        postTask.apiUrl = "/Sessions/Capabilities/Full"
        postTask.control = "RUN"
        return
    end if
    if isValid(event.videoCodecCapabilityChanged)
        print "event.videoCodecCapabilityChanged = ", event.videoCodecCapabilityChanged
        postTask = createObject("roSGNode", "PostTask")
        postTask.arrayData = getDeviceCapabilities()
        postTask.apiUrl = "/Sessions/Capabilities/Full"
        postTask.control = "RUN"
        return
    end if
end sub

sub onReturnDataEvent(msg)
    ' User has chosen an option in a radio dialog
    popupNode = msg.getData()
    activeScene = m.global.sceneManager.callFunc("getActiveScene")
    if not isValid(activeScene) then
        return
    end if
    if not isChainValid(popupNode, "type") then
        return
    end if
    if isStringEqual(popupNode.type, "partselect")
        m.global.sceneManager.unobserveField("returnData")
        activeScene.selectedPart = popupNode
        m.global.sceneManager.callFunc("dismissDialog")
        return
    end if
    if isStringEqual(popupNode.type, "cultureselect")
        activeScene.selectedCulture = popupNode
        m.global.sceneManager.callFunc("dismissDialog")
        return
    end if
    if isStringEqual(popupNode.type, "remotesubtitleselect")
        if not isValid(popupNode.id) then
            return
        end if
        mySubtitleList = activeScene.findNode("mySubtitleList")
        ' Add downloading message to My Subtitles so users know we're processing their input
        if isValid(mySubtitleList)
            subtitleListContent = mySubtitleList.LookupCI("content")
            canAddSubtitle = true
            ' Search list of subtitles to see if we already have a downloading message for this item
            for each subtitle in subtitleListContent.getChildren(-1, 0)
                if subtitle.LookupCI("index") = -1
                    if isStringEqual(subtitle.LookupCI("displaytitle"), popupNode.LookupCI("name"))
                        canAddSubtitle = false
                    end if
                end if
            end for
            ' Don't add multiple downloading message for the same subtitle name
            if canAddSubtitle
                mySubtitle = CreateObject("roSGNode", "SubtitleData")
                mySubtitle.path = tr("Downloading - Refresh for updated status")
                mySubtitle.index = -1
                mySubtitle.displaytitle = popupNode.LookupCI("name")
                mySubtitle.canDelete = false
                subtitleListContent.insertChild(mySubtitle, 0)
                mySubtitleList.content = subtitleListContent
                api_items_DownloadRemoteSubtitles(chainLookup(activeScene, "itemContent.id"), popupNode.LookupCI("id"))
            end if
        end if
        ' Prevent double fires
        popupNode.id = invalid
    end if
end sub

sub onDataReturnedEvent(msg)
    popupNode = msg.getRoSGNode()
    stopLoadingSpinner()
    if not isChainValid(popupNode, "returnData")
        print "[DIALOG] No returnData in popupNode"
        return
    end if
    selectedPopupID = chainLookup(popupNode, "returndata.id")
    itemID = chainLookup(popupNode, "returndata.itemID")
    params = chainLookup(popupNode, "returndata.params")
    selectedPopupAction = chainLookup(popupNode, "returndata.indexselected")
    selectedPopupButton = chainLookup(popupNode, "returndata.buttonselected")
    print "[DIALOG] Popup ID: " + selectedPopupID + " Action: " + stri(selectedPopupAction).trim()
    if isStringEqual(selectedPopupID, "newPlaylist")
        newPlaylistName = chainLookup(popupNode, "returndata.text")
        if not isValidAndNotEmpty(newPlaylistName) then
            return
        end if
        api_playlists_Create({
            name: newPlaylistName
            ids: itemID
            users: [
                {
                    userid: m.global.session.user.id
                    canedit: true
                }
            ]
            userId: m.global.session.user.id
            IsPublic: false
        })
        return
    end if
    if isStringEqual(selectedPopupID, "existingPlaylist")
        ' Check if user pressed back and didn't select anything
        if isStringEqual(selectedPopupButton, "") then
            return
        end if
        api_playlists_Add(selectedPopupButton.id, {
            ids: itemID
            userId: m.global.session.user.id
        })
        return
    end if
    if isStringEqual(selectedPopupID, "playback")
        print "[DIALOG] Processing playback dialog"
        selectedItem = m.global.queueManager.callFunc("getHold")
        m.global.queueManager.callFunc("clearHold")
        if not isValidAndNotEmpty(selectedItem) or not isValid(selectedItem[0])
            print "[DIALOG] No held item for playback"
            return
        end if
        print "[DIALOG] Calling processPlaybackPopup with action: " + stri(selectedPopupAction).trim()
        processPlaybackPopup(selectedPopupAction, selectedItem)
        return
    end if
    if isStringEqual(selectedPopupID, "searchLibrary")
        searchTerm = chainLookup(popupNode, "returndata.text")
        if not isValid(searchTerm) then
            return
        end if
        activeScene = m.global.sceneManager.callFunc("getActiveScene")
        if not isValid(activeScene) then
            return
        end if
        activeScene.searchTerm = searchTerm
        return
    end if
    if isStringEqual(selectedPopupID, "libraryitem")
        if not isValid(itemID) then
            return
        end if
        if not isString(selectedPopupButton) then
            return
        end if
        processLibraryItemPopup(selectedPopupButton, itemID, params)
        return
    end if
    if isStringEqual(selectedPopupID, "stillwatching")
        if not isString(selectedPopupButton) then
            return
        end if
        processStillWatchingPopup(selectedPopupButton)
        return
    end if
    if isStringEqual(selectedPopupID, "playlist")
        if not isValid(itemID) then
            return
        end if
        processPlaylistPopup(selectedPopupButton, itemID)
        return
    end if
    if isStringEqual(selectedPopupID, "delete_item")
        print "[DIALOG] Processing delete_item dialog, action: " + stri(selectedPopupAction).trim() + " itemID: " + itemID
        ' User chose "Delete" (index 1)
        if selectedPopupAction = 1
            if isValidAndNotEmpty(itemID)
                print "[DIALOG] Calling ItemDelete for id: " + itemID
                deleteResult = ItemDelete(itemID)
                print "[DIALOG] ItemDelete result: " + deleteResult.toStr()
                if deleteResult
                    m.global.sceneManager.callFunc("popScene")
                else
                    m.global.sceneManager.callFunc("standardDialog", tr("Error"), tr("Failed to delete item."))
                end if
            else
                print "[DIALOG] Invalid itemID for delete"
            end if
        else
            print "[DIALOG] User cancelled delete (action <> 1)"
        end if
        return
    end if
end sub

sub processPlaybackPopup(selectedPopupAction as integer, selectedItem as object)
    'Resume video from resume point
    if selectedPopupAction = 0
        selectedItem[0].startingPoint = (function(chainLookup, selectedItem)
                __bsConsequent = chainLookup(selectedItem[0], "json.UserData.PlaybackPositionTicks")
                if __bsConsequent <> invalid then
                    return __bsConsequent
                else
                    return 0
                end if
            end function)(chainLookup, selectedItem)
        MainAction_playItem(selectedItem[0], {
            method: "push"
            bypassNextPreferredAudioTrackIndexReset: true
        })
        return
    end if
    'Start Over from beginning selected, set position to 0
    if selectedPopupAction = 1
        selectedItem[0].startingPoint = 0
        MainAction_playItem(selectedItem[0], {
            method: "push"
            bypassNextPreferredAudioTrackIndexReset: true
        })
        return
    end if
    ' User chose Go to series
    if selectedPopupAction = 2
        CreateSeriesDetailsGroup(chainLookup(selectedItem[0], "json.SeriesId"))
        return
    end if
    ' User chose Go to season
    if selectedPopupAction = 3
        seriesID = chainLookup(selectedItem[0], "json.SeriesId")
        seasonID = chainLookup(selectedItem[0], "json.seasonID")
        if isAllValid([
            seriesID
            seasonID
        ])
            CreateSeasonDetailsGroupByID(seriesID, seasonID)
        else
            message_dialog(tr("Error loading Season"))
        end if
        return
    end if
    ' User chose Go to episode
    if selectedPopupAction = 4
        queueMovieDetailsLoad(selectedItem[0])
        return
    end if
end sub

sub processStillWatchingPopup(selectedPopupButton as string)
    if isStringEqual(selectedPopupButton, tr("Yes, continue"))
        m.global.sceneManager.callFunc("clearPreviousScene")
        m.global.queueManager.callFunc("moveForward")
        m.global.queueManager.callFunc("playQueue")
    end if
    if isStringEqual(selectedPopupButton, tr("No, stop playback"))
        m.global.queueManager.callFunc("bypassNextPreferredAudioTrackIndexReset")
        m.global.queueManager.callFunc("clear")
        m.global.sceneManager.callFunc("popScene")
    end if
end sub

sub processPlaylistPopup(selectedPopupButton as string, itemID as string)
    if isStringEqual(selectedPopupButton, tr("Existing Playlist"))
        if not isValidAndNotEmpty(m.playlistData)
            activeScene = m.global.sceneManager.callFunc("getActiveScene")
            if not isValid(activeScene) then
                return
            end if
            scenePlaylistData = activeScene.LookupCI("playlistData")
            if not isValidAndNotEmpty(scenePlaylistData) then
                return
            end if
            m.playlistData = activeScene.playlistData
        end if
        stopLoadingSpinner()
        m.global.sceneManager.callFunc("optionDialog", "existingPlaylist", tr("Add To Playlist"), [], m.playlistData, {
            id: itemID
        })
        return
    end if
    if isStringEqual(selectedPopupButton, tr("New Playlist"))
        resumeData = [
            tr("Create")
        ]
        stopLoadingSpinner()
        m.global.sceneManager.callFunc("keyboardDialog", "newPlaylist", tr("Create New Playlist"), [
            "Input name of new playlist"
        ], resumeData, "", itemID)
        return
    end if
    ' Remove item from playlist
    if isStringEqual(selectedPopupButton, tr("Remove From Playlist"))
        ' Remove item from the item grid
        activeScene = m.global.sceneManager.callFunc("getActiveScene")
        if not isValid(activeScene) then
            return
        end if
        itemGrid = activeScene.findNode("playlist")
        if not isValid(itemGrid) then
            return
        end if
        itemGrid.content.removeChildIndex(itemGrid.itemFocused)
        mainAction_removeItemFromPlaylist(activeScene.pageContent.LookupCI("id"), itemID)
        return
    end if
end sub

sub processLibraryItemPopup(selectedPopupButton as string, itemID as string, params as object)
    if isStringEqual(selectedPopupButton, tr("Play Track"))
        quickplay_audio({
            id: itemID
            type: "audio"
        })
        m.global.queueManager.callFunc("playQueue")
        return
    end if
    if isStringEqual(selectedPopupButton, tr("Play Album"))
        ' First try to play in audio mini player
        scene = m.scene
        if isValid(scene)
            audioMiniPlayer = scene.findNode("audioMiniPlayer")
            if isValid(audioMiniPlayer)
                audioMiniPlayer.callFunc("setVisible", true)
            end if
        end if
        quickplay_album({
            id: itemID
            type: "musicalbum"
        })
        if m.global.queueManager.callFunc("getIsShuffled")
            m.global.queueManager.callFunc("resetShuffle")
        end if
        m.global.queueManager.callFunc("playQueue")
        return
    end if
    if isStringEqual(selectedPopupButton, tr("Shuffle Play Album"))
        ' First try to play in audio mini player
        scene = m.scene
        if isValid(scene)
            audioMiniPlayer = scene.findNode("audioMiniPlayer")
            if isValid(audioMiniPlayer)
                audioMiniPlayer.callFunc("setVisible", true)
            end if
        end if
        quickplay_album({
            id: itemID
            type: "musicalbum"
        })
        if not m.global.queueManager.callFunc("getIsShuffled")
            m.global.queueManager.callFunc("toggleShuffle")
        end if
        m.global.queueManager.callFunc("playQueue")
        return
    end if
    if isStringEqual(selectedPopupButton, tr("Instant Mix Album"))
        ' First try to play in audio mini player
        scene = m.scene
        if isValid(scene)
            audioMiniPlayer = scene.findNode("audioMiniPlayer")
            if isValid(audioMiniPlayer)
                audioMiniPlayer.callFunc("setVisible", true)
            end if
        end if
        quickplay_album({
            id: itemID
            type: "musicalbum"
        })
        instantMixList = CreateInstantMix(itemID)
        if isChainValid(instantMixList, "items")
            MainAction_playItem(instantMixList.LookupCI("Items"), {
                method: "set"
                resetShuffle: true
            })
        end if
        return
    end if
    ' Add item to user's list
    if isStringEqual(selectedPopupButton, tr("Add To My List"))
        MainAction_addItemToMyList(itemID)
        return
    end if
    if isStringEqual(selectedPopupButton, tr("Add To Favorites"))
        MainAction_addItemToFavorites(itemID)
        return
    end if
    if isStringEqual(selectedPopupButton, tr("Remove From Favorites"))
        MainAction_removeItemFromFavorites(itemID)
        return
    end if
    if isStringEqual(selectedPopupButton, tr("Go To Series"))
        CreateSeriesDetailsGroup(params.seriesid)
        return
    end if
    if isStringEqual(selectedPopupButton, tr("Go To Season"))
        CreateSeasonDetailsGroupByID(params.LookupCI("seriesid"), params.LookupCI("seasonid"))
        return
    end if
    if isStringEqual(selectedPopupButton, tr("Play Instant Mix"))
        ' Create instant mix based on selected artist
        startLoadingSpinner()
        instantMixList = CreateInstantMix(params.LookupCI("AlbumId"))
        if isChainValid(instantMixList, "items")
            MainAction_playItem(instantMixList.LookupCI("Items"), {
                method: "set"
                resetShuffle: true
            })
        else
            stopLoadingSpinner()
        end if
        return
    end if
    if isStringEqual(selectedPopupButton, tr("Go To Artist"))
        CreateArtistView({
            name: params.LookupCI("artistname")
            id: params.LookupCI("artistid")
        })
        return
    end if
    if selectedPopupButton.Instr(tr("Go To Genre")) <> -1
        ' Set filter settings so library loads with selected genre as selected filter
        set_user_setting("display.jumpToFilter.landing", "albums")
        set_user_setting("display.jumpToFilter.filter", "Genres")
        set_user_setting("display.jumpToFilter.filterOptions", ("{" + chr(34) + "Genres" + chr(34) + ": " + chr(34) + bslib_toString(params.LookupCI("GenreName")) + chr(34) + "}"))
        libraryContent = CreateObject("roSGNode", "JFContentItem")
        libraryContent.id = params.LookupCI("LibraryId")
        libraryContent.parentFolder = params.LookupCI("LibraryId")
        libraryContent.type = "Music"
        libraryContent.json = {
            type: "collectionfolder"
            jumpToFilter: params.LookupCI("GenreId")
        }
        group = CreateMusicLibraryView(libraryContent)
        m.global.sceneManager.callFunc("pushScene", group)
        return
    end if
    ' Mark item as played
    if isStringEqual(selectedPopupButton, tr("Mark As Played"))
        MainAction_setPlayed(itemID, true)
        group = m.global.sceneManager.callFunc("getActiveScene")
        if isValid(group)
            if isStringEqual(group.subtype(), "home")
                group.callFunc("refresh")
            end if
        end if
        return
    end if
    ' Mark item as unplayed
    if isStringEqual(selectedPopupButton, tr("Mark As Unplayed"))
        MainAction_setPlayed(itemID, false)
        group = m.global.sceneManager.callFunc("getActiveScene")
        if isValid(group)
            if isStringEqual(group.subtype(), "home")
                group.callFunc("refresh")
            end if
        end if
        return
    end if
    ' Add item to playlist
    if isStringEqual(selectedPopupButton, tr("Add To Playlist"))
        activeScene = m.global.sceneManager.callFunc("getActiveScene")
        MainAction_onPlaylistButtonClicked({
            itemContent: {
                id: itemID
            }
        })
        return
    end if
    if isStringEqual(selectedPopupButton, tr("Existing Playlist"))
        if not isValidAndNotEmpty(m.playlistData)
            activeScene = m.global.sceneManager.callFunc("getActiveScene")
            if not isValid(activeScene) then
                return
            end if
            scenePlaylistData = activeScene.LookupCI("playlistData")
            if not isValidAndNotEmpty(scenePlaylistData) then
                return
            end if
            m.playlistData = activeScene.playlistData
        end if
        stopLoadingSpinner()
        m.global.sceneManager.callFunc("optionDialog", "existingPlaylist", tr("Add To Playlist"), [], m.playlistData, {
            id: itemID
        })
        return
    end if
    if isStringEqual(selectedPopupButton, tr("Delete Playlist"))
        api_items_Delete({
            ids: itemID
        })
        activeScene = m.global.sceneManager.callFunc("getActiveScene")
        if not isValid(activeScene) then
            return
        end if
        itemGrid = activeScene.findNode("itemGrid")
        if not isValid(itemGrid) then
            return
        end if
        itemGrid.content.removeChildIndex(itemGrid.itemFocused)
        return
    end if
    if isStringEqual(selectedPopupButton, tr("New Playlist"))
        resumeData = [
            tr("Create")
        ]
        stopLoadingSpinner()
        m.global.sceneManager.callFunc("keyboardDialog", "newPlaylist", tr("Create New Playlist"), [
            "Input name of new playlist"
        ], resumeData, "", itemID)
        return
    end if
    if isStringEqual(selectedPopupButton, tr("Shuffle Play Collection"))
        quickplay_boxset({
            id: itemID
        })
        if not m.global.queueManager.callFunc("getIsShuffled")
            m.global.queueManager.callFunc("toggleShuffle")
        end if
        m.global.queueManager.callFunc("getIsShuffled")
        m.global.queueManager.callFunc("playQueue")
        return
    end if
    ' Remove item from user's list
    if isStringEqual(selectedPopupButton, tr("Remove From My List"))
        MainAction_removeItemFromMyList(itemID)
        ' If we're in My List, remove item from the item grid
        activeScene = m.global.sceneManager.callFunc("getActiveScene")
        if not isValid(activeScene) then
            return
        end if
        if isChainValid(activeScene, "parentItem.collectionType")
            if isStringEqual(activeScene.parentItem.collectionType, "mylist")
                itemGrid = activeScene.findNode("itemGrid")
                if not isValid(itemGrid) then
                    return
                end if
                itemGrid.content.removeChildIndex(itemGrid.itemFocused)
            end if
        end if
        return
    end if
end sub
'//# sourceMappingURL=./MainEventHandlers.brs.map