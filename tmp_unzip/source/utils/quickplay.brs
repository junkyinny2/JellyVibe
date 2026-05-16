' All of the Quick Play logic seperated by media type
' Takes an array of items and adds to global queue.
' Also shuffles the playlist if asked
sub quickplay_pushToQueue(queueArray as object, shufflePlay = false as boolean)
    if isValidAndNotEmpty(queueArray)
        ' load everything
        for each item in queueArray
            m.global.queueManager.callFunc("push", item)
        end for
        ' shuffle the playlist if asked
        if shufflePlay and m.global.queueManager.callFunc("getCount") > 1
            m.global.queueManager.callFunc("toggleShuffle")
        end if
    end if
end sub

' A single video file.
sub quickplay_video(itemNode as object)
    if not isValid(itemNode) or not isValid(itemNode.id) or not isValid(itemNode.json) then
        return
    end if
    ' attempt to play video file. resume if possible
    if isValidAndNotEmpty(itemNode.selectedVideoStreamId)
        itemNode.id = itemNode.selectedVideoStreamId
    end if
    audio_stream_idx = 0
    if isValid(itemNode.selectedAudioStreamIndex) and itemNode.selectedAudioStreamIndex > 0
        audio_stream_idx = itemNode.selectedAudioStreamIndex
    end if
    itemNode.selectedAudioStreamIndex = audio_stream_idx
    playbackPosition = 0
    if isValid(itemNode.json.userdata) and isValid(itemNode.json.userdata.PlaybackPositionTicks)
        playbackPosition = itemNode.json.userdata.PlaybackPositionTicks
    end if
    itemNode.startingPoint = playbackPosition
    m.global.queueManager.callFunc("push", itemNode)
end sub

' A single audiobook file.
sub quickplay_audioBook(itemNode as object)
    if not isValid(itemNode) or not isValid(itemNode.id) or not isValid(itemNode.json) then
        return
    end if
    playbackPosition = 0
    if isValid(itemNode.json.userdata) and isValid(itemNode.json.userdata.PlaybackPositionTicks)
        playbackPosition = itemNode.json.userdata.PlaybackPositionTicks
    end if
    itemNode.startingPoint = playbackPosition
    m.global.queueManager.callFunc("push", itemNode)
end sub

' A single audio file.
sub quickplay_audio(itemNode as object)
    if not isValid(itemNode) or not isValid(itemNode.id) then
        return
    end if
    m.global.queueManager.callFunc("push", itemNode)
end sub

' A single music video file.
sub quickplay_musicVideo(itemNode as object)
    if not isValid(itemNode) or not isValid(itemNode.id) or not isValid(itemNode.json) then
        return
    end if
    m.global.queueManager.callFunc("push", itemNode)
end sub

' A single photo.
sub quickplay_photo(itemNode as object)
    if not isValid(itemNode) or not isValid(itemNode.id) then
        return
    end if
    photoPlayer = CreateObject("roSgNode", "PhotoDetails")
    photoPlayer.itemsNode = itemNode
    photoPlayer.itemIndex = 0
    m.global.sceneManager.callfunc("pushScene", photoPlayer)
end sub

' A photo album.
sub quickplay_photoAlbum(itemNode as object)
    if not isValid(itemNode) or not isValid(itemNode.id) then
        return
    end if
    ' grab all photos inside photo album
    photoAlbumData = api_items_Get({
        "userid": m.global.session.user.id
        "parentId": itemNode.id
        "includeItemTypes": "Photo"
        "sortBy": "Random"
        "Recursive": true
    })
    if isValid(photoAlbumData) and isValidAndNotEmpty(photoAlbumData.items)
        photoPlayer = CreateObject("roSgNode", "PhotoDetails")
        photoPlayer.isSlideshow = true
        photoPlayer.isRandom = false
        photoPlayer.itemsArray = photoAlbumData.items
        photoPlayer.itemIndex = 0
        m.global.sceneManager.callfunc("pushScene", photoPlayer)
    else
        stopLoadingSpinner()
    end if
end sub

' A music album.
' Play the entire album starting with track 1.
sub quickplay_album(itemNode as object)
    if not isValid(itemNode) or not isValid(itemNode.id) then
        return
    end if
    ' grab list of songs in the album
    albumSongs = api_items_Get({
        "userid": m.global.session.user.id
        "parentId": itemNode.id
        "imageTypeLimit": 1
        "sortBy": "SortName"
        "limit": 2000
        "enableUserData": false
        "EnableTotalRecordCount": false
    })
    if isValid(albumSongs) and isValidAndNotEmpty(albumSongs.items)
        quickplay_pushToQueue(albumSongs.items)
    else
        stopLoadingSpinner()
    end if
end sub

' A music artist.
' Shuffle play all songs by artist.
sub quickplay_artist(itemNode as object)
    if not isValid(itemNode) or not isValid(itemNode.id) then
        return
    end if
    ' get all songs by artist
    artistSongs = api_items_Get({
        "userid": m.global.session.user.id
        "artistIds": itemNode.id
        "includeItemTypes": "Audio"
        "sortBy": "random"
        "limit": 2000
        "imageTypeLimit": 1
        "Recursive": true
        "enableUserData": false
        "EnableTotalRecordCount": false
    })
    if isValid(artistSongs) and isValidAndNotEmpty(artistSongs.items)
        m.global.queueManager.callFunc("set", artistSongs.items)
        m.global.queueManager.callFunc("toggleShuffle")
    else
        stopLoadingSpinner()
    end if
end sub

' A boxset.
' Play all items inside.
sub quickplay_boxset(itemNode as object)
    if not isValid(itemNode) or not isValid(itemNode.id) then
        return
    end if
    data = api_items_Get({
        "userid": m.global.session.user.id
        "parentid": itemNode.id
        "limit": 2000
        "EnableTotalRecordCount": false
    })
    if isValid(data) and isValidAndNotEmpty(data.Items)
        quickplay_pushToQueue(data.items)
    else
        stopLoadingSpinner()
    end if
end sub

' A TV Show Series.
' Play the first unwatched episode.
' If none, shuffle play the whole series.
sub quickplay_series(itemNode as object)
    if not isValid(itemNode) or not isValid(itemNode.id) then
        return
    end if
    ' If quickplayFromResume is set, start playback attempt from first resumable episode before looking at next up
    quickplayFromResume = chainLookupReturn(itemNode, "quickplayFromResume", false)
    if quickplayFromResume
        data = api_useritems_GetResumeItems({
            "parentId": itemNode.id
            "userid": m.global.session.user.id
            "SortBy": "SortName"
            "recursive": true
            "SortOrder": "Ascending"
            "Filters": "IsResumable"
            "EnableTotalRecordCount": false
        })
        if isValid(data) and isValidAndNotEmpty(data.Items)
            ' play the resumable episode
            if isValid(data.Items[0].UserData) and isValid(data.Items[0].UserData.PlaybackPositionTicks)
                data.Items[0].startingPoint = data.Items[0].userdata.PlaybackPositionTicks
            end if
            m.global.queueManager.callFunc("push", data.Items[0])
            return
        end if
    else
        data = api_shows_GetNextUp({
            "seriesId": itemNode.id
            "recursive": true
            "SortBy": "DatePlayed"
            "SortOrder": "Descending"
            "ImageTypeLimit": 1
            "UserId": m.global.session.user.id
            "EnableRewatching": m.global.session.user.settings["ui.details.enablerewatchingnextup"]
            "DisableFirstEpisode": false
            "EnableTotalRecordCount": false
        })
        if isValid(data) and isValidAndNotEmpty(data.Items)
            ' there are unwatched episodes
            m.global.queueManager.callFunc("push", data.Items[0])
            return
        end if
    end if
    if quickplayFromResume
        data = api_shows_GetNextUp({
            "seriesId": itemNode.id
            "recursive": true
            "SortBy": "DatePlayed"
            "SortOrder": "Descending"
            "ImageTypeLimit": 1
            "UserId": m.global.session.user.id
            "EnableRewatching": m.global.session.user.settings["ui.details.enablerewatchingnextup"]
            "DisableFirstEpisode": false
            "EnableTotalRecordCount": false
        })
        if isValid(data) and isValidAndNotEmpty(data.Items)
            ' there are unwatched episodes
            m.global.queueManager.callFunc("push", data.Items[0])
            return
        end if
    else
        ' next up check was empty
        ' check for a resumable episode
        data = api_useritems_GetResumeItems({
            "parentId": itemNode.id
            "userid": m.global.session.user.id
            "SortBy": "DatePlayed"
            "recursive": true
            "SortOrder": "Descending"
            "Filters": "IsResumable"
            "EnableTotalRecordCount": false
        })
        if isValid(data) and isValidAndNotEmpty(data.Items)
            ' play the resumable episode
            if isValid(data.Items[0].UserData) and isValid(data.Items[0].UserData.PlaybackPositionTicks)
                data.Items[0].startingPoint = data.Items[0].userdata.PlaybackPositionTicks
            end if
            m.global.queueManager.callFunc("push", data.Items[0])
            return
        end if
    end if
    ' shuffle all episodes
    data = api_shows_GetEpisodes(itemNode.id, {
        "userid": m.global.session.user.id
        "SortBy": bslib_ternary(quickplayFromResume, "SortName", "Random")
        "limit": bslib_ternary(quickplayFromResume, 1, 2000)
        "EnableTotalRecordCount": false
        "isMissing": false
    })
    if isValid(data) and isValidAndNotEmpty(data.Items)
        ' add all episodes found to a playlist
        quickplay_pushToQueue(data.Items)
    else
        stopLoadingSpinner()
    end if
end sub

' More than one TV Show Series.
' Shuffle play all watched episodes
sub quickplay_multipleSeries(itemNodes as object)
    if isValidAndNotEmpty(itemNodes)
        numTotal = 0
        numLimit = 2000
        for each tvshow in itemNodes
            ' grab all watched episodes for each series
            showData = api_shows_GetEpisodes(tvshow.id, {
                "userId": m.global.session.user.id
                "SortBy": "Random"
                "imageTypeLimit": 0
                "EnableTotalRecordCount": false
                "enableImages": false
                "isMissing": false
            })
            if isValid(showData) and isValidAndNotEmpty(showData.items)
                playedEpisodes = []
                ' add all played episodes to queue
                for each episode in showData.items
                    if isValid(episode.userdata) and isValid(episode.userdata.Played)
                        if episode.userdata.Played
                            playedEpisodes.push(episode)
                        end if
                    end if
                end for
                quickplay_pushToQueue(playedEpisodes)
                ' keep track of how many items we've seen
                numTotal = numTotal + showData.items.count()
                if numTotal >= numLimit
                    ' stop grabbing more items if we hit our limit
                    exit for
                end if
            end if
        end for
        if m.global.queueManager.callFunc("getCount") > 1
            m.global.queueManager.callFunc("toggleShuffle")
        else
            stopLoadingSpinner()
        end if
    end if
end sub

' A container with some kind of videos inside of it
sub quickplay_videoContainer(itemNode as object)
    collectionType = Lcase(itemNode.collectionType)
    if collectionType = "movies"
        ' get randomized list of videos inside
        data = api_items_Get({
            "userid": m.global.session.user.id
            "parentId": itemNode.id
            "sortBy": "Random"
            "recursive": true
            "includeItemTypes": "Movie,Video"
            "limit": 2000
        })
        if isValid(data) and isValidAndNotEmpty(data.items)
            videoList = []
            ' add each item to the queue
            for each item in data.Items
                ' only add videos we're not currently watching
                if isValid(item.userdata) and isValid(item.userdata.PlaybackPositionTicks)
                    if item.userdata.PlaybackPositionTicks = 0
                        videoList.push(item)
                    end if
                end if
            end for
            quickplay_pushToQueue(videoList)
        else
            stopLoadingSpinner()
        end if
        return
    else if collectionType = "tvshows" or collectionType = "collectionfolder"
        ' get list of tv shows inside
        tvshowsData = api_items_Get({
            "userid": m.global.session.user.id
            "parentId": itemNode.id
            "sortBy": "Random"
            "recursive": true
            "excludeItemTypes": "Season"
            "imageTypeLimit": 0
            "enableUserData": false
            "EnableTotalRecordCount": false
            "enableImages": false
            "isMissing": false
        })
        if isValid(tvshowsData) and isValidAndNotEmpty(tvshowsData.items)
            ' the type of media returned from api may change.
            if tvshowsData.items[0].Type = "Series"
                quickplay_multipleSeries(tvshowsData.items)
            else
                ' if first item is not a series, then assume they are all videos and/or episodes
                quickplay_pushToQueue(tvshowsData.items)
            end if
        else
            stopLoadingSpinner()
        end if
    else
        stopLoadingSpinner()
        print "Quick Play videoContainer WARNING: Unknown collection type"
    end if
end sub

' A TV Show Season.
' Play the first unwatched episode.
' If none, play the whole season starting with episode 1.
sub quickplay_season(itemNode as object)
    if not isChainValid(itemNode, "json.SeriesId") or not isValid(itemNode.id) then
        return
    end if
    unwatchedData = api_shows_GetEpisodes(itemNode.json.SeriesId, {
        "seasonId": itemNode.id
        "userid": m.global.session.user.id
        "limit": 2000
        "EnableTotalRecordCount": false
        "isMissing": false
    })
    if isValid(unwatchedData) and isValidAndNotEmpty(unwatchedData.Items)
        ' find the first unwatched episode
        firstUnwatchedEpisodeIndex = invalid
        for each item in unwatchedData.Items
            if isValid(item.UserData)
                if isValid(item.UserData.Played) and item.UserData.Played = false
                    if isValid(item.IndexNumber) then
                        firstUnwatchedEpisodeIndex = item.IndexNumber - 1
                    else
                        firstUnwatchedEpisodeIndex = 0
                    end if
                    if isValid(item.UserData.PlaybackPositionTicks)
                        item.startingPoint = item.UserData.PlaybackPositionTicks
                    end if
                    exit for
                end if
            end if
        end for
        if isValid(firstUnwatchedEpisodeIndex)
            ' add the first unwatched episode and the rest of the season to a playlist
            for i = firstUnwatchedEpisodeIndex to unwatchedData.Items.count() - 1
                m.global.queueManager.callFunc("push", unwatchedData.Items[i])
            end for
        else
            ' try to find a "continue watching" episode
            continueData = api_useritems_GetResumeItems({
                "parentId": itemNode.id
                "userid": m.global.session.user.id
                "SortBy": "DatePlayed"
                "recursive": true
                "SortOrder": "Descending"
                "Filters": "IsResumable"
                "EnableTotalRecordCount": false
            })
            if isValid(continueData) and isValidAndNotEmpty(continueData.Items)
                ' play the resumable episode
                for each item in continueData.Items
                    if isValid(item.UserData) and isValid(item.UserData.PlaybackPositionTicks)
                        item.startingPoint = item.userdata.PlaybackPositionTicks
                    end if
                    m.global.queueManager.callFunc("push", item)
                end for
            else
                ' play the whole season in order
                if isValid(unwatchedData) and isValidAndNotEmpty(unwatchedData.Items)
                    ' add all episodes found to a playlist
                    quickplay_pushToQueue(unwatchedData.Items)
                end if
            end if
        end if
    else
        stopLoadingSpinner()
    end if
end sub

' Quick Play A Person.
' Shuffle play all videos found
sub quickplay_person(itemNode as object)
    if not isValid(itemNode) or not isValid(itemNode.id) then
        return
    end if
    ' get movies and videos by the person
    personMovies = api_items_Get({
        "userid": m.global.session.user.id
        "personIds": itemNode.id
        "includeItemTypes": "Movie,Video"
        "excludeItemTypes": "Season,Series"
        "recursive": true
        "limit": 2000
    })
    if isValid(personMovies) and isValidAndNotEmpty(personMovies.Items)
        ' add each item to the queue
        quickplay_pushToQueue(personMovies.Items)
    end if
    ' get watched episodes by the person
    personEpisodes = api_items_Get({
        "userid": m.global.session.user.id
        "personIds": itemNode.id
        "includeItemTypes": [
            "Episode"
            "Recording"
        ]
        "isPlayed": true
        "excludeItemTypes": "Season,Series"
        "recursive": true
        "limit": 2000
    })
    if isValid(personEpisodes) and isValidAndNotEmpty(personEpisodes.Items)
        ' add each item to the queue
        quickplay_pushToQueue(personEpisodes.Items)
    end if
    if m.global.queueManager.callFunc("getCount") > 1
        m.global.queueManager.callFunc("toggleShuffle")
    else
        stopLoadingSpinner()
    end if
end sub

' Quick Play A TVChannel
sub quickplay_tvChannel(itemNode as object)
    if not isValid(itemNode) or not isValid(itemNode.id) then
        return
    end if
    thisItem = {
        id: itemNode.id
        type: "video"
    }
    m.global.queueManager.callFunc("clear")
    m.global.queueManager.callFunc("resetShuffle")
    m.global.queueManager.callFunc("push", thisItem)
end sub

' Quick Play A Live Program
sub quickplay_program(itemNode as object)
    if not isValid(itemNode) or not isValid(itemNode.json) or not isValid(itemNode.json.ChannelId) then
        return
    end if
    thisItem = {
        id: itemNode.id
        type: "video"
    }
    m.global.queueManager.callFunc("clear")
    m.global.queueManager.callFunc("resetShuffle")
    m.global.queueManager.callFunc("push", thisItem)
end sub

' Quick Play A Playlist.
' Play the first unwatched episode.
' If none, play the whole season starting with episode 1.
sub quickplay_playlist(itemNode as object)
    if not isValid(itemNode) or not isValid(itemNode.id) then
        return
    end if
    ' get playlist items
    myPlaylist = api_playlists_GetItems(itemNode.id, {
        "userId": m.global.session.user.id
        "limit": 2000
    })
    if isValid(myPlaylist) and isValidAndNotEmpty(myPlaylist.Items)
        ' add each item to the queue
        quickplay_pushToQueue(myPlaylist.Items)
        if m.global.queueManager.callFunc("getCount") > 1
            m.global.queueManager.callFunc("toggleShuffle")
        end if
    else
        stopLoadingSpinner()
    end if
end sub

' Quick Play A folder.
' Shuffle play all items found
sub quickplay_folder(itemNode as object)
    if not isValid(itemNode) or not isValid(itemNode.id) then
        return
    end if
    paramArray = {
        "userid": m.global.session.user.id
        "includeItemTypes": [
            "Episode"
            "Recording"
            "Movie"
            "Video"
        ]
        "videoTypes": "VideoFile"
        "sortBy": "Random"
        "limit": 2000
        "imageTypeLimit": 1
        "Recursive": true
        "enableUserData": false
        "EnableTotalRecordCount": false
    }
    ' modify api query based on folder type
    folderType = Lcase(itemNode.json.type)
    if folderType = "studio"
        paramArray["studioIds"] = itemNode.id
    else if folderType = "genre"
        paramArray["genreIds"] = itemNode.id
        if isValid(itemNode.json.MovieCount) and itemNode.json.MovieCount > 0
            paramArray["includeItemTypes"] = "Movie"
        end if
    else if folderType = "musicgenre"
        paramArray["genreIds"] = itemNode.id
        paramArray.delete("videoTypes")
        paramArray["includeItemTypes"] = "Audio"
    else if folderType = "photoalbum"
        paramArray["parentId"] = itemNode.id
        paramArray["includeItemTypes"] = "Photo"
        paramArray.delete("videoTypes")
        paramArray.delete("Recursive")
    else
        paramArray["parentId"] = itemNode.id
    end if
    ' look for tv series instead of video files
    if isValid(itemNode.json.SeriesCount) and itemNode.json.SeriesCount > 0
        paramArray["includeItemTypes"] = "Series"
        paramArray.Delete("videoTypes")
    end if
    ' get folder items
    folderData = api_items_Get(paramArray)
    if isValid(folderData) and isValidAndNotEmpty(folderData.items)
        if isValid(itemNode.json.SeriesCount) and itemNode.json.SeriesCount > 0
            if itemNode.json.SeriesCount = 1
                quickplay_series(folderData.items[0])
            else
                quickplay_multipleSeries(folderData.items)
            end if
        else
            if folderType = "photoalbum"
                photoPlayer = CreateObject("roSgNode", "PhotoDetails")
                photoPlayer.isSlideshow = true
                photoPlayer.isRandom = false
                photoPlayer.itemsArray = folderData.items
                photoPlayer.itemIndex = 0
                m.global.sceneManager.callfunc("pushScene", photoPlayer)
            else
                quickplay_pushToQueue(folderData.items, true)
            end if
        end if
    else
        stopLoadingSpinner()
    end if
end sub

' Quick Play A CollectionFolder.
' Shuffle play the items inside
' with some differences based on collectionType.
sub quickplay_collectionFolder(itemNode as object)
    if not isValid(itemNode) or not isValid(itemNode.id) then
        return
    end if
    ' play depends on the kind of files inside the collectionfolder
    collectionType = LCase(itemNode.collectionType)
    if collectionType = "movies"
        quickplay_videoContainer(itemNode)
    else if collectionType = "music"
        ' get audio files from under this collection
        ' sort songs by album then artist
        songsData = api_items_Get({
            "userid": m.global.session.user.id
            "parentId": itemNode.id
            "includeItemTypes": "Audio"
            "sortBy": "Album"
            "Recursive": true
            "limit": 2000
            "imageTypeLimit": 1
            "enableUserData": false
            "EnableTotalRecordCount": false
        })
        if isValid(songsData) and isValidAndNotEmpty(songsData.items)
            quickplay_pushToQueue(songsData.Items, true)
        else
            stopLoadingSpinner()
        end if
    else if collectionType = "books"
        ' get audio files from under this collection
        ' sort songs by album then artist
        songsData = api_items_Get({
            "userid": m.global.session.user.id
            "parentId": itemNode.id
            "mediaTypes": "Audio"
            "Filters": "IsNotFolder"
            "includeItemTypes": "audiobooks"
            "Recursive": true
            "limit": 2000
            "imageTypeLimit": 1
            "enableUserData": false
            "EnableTotalRecordCount": false
        })
        if isValid(songsData) and isValidAndNotEmpty(songsData.items)
            quickplay_pushToQueue(songsData.Items, true)
        else
            stopLoadingSpinner()
        end if
    else if collectionType = "boxsets"
        ' get list of all boxsets inside
        boxsetData = api_items_Get({
            "userid": m.global.session.user.id
            "parentId": itemNode.id
            "limit": 2000
            "imageTypeLimit": 0
            "enableUserData": false
            "EnableTotalRecordCount": false
            "enableImages": false
        })
        if isValid(boxsetData) and isValidAndNotEmpty(boxsetData.items)
            ' pick a random boxset
            arrayIndex = Rnd(boxsetData.items.count()) - 1
            myBoxset = boxsetData.items[arrayIndex]
            ' grab list of items from boxset
            boxsetData = api_items_Get({
                "userid": m.global.session.user.id
                "parentId": myBoxset.id
                "EnableTotalRecordCount": false
            })
            if isValid(boxsetData) and isValidAndNotEmpty(boxsetData.items)
                ' add all boxset items to queue
                quickplay_pushToQueue(boxsetData.Items)
            else
                stopLoadingSpinner()
            end if
        end if
    else if collectionType = "tvshows" or collectionType = "collectionfolder"
        quickplay_videoContainer(itemNode)
    else if collectionType = "musicvideos"
        ' get randomized list of videos inside
        data = api_items_Get({
            "userid": m.global.session.user.id
            "parentId": itemNode.id
            "includeItemTypes": "MusicVideo"
            "sortBy": "Random"
            "Recursive": true
            "limit": 2000
            "imageTypeLimit": 1
            "enableUserData": false
            "EnableTotalRecordCount": false
        })
        if isValid(data) and isValidAndNotEmpty(data.items)
            quickplay_pushToQueue(data.Items)
        else
            stopLoadingSpinner()
        end if
    else if collectionType = "homevideos"
        ' Photo library - items can be type video, photo, or photoAlbum
        ' grab all photos inside library
        folderData = api_items_Get({
            "userid": m.global.session.user.id
            "parentId": itemNode.id
            "includeItemTypes": "Photo"
            "sortBy": "Random"
            "Recursive": true
        })
        if isValid(folderData) and isValidAndNotEmpty(folderData.items)
            photoPlayer = CreateObject("roSgNode", "PhotoDetails")
            photoPlayer.isSlideshow = true
            photoPlayer.isRandom = false
            photoPlayer.itemsArray = folderData.items
            photoPlayer.itemIndex = 0
            m.global.sceneManager.callfunc("pushScene", photoPlayer)
        else
            stopLoadingSpinner()
        end if
    else
        stopLoadingSpinner()
        print "Quick Play WARNING: Unknown collection type"
    end if
end sub

' Quick Play A UserView.
' Play logic depends on "collectionType".
sub quickplay_userView(itemNode as object)
    ' play depends on the kind of files inside the collectionfolder
    collectionType = LCase(itemNode.collectionType)
    if collectionType = "playlists"
        ' get list of all playlists inside
        playlistData = api_items_Get({
            "userid": m.global.session.user.id
            "parentId": itemNode.id
            "imageTypeLimit": 0
            "enableUserData": false
            "EnableTotalRecordCount": false
            "enableImages": false
        })
        if isValid(playlistData) and isValidAndNotEmpty(playlistData.items)
            ' pick a random playlist
            arrayIndex = Rnd(playlistData.items.count()) - 1
            myPlaylist = playlistData.items[arrayIndex]
            ' grab list of items from playlist
            playlistItems = api_playlists_GetItems(myPlaylist.id, {
                "userId": m.global.session.user.id
                "EnableTotalRecordCount": false
                "limit": 2000
            })
            ' validate api results
            if isValid(playlistItems) and isValidAndNotEmpty(playlistItems.items)
                quickplay_pushToQueue(playlistItems.items, true)
            else
                stopLoadingSpinner()
            end if
        end if
    else if collectionType = "livetv"
        ' get list of all tv channels
        channelData = api_items_Get({
            "userid": m.global.session.user.id
            "includeItemTypes": "TVChannel"
            "sortBy": "Random"
            "Recursive": true
            "imageTypeLimit": 0
            "enableUserData": false
            "EnableTotalRecordCount": false
            "enableImages": false
        })
        if isValid(channelData) and isValidAndNotEmpty(channelData.items)
            ' pick a random channel
            arrayIndex = Rnd(channelData.items.count()) - 1
            myChannel = channelData.items[arrayIndex]
            ' play channel
            quickplay_tvChannel(myChannel)
        else
            stopLoadingSpinner()
        end if
    else if collectionType = "movies"
        quickplay_videoContainer(itemNode)
    else if collectionType = "tvshows"
        quickplay_videoContainer(itemNode)
    else
        stopLoadingSpinner()
        print "Quick Play CollectionFolder WARNING: Unknown collection type"
    end if
end sub
'//# sourceMappingURL=./quickplay.brs.map