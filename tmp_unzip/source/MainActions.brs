'import "pkg:/components/manager/ViewCreator.bs"
'import "pkg:/source/enums/CollectionType.bs"
'import "pkg:/source/enums/ItemType.bs"
'import "pkg:/source/enums/ResumePopupAction.bs"
'import "pkg:/source/enums/String.bs"
'import "pkg:/source/utils/misc.bs"
sub MainAction_onPlayButtonClicked(activeScene as object)
    traceStep("PLAY_TRACE", "MainActions.onPlayButtonClicked start subtype=" + ((function(__bsCondition, activeScene)
            if __bsCondition then
                return activeScene.subType()
            else
                return "<invalid>"
            end if
        end function)(isValid(activeScene) and isValid(activeScene.subType), activeScene)))
    startLoadingSpinner()
    ' DO NOT overwrite itemContent.id as it is the primary ItemId needed for metadata/reporting.
    ' Instead, ensure the selected media source is available on the node.
    mediaSourceId = chainLookup(activeScene, "selectedVideoStreamId")
    ' Check if a specific Audio Stream was selected
    activeScene.itemContent.selectedAudioStreamIndex = (function(activeScene, chainLookup)
            __bsConsequent = chainLookup(activeScene, "selectedAudioStreamIndex")
            if __bsConsequent <> invalid then
                return __bsConsequent
            else
                return 0
            end if
        end function)(activeScene, chainLookup)
    ' Check for direct resume request from MovieDetails
    resumePlayback = false
    if isChainValid(activeScene, "resumePlayback")
        resumePlayback = activeScene.resumePlayback
        ' Reset the flag so future "Play" clicks don't auto-resume
        activeScene.resumePlayback = false
    end if
    ' Use val() or Double arithmetic to ensure we don't overflow 32-bit Integer
    rawTicks = chainLookup(activeScene, "itemContent.json.UserData.PlaybackPositionTicks")
    if not isValid(rawTicks) or rawTicks = 0
        rawTicks = chainLookup(activeScene, "itemContent.json.userdata.PlaybackPositionTicks")
    end if
    if isValid(rawTicks) then
        playbackPositionTicks = (rawTicks + 0.0)
    else
        playbackPositionTicks = 0.0
    end if
    itemIdText = chainLookupReturn(activeScene, "itemContent.id", "<none>")
    ' Use ToStr() on boxed value to handle Double/LongInt correctly in logs
    if (playbackPositionTicks > 0) then
        ticksStr = Box(playbackPositionTicks).ToStr()
    else
        ticksStr = "0"
    end if
    traceStep("PLAY_TRACE", "MainActions.onPlayButtonClicked ticks=" + ticksStr + " id=" + itemIdText + " mediaSourceId=" + (bslib_ternary(isValid(mediaSourceId), mediaSourceId, "<none>")) + " directResume=" + debugBool(resumePlayback))
    ' Pass the selected media source ID in the params if it differs from the main item ID
    playParams = {
        method: "push"
        bypassNextPreferredAudioTrackIndexReset: true
        startingPoint: playbackPositionTicks
    }
    if isValid(mediaSourceId) and mediaSourceId <> ""
        ' Set mediaSourceId on the node so QueueManager/ViewCreator can use it for GetPlaybackInfo
        activeScene.itemContent.addFields({
            mediaSourceId: mediaSourceId
        })
        if mediaSourceId <> activeScene.itemContent.id
            playParams.mediaSourceId = mediaSourceId
        end if
    end if
    if resumePlayback and playbackPositionTicks > 0
        traceStep("PLAY_TRACE", "MainActions.onPlayButtonClicked direct resume path")
        MainAction_playItem(activeScene.itemContent, playParams)
    else
        traceStep("PLAY_TRACE", "MainActions.onPlayButtonClicked calling playItem from start")
        playParams.startingPoint = 0
        MainAction_playItem(activeScene.itemContent, playParams)
    end if
    if isChainValid(activeScene, "lastFocus.id") and isStringEqual(activeScene.lastFocus.id, "main_group")
        buttons = activeScene.findNode("buttons")
        if isValid(buttons)
            activeScene.lastFocus = activeScene.findNode("buttons")
        end if
    end if
    if isChainValid(activeScene, "lastFocus")
        activeScene.lastFocus.setFocus(true)
    end if
    traceStep("PLAY_TRACE", "MainActions.onPlayButtonClicked end")
end sub

sub MainAction_onPartButtonClicked(activeScene as object)
    partData = {
        data: [
            {
                id: chainLookup(activeScene, "additionalParts.masterID")
                type: "partselect"
                Track: {
                    description: "Part 1"
                }
            }
        ]
    }
    selectedPart = (function(activeScene, chainLookup)
            __bsConsequent = chainLookup(activeScene, "selectedPart.id")
            if __bsConsequent <> invalid then
                return __bsConsequent
            else
                return ""
            end if
        end function)(activeScene, chainLookup)
    i = 2
    for each part in chainLookup(activeScene, "additionalParts.parts.Items")
        part.type = "partselect"
        part.Track = {}
        part.Track.description = ("Part " + bslib_toString(i))
        if selectedPart <> ""
            if isStringEqual(part.id, selectedPart)
                part.selected = true
            end if
        end if
        partData.data.push(part)
        i++
    end for
    m.global.sceneManager.callFunc("radioDialog", tr("Select Part"), partData)
    m.global.sceneManager.observeField("returnData", m.port)
end sub

sub MainAction_onTrailerButtonClicked(activeScene as object)
    startLoadingSpinner()
    if isChainValid(activeScene, "additionalParts.masterID")
        trailerData = api_items_GetLocalTrailers(activeScene.additionalParts.masterID, {
            userId: m.global.session.user.id
        })
    else
        trailerData = api_items_GetLocalTrailers(activeScene.id, {
            userId: m.global.session.user.id
        })
    end if
    if isValid(trailerData) and isValid(trailerData[0]) and isValid(trailerData[0].id)
        MainAction_playItem(trailerData, {
            method: "set"
            bypassNextPreferredAudioTrackIndexReset: true
        })
    else
        stopLoadingSpinner()
    end if
    if isChainValid(activeScene, "lastFocus")
        activeScene.lastFocus.setFocus(true)
    end if
end sub

sub MainAction_onWatchedButtonClicked(activeScene as object)
    movie = chainLookup(activeScene, "itemContent")
    if not isChainValid(movie, "watched") or not isValid(movie.id) then
        return
    end if
    if movie.watched
        MainAction_setPlayed(movie.id, false)
    else
        MainAction_setPlayed(movie.id, true)
        movieData = movie.json
        movieData.UserData.PlaybackPositionTicks = 0
        movie.json = movieData
    end if
    movie.watched = not movie.watched
end sub

sub MainAction_onMyListButtonClicked(activeScene as object)
    movie = chainLookup(activeScene, "itemContent")
    if not isValid(movie.id) then
        return
    end if
    if activeScene.isInMyList
        MainAction_removeItemFromMyList(movie.id)
    else
        MainAction_addItemToMyList(movie.id)
    end if
    activeScene.isInMyList = not activeScene.isInMyList
end sub

sub MainAction_onPlaylistButtonClicked(activeScene as object)
    startLoadingSpinner()
    movie = chainLookup(activeScene, "itemContent")
    if not isValid(movie.id) then
        return
    end if
    m.LoadPlaylistsTask = createObject("roSGNode", "LoadItemsTask")
    m.LoadPlaylistsTask.itemId = movie.id
    m.LoadPlaylistsTask.itemsToLoad = "playlists"
    m.LoadPlaylistsTask.observeFieldScoped("content", m.port)
    m.LoadPlaylistsTask.control = "RUN"
end sub

sub MainAction_onFavoriteButtonClicked(activeScene as object)
    movie = chainLookup(activeScene, "itemContent")
    if not isChainValid(movie, "favorite") or not isValid(movie.id) then
        return
    end if
    if movie.favorite
        api_users_UnmarkFavorite(movie.id, {
            userId: m.global.session.user.id
        })
    else
        api_users_MarkFavorite(movie.id, {
            userId: m.global.session.user.id
        })
    end if
    movie.favorite = not movie.favorite
    if isValid(activeScene) and LCase(activeScene.subType()) = "persondetails"
        activeScene.callFunc("setFavoriteColor")
    end if
end sub

sub MainAction_onEditSubtitlesButtonClicked(activeScene as object)
    subtitleSearchView = createObject("roSGNode", "SubtitleSearchView")
    subtitleSearchView.observeField("subtitleLanguageButtonSelected", m.port)
    subtitleSearchView.observeField("subtitleSearchButtonSelected", m.port)
    subtitleSearchView.observeField("subtitleToDelete", m.port)
    ' Set preferredSubtitleLanguage data so we can default the dropdown and popup correctly
    subtitleSearchView.cultures = api_localization_GetCultures()
    preferredSubtitleLanguage = chainLookup(m.global.session, "user.configuration.SubtitleLanguagePreference")
    if not isValidAndNotEmpty(preferredSubtitleLanguage)
        preferredSubtitleLanguage = "eng"
    end if
    subtitleSearchView.preferredSubtitleLanguage = preferredSubtitleLanguage
    ' Load the My Subtitles data now so it's up to date if user adds/deletes something it's updated
    ' If the data is bad, don't load the view
    metaData = ItemMetaData(activeScene.itemContent.id)
    if isValidAndNotEmpty(metaData)
        subtitleSearchView.itemContent = metaData
        m.global.sceneManager.callFunc("pushScene", subtitleSearchView)
    end if
end sub

sub MainAction_onGoToSeriesButtonClicked(activeScene as object)
    CreateSeriesDetailsGroup(activeScene.itemContent.showID)
end sub

sub MainAction_onGoToSeasonButtonClicked(activeScene as object)
    CreateSeasonDetailsGroupByID(activeScene.itemContent.LookupCI("showID"), activeScene.itemContent.LookupCI("seasonID"))
end sub

sub MainAction_playItem(item as dynamic, params = {} as object)
    if not isValid(item)
        traceStep("PLAY_TRACE", "MainActions.playItem called with invalid item")
        return
    end if
    itemIdText = chainLookupReturn(item, "id", "<none>")
    itemTypeText = chainLookupReturn(item, "type", "<none>")
    traceStep("PLAY_TRACE", "MainActions.playItem start itemId=" + itemIdText + " type=" + itemTypeText)
    startLoadingSpinner()
    playItemParams = {
        method: "push"
        bypassNextPreferredAudioTrackIndexReset: false
        resetShuffle: false
        position: -1
        startingPoint: -1
    }
    playItemParams.append(params)
    traceStep("PLAY_TRACE", "MainActions.playItem params method=" + playItemParams.method + " resetShuffle=" + debugBool(playItemParams.resetShuffle) + " position=" + stri(playItemParams.position).trim())
    if playItemParams.bypassNextPreferredAudioTrackIndexReset
        m.global.queueManager.callFunc("bypassNextPreferredAudioTrackIndexReset")
    end if
    if playItemParams.resetShuffle
        m.global.queueManager.callFunc("resetShuffle")
    end if
    m.global.queueManager.callFunc("clear")
    m.global.queueManager.callFunc(playItemParams.method, item)
    if playItemParams.position <> -1
        m.global.queueManager.callFunc("setPosition", playItemParams.position)
    end if
    if playItemParams.startingPoint <> -1
        m.global.queueManager.callFunc("setTopStartingPoint", playItemParams.startingPoint)
    end if
    ' If a specific media source ID was provided, set it on the item in the queue
    if isValid(playItemParams.mediaSourceId) and playItemParams.mediaSourceId <> ""
        currentItem = m.global.queueManager.callFunc("getCurrentItem")
        if isValid(currentItem)
            currentItem.mediaSourceId = playItemParams.mediaSourceId
        end if
    end if
    traceStep("PLAY_TRACE", "MainActions.playItem invoking playQueue")
    m.global.queueManager.callFunc("playQueue")
    traceStep("PLAY_TRACE", "MainActions.playItem end")
end sub

' Check if this is a, "OK" Dialog and close if so
sub MainAction_closeOKDialog(msg)
    dialog = msg.getRoSGNode()
    if isStringEqual(dialog.id, "OKDialog")
        dialog.unobserveField("buttonSelected")
        dialog.close = true
    end if
end sub

sub MainAction_setPlayed(itemID as string, isPlayed as boolean)
    group = m.global.sceneManager.callFunc("getActiveScene")
    if isValid(group)
        if isStringEqual(group.subtype(), "VisualLibraryScene")
            group.selectedItem = invalid
            group.quickPlayNode = invalid
            itemFocused = group.callFunc("getItemFocused")
            itemFocused.callFunc("setWatched", isPlayed)
        end if
    end if
    if isPlayed
        date = CreateObject("roDateTime")
        dateStr = date.ToISOString()
        api_users_MarkPlayed(itemID, {
            "DatePlayed": dateStr
            "PlaybackPositionTicks": 0
            userId: m.global.session.user.id
        })
        return
    end if
    api_users_UnmarkPlayed(itemID, {
        userId: m.global.session.user.id
    })
end sub

sub MainAction_addItemToFavorites(itemID as string)
    api_users_MarkFavorite(itemID, {
        userId: m.global.session.user.id
    })
    group = m.global.sceneManager.callFunc("getActiveScene")
    if isValid(group)
        if isStringEqual(group.subtype(), "home")
            group.callFunc("refresh")
            return
        end if
        if isStringEqual(group.subtype(), "albumView")
            group.IsFavorite = true
        end if
    end if
end sub

sub MainAction_removeItemFromFavorites(itemID as string)
    api_users_UnmarkFavorite(itemID, {
        userId: m.global.session.user.id
    })
    group = m.global.sceneManager.callFunc("getActiveScene")
    if isValid(group)
        if isStringEqual(group.subtype(), "home")
            group.callFunc("refresh")
            return
        end if
        if isStringEqual(group.subtype(), "albumView")
            group.IsFavorite = false
        end if
    end if
end sub

sub MainAction_addItemToMyList(itemID as string)
    data = api_GetUserViews({
        "userId": m.global.session.user.id
    })
    if not isChainValid(data, "items") then
        return
    end if
    myListPlaylist = invalid
    for each item in data.LookupCI("items")
        if isStringEqual(item.LookupCI("CollectionType"), "playlists")
            myListPlaylist = api_items_Get({
                "userid": m.global.session.user.id
                "includeItemTypes": "Playlist"
                "nameStartsWith": "|My List|"
                "parentId": item.LookupCI("id")
            })
            exit for
        end if
    end for
    ' My list playlist exists. Add item to it
    if isValid(myListPlaylist) and isValidAndNotEmpty(myListPlaylist.items)
        api_playlists_Add(myListPlaylist.items[0].LookupCI("id"), {
            ids: itemID
            userid: m.global.session.user.id
        })
        group = m.global.sceneManager.callFunc("getActiveScene")
        if isValid(group)
            if isStringEqual(group.subtype(), "home")
                group.callFunc("refresh")
            end if
        end if
        return
    end if
    ' My list playlist does not exist. Create it with this item
    api_playlists_Create({
        name: "|My List|"
        ids: [
            itemID
        ]
        userid: m.global.session.user.id
        mediatype: "Unknown"
        users: [
            {
                userid: m.global.session.user.id
                canedit: true
            }
        ]
        ispublic: false
    })
    group = m.global.sceneManager.callFunc("getActiveScene")
    if isValid(group)
        if isStringEqual(group.subtype(), "home")
            group.callFunc("refresh")
        end if
    end if
end sub

' Remove item from user's My List playlist
sub MainAction_removeItemFromMyList(itemID as string)
    data = api_GetUserViews({
        "userId": m.global.session.user.id
    })
    if not isChainValid(data, "items") then
        return
    end if
    myListPlaylist = invalid
    for each item in data.LookupCI("items")
        if isStringEqual(item.LookupCI("CollectionType"), "playlists")
            myListPlaylist = api_items_Get({
                "userid": m.global.session.user.id
                "includeItemTypes": "Playlist"
                "nameStartsWith": "|My List|"
                "parentId": item.LookupCI("id")
            })
            exit for
        end if
    end for
    ' My list playlist exists. Remove item from it
    if isValid(myListPlaylist) and isValidAndNotEmpty(myListPlaylist.items)
        api_playlists_Remove(myListPlaylist.items[0].LookupCI("id"), {
            entryIds: itemID
        })
        group = m.global.sceneManager.callFunc("getActiveScene")
        if isValid(group)
            if isStringEqual(group.subtype(), "home")
                group.callFunc("refresh")
            end if
        end if
    end if
end sub

' Remove item from playlist
sub MainAction_removeItemFromPlaylist(playlistID as string, itemID as string)
    if isValidAndNotEmpty(playlistID) and isValidAndNotEmpty(itemID)
        api_playlists_Remove(playlistID, {
            entryIds: itemID
        })
    end if
end sub
'//# sourceMappingURL=./MainActions.brs.map