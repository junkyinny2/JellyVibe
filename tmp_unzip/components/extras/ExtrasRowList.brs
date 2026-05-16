'import "pkg:/source/api/sdk.bs"
'import "pkg:/source/enums/ColorPalette.bs"
'import "pkg:/source/enums/ImageType.bs"
'import "pkg:/source/enums/ItemType.bs"
'import "pkg:/source/enums/PersonType.bs"
'import "pkg:/source/enums/TaskControl.bs"
'import "pkg:/source/enums/VideoType.bs"
'import "pkg:/source/utils/controlStyle.bs"
'import "pkg:/source/utils/misc.bs"





sub init()
    m.top.visible = true
    m.top.drawFocusFeedback = true
    m.top.focusBitmapBlendColor = getControlAccentColor("#7B2FBE")
    updateSize()
    m.top.observeField("rowItemSelected", "onRowItemSelected")
    m.top.observeField("rowItemFocused", "onRowItemFocused")
    ' Set up all Tasks
    m.LoadPeopleTask = CreateObject("roSGNode", "LoadItemsTask")
    m.LoadPeopleTask.itemsToLoad = "people"
    m.LikeThisTask = CreateObject("roSGNode", "LoadItemsTask")
    m.LikeThisTask.itemsToLoad = "likethis"
    m.IncludedInTask = CreateObject("roSGNode", "LoadItemsTask")
    m.IncludedInTask.itemsToLoad = "includedin"
    m.SpecialFeaturesTask = CreateObject("roSGNode", "LoadItemsTask")
    m.SpecialFeaturesTask.itemsToLoad = "specialfeatures"
    m.LoadMoviesTask = CreateObject("roSGNode", "LoadItemsTask")
    m.LoadMoviesTask.itemsToLoad = "personMovies"
    m.LoadShowsTask = CreateObject("roSGNode", "LoadItemsTask")
    m.LoadShowsTask.itemsToLoad = "personTVShows"
    m.LoadEpisodesTask = CreateObject("roSGNode", "LoadItemsTask")
    m.LoadEpisodesTask.itemsToLoad = "seasonOfEpisodes"
    m.LoadSeriesTask = CreateObject("roSGNode", "LoadItemsTask")
    m.LoadSeriesTask.itemsToLoad = "personSeries"
end sub

sub updateSize()
    itemHeight = 396
    m.top.itemSize = [
        1710
        itemHeight
    ]
    m.top.rowItemSpacing = [
        36
        36
    ]
end sub

sub onSeasonOfEpisodesLoaded()
    data = m.LoadEpisodesTask.content
    m.LoadEpisodesTask.unobserveField("content")
    if not isValidAndNotEmpty(data) then
        return
    end if
    if not m.top.hasItems then
        m.top.hasItems = true
    end if
    header = "Season"
    if isChainValid(data[0], "json.ParentIndexNumber")
        header += (" " + bslib_toString(data[0].json.ParentIndexNumber))
    end if
    ' We can't simply use the episode index due to combination episodes
    shiftAmount = 0
    if isValidAndNotEmpty(m.top.episodeID)
        for each episode in data
            if isStringEqual(m.top.episodeID, episode.json.LookupCI("id")) then
                exit for
            end if
            shiftAmount++
        end for
    end if
    ' Shift episodes array so the selected episode is displayed first
    if shiftAmount > 0
        for i = 0 to shiftAmount - 1
            itemToMove = data.Shift()
            data.push(itemToMove)
        end for
    end if
    row = buildRow(header, data, 502)
    m.top.content.appendChild(row)
    addRowSize([
        502
        396
    ])
end sub

sub loadParts(data as object)
    extrasTimer = CreateObject("roTimespan")
    extrasTimer.Mark()
    m.SpecialFeaturesTask.observeField("content", "onSpecialFeaturesLoaded")
    m.LoadPeopleTask.observeField("content", "onPeopleLoaded")
    m.IncludedInTask.observeField("content", "onIncludedInLoaded")
    m.LikeThisTask.observeField("content", "onLikeThisLoaded")
    m.LoadEpisodesTask.observeField("content", "onSeasonOfEpisodesLoaded")
    m.top.content = CreateObject("roSGNode", "ContentNode")
    m.top.hasItems = false
    m.top.rowItemSize = []
    ' If we already have seasonData, add it as the first row
    if isValid(m.top.seasonData)
        onSeasonDataChanged()
    end if
    m.itemData = data
    m.parentItemType = LCase(chainLookupReturn(data, "Type", ""))
    m.top.parentId = data.id
    traceStep("MOVIE_TRACE", "ExtrasRowList.loadParts start parentId=" + m.top.parentId + " type=" + m.parentItemType)
    m.people = chainLookupReturn(data, "People", [])
    ' Avoid network fetches here: loadParts() runs on the render thread while the details screen is opening.
    ' If People metadata is missing, skip the Cast & Crew row instead of blocking the UI.
    if not isValid(m.people)
        m.people = []
    end if
    m.LoadPeopleTask.peopleList = m.people
    ' Emby-like flow: Cast & Crew first, then Included In, then More Like This.
    m.LoadPeopleTask.control = "RUN"
    traceStep("MOVIE_TRACE", "ExtrasRowList.loadParts LoadPeopleTask RUN elapsedMs=" + stri(extrasTimer.TotalMilliseconds()).trim())
    if isAllValid([
        m.top.seasonID
        m.top.showID
    ])
        m.LoadEpisodesTask.showID = m.top.showID
        m.LoadEpisodesTask.seasonID = m.top.seasonID
        m.LoadEpisodesTask.control = "RUN"
    end if
end sub

sub appendChaptersRow(itemData as object)
    if not isValid(itemData) then
        return
    end if
    chapters = chainLookupReturn(itemData, "Chapters", invalid)
    if not isValidAndNotEmpty(chapters)
        mediaSources = chainLookupReturn(itemData, "MediaSources", invalid)
        if isValidAndNotEmpty(mediaSources)
            primarySource = mediaSources[0]
            if isChainValid(primarySource, "Chapters") and isValidAndNotEmpty(primarySource.Chapters)
                chapters = primarySource.Chapters
            end if
        end if
    end if
    if not isValidAndNotEmpty(chapters) then
        return
    end if
    parentItemId = chainLookupReturn(itemData, "Id", chainLookupReturn(itemData, "id", ""))
    if not isValidAndNotEmpty(parentItemId) then
        return
    end if
    parentItemType = chainLookupReturn(itemData, "Type", "movie")
    if not isValid(m.top.content)
        m.top.content = CreateObject("roSGNode", "ContentNode")
    end if
    chapterRow = m.top.content.createChild("ContentNode")
    chapterRow.Title = tr("Chapters")
    for i = 0 to chapters.Count() - 1
        chapter = chapters[i]
        startTicks = chainLookupReturn(chapter, "StartPositionTicks", 0)
        chapterNode = CreateObject("roSGNode", "ExtrasData")
        chapterNode.id = parentItemId
        chapterNode.Type = "Chapter"
        chapterNode.itemType = parentItemType
        chapterNode.startingPoint = startTicks
        chapterNode.labelText = getChapterLabel(chapter, i + 1)
        chapterNode.subTitle = ticksToHuman(startTicks)
        chapterNode.gridLike = true
        chapterNode.imageWidth = 400
        chapterNode.posterURL = api_items_GetImageURL(parentItemId, "Chapter", i, {
            "maxHeight": 225
            "maxWidth": 400
            "quality": "90"
        })
        if not isValidAndNotEmpty(chapterNode.posterURL)
            chapterNode.posterURL = "pkg:/images/media_type_icons/movie.png"
        end if
        chapterNode.json = {
            Id: parentItemId
            Name: chapterNode.labelText
            Type: parentItemType
        }
        chapterRow.appendChild(chapterNode)
    end for
    if chapterRow.getChildCount() = 0
        m.top.content.removeChild(chapterRow)
        return
    end if
    if not m.top.hasItems then
        m.top.hasItems = true
    end if
    addRowSize([
        400
        330
    ])
end sub

function getChapterLabel(chapter as object, chapterNumber as integer) as string
    chapterName = chainLookupReturn(chapter, "Name", "")
    if not isValidAndNotEmpty(chapterName)
        chapterName = (bslib_toString(tr("Chapter")) + " " + bslib_toString(chapterNumber))
    end if
    return chapterName
end function

sub loadPersonVideos(personId)
    m.personId = personId
    m.LoadMoviesTask.itemId = m.personId
    m.LoadMoviesTask.observeField("content", "onMoviesLoaded")
    m.LoadMoviesTask.control = "RUN"
end sub

sub onPeopleLoaded()
    people = m.LoadPeopleTask.content
    m.loadPeopleTask.unobserveField("content")
    peopleCount = 0
    if isValid(people)
        peopleCount = people.Count()
    end if
    traceStep("MOVIE_TRACE", "ExtrasRowList.onPeopleLoaded count=" + stri(peopleCount).trim())
    if isValidAndNotEmpty(people)
        if not m.top.hasItems then
            m.top.hasItems = true
        end if
        if not isValid(m.top.content)
            m.top.content = CreateObject("roSGNode", "ContentNode")
        end if
        row = m.top.content.createChild("ContentNode")
        row.Title = tr("Cast & Crew")
        for each person in people
            if LCase(person.json.LookupCI("type")) = "actor" and isValid(person.json.LookupCI("Role")) and person.json.LookupCI("Role").ToStr().Trim() <> ""
                person.subTitle = (bslib_toString(tr("as")) + " " + bslib_toString(person.json.LookupCI("Role")))
            else
                person.subTitle = person.json.LookupCI("Type")
            end if
            person.Type = capitalize("person")
            row.appendChild(person)
        end for
        addRowSize([
            234
            396
        ])
    end if
    if isValid(m.IncludedInTask)
        m.IncludedInTask.itemId = m.top.parentId
        m.IncludedInTask.control = "RUN"
        traceStep("MOVIE_TRACE", "ExtrasRowList.onPeopleLoaded IncludedInTask RUN")
    else
        m.LikeThisTask.itemId = m.top.parentId
        m.LikeThisTask.control = "RUN"
        traceStep("MOVIE_TRACE", "ExtrasRowList.onPeopleLoaded fallback LikeThisTask RUN")
    end if
end sub

sub onIncludedInLoaded()
    if isValid(m.IncludedInTask)
        data = m.IncludedInTask.content
        m.IncludedInTask.unobserveField("content")
    else
        data = []
    end if
    includeCount = 0
    if isValid(data)
        includeCount = data.Count()
    end if
    traceStep("MOVIE_TRACE", "ExtrasRowList.onIncludedInLoaded count=" + stri(includeCount).trim())
    if isValidAndNotEmpty(data)
        if not m.top.hasItems then
            m.top.hasItems = true
        end if
        if not isValid(m.top.content)
            m.top.content = CreateObject("roSGNode", "ContentNode")
        end if
        row = m.top.content.createChild("ContentNode")
        row.Title = "Included In"
        for each item in data
            item.Id = item.json.LookupCI("Id")
            item.labelText = item.json.LookupCI("Name")
            item.subTitle = ""
            item.Type = item.json.LookupCI("Type")
            item.imageWidth = 234
            row.appendChild(item)
        end for
        addRowSize([
            234
            396
        ])
    end if
    m.LikeThisTask.itemId = m.top.parentId
    m.LikeThisTask.control = "RUN"
    traceStep("MOVIE_TRACE", "ExtrasRowList.onIncludedInLoaded LikeThisTask RUN")
end sub

sub onLikeThisLoaded()
    data = m.LikeThisTask.content
    m.LikeThisTask.unobserveField("content")
    likeThisCount = 0
    if isValid(data)
        likeThisCount = data.Count()
    end if
    traceStep("MOVIE_TRACE", "ExtrasRowList.onLikeThisLoaded count=" + stri(likeThisCount).trim())
    parentType = m.parentItemType
    rowImageWidth = 234
    rowSize = [
        234
        396
    ]
    if parentType = "musicvideo" or parentType = "video"
        ' Landscape-first media should render in wide slots like jellyrock.
        rowImageWidth = 400
        rowSize = [
            400
            380
        ]
    else if parentType = "photo" or parentType = "photoalbum"
        rowImageWidth = 400
        rowSize = [
            400
            380
        ]
    else if parentType = "musicartist" or parentType = "musicalbum" or parentType = "audio" or parentType = "playlist" or parentType = "program" or parentType = "tvchannel"
        rowImageWidth = 305
        rowSize = [
            305
            396
        ]
    end if
    if isValidAndNotEmpty(data)
        if not m.top.hasItems then
            m.top.hasItems = true
        end if
        row = m.top.content.createChild("ContentNode")
        row.Title = tr("More Like This")
        for each item in data
            item.Id = item.json.LookupCI("Id")
            item.labelText = item.json.LookupCI("Name")
            item.gridLike = true
            item.imageWidth = rowImageWidth
            if isValid(item.json.LookupCI("ProductionYear"))
                item.subTitle = stri(item.json.LookupCI("ProductionYear"))
            else if isValid(item.json.LookupCI("PremiereDate"))
                premierYear = CreateObject("roDateTime")
                premierYear.FromISO8601String(item.json.LookupCI("PremiereDate"))
                item.subTitle = stri(premierYear.GetYear())
            end if
            item.Type = item.json.LookupCI("Type")
            row.appendChild(item)
        end for
        addRowSize(rowSize)
    end if
    appendTagsRow(m.itemData)
    if parentType = "movie" or parentType = "video" or parentType = "recording"
        m.SpecialFeaturesTask.itemId = m.top.parentId
        m.SpecialFeaturesTask.control = "RUN"
        traceStep("MOVIE_TRACE", "ExtrasRowList.onLikeThisLoaded SpecialFeaturesTask RUN")
    end if
end sub

sub appendTagsRow(itemData as object)
    if not isValid(itemData) then
        return
    end if
    tagItems = []
    if isChainValid(itemData, "TagItems") and isValidAndNotEmpty(itemData.TagItems)
        tagItems = itemData.TagItems
    else if isChainValid(itemData, "Tags") and isValidAndNotEmpty(itemData.Tags)
        tagItems = itemData.Tags
    end if
    if not isValidAndNotEmpty(tagItems) then
        return
    end if
    if not isValid(m.top.content)
        m.top.content = CreateObject("roSGNode", "ContentNode")
    end if
    tagRow = m.top.content.createChild("ContentNode")
    tagRow.Title = tr("Tags")
    parentFolderId = chainLookupReturn(itemData, "ParentId", "")
    if not isValidAndNotEmpty(parentFolderId)
        parentFolderId = " "
    end if
    seenTags = {}
    uniqueTags = []
    for i = 0 to tagItems.Count() - 1
        tagEntry = tagItems[i]
        tagName = ""
        tagId = ""
        if isStringEqual(type(tagEntry), "roString")
            tagName = tagEntry
        else if isStringEqual(type(tagEntry), "roAssociativeArray")
            tagName = chainLookupReturn(tagEntry, "Name", "")
            tagId = chainLookupReturn(tagEntry, "Id", "")
        end if
        tagName = tagName.Trim()
        if not isValidAndNotEmpty(tagName) then
            continue for
        end if
        dedupeKey = LCase(tagName)
        if seenTags.DoesExist(dedupeKey) then
            continue for
        end if
        seenTags[dedupeKey] = true
        uniqueTags.push({
            name: tagName
            id: tagId
            key: dedupeKey
        })
    end for
    if not isValidAndNotEmpty(uniqueTags)
        m.top.content.removeChild(tagRow)
        return
    end if
    for i = 0 to uniqueTags.Count() - 1
        tagEntry = uniqueTags[i]
        tagLabel = tagEntry.name
        tagNode = CreateObject("roSGNode", "ExtrasData")
        if isValidAndNotEmpty(tagEntry.id)
            tagNode.id = tagEntry.id
        else
            tagNode.id = ("tag-" + bslib_toString(i) + "-" + bslib_toString(tagEntry.key))
        end if
        tagNode.Type = "Tag"
        tagNode.labelText = tagLabel
        tagNode.subTitle = ""
        tagNode.gridLike = false
        tagNode.imageWidth = 260
        tagNode.posterURL = ""
        tagNode.parentFolder = parentFolderId
        tagNode.libraryID = parentFolderId
        tagNode.tagId = tagEntry.id
        tagNode.tagName = tagEntry.name
        tagNode.json = {
            Id: tagNode.id
            Name: tagEntry.name
            Type: "Tag"
        }
        tagRow.appendChild(tagNode)
    end for
    if not m.top.hasItems then
        m.top.hasItems = true
    end if
    addRowSize([
        260
        90
    ])
end sub

function onSpecialFeaturesLoaded()
    data = m.SpecialFeaturesTask.content
    m.SpecialFeaturesTask.unobserveField("content")
    featureCount = 0
    if isValid(data)
        featureCount = data.Count()
    end if
    traceStep("MOVIE_TRACE", "ExtrasRowList.onSpecialFeaturesLoaded count=" + stri(featureCount).trim())
    if isValidAndNotEmpty(data)
        if not m.top.hasItems then
            m.top.hasItems = true
        end if
        if not isValid(m.top.content)
            m.top.content = CreateObject("roSGNode", "ContentNode")
        end if
        row = m.top.content.createChild("ContentNode")
        row.Title = tr("Special Features")
        for each item in data
            m.top.visible = true
            item.Id = item.json.LookupCI("Id")
            item.labelText = item.json.LookupCI("Name")
            item.subTitle = ""
            item.Type = item.json.LookupCI("Type")
            item.imageWidth = 450
            row.appendChild(item)
        end for
        addRowSize([
            462
            372
        ])
    end if
    return m.top.content
end function

sub onMoviesLoaded()
    data = m.LoadMoviesTask.content
    m.LoadMoviesTask.unobserveField("content")
    rlContent = CreateObject("roSGNode", "ContentNode")
    if isValidAndNotEmpty(data)
        if not m.top.hasItems then
            m.top.hasItems = true
        end if
        row = rlContent.createChild("ContentNode")
        row.title = tr("Movies")
        for each mov in data
            mov.Id = mov.json.Id
            mov.labelText = mov.json.Name
            mov.subTitle = mov.json.ProductionYear
            mov.Type = mov.json.Type
            row.appendChild(mov)
        end for
        m.top.rowItemSize = [
            [
                234
                396
            ]
        ]
    end if
    m.top.content = rlContent
    syncVisibleRowCount()
    m.LoadShowsTask.itemId = m.personId
    m.LoadShowsTask.observeField("content", "onShowsLoaded")
    m.LoadShowsTask.control = "RUN"
end sub

sub onShowsLoaded()
    data = m.LoadShowsTask.content
    m.LoadShowsTask.unobserveField("content")
    if isValidAndNotEmpty(data)
        if not m.top.hasItems then
            m.top.hasItems = true
        end if
        row = buildRow("TV Shows", data, 502)
        m.top.content.appendChild(row)
        addRowSize([
            502
            396
        ])
    end if
    m.LoadSeriesTask.itemId = m.personId
    m.LoadSeriesTask.observeField("content", "onSeriesLoaded")
    m.LoadSeriesTask.control = "RUN"
end sub

sub onSeriesLoaded()
    data = m.LoadSeriesTask.content
    m.LoadSeriesTask.unobserveField("content")
    if isValidAndNotEmpty(data)
        if not m.top.hasItems then
            m.top.hasItems = true
        end if
        row = buildRow("Series", data)
        m.top.content.appendChild(row)
        addRowSize([
            234
            396
        ])
    end if
    m.top.visible = true
end sub

function buildRow(rowTitle as string, items, imgWdth = 0)
    row = CreateObject("roSGNode", "ContentNode")
    row.Title = tr(rowTitle)
    for each mov in items
        if LCase(mov.json.type) = "episode"
            if isAllValid([
                mov.json.SeriesName
                mov.json.ParentIndexNumber
                mov.json.IndexNumber
                mov.json.Name
            ])
                mov.labelText = mov.json.SeriesName
                endingEpisode = ""
                if isValid(mov.json.LookupCI("indexNumberEnd"))
                    endingEpisode = ("-" + bslib_toString(mov.json.LookupCI("indexNumberEnd")))
                end if
                mov.subTitle = ("S" + bslib_toString(mov.json.ParentIndexNumber) + ":E" + bslib_toString(mov.json.IndexNumber) + bslib_toString(endingEpisode) + " - " + bslib_toString(mov.json.Name))
            else
                mov.labelText = mov.json.Name
                mov.subTitle = mov.json.ProductionYear
            end if
        else
            mov.labelText = mov.json.Name
            mov.subTitle = mov.json.ProductionYear
            if isValid(mov.json.EndDate)
                mov.subTitle += (" - " + bslib_toString(LEFT(mov.json.EndDate, 4)))
            end if
        end if
        mov.Id = mov.json.Id
        mov.Type = mov.json.Type
        if imgWdth > 0
            mov.imageWidth = imgWdth
        end if
        row.appendChild(mov)
    end for
    return row
end function

sub addRowSize(newRow)
    sizeArray = m.top.rowItemSize
    newSizeArray = []
    for each size in sizeArray
        newSizeArray.push(size)
    end for
    newSizeArray.push(newRow)
    m.top.rowItemSize = newSizeArray
    syncVisibleRowCount()
end sub

sub syncVisibleRowCount()
    if not isValid(m.top.content) then
        return
    end if
    rowCount = m.top.content.getChildCount()
    if rowCount < 2
        m.top.numRows = rowCount
    else
        m.top.numRows = 2
    end if
end sub

sub onRowItemSelected()
    m.top.selectedItem = m.top.content.getChild(m.top.rowItemSelected[0]).getChild(m.top.rowItemSelected[1])
    m.top.selectedItem = invalid
end sub

sub onRowItemFocused()
    m.top.focusedItem = m.top.content.getChild(m.top.rowItemFocused[0]).getChild(m.top.rowItemFocused[1])
end sub

sub onSeasonDataChanged()
    if not isValid(m.top.seasonData) then
        return
    end if
    if not m.top.hasItems then
        m.top.hasItems = true
    end if
    seasons = m.top.seasonData.getChildren(-1, 0)
    if seasons.Count() = 0 then
        return
    end if
    if not isValid(m.top.content)
        m.top.content = CreateObject("roSGNode", "ContentNode")
    end if
    ' Avoid adding duplicate seasons row if it already exists
    for each existingRow in m.top.content.getChildren(-1, 0)
        if existingRow.Title = tr("Seasons") then
            return
        end if
    end for
    row = m.top.content.createChild("ContentNode")
    row.Title = tr("Seasons")
    for each season in seasons
        ' Convert TVSeasonData to ExtrasData format
        seasonNode = CreateObject("roSGNode", "ExtrasData")
        seasonNode.id = season.json.id
        seasonNode.labelText = season.json.name
        seasonNode.Type = "Season"
        seasonNode.posterURL = season.posterURL
        seasonJson = season.json
        if not isChainValid(seasonJson, "SeriesId")
            seasonJson.SeriesId = m.top.parentId
        end if
        seasonNode.json = seasonJson
        row.appendChild(seasonNode)
    end for
    addRowSize([
        234
        396
    ])
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    return false
end function
'//# sourceMappingURL=./ExtrasRowList.brs.map