'import "pkg:/source/api/baserequest.bs"
'import "pkg:/source/api/Image.bs"
'import "pkg:/source/api/Items.bs"
'import "pkg:/source/api/sdk.bs"
'import "pkg:/source/enums/ItemType.bs"
'import "pkg:/source/enums/String.bs"
'import "pkg:/source/utils/config.bs"
'import "pkg:/source/utils/deviceCapabilities.bs"
'import "pkg:/source/utils/misc.bs"

sub init()
    m.top.itemsToLoad = "libraries"
    m.top.functionName = "loadItems"
end sub

function loadLibraries() as object
    results = []
    data = api_GetUserViews({
        "userId": m.global.session.user.id
    })
    if not isChainValid(data, "items") then
        return results
    end if
    for each item in data.LookupCI("items")
        itemName = item.LookupCI("name")
        itemId = item.LookupCI("Id")
        ' Skip items with no name or no ID (prevents empty boxes)
        if not isValidAndNotEmpty(itemName) or not isValidAndNotEmpty(itemId) then
            continue for
        end if
        if itemName.trim() = "" then
            continue for
        end if
        ' Explicitly filter out "My List" and "Collections" ghost boxes
        itemNameLower = LCase(itemName)
        if itemNameLower = "my list" then
            continue for
        end if
        ' If it has no image tags and is not a recognized type with an icon fallback, skip it
        imageTags = item.LookupCI("ImageTags")
        hasImages = isValidAndNotEmpty(imageTags) and type(imageTags) = "roAssociativeArray" and imageTags.count() > 0
        if not hasImages
            collectionType = LCase((function(item)
                    __bsConsequent = item.LookupCI("CollectionType")
                    if __bsConsequent <> invalid then
                        return __bsConsequent
                    else
                        return ""
                    end if
                end function)(item))
            ' Recognized types that we have icons for in HomeData.bs
            if not inArray([
                "livetv"
                "folders"
                "nextup"
                "playlists"
                "movies"
                "tvshows"
                "music"
                "boxsets"
                "boxset"
                "collections"
            ], collectionType)
                continue for
            end if
        end if
        tmp = CreateObject("roSGNode", "HomeData")
        tmp.json = {
            id: item.LookupCI("Id")
            name: item.LookupCI("name")
            Type: item.LookupCI("Type")
            CollectionType: item.LookupCI("CollectionType")
            ImageTags: item.LookupCI("ImageTags")
            UserData: item.LookupCI("UserData")
            ParentThumbImageTag: item.LookupCI("ParentThumbImageTag")
            ParentBackdropImageTags: item.LookupCI("ParentBackdropImageTags")
            ParentBackdropItemId: item.LookupCI("ParentBackdropItemId")
            SeriesPrimaryImageTag: item.LookupCI("SeriesPrimaryImageTag")
            BackdropImageTags: item.LookupCI("BackdropImageTags")
        }
        tmp.collectionType = item.LookupCI("CollectionType")
        results.push(tmp)
    end for
    return results
end function

function loadLatestMedia() as object
    results = []
    params = {
        userId: m.global.session.user.id
        limit: 25
        parentId: m.top.itemId
        enableImageTypes: (bslib_toString("Primary") + ", " + bslib_toString("Backdrop") + ", " + bslib_toString("Thumb"))
        imageTypeLimit: 1
        enableTotalRecordCount: false
        fields: "Genres"
    }
    data = api_items_GetLatest(params)
    if not isValidAndNotEmpty(data) then
        return results
    end if
    for each item in data
        if not isStringEqual(item.Type, "book")
            tmp = CreateObject("roSGNode", "HomeData")
            tmp.json = {
                id: item.LookupCI("Id")
                name: item.LookupCI("name")
                Type: item.LookupCI("Type")
                CollectionType: item.LookupCI("CollectionType")
                ChannelName: item.LookupCI("ChannelName")
                ChannelId: item.LookupCI("ChannelId")
                EpisodeTitle: item.LookupCI("EpisodeTitle")
                ChildCount: item.LookupCI("ChildCount")
                EndDate: item.LookupCI("EndDate")
                OfficialRating: item.LookupCI("OfficialRating")
                ProductionYear: item.LookupCI("ProductionYear")
                Album: item.LookupCI("Album")
                SeriesName: item.LookupCI("SeriesName")
                SeriesId: item.LookupCI("SeriesId")
                SeasonId: item.LookupCI("SeasonId")
                ParentIndexNumber: item.LookupCI("ParentIndexNumber")
                IndexNumber: item.LookupCI("IndexNumber")
                IndexNumberEnd: item.LookupCI("IndexNumberEnd")
                AlbumArtist: item.LookupCI("AlbumArtist")
                AlbumArtistId: (function(__bsCondition, item)
                        if __bsCondition then
                            return item.AlbumArtists[0].LookupCI("id")
                        else
                            return invalid
                        end if
                    end function)(isValidAndNotEmpty(item.AlbumArtists), item)
                Genre: (function(__bsCondition, item)
                        if __bsCondition then
                            return item.GenreItems
                        else
                            return invalid
                        end if
                    end function)(isValidAndNotEmpty(item.GenreItems), item)
                Status: item.LookupCI("Status")
                ImageTags: item.LookupCI("ImageTags")
                UserData: item.LookupCI("UserData")
                ParentThumbImageTag: item.LookupCI("ParentThumbImageTag")
                ParentBackdropImageTags: item.LookupCI("ParentBackdropImageTags")
                ParentBackdropItemId: item.LookupCI("ParentBackdropItemId")
                SeriesPrimaryImageTag: item.LookupCI("SeriesPrimaryImageTag")
                BackdropImageTags: item.LookupCI("BackdropImageTags")
                LibraryId: m.top.itemId
            }
            results.push(tmp)
        end if
    end for
    return results
end function

function loadContinueWatching() as object
    results = []
    params = {
        recursive: true
        SortBy: "DatePlayed"
        SortOrder: "Descending"
        Filters: "IsResumable"
        MediaTypes: "video"
        excludeItemTypes: "book"
        EnableTotalRecordCount: false
    }
    data = api_useritems_GetResumeItems(params)
    if not isChainValid(data, "Items") then
        return results
    end if
    for each item in data.Items
        tmp = CreateObject("roSGNode", "HomeData")
        tmp.Id = item.LookupCI("Id")
        tmp.name = item.LookupCI("name")
        tmp.type = item.LookupCI("Type")
        tmp.json = {
            Id: item.LookupCI("Id")
            name: item.LookupCI("name")
            Type: item.LookupCI("Type")
            SeriesName: item.LookupCI("SeriesName")
            SeriesId: item.LookupCI("SeriesId")
            SeasonId: item.LookupCI("SeasonId")
            ProductionYear: item.LookupCI("ProductionYear")
            Status: item.LookupCI("Status")
            EndDate: item.LookupCI("EndDate")
            ParentIndexNumber: item.LookupCI("ParentIndexNumber")
            IndexNumber: item.LookupCI("IndexNumber")
            IndexNumberEnd: item.LookupCI("IndexNumberEnd")
            OfficialRating: item.LookupCI("OfficialRating")
            CollectionType: item.LookupCI("CollectionType")
            ImageTags: item.LookupCI("ImageTags")
            UserData: item.LookupCI("UserData")
            ParentThumbItemId: item.LookupCI("ParentThumbItemId")
            ParentThumbImageTag: item.LookupCI("ParentThumbImageTag")
            ParentBackdropImageTags: item.LookupCI("ParentBackdropImageTags")
            ParentBackdropItemId: item.LookupCI("ParentBackdropItemId")
            SeriesPrimaryImageTag: item.LookupCI("SeriesPrimaryImageTag")
            BackdropImageTags: item.LookupCI("BackdropImageTags")
        }
        results.push(tmp)
    end for
    return results
end function

function loadSeasonOfEpisodes() as object
    results = []
    data = TVEpisodes(m.top.showID, m.top.seasonID)
    if not isChainValid(data, "Items") then
        return results
    end if
    for each item in data.LookupCI("items")
        tmp = CreateObject("roSGNode", "ExtrasData")
        imgParms = {
            "Tags": item.json.ImageTags.Primary
            MaxWidth: 502
            MaxHeight: 300
        }
        tmp.posterURL = ImageUrl(item.Id, "Primary", imgParms)
        tmp.json = {
            Id: item.LookupCI("ID")
            IndexNumber: item.json.LookupCI("IndexNumber")
            Name: item.json.LookupCI("Name")
            ParentIndexNumber: item.json.LookupCI("ParentIndexNumber")
            IndexNumberEnd: item.json.LookupCI("IndexNumberEnd")
            ProductionYear: item.json.LookupCI("ProductionYear")
            SeriesName: item.json.LookupCI("SeriesName")
            EndDate: item.json.LookupCI("EndDate")
            Type: item.json.LookupCI("Type")
        }
        results.push(tmp)
    end for
    return results
end function

function loadContinueListening() as object
    results = []
    params = {
        recursive: true
        SortBy: "DatePlayed"
        SortOrder: "Descending"
        Filters: "IsResumable"
        MediaTypes: "audio"
        EnableTotalRecordCount: false
    }
    data = api_useritems_GetResumeItems(params)
    if not isChainValid(data, "Items") then
        return results
    end if
    for each item in data.Items
        tmp = CreateObject("roSGNode", "HomeData")
        tmp.Id = item.LookupCI("Id")
        tmp.name = item.LookupCI("name")
        tmp.type = item.LookupCI("Type")
        tmp.json = {
            Id: item.LookupCI("Id")
            name: item.LookupCI("name")
            Type: item.LookupCI("Type")
            SeriesName: item.LookupCI("SeriesName")
            ProductionYear: item.LookupCI("ProductionYear")
            Status: item.LookupCI("Status")
            EndDate: item.LookupCI("EndDate")
            ParentIndexNumber: item.LookupCI("ParentIndexNumber")
            IndexNumberEnd: item.LookupCI("IndexNumberEnd")
            IndexNumber: item.LookupCI("IndexNumber")
            OfficialRating: item.LookupCI("OfficialRating")
            CollectionType: item.LookupCI("CollectionType")
            ImageTags: item.LookupCI("ImageTags")
            UserData: item.LookupCI("UserData")
            ParentThumbItemId: item.LookupCI("ParentThumbItemId")
            ParentThumbImageTag: item.LookupCI("ParentThumbImageTag")
            ParentBackdropImageTags: item.LookupCI("ParentBackdropImageTags")
            ParentBackdropItemId: item.LookupCI("ParentBackdropItemId")
            SeriesPrimaryImageTag: item.LookupCI("SeriesPrimaryImageTag")
            BackdropImageTags: item.LookupCI("BackdropImageTags")
        }
        results.push(tmp)
    end for
    return results
end function

function loadMoreLikeThis() as object
    results = []
    params = {
        "userId": m.global.session.user.id
        "limit": 25
    }
    data = api_items_GetSimilar(m.top.itemId, params)
    if not isChainValid(data, "Items") then
        return results
    end if
    for each item in data.items
        tmp = CreateObject("roSGNode", "ExtrasData")
        imgParms = {
            "Tags": item.PrimaryImageTag
            MaxWidth: 464
            MaxHeight: 720
        }
        if isStringEqual(item.LookupCI("type"), "musicvideo")
            imgParms.MaxHeight = 260
            imgParms.MaxWidth = 400
        end if
        tmp.posterURL = ImageUrl(item.Id, "Primary", imgParms)
        tmp.json = {
            Id: item.LookupCI("ID")
            Name: item.LookupCI("Name")
            PremiereDate: item.LookupCI("PremiereDate")
            OfficialRating: item.LookupCI("OfficialRating")
            ProductionYear: item.LookupCI("ProductionYear")
            EndDate: item.LookupCI("EndDate")
            Type: item.LookupCI("Type")
        }
        results.push(tmp)
    end for
    return results
end function

function loadSimilarArtists() as object
    results = []
    params = {
        userId: m.global.session.user.id
        limit: 19
        enableImageTypes: (bslib_toString("Primary"))
    }
    data = api_artists_GetSimilar(m.top.itemId, params)
    if not isChainValid(data, "Items") then
        return results
    end if
    i = 0
    for each item in data.items
        ' Don't include Various Artists
        if isStringEqual("Various Artists", item.LookupCI("Name"))
            continue for
        end if
        tmp = CreateObject("roSGNode", "MusicArtistData")
        imgParms = {
            "Tags": item.PrimaryImageTag
            MaxWidth: 270
            MaxHeight: 270
        }
        tmp.posterURL = ImageUrl(item.Id, "Primary", imgParms)
        tmp.json = {
            Id: item.LookupCI("ID")
            Name: item.LookupCI("Name")
            Type: item.LookupCI("Type")
        }
        results.push(tmp)
        i++
        if i = 18 then
            exit for
        end if
    end for
    return results
end function

function loadSpecialFeatures() as object
    results = []
    data = api_items_GetSpecialFeatures(m.top.itemId, {
        "userId": m.global.session.user.id
    })
    if not isValidAndNotEmpty(data) then
        return results
    end if
    for each item in data
        tmp = CreateObject("roSGNode", "ExtrasData")
        results.push(tmp)
        params = {
            Tags: item.ImageTags.Primary
            MaxWidth: 450
            MaxHeight: 402
        }
        tmp.posterURL = ImageUrl(item.Id, "Primary", params)
        tmp.json = {
            Id: item.LookupCI("ID")
            Name: item.LookupCI("Name")
            Type: item.LookupCI("Type")
            ExtraType: item.LookupCI("ExtraType")
        }
    end for
    return results
end function

function loadIncludedIn() as object
    results = []
    data = api_items_GetAncestors(m.top.itemId, {
        "userId": m.global.session.user.id
        "fields": "ImageTags,ProductionYear,PremiereDate"
    })
    if not isValidAndNotEmpty(data) then
        return results
    end if
    for each item in data
        ancestorType = LCase(chainLookupReturn(item, "Type", ""))
        if ancestorType <> "boxset" and ancestorType <> "playlist"
            continue for
        end if
        itemId = chainLookupReturn(item, "Id", "")
        if not isValidAndNotEmpty(itemId)
            continue for
        end if
        tmp = CreateObject("roSGNode", "ExtrasData")
        tmp.id = itemId
        tmp.imageWidth = 234
        imageParams = {
            MaxWidth: 234
            MaxHeight: 330
        }
        primaryTag = chainLookupReturn(item, "ImageTags.Primary", "")
        if isValidAndNotEmpty(primaryTag)
            imageParams.AddReplace("Tags", primaryTag)
        end if
        tmp.posterURL = ImageUrl(itemId, "Primary", imageParams)
        tmp.json = {
            Id: itemId
            Name: chainLookupReturn(item, "Name", "")
            Type: chainLookupReturn(item, "Type", "boxset")
            ProductionYear: chainLookupReturn(item, "ProductionYear", invalid)
            PremiereDate: chainLookupReturn(item, "PremiereDate", invalid)
        }
        results.push(tmp)
    end for
    return results
end function

function loadLiveTVOnNow() as object
    results = []
    params = {
        userId: m.global.session.user.id
        isAiring: true
        limit: 25
        imageTypeLimit: 1
        enableImageTypes: (bslib_toString("Primary") + ", " + bslib_toString("Backdrop") + ", " + bslib_toString("Thumb"))
        enableTotalRecordCount: false
        fields: "ChannelInfo,PrimaryImageAspectRatio"
    }
    data = api_liveTV_GetRecommendedPrograms(params)
    if not isChainValid(data, "Items") then
        return results
    end if
    for each item in data.Items
        tmp = CreateObject("roSGNode", "HomeData")
        tmp.json = {
            id: item.LookupCI("Id")
            name: item.LookupCI("name")
            ImageURL: ImageURL(item.LookupCI("Id"))
            Type: item.LookupCI("Type")
            mediatype: item.LookupCI("mediatype")
            CollectionType: item.LookupCI("CollectionType")
            ChannelName: item.LookupCI("ChannelName")
            ChannelId: item.LookupCI("ChannelId")
            EpisodeTitle: item.LookupCI("EpisodeTitle")
            ChildCount: item.LookupCI("ChildCount")
            EndDate: item.LookupCI("EndDate")
            OfficialRating: item.LookupCI("OfficialRating")
            ProductionYear: item.LookupCI("ProductionYear")
            Album: item.LookupCI("Album")
            SeriesName: item.LookupCI("SeriesName")
            ParentIndexNumber: item.LookupCI("ParentIndexNumber")
            IndexNumberEnd: item.LookupCI("IndexNumberEnd")
            IndexNumber: item.LookupCI("IndexNumber")
            AlbumArtist: item.LookupCI("AlbumArtist")
            Status: item.LookupCI("Status")
            ImageTags: item.LookupCI("ImageTags")
            UserData: item.LookupCI("UserData")
            ParentThumbImageTag: item.LookupCI("ParentThumbImageTag")
            ParentBackdropImageTags: item.LookupCI("ParentBackdropImageTags")
            ParentBackdropItemId: item.LookupCI("ParentBackdropItemId")
            SeriesPrimaryImageTag: item.LookupCI("SeriesPrimaryImageTag")
            BackdropImageTags: item.LookupCI("BackdropImageTags")
        }
        results.push(tmp)
    end for
    return results
end function

function loadNextUp() as object
    results = []
    params = {
        recursive: true
        SortBy: "DatePlayed"
        SortOrder: "Descending"
        ImageTypeLimit: 1
        UserId: m.global.session.user.id
        EnableRewatching: m.global.session.user.settings["ui.details.enablerewatchingnextup"]
        DisableFirstEpisode: false
        limit: 26
        EnableTotalRecordCount: false
    }
    maxDaysInNextUp = m.global.session.user.settings["ui.details.maxdaysnextup"].ToInt()
    if isValid(maxDaysInNextUp)
        if maxDaysInNextUp > 0
            dateToday = CreateObject("roDateTime")
            dateCutoff = CreateObject("roDateTime")
            dateCutoff.FromSeconds(dateToday.AsSeconds() - (maxDaysInNextUp * 86400))
            params.AddReplace("NextUpDateCutoff", dateCutoff.ToISOString())
        end if
    end if
    addViewAll = false
    data = api_shows_GetNextUp(params)
    count = 0
    if isChainValid(data, "Items")
        for each item in data.Items
            tmp = CreateObject("roSGNode", "HomeData")
            tmp.json = item
            results.push(tmp)
            count++
            if count = 24
                addViewAll = true
                exit for
            end if
        end for
    end if
    if addViewAll
        tmp = CreateObject("roSGNode", "HomeData")
        tmp.type = "collectionfolder"
        tmp.usePoster = false
        tmp.json = {
            IsFolder: true
            Name: tr("View All Next Up")
            Type: "collectionfolder"
            CollectionType: "nextup"
        }
        results.push(tmp)
    end if
    return results
end function

function loadFavorites() as object
    results = []
    sortField = chainLookupReturn(m.global.session, "user.settings.`ui.home.favoritesSortField`", "random")
    sortOrder = chainLookupReturn(m.global.session, "user.settings.`ui.home.favoritesSortOrder`", "Ascending")
    params = {
        userid: m.global.session.user.id
        Filters: "IsFavorite"
        Limit: 25
        recursive: true
        sortby: sortField
        sortOrder: sortOrder
        EnableTotalRecordCount: false
    }
    data = api_items_Get(params)
    if not isChainValid(data, "Items") then
        return results
    end if
    for each item in data.Items
        if inArray([
            "book"
            "audio"
        ], item.type) then
            continue for
        end if
        tmp = CreateObject("roSGNode", "HomeData")
        params = {
            Tags: item.PrimaryImageTag
            MaxWidth: 234
            MaxHeight: 330
        }
        tmp.posterURL = ImageUrl(item.Id, "Primary", params)
        tmp.json = {
            Id: item.LookupCI("Id")
            name: item.LookupCI("name")
            Type: item.LookupCI("Type")
            SeriesName: item.LookupCI("SeriesName")
            SeriesId: item.LookupCI("SeriesId")
            SeasonId: item.LookupCI("SeasonId")
            ProductionYear: item.LookupCI("ProductionYear")
            Status: item.LookupCI("Status")
            EndDate: item.LookupCI("EndDate")
            ParentIndexNumber: item.LookupCI("ParentIndexNumber")
            IndexNumberEnd: item.LookupCI("IndexNumberEnd")
            IndexNumber: item.LookupCI("IndexNumber")
            OfficialRating: item.LookupCI("OfficialRating")
            CollectionType: item.LookupCI("CollectionType")
            ImageTags: item.LookupCI("ImageTags")
            UserData: item.LookupCI("UserData")
            ParentThumbItemId: item.LookupCI("ParentThumbItemId")
            ParentThumbImageTag: item.LookupCI("ParentThumbImageTag")
            ParentBackdropImageTags: item.LookupCI("ParentBackdropImageTags")
            ParentBackdropItemId: item.LookupCI("ParentBackdropItemId")
            SeriesPrimaryImageTag: item.LookupCI("SeriesPrimaryImageTag")
            BackdropImageTags: item.LookupCI("BackdropImageTags")
        }
        results.push(tmp)
    end for
    return results
end function

function loadIsInMyList() as object
    results = [
        false
    ]
    listData = loadMyList()
    for each item in listData
        if isStringEqual(m.top.itemId, item.LookupCI("id"))
            results = [
                true
            ]
            exit for
        end if
    end for
    return results
end function

function loadMyList() as object
    results = []
    data = api_GetUserViews({
        "userId": m.global.session.user.id
    })
    if not isChainValid(data, "Items") then
        return results
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
        return results
    end if
    playlistID = myListPlaylist.items[0].LookupCI("id")
    if not isValid(playlistID) then
        return results
    end if
    myListData = api_items_Get({
        UserId: m.global.session.user.id
        ImageTypeLimit: 1
        EnableImageTypes: (bslib_toString("Primary") + ", " + bslib_toString("Backdrop") + ", " + bslib_toString("Thumb"))
        Limit: 50
        EnableTotalRecordCount: false
        ParentId: playlistID
    })
    if not isChainValid(myListData, "Items") then
        return results
    end if
    for each item in myListData.Items
        if inArray([
            "book"
            "audio"
        ], item.type) then
            continue for
        end if
        tmp = CreateObject("roSGNode", "HomeData")
        params = {
            Tags: item.PrimaryImageTag
            MaxWidth: 234
            MaxHeight: 330
        }
        tmp.posterURL = ImageUrl(item.Id, "Primary", params)
        tmp.json = {
            PlaylistID: playlistID
            Id: item.LookupCI("Id")
            name: item.LookupCI("name")
            Type: item.LookupCI("Type")
            SeriesName: item.LookupCI("SeriesName")
            SeriesId: item.LookupCI("SeriesId")
            SeasonId: item.LookupCI("SeasonId")
            ProductionYear: item.LookupCI("ProductionYear")
            Status: item.LookupCI("Status")
            EndDate: item.LookupCI("EndDate")
            ParentIndexNumber: item.LookupCI("ParentIndexNumber")
            IndexNumberEnd: item.LookupCI("IndexNumberEnd")
            IndexNumber: item.LookupCI("IndexNumber")
            OfficialRating: item.LookupCI("OfficialRating")
            CollectionType: item.LookupCI("CollectionType")
            ImageTags: item.LookupCI("ImageTags")
            UserData: item.LookupCI("UserData")
            ParentThumbItemId: item.LookupCI("ParentThumbItemId")
            ParentThumbImageTag: item.LookupCI("ParentThumbImageTag")
            ParentBackdropImageTags: item.LookupCI("ParentBackdropImageTags")
            ParentBackdropItemId: item.LookupCI("ParentBackdropItemId")
            SeriesPrimaryImageTag: item.LookupCI("SeriesPrimaryImageTag")
            BackdropImageTags: item.LookupCI("BackdropImageTags")
        }
        results.push(tmp)
    end for
    if myListData.Items.count() > 3
        tmp = CreateObject("roSGNode", "HomeData")
        tmp.id = playlistID
        tmp.type = "collectionfolder"
        tmp.usePoster = false
        tmp.json = {
            id: playlistID
            PlaylistID: playlistID
            IsFolder: true
            Name: tr("View Full List")
            Type: "collectionfolder"
            CollectionType: "mylist"
        }
        results.Unshift(tmp)
    end if
    return results
end function

function loadPlaylists() as object
    results = []
    data = api_GetUserViews({
        "userId": m.global.session.user.id
    })
    if not isChainValid(data, "Items") then
        return results
    end if
    playlistData = invalid
    for each item in data.LookupCI("items")
        if isStringEqual(item.LookupCI("CollectionType"), "playlists")
            playlistData = api_items_Get({
                userid: m.global.session.user.id
                includeItemTypes: "Playlist"
                parentId: item.LookupCI("id")
                SortBy: "SortName"
            })
            exit for
        end if
    end for
    if not isValid(playlistData) or not isValidAndNotEmpty(playlistData.items) then
        return results
    end if
    for each item in playlistData.Items
        if isStringEqual(item.name, "|My List|") then
            continue for
        end if
        canEditPermission = api_playlists_GetUser(item.id, m.global.session.user.id)
        if not isValid(canEditPermission) then
            continue for
        end if
        if not isChainValid(canEditPermission, "canedit") then
            continue for
        end if
        if not chainLookup(canEditPermission, "canedit") then
            continue for
        end if
        tmp = CreateObject("roSGNode", "PlaylistData")
        tmp.type = "Playlist"
        tmp.title = item.name
        tmp.id = item.id
        results.push(tmp)
    end for
    return results
end function

function loadItemsByPerson(videoType, dimens = {}) as object
    results = []
    params = {
        userid: m.global.session.user.id
        personIds: m.top.itemId
        recursive: true
        includeItemTypes: videoType
        Limit: 50
        SortBy: "Random"
    }
    data = api_items_Get(params)
    if not isValidAndNotEmpty(data) then
        return results
    end if
    for each item in data.items
        tmp = CreateObject("roSGNode", "ExtrasData")
        imgParms = {
            "Tags": item.ImageTags.Primary
        }
        imgParms.append(dimens)
        tmp.posterURL = ImageUrl(item.Id, "Primary", imgParms)
        tmp.json = {
            Id: item.LookupCI("ID")
            IndexNumber: item.LookupCI("IndexNumber")
            Name: item.LookupCI("Name")
            ParentIndexNumber: item.LookupCI("ParentIndexNumber")
            IndexNumberEnd: item.LookupCI("IndexNumberEnd")
            ProductionYear: item.LookupCI("ProductionYear")
            SeriesName: item.LookupCI("SeriesName")
            EndDate: item.LookupCI("EndDate")
            Type: item.LookupCI("Type")
        }
        results.push(tmp)
    end for
    return results
end function

function loadPeople() as object
    results = []
    for each person in m.top.peopleList
        tmp = CreateObject("roSGNode", "ExtrasData")
        tmp.Id = person.Id
        tmp.labelText = person.Name
        params = {
            Tags: person.PrimaryImageTag
            MaxWidth: 234
            MaxHeight: 330
        }
        tmp.posterURL = ImageUrl(person.Id, "Primary", params)
        tmp.json = {
            type: person.LookupCI("type")
            Role: person.LookupCI("role")
        }
        results.push(tmp)
    end for
    return results
end function

sub loadItems()
    if not isValidAndNotEmpty(m.global.session.user.id)
        m.top.content = []
        return
    end if
    if isStringEqual(m.top.itemsToLoad, "libraries")
        m.top.content = loadLibraries()
        return
    end if
    if isStringEqual(m.top.itemsToLoad, "latest")
        m.top.content = loadLatestMedia()
        return
    end if
    if isStringEqual(m.top.itemsToLoad, "continue")
        m.top.content = loadContinueWatching()
        return
    end if
    if isStringEqual(m.top.itemsToLoad, "nextUp")
        m.top.content = loadNextUp()
        return
    end if
    if isStringEqual(m.top.itemsToLoad, "seasonOfEpisodes")
        try
            m.top.content = loadSeasonOfEpisodes()
        catch e
            m.top.content = []
        end try
        return
    end if
    if isStringEqual(m.top.itemsToLoad, "favorites")
        m.top.content = loadFavorites()
        return
    end if
    if isStringEqual(m.top.itemsToLoad, "mylist")
        m.top.content = loadMyList()
        return
    end if
    if isStringEqual(m.top.itemsToLoad, "playlists")
        m.top.content = loadPlaylists()
        return
    end if
    if isStringEqual(m.top.itemsToLoad, "isInMyList")
        m.top.content = loadIsInMyList()
        return
    end if
    if isStringEqual(m.top.itemsToLoad, "backdropImage")
        m.top.content = [
            BackdropImage(m.top.itemId)
        ]
        return
    end if
    if isStringEqual(m.top.itemsToLoad, "audioStream")
        m.top.content = [
            AudioStream(m.top.itemId)
        ]
        return
    end if
    if isStringEqual(m.top.itemsToLoad, "metaData")
        metaTimer = CreateObject("roTimespan")
        metaTimer.Mark()
        traceStep("MOVIE_TRACE", "LoadItemsTask.metaData start itemId=" + m.top.itemId)
        m.top.content = [
            ItemMetaData(m.top.itemId, false)
        ]
        traceStep("MOVIE_TRACE", "LoadItemsTask.metaData end itemId=" + m.top.itemId + " elapsedMs=" + stri(metaTimer.TotalMilliseconds()).trim())
        return
    end if
    if isStringEqual(m.top.itemsToLoad, "personSeries")
        m.top.content = loadItemsByPerson("series")
        return
    end if
    if isStringEqual(m.top.itemsToLoad, "personTVShows")
        m.top.content = loadItemsByPerson("episode", {
            MaxWidth: 502
            MaxHeight: 300
        })
        return
    end if
    if isStringEqual(m.top.itemsToLoad, "personMovies")
        m.top.content = loadItemsByPerson("movie")
        return
    end if
    if isStringEqual(m.top.itemsToLoad, "people")
        m.top.content = loadPeople()
        return
    end if
    if isStringEqual(m.top.itemsToLoad, "likethis")
        m.top.content = loadMoreLikeThis()
        return
    end if
    if isStringEqual(m.top.itemsToLoad, "similarartists")
        m.top.content = loadSimilarArtists()
        return
    end if
    if isStringEqual(m.top.itemsToLoad, "specialfeatures")
        m.top.content = loadSpecialFeatures()
        return
    end if
    if isStringEqual(m.top.itemsToLoad, "includedin")
        m.top.content = loadIncludedIn()
        return
    end if
    if isStringEqual(m.top.itemsToLoad, "continueListening")
        m.top.content = loadContinueListening()
        return
    end if
    if isStringEqual(m.top.itemsToLoad, "onNow")
        m.top.content = loadLiveTVOnNow()
        return
    end if
    m.top.content = []
end sub
'//# sourceMappingURL=./LoadItemsTask.brs.map