'import "pkg:/source/api/baserequest.bs"
'import "pkg:/source/api/Image.bs"
'import "pkg:/source/api/Items.bs"
'import "pkg:/source/api/sdk.bs"
'import "pkg:/source/enums/ImageType.bs"
'import "pkg:/source/utils/config.bs"
'import "pkg:/source/utils/deviceCapabilities.bs"
'import "pkg:/source/utils/misc.bs"

sub init()
    m.top.filter = "All"
    m.top.sortField = "SortName"
    m.top.functionName = "loadItems"
    m.top.limit = 60
end sub

sub loadItems()
    results = []
    sort_field = m.top.sortField
    if m.top.sortAscending = true
        sort_order = "Ascending"
    else
        sort_order = "Descending"
    end if
    if m.top.ItemType = "LogoImage"
        logoImageExists = api_items_HeadImageURLByName(m.top.itemId, "Logo")
        if logoImageExists
            m.top.content = [
                api_items_GetImageURL(m.top.itemId, "Logo", 0, {
                    "format": "Png"
                    "maxHeight": 500
                    "maxWidth": 500
                    "quality": "90"
                })
            ]
        else
            m.top.content = []
        end if
        return
    end if
    params = {
        limit: m.top.limit
        StartIndex: m.top.startIndex
        parentid: m.top.itemId
        SortBy: sort_field
        SortOrder: sort_order
        recursive: m.top.recursive
        Fields: "Overview, RecursiveItemCount"
        StudioIds: m.top.studioIds
        genreIds: m.top.genreIds
        TagIds: m.top.tagIds
        Tags: m.top.tags
    }
    if m.top.tags <> invalid and m.top.tags <> ""
        print "[FILTER] Filtering by tag=" + m.top.tags + " itemId=" + m.top.itemId
    end if
    ' Handle special case when getting names starting with numeral
    if m.top.NameStartsWith <> ""
        if m.top.NameStartsWith = "#"
            if m.top.ItemType = "LiveTV" or m.top.ItemType = "TvChannel"
                params.searchterm = "A"
                params.append({
                    parentid: " "
                })
            else
                params.NameLessThan = "A"
            end if
        else
            if m.top.ItemType = "LiveTV" or m.top.ItemType = "TvChannel"
                params.searchterm = m.top.nameStartsWith
                params.append({
                    parentid: " "
                })
            else
                params.NameStartsWith = m.top.nameStartsWith
            end if
        end if
    end if
    'reset data
    if LCase(m.top.searchTerm) = LCase(tr("all"))
        params.searchTerm = " "
    else if m.top.searchTerm <> ""
        params.searchTerm = m.top.searchTerm
    end if
    filter = LCase(m.top.filter)
    if filter = "all"
        ' do nothing
    else if filter = "favorites"
        params.append({
            Filters: "IsFavorite"
        })
        params.append({
            isFavorite: true
        })
    else if filter = "unplayed"
        params.append({
            Filters: "IsUnplayed"
        })
    else if filter = "played"
        params.append({
            Filters: "IsPlayed"
        })
    else if filter = "resumable"
        params.append({
            Filters: "IsResumable"
        })
    else if filter = "features"
        if isChainValid(m.top.filterOptions, "Features")
            featureFilterList = m.top.filterOptions.Features
            if featureFilterList.instr("Subtitles") <> -1
                params.append({
                    HasSubtitles: true
                })
            end if
            if featureFilterList.instr("Special Features") <> -1
                params.append({
                    HasSpecialFeature: true
                })
            end if
            if featureFilterList.instr("Theme Song") <> -1
                params.append({
                    HasThemeSong: true
                })
            end if
            if featureFilterList.instr("Theme Video") <> -1
                params.append({
                    HasThemeVideo: true
                })
            end if
        end if
    end if
    if filter <> "features"
        if isValid(m.top.filterOptions)
            if m.top.filterOptions.count() > 0
                params.append(m.top.filterOptions)
            end if
        end if
    end if
    if m.top.ItemType <> ""
        params.append({
            IncludeItemTypes: m.top.ItemType
        })
    end if
    if m.top.ItemType = "LiveTV"
        url = "LiveTv/Channels"
        params.append({
            UserId: m.global.session.user.id
        })
    else if m.top.view = "Networks"
        url = "Studios"
        params.append({
            UserId: m.global.session.user.id
        })
    else if isStringEqual(m.top.view, "Genres")
        url = "Genres"
        params.append({
            UserId: m.global.session.user.id
            includeItemTypes: m.top.itemType
        })
        params.append({
            "Fields": "Overview,ImageTags,PrimaryImageAspectRatio"
        })
    else if LCase(m.top.view) = "tags"
        url = "Items"
        ' Query items to collect tags - high limit for full coverage
        ' Only fetch media types that support tags (exclude audiobooks, music, etc.)
        params = {
            UserId: m.global.session.user.id
            ParentId: m.top.itemId
            Fields: "Tags,ImageTags,PrimaryImageAspectRatio"
            Recursive: true
            Limit: 500
            includeItemTypes: "Movie,Series,BoxSet"
            SortBy: "SortName"
            SortOrder: "Ascending"
        }
        print "[TAGS_DEBUG] includeItemTypes set to: Movie,Series,BoxSet"
    else if m.top.ItemType = "MusicArtist"
        url = "Artists"
        params.append({
            UserId: m.global.session.user.id
            Fields: "Genres"
        })
        params.IncludeItemTypes = "MusicAlbum,Audio"
    else if m.top.ItemType = "AlbumArtists"
        url = "Artists/AlbumArtists"
        params.append({
            UserId: m.global.session.user.id
            Fields: "Genres"
        })
        params.IncludeItemTypes = "MusicAlbum,Audio"
    else if m.top.ItemType = "MusicAlbum"
        url = "Items"
        params.append({
            ImageTypeLimit: 1
            UserId: m.global.session.user.id
        })
        params.append({
            EnableImageTypes: "Primary,Backdrop,Banner,Thumb"
        })
    else if m.top.ItemType = "audiobooks"
        params.append({
            mediaTypes: "Audio"
            UserId: m.global.session.user.id
        })
        params.append({
            Filters: "IsNotFolder"
        })
        params.append({
            EnableImageTypes: "Primary,Backdrop,Banner,Thumb"
        })
        url = "Items"
    else if LCase(m.top.ItemType) = "nextup"
        url = "Shows/NextUp"
        params.limit = 100 ' If you have more than 100 in your Next Up queue, maybe go outside a bit more.
        params.append({
            ImageTypeLimit: 1
        })
        params.append({
            EnableImageTypes: "Primary,Backdrop,Banner,Thumb"
        })
    else if isStringEqual(m.top.ItemType, "mylist")
        data = api_GetUserViews({
            "userId": m.global.session.user.id
        })
        if not isChainValid(data, "Items") then
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
        if not isValid(myListPlaylist) or not isValidAndNotEmpty(myListPlaylist.items) then
            return
        end if
        playlistID = myListPlaylist.items[0].LookupCI("id")
        if not isValid(playlistID) then
            return
        end if
        url = "/items/"
        params.append({
            UserId: m.global.session.user.id
            ImageTypeLimit: 1
            EnableImageTypes: (bslib_toString("Primary") + ", " + bslib_toString("Backdrop") + ", " + bslib_toString("Thumb"))
            Limit: 50
            EnableTotalRecordCount: false
            ParentId: playlistID
        })
    else
        params.append({
            UserId: m.global.session.user.id
        })
        url = "Items"
    end if
    ' Handle Folders filter - show movies with folder name as title
    if LCase(m.top.filter) = "folders"
        movieResp = APIRequest("Items", {
            "userId": m.global.session.user.id
            "parentId": m.top.itemId
            "includeItemTypes": "Movie"
            "Limit": 500
            "StartIndex": 0
            "SortBy": "SortName"
            "SortOrder": "Ascending"
            "Fields": "ImageTags,Path"
        })
        movieData = getJson(movieResp)
        if isValid(movieData) and isValid(movieData.Items)
            if isValid(movieData.TotalRecordCount) then
                m.top.totalRecordCount = movieData.TotalRecordCount
            end if
            for each item in movieData.Items
                tmp = CreateObject("roSGNode", "MovieData")
                tmp.json = item
                tmp.id = item.id
                tmp.type = "Movie"
                ' Extract folder name from Path (second-to-last segment)
                ' e.g., /movies/MyFolder/file.mkv -> MyFolder
                folderName = ""
                if isValid(item.Path) and item.Path <> ""
                    pathStr = item.Path
                    ' Find last two "/" separators
                    lastSep = 0
                    prevSep = 0
                    searchStart = 1
                    while searchStart < pathStr.Len()
                        found = Instr(searchStart, pathStr, "/")
                        if found = 0 then
                            exit while
                        end if
                        prevSep = lastSep
                        lastSep = found
                        searchStart = found + 1
                    end while
                    if prevSep > 0
                        folderName = Mid(pathStr, prevSep + 1, lastSep - prevSep - 1)
                    end if
                end if
                if folderName = "" then
                    folderName = item.Name
                end if
                tmp.title = folderName
                tmp.Title = folderName
                if isValid(item.ImageTags) and isValid(item.ImageTags.Primary)
                    tmp.posterUrl = api_items_GetImageURL(item.Id, "Primary", 0, {
                        "maxWidth": 270
                        "maxHeight": 400
                    })
                end if
                results.push(tmp)
            end for
        end if
        m.top.content = results
        return
    end if
    ' Handle Trailers filter
    if LCase(m.top.filter) = "trailers"
        trailerParams = {
            "userId": m.global.session.user.id
            "Limit": m.top.limit
            "StartIndex": m.top.startIndex
            "Fields": "Overview,PrimaryImageAspectRatio,ImageTags"
        }
        trailerResp = api_trailers_Get(trailerParams)
        if isValid(trailerResp) and isValid(trailerResp.Items)
            if isValid(trailerResp.TotalRecordCount) then
                m.top.totalRecordCount = trailerResp.TotalRecordCount
            end if
            for each item in trailerResp.Items
                tmp = CreateObject("roSGNode", "MovieData")
                tmp.json = item
                tmp.id = item.id
                tmp.title = item.Name
                tmp.Title = item.Name
                tmp.type = "Movie"
                if isValid(item.ImageTags) and isValid(item.ImageTags.Primary)
                    tmp.posterUrl = api_items_GetImageURL(item.id, "Primary", 0, {
                        "maxWidth": 270
                        "maxHeight": 400
                    })
                end if
                results.push(tmp)
            end for
        end if
        m.top.content = results
        return
    end if
    ' Handle Playlists filter
    if LCase(m.top.filter) = "playlists"
        playlistParams = {
            "userId": m.global.session.user.id
            "parentId": m.top.itemId
            "includeItemTypes": "Playlist"
            "Limit": m.top.limit
            "StartIndex": m.top.startIndex
            "SortBy": "SortName"
            "SortOrder": "Ascending"
            "Fields": "Overview,PrimaryImageAspectRatio,ImageTags"
            "recursive": true
        }
        playlistResp = APIRequest("Items", playlistParams)
        playlistData = getJson(playlistResp)
        if isValid(playlistData) and isValid(playlistData.Items)
            if isValid(playlistData.TotalRecordCount) then
                m.top.totalRecordCount = playlistData.TotalRecordCount
            end if
            for each item in playlistData.Items
                tmp = CreateObject("roSGNode", "MovieData")
                tmp.json = item
                tmp.id = item.id
                tmp.title = item.Name
                tmp.Title = item.Name
                tmp.type = "Playlist"
                if isValid(item.ImageTags) and isValid(item.ImageTags.Primary)
                    tmp.posterUrl = api_items_GetImageURL(item.id, "Primary", 0, {
                        "maxWidth": 270
                        "maxHeight": 400
                    })
                end if
                results.push(tmp)
            end for
        end if
        m.top.content = results
        return
    end if
    ' Handle Collections filter
    if LCase(m.top.filter) = "collections"
        collectionParams = {
            "userId": m.global.session.user.id
            "parentId": m.top.itemId
            "includeItemTypes": "BoxSet"
            "Limit": m.top.limit
            "StartIndex": m.top.startIndex
            "SortBy": "SortName"
            "SortOrder": "Ascending"
            "Fields": "Overview,PrimaryImageAspectRatio,ImageTags"
            "recursive": true
        }
        collectionResp = APIRequest("Items", collectionParams)
        collectionData = getJson(collectionResp)
        if isValid(collectionData) and isValid(collectionData.Items)
            if isValid(collectionData.TotalRecordCount) then
                m.top.totalRecordCount = collectionData.TotalRecordCount
            end if
            for each item in collectionData.Items
                tmp = CreateObject("roSGNode", "CollectionData")
                tmp.json = item
                tmp.id = item.id
                tmp.title = item.Name
                tmp.type = "BoxSet"
                if isValid(item.ImageTags) and isValid(item.ImageTags.Primary)
                    tmp.posterUrl = api_items_GetImageURL(item.id, "Primary", 0, {
                        "maxWidth": 270
                        "maxHeight": 400
                    })
                end if
                results.push(tmp)
            end for
        end if
        m.top.content = results
        return
    end if
    resp = APIRequest(url, params)
    data = getJson(resp)
    ' If user has filtered by #, include special characters sorted after Z as well
    if isValid(params.NameLessThan)
        if LCase(params.NameLessThan) = "a"
            ' Use same params except for name filter param
            params.NameLessThan = ""
            params.NameStartsWithOrGreater = "z"
            ' Perform 2nd API lookup for items starting with Z or greater
            startsWithZAndGreaterResp = APIRequest(url, params)
            startsWithZAndGreaterData = getJson(startsWithZAndGreaterResp)
            if isValidAndNotEmpty(startsWithZAndGreaterData)
                specialCharacterItems = []
                ' Filter out items starting with Z
                for each item in startsWithZAndGreaterData.Items
                    itemName = LCase(item.name)
                    if not itemName.StartsWith("z")
                        specialCharacterItems.Push(item)
                    end if
                end for
                ' Append data to results from before A
                data.Items.Append(specialCharacterItems)
                data.TotalRecordCount += specialCharacterItems.Count()
            end if
        end if
    end if
    if data <> invalid
        if isStringEqual(m.top.view, "Tags")
            tagsList = []
            uniqueTags = {}
            tagImages = {} ' Store sample images for each tag
            tagChildren = {} ' Store sample child nodes for each tag
            tagItemCount = 0
            if type(data) = "roAssociativeArray" and isValid(data.Items)
                for each item in data.Items
                    tagArray = invalid
                    if isValid(item.Tags) and type(item.Tags) = "roArray"
                        tagArray = item.Tags
                    else if isValid(item.TagItems) and type(item.TagItems) = "roArray"
                        tagArray = item.TagItems
                    end if
                    if tagArray <> invalid
                        tagItemCount++
                        ' Get item image for tag thumbnail
                        itemImage = ""
                        if isValid(item.Id) and isValid(item.ImageTags) and isValid(item.ImageTags.Primary)
                            itemImage = api_items_GetImageURL(item.Id, "primary", 0, {
                                "maxWidth": 270
                                "maxHeight": 270
                            })
                        end if
                        for each tag in tagArray
                            tagStr = ""
                            if (type(tag) = "String" or type(tag) = "roString") and tag <> ""
                                tagStr = tag
                            else if type(tag) = "roAssociativeArray"
                                if isValid(tag.Name) and tag.Name <> ""
                                    tagStr = tag.Name
                                else if isValid(tag.name) and tag.name <> ""
                                    tagStr = tag.name
                                end if
                            end if
                            if tagStr <> ""
                                lcTag = LCase(tagStr)
                                if not isValid(uniqueTags[lcTag])
                                    uniqueTags[lcTag] = tagStr
                                    tagChildren[lcTag] = []
                                    ' Store first available image for this tag
                                    if itemImage <> ""
                                        tagImages[lcTag] = itemImage
                                    end if
                                end if
                                ' Collect up to 4 sample children for 2x2 grid
                                if tagChildren[lcTag].Count() < 4
                                    childNode = CreateObject("roSGNode", "MovieData")
                                    childNode.id = item.id
                                    childNode.posterUrl = api_items_GetImageURL(item.id, "primary", 0, {
                                        "maxWidth": 200
                                        "maxHeight": 300
                                    })
                                    childNode.backdropUrl = api_items_GetImageURL(item.id, "backdrop", 0, {
                                        "maxWidth": 1920
                                        "maxHeight": 1080
                                    })
                                    tagChildren[lcTag].push(childNode)
                                end if
                            end if
                        end for
                    end if
                end for
            end if
            for each tagKey in uniqueTags
                tagValue = uniqueTags[tagKey]
                tagImage = ""
                if isValid(tagImages[tagKey])
                    tagImage = tagImages[tagKey]
                end if
                tagsList.push({
                    Name: tagValue
                    Id: tagValue
                    Type: "Tag"
                    ImageUrl: tagImage
                    Children: tagChildren[tagKey]
                })
            end for
            ' Sort tags alphabetically by name (case-insensitive)
            if tagsList.Count() > 1
                ' Create lowercase map for case-insensitive sorting
                sortIndex = []
                for i = 0 to tagsList.Count() - 1
                    sortIndex.push({
                        lcName: LCase(tagsList[i].Name)
                        originalIndex: i
                    })
                end for
                ' Simple insertion sort on the index
                for i = 1 to sortIndex.Count() - 1
                    key = sortIndex[i]
                    j = i - 1
                    while j >= 0 and sortIndex[j].lcName > key.lcName
                        sortIndex[j + 1] = sortIndex[j]
                        j = j - 1
                    end while
                    sortIndex[j + 1] = key
                end for
                ' Rebuild list in sorted order
                sortedTags = []
                for each idx in sortIndex
                    sortedTags.push(tagsList[idx.originalIndex])
                end for
                tagsList = sortedTags
            end if
            data = {
                Items: tagsList
                TotalRecordCount: tagsList.Count()
            }
        end if
        ' Normalize flat array responses
        if type(data) = "roArray"
            data = {
                Items: data
                TotalRecordCount: data.Count()
            }
        end if
        if data.TotalRecordCount <> invalid then
            m.top.totalRecordCount = data.TotalRecordCount
        end if
        for each item in data.Items
            tmp = invalid
            ' Ensure item is an object if we're going to check .Type
            itemType = ""
            if type(item) = "roAssociativeArray"
                if item.Type <> invalid then
                    itemType = item.Type
                end if
            end if
            if m.top.ItemType = "audiobooks"
                if itemType = "AudioBook"
                    tmp = CreateObject("roSGNode", "MusicSongData")
                    tmp.posterUrl = api_items_GetImageURL(item.id, "primary", 0, {
                        "maxHeight": 280
                        "maxWidth": 280
                        "quality": "90"
                    })
                    tmp.type = "audiobook"
                    tmp.json = item
                    tmp.title = item.name
                end if
            else
                if itemType = "Movie" or itemType = "MusicVideo"
                    tmp = CreateObject("roSGNode", "MovieData")
                else if itemType = "Series"
                    tmp = CreateObject("roSGNode", "SeriesData")
                else if itemType = "BoxSet" or itemType = "ManualPlaylistsFolder"
                    tmp = CreateObject("roSGNode", "CollectionData")
                else if itemType = "TvChannel"
                    tmp = CreateObject("roSGNode", "ChannelData")
                else if itemType = "Folder" or itemType = "ChannelFolderItem" or itemType = "CollectionFolder"
                    tmp = CreateObject("roSGNode", "FolderData")
                else if itemType = "Video" or itemType = "Recording"
                    tmp = CreateObject("roSGNode", "VideoData")
                else if itemType = "Photo"
                    tmp = CreateObject("roSGNode", "PhotoData")
                else if itemType = "PhotoAlbum"
                    tmp = CreateObject("roSGNode", "FolderData")
                else if itemType = "Playlist"
                    tmp = CreateObject("roSGNode", "PlaylistData")
                    tmp.type = "Playlist"
                    tmp.image = PosterImage(item.id, {
                        "maxHeight": 450
                        "maxWidth": 450
                        "quality": "90"
                    })
                else if itemType = "Episode"
                    tmp = CreateObject("roSGNode", "TVEpisode")
                    tmp.title = item.name
                    seasonName = (" - " + bslib_toString(item.LookupCI("SeasonName")))
                    if isValid(item.LookupCI("IndexNumber"))
                        seasonName += (" " + bslib_toString(tr("Episode")) + " " + bslib_toString(item.LookupCI("IndexNumber")))
                    end if
                    tmp.fullNameWithShowTitle = (bslib_toString(item.LookupCI("seriesname")) + bslib_toString(seasonName) + " - " + bslib_toString(item.LookupCI("name")))
                    if LCase(m.top.ItemType) = "nextup"
                        tmp.type = "Episode"
                    end if
                else if LCase(itemType) = "recording"
                    tmp = CreateObject("roSGNode", "RecordingData")
                else if itemType = "Genre"
                    tmp = CreateObject("roSGNode", "FolderData")
                    tmp.title = item.name
                    tmp.id = item.id
                    tmp.type = "Genre"
                    ' Get sample poster from genre's own ImageTags or fetch a sample item
                    genrePoster = ""
                    if isValid(item.ImageTags) and isValid(item.ImageTags.Primary)
                        genrePoster = api_items_GetImageURL(item.id, "Primary", 0, {
                            "maxWidth": 270
                            "maxHeight": 400
                        })
                    else
                        sampleParams = {
                            UserId: m.global.session.user.id
                            IncludeItemTypes: m.top.itemType
                            Recursive: true
                            Limit: 1
                            Fields: "ImageTags"
                            GenreIds: item.id
                        }
                        sampleResp = APIRequest("Items", sampleParams)
                        sampleData = getJson(sampleResp)
                        if isValid(sampleData) and isValid(sampleData.Items) and sampleData.Items.Count() > 0
                            firstItem = sampleData.Items[0]
                            if isValid(firstItem.ImageTags) and isValid(firstItem.ImageTags.Primary)
                                genrePoster = api_items_GetImageURL(firstItem.Id, "Primary", 0, {
                                    "maxWidth": 270
                                    "maxHeight": 400
                                })
                            end if
                        end if
                    end if
                    if genrePoster <> "" then
                        tmp.posterUrl = genrePoster
                    end if
                    tagJson = {
                        name: item.name
                        id: item.id
                        type: "Genre"
                    }
                    tmp.parentFolder = m.top.itemId
                    tmp.json = tagJson
                else if itemType = "Tag" or isStringEqual(m.top.view, "Tags")
                    tmp = CreateObject("roSGNode", "FolderData")
                    tagImage = ""
                    if type(item) = "roString"
                        tmp.title = item
                        tmp.id = item
                        tagJson = {
                            name: item
                            id: item
                            type: "Tag"
                        }
                    else
                        tmp.title = item.name
                        tmp.id = item.id
                        tagJson = item
                        tagJson.AddReplace("type", "Tag")
                        ' Get image URL from tag data if available
                        if isValid(item.ImageUrl) and item.ImageUrl <> ""
                            tagImage = item.ImageUrl
                        end if
                    end if
                    tmp.type = "Tag"
                    tmp.parentFolder = m.top.itemId
                    tmp.json = tagJson
                    ' Set poster images if we have an image URL
                    if tagImage <> ""
                        tmp.FHDPOSTERURL = tagImage
                        tmp.HDPOSTERURL = tagImage
                        tmp.SDPOSTERURL = tagImage
                        tmp.posterUrl = tagImage
                    end if
                    ' Add sample children for 2x2 grid
                    if isValid(item.Children)
                        for each child in item.Children
                            tmp.appendChild(child)
                        end for
                    end if
                else if itemType = "Studio"
                    tmp = CreateObject("roSGNode", "FolderData")
                else if itemType = "MusicAlbum"
                    tmp = CreateObject("roSGNode", "MusicAlbumData")
                    tmp.type = "MusicAlbum"
                    if api_items_HeadImageURLByName(item.id, "primary")
                        tmp.posterURL = ImageURL(item.id, "Primary")
                    else
                        tmp.posterURL = ImageURL(item.id, "backdrop")
                    end if
                else if itemType = "MusicArtist"
                    tmp = CreateObject("roSGNode", "MusicArtistData")
                else if itemType = "Audio"
                    tmp = CreateObject("roSGNode", "MusicSongData")
                    tmp.type = "Audio"
                    tmp.image = api_items_GetImageURL(item.id, "primary", 0, {
                        "maxHeight": 280
                        "maxWidth": 280
                        "quality": "90"
                    })
                else if itemType = "MusicGenre"
                    tmp = CreateObject("roSGNode", "FolderData")
                    tmp.title = item.name
                    tmp.parentFolder = m.top.itemId
                    tmp.json = item
                    tmp.type = "Folder"
                    tmp.posterUrl = api_items_GetImageURL(item.id, "primary", 0, {
                        "maxHeight": 270
                        "maxWidth": 270
                        "quality": "90"
                    })
                else
                    ' print `Unknown Type ${item.Type}`
                end if
            end if
            if tmp <> invalid
                item.AddReplace("passedData", m.top.passToItem)
                if not isStringEqual(item.Type, "genre") and LCase(item.Type) <> "musicgenre"
                    tmp.parentFolder = m.top.itemId
                    tmp.json = item
                    if item.UserData <> invalid and item.UserData.isFavorite <> invalid
                        tmp.favorite = item.UserData.isFavorite
                    end if
                end if
                results.push(tmp)
            end if
        end for
    end if
    m.top.content = results
end sub
'//# sourceMappingURL=./LoadItemsTask2.brs.map