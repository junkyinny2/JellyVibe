'import "pkg:/source/api/Image.bs"
'import "pkg:/source/api/Items.bs"
'import "pkg:/source/constants/HomeRowItemSizes.bs"
'import "pkg:/source/enums/AnimationControl.bs"
'import "pkg:/source/enums/AnimationState.bs"
'import "pkg:/source/enums/ColorPalette.bs"
'import "pkg:/source/enums/KeyCode.bs"
'import "pkg:/source/utils/misc.bs"
'import "pkg:/source/enums/PosterLoadStatus.bs"
'import "pkg:/source/enums/ViewLoadStatus.bs"
'import "pkg:/source/utils/config.bs"
'import "pkg:/source/utils/deviceCapabilities.bs"
'import "pkg:/source/utils/misc.bs"

sub init()
    m.top.overhangVisible = false
    m.top.optionsAvailable = false
    m.extrasSlider = m.top.findNode("tvSeasonExtras")
    m.extrasGrid = m.top.findNode("extrasGrid")
    m.seriesDetailsSlider = m.top.findNode("seriesDetailsSlider")
    m.seriesDetailsSliderInterp = m.top.findNode("seriesDetailsSliderInterp")
    m.seriesDetailsClosing = false
    if isValid(m.seriesDetailsSlider)
        m.seriesDetailsSlider.observeField("state", "onSeriesDetailsSliderStateChanged")
    end if
    m.getShuffleEpisodesTask = createObject("roSGNode", "getShuffleEpisodesTask")
    m.extrasSlider.visible = false
    m.overview = m.top.findNode("overview")
    m.playedIndicator = m.top.findNode("playedIndicator")
    m.tvshowPoster = m.top.findNode("tvshowPoster")
    m.overviewSelected = false
    m.extrasPanelOpenY = 306
    m.extrasPanelClosedY = 972
    m.extrasPanelFocusedOpacity = 0.85
    m.extrasPanelRestOpacity = 0.65
    m.seriesExtrasPadding = 24
    m.seriesExtrasActive = false
    m.overview.ellipsisText = tr("...")
    m.loadStatus = 0
    m.detailsGroup = m.top.findNode("detailsGroup")
    m.mainContent = m.top.findnode("mainContent")
    m.defaultTopLevelTranslation = [
        100
        360
    ]
    m.buttonGrp = m.top.findNode("buttons")
    m.buttonCount = m.buttonGrp.getChildCount()
    ' Force buttons to correct translation
    m.buttonGrp.translation = [
        100
        852
    ]
    m.resume = m.top.findNode("resume")
    if isValid(m.resume) then
        applyControlButtonStyle(m.resume)
    end if
    m.extras = m.top.findNode("extras")
    if isValid(m.extras) then
        applyControlButtonStyle(m.extras)
    end if
    m.play = m.top.findNode("play")
    applyControlButtonStyle(m.play)
    m.shuffle = m.top.findNode("shuffle")
    applyControlButtonStyle(m.shuffle)
    m.watched = m.top.findNode("watched-button")
    applyControlButtonStyle(m.watched)
    m.favorite = m.top.findNode("favorite-button")
    applyControlButtonStyle(m.favorite)
    m.info = m.top.findNode("info-button")
    applyControlButtonStyle(m.info)
    m.delete = m.top.findNode("delete")
    applyControlButtonStyle(m.delete)
    hasDeletePermissions = chainLookupReturn(m.global.session, "user.Policy.EnableContentDeletion", false)
    if not hasDeletePermissions and isValid(m.delete)
        m.buttonGrp.removeChild(m.delete)
        m.delete = invalid
        m.buttonCount = m.buttonGrp.getChildCount()
    end if
    m.previouslySelectedButtonIndex = -1
    m.top.observeField("selectedButtonIndex", "onButtonSelectedChange")
    m.top.selectedButtonIndex = 0
    m.buttonGrp.observeField("escape", "onButtonGroupEscape")
    setFontSizes()
end sub

sub applyControlButtonStyle(button as object)
    if not isValid(button) then
        return
    end if
    button.focusBackground = "#ffffff"
    button.textColor = "#ffffff"
    button.focusTextColor = "#000000"
    button.focusIconBlendColor = "#000000"
end sub

sub onDisplayResumeButtonChange()
    if not m.top.displayResumeButton
        if isValid(m.resume)
            m.buttonGrp.removeChild(m.resume)
            m.resume = invalid
            m.buttonCount = m.buttonGrp.getChildCount()
            onButtonSelectedChange()
        end if
        if isValid(m.play) then
            m.play.text = tr("Play")
        end if
        return
    end if
    if not isValid(m.resume)
        previousSelectedButton = m.buttonGrp.getChild(m.top.selectedButtonIndex)
        if isValid(previousSelectedButton) then
            previousSelectedButton.focus = false
        end if
        m.resume = createObject("roSGNode", "IconButton")
        m.resume.id = "resume"
        m.resume.background = "#55020B2A"
        m.resume.padding = "18"
        m.resume.icon = "pkg:/images/icons/resume.png"
        m.resume.text = "Resume"
        m.resume.height = "75"
        m.resume.width = "140"
        m.resume.highlightTextArea = true
        applyControlButtonStyle(m.resume)
        m.buttonGrp.insertChild(m.resume, 0)
        m.buttonCount = m.buttonGrp.getChildCount()
        if m.buttonGrp.isInFocusChain() then
            onButtonSelectedChange()
        end if
    end if
    if m.top.resumeTicks > 0
        resumeTime = ticksToHuman(m.top.resumeTicks)
        m.resume.text = tr("Resume at %1").Replace("%1", resumeTime)
        if isValid(m.play) then
            m.play.text = tr("Play from beginning")
        end if
    else
        m.resume.text = tr("Resume")
        if isValid(m.play) then
            m.play.text = tr("Play")
        end if
    end if
end sub

sub onResumeTicksChange()
    if isValid(m.resume) and m.top.resumeTicks > 0
        resumeTime = ticksToHuman(m.top.resumeTicks)
        m.resume.text = tr("Resume at %1").Replace("%1", resumeTime)
        if isValid(m.play) then
            m.play.text = tr("Play from beginning")
        end if
    end if
end sub

sub onButtonSelectedChange()
    if m.previouslySelectedButtonIndex > -1
        previousSelectedButton = m.buttonGrp.getChild(m.previouslySelectedButtonIndex)
        if isValid(previousSelectedButton) then
            previousSelectedButton.focus = false
        end if
    end if
    selectedButton = m.buttonGrp.getChild(m.top.selectedButtonIndex)
    if isValid(selectedButton)
        selectedButton.setfocus(true)
        selectedButton.focus = true
    end if
    m.overviewSelected = false
    if isValid(m.overview) then
        m.overview.color = "#ffffff"
    end if
end sub

sub onButtonGroupEscape()
    escapeDir = m.buttonGrp.escape
    if escapeDir = "up"
        if not isStringEqual(m.overview.text, "")
            selectedButton = m.buttonGrp.getChild(m.top.selectedButtonIndex)
            if isValid(selectedButton) then
                selectedButton.focus = false
            end if
            m.overviewSelected = true
        end if
    else if escapeDir = "down"
        if isValid(m.extrasSlider) and m.extrasGrid.hasItems
            showSeriesExtras(m.extrasGrid)
        end if
    end if
end sub

sub setFontSizes()
    if isValid(m.overview) then
        m.overview.font.size = 27
    end if
    title = m.top.findNode("title")
    if isValid(title) then
        title.font.size = 45
    end if
    runtime = m.top.findNode("runtime")
    if isValid(runtime) then
        runtime.font.size = 23
    end if
    numberofepisodes = m.top.findNode("numberofepisodes")
    if isValid(numberofepisodes) then
        numberofepisodes.font.size = 23
    end if
    released = m.top.findNode("released")
    if isValid(released) then
        released.font.size = 23
    end if
    genres = m.top.findNode("genres")
    if isValid(genres) then
        genres.font.size = 23
    end if
    rating = m.top.findNode("rating")
    if isValid(rating) then
        rating.font.size = 23
    end if
    communityReview = m.top.findNode("communityReview")
    if isValid(communityReview) then
        communityReview.font.size = 23
    end if
    history = m.top.findNode("history")
    if isValid(history) then
        history.font.size = 23
    end if
end sub

sub itemContentChanged()
    item = m.top.itemContent
    if not isValid(item) then
        return
    end if
    itemData = item.json
    if not isValid(itemData) then
        return
    end if
    stopLoadingSpinner()
    m.overviewSelected = false
    if isValid(m.overview) then
        m.overview.color = "#ffffff"
    end if
    ' Build poster URL directly from json since SeriesData.posterURL is not pre-set
    seriesId = chainLookupReturn(itemData, "Id", chainLookupReturn(itemData, "id", ""))
    if isValidAndNotEmpty(seriesId)
        m.tvshowPoster.uri = api_items_GetImageURL(seriesId, "Primary", 0, {
            "maxHeight": 450
            "maxWidth": 300
            "quality": "90"
        })
    end if
    setBackdropImage(itemData)
    item.watched = chainLookupReturn(item, "json.UserData.Played", false)
    item.favorite = chainLookupReturn(item, "json.UserData.IsFavorite", false)
    m.playedIndicator.data = {
        played: item.watched
        unplayedCount: chainLookupReturn(item, "json.UserData.UnplayedItemCount", 0)
    }
    setWatchedColor()
    setFavoriteColor()
    setFieldText("title", itemData.name)
    if type(itemData.RunTimeTicks) = "LongInteger"
        setFieldText("runtime", stri(getRuntime()) + " mins")
    else
        m.top.findNode("topLevelDetails").removeChild(m.top.findNode("runtimeContainer"))
    end if
    if isChainValid(item, "json.RecursiveItemCount")
        setFieldText("numberofepisodes", stri(item.json.RecursiveItemCount) + " episodes")
    else
        m.top.findNode("topLevelDetails").removeChild(m.top.findNode("numberofepisodesContainer"))
    end if
    if isValid(itemData.productionYear)
        setFieldText("released", itemData.productionYear)
    else
        m.top.findNode("topLevelDetails").removeChild(m.top.findNode("releasedContainer"))
    end if
    if isValid(itemData.officialRating)
        setFieldText("rating", itemData.officialRating)
    else
        m.top.findNode("topLevelDetails").removeChild(m.top.findNode("ratingContainer"))
    end if
    if chainLookupReturn(m.global.session, "user.settings.`ui.itemdetail.showRatings`", true)
        if isValid(itemData.communityRating)
            setFieldText("communityReview", int(itemData.communityRating * 10) / 10)
        else
            m.top.findNode("topLevelDetails").removeChild(m.top.findNode("communityReviewContainer"))
        end if
    else
        m.top.findNode("topLevelDetails").removeChild(m.top.findNode("communityReviewContainer"))
    end if
    setFieldText("overview", itemData.overview)
    if isValid(m.extrasGrid) then
        m.extrasGrid.callFunc("loadParts", itemData)
    end if
end sub

sub onSeasonDataChanged()
    if isValid(m.extrasGrid) then
        m.extrasGrid.seasonData = m.top.seasonData
    end if
end sub

sub setFieldText(field, value)
    node = m.top.findNode(field)
    if node = invalid or value = invalid then
        return
    end if
    if type(value) = "roInt" or type(value) = "Integer" or type(value) = "roFloat" or type(value) = "Float"
        value = str(value).trim()
    else if type(value) <> "roString" and type(value) <> "String"
        value = ""
    end if
    node.text = value
end sub

function getRuntime() as integer
    itemData = m.top.itemContent.json
    return round(itemData.RunTimeTicks / 600000000.0)
end function

function round(f as float) as integer
    m = int(f)
    n = m + 1
    if abs(f - n) > abs(f - m) then
        return m
    else
        return n
    end if
end function

sub OnScreenShown()
    if isValid(m.top.lastFocus)
        m.top.lastFocus.setFocus(true)
    else
        firstButton = m.buttonGrp.getChild(0)
        if isValid(firstButton) then
            firstButton.setFocus(true)
        end if
    end if
    if isStringEqual(m.loadStatus, 0)
        m.loadStatus = 1
        return
    end if
    m.loadStatus = 2
    m.top.refreshSeasonDetailsData = not m.top.refreshSeasonDetailsData
end sub

function getFocusedItem() as object
    if m.extrasSlider.isInFocusChain() and isValid(m.extrasGrid.focusedItem)
        return m.extrasGrid.focusedItem
    end if
    return invalid
end function

sub onShuffleEpisodeDataLoaded()
    m.getShuffleEpisodesTask.unobserveField("data")
    m.global.queueManager.callFunc("set", m.getShuffleEpisodesTask.data.items)
    m.global.queueManager.callFunc("playQueue")
end sub

sub createFullDscrDlg()
    titleText = chainLookupReturn(m.top.itemContent, "title", chainLookupReturn(m.top.itemContent, "json.name", tr("Plot")))
    overviewText = chainLookupReturn(m.top.itemContent, "json.overview", "")
    if isValidAndNotEmpty(overviewText)
        m.global.sceneManager.callFunc("standardDialog", titleText, {
            data: [
                "<p>" + overviewText + "</p>"
            ]
        })
    end if
end sub

sub showSeriesExtras(extrasSection as object)
    if not isValid(extrasSection) or m.seriesExtrasActive then
        return
    end if
    m.seriesDetailsClosing = false
    m.extrasSlider.visible = true
    extrasSection.setFocus(true)
    vertSlider = m.extrasSlider.findNode("VertSlider")
    extrasFader = m.extrasSlider.findNode("extrasFader")
    pplAnime = m.extrasSlider.findNode("pplAnime")
    if isValid(m.seriesDetailsSlider)
        m.seriesDetailsSlider.reverse = false
        m.seriesDetailsSlider.control = "start"
    end if
    if isValid(vertSlider) then
        vertSlider.reverse = false
    end if
    if isValid(extrasFader) then
        extrasFader.reverse = false
    end if
    if isValid(pplAnime) then
        pplAnime.control = "start"
    end if
    m.seriesExtrasActive = true
end sub

sub hideSeriesExtras()
    if not m.seriesExtrasActive then
        return
    end if
    vertSlider = m.extrasSlider.findNode("VertSlider")
    extrasFader = m.extrasSlider.findNode("extrasFader")
    pplAnime = m.extrasSlider.findNode("pplAnime")
    m.seriesDetailsClosing = true
    if isValid(m.seriesDetailsSlider)
        m.seriesDetailsSlider.reverse = true
        m.seriesDetailsSlider.control = "start"
    else
        m.seriesExtrasActive = false
        m.seriesDetailsClosing = false
        m.extrasSlider.visible = false
    end if
    if isValid(vertSlider) then
        vertSlider.reverse = true
    end if
    if isValid(extrasFader) then
        extrasFader.reverse = true
    end if
    if isValid(pplAnime) then
        pplAnime.control = "start"
    end if
end sub

sub updateSeriesDetailsAnimationTarget()
    ' No longer strictly needed as we use relative translation on detailsGroup
end sub

sub setSeriesDetailsSlideTarget(targetY as float)
end sub

sub setSeriesDetailsSlideToDefault()
end sub

function isSeriesExtrasTopRowFocused() as boolean
    if not isValid(m.extrasGrid) then
        return false
    end if
    if isValid(m.extrasGrid.rowItemFocused) and m.extrasGrid.rowItemFocused.Count() > 0
        return m.extrasGrid.rowItemFocused[0] = 0
    end if
    return m.extrasGrid.itemFocused = 0
end function

sub onSeriesDetailsSliderStateChanged()
    if not m.seriesDetailsClosing or not isStringEqual(m.seriesDetailsSlider.state, "stopped") then
        return
    end if
    m.seriesExtrasActive = false
    m.seriesDetailsClosing = false
    m.extrasSlider.visible = false
    onButtonSelectedChange()
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if press and m.seriesDetailsClosing then
        return true
    end if
    if m.overviewSelected
        if not press then
            return false
        end if
        if key = "OK" then
            createFullDscrDlg()
            return true
        end if
        if isStringEqual(key, "down")
            m.overviewSelected = false
            if isValid(m.overview) then
                m.overview.color = "#ffffff"
            end if
            onButtonSelectedChange()
            return true
        end if
        return false
    end if
    if m.buttonGrp.isInFocusChain()
        if isStringEqual(key, "up")
            if not isStringEqual(m.overview.text, "")
                selectedButton = m.buttonGrp.getChild(m.top.selectedButtonIndex)
                selectedButton.focus = false
                m.overviewSelected = true
                return true
            end if
        end if
        if isStringEqual(key, "OK") or isStringEqual(key, "play")
            if not press then
                return false
            end if
            if m.shuffle.hasFocus()
                m.getShuffleEpisodesTask.showID = m.top.itemContent.id
                m.getShuffleEpisodesTask.observeField("data", "onShuffleEpisodeDataLoaded")
                m.getShuffleEpisodesTask.control = "RUN"
                return true
            else if isValid(m.resume) and m.resume.hasFocus()
                quickplayData = m.top.itemContent
                quickplayData.quickplayFromResume = true
                m.top.quickPlayNode = quickplayData
                return true
            else if m.extras.hasFocus()
                showSeriesExtras(m.extrasGrid)
                return true
            else if m.play.hasFocus()
                m.top.playSeriesFromStart = not m.top.playSeriesFromStart
                return true
            else if isValid(m.delete) and m.delete.hasFocus()
                confirmDeleteItem()
                return true
            else if m.info.hasFocus()
                showSeriesInfo()
                return true
            else if m.watched.hasFocus() or m.favorite.hasFocus()
                m.top.buttonSelected = m.buttonGrp.getChild(m.top.selectedButtonIndex).id
                if m.watched.hasFocus() then
                    m.top.itemContent.watched = not m.top.itemContent.watched
                    setWatchedColor()
                else
                    m.top.itemContent.favorite = not m.top.itemContent.favorite
                    setFavoriteColor()
                end if
                return true
            end if
            return false
        end if
        if isStringEqual(key, "left")
            if not press then
                return false
            end if
            if m.top.selectedButtonIndex > 0
                m.previouslySelectedButtonIndex = m.top.selectedButtonIndex
                m.top.selectedButtonIndex = m.top.selectedButtonIndex - 1
                return true
            end if
        end if
        if isStringEqual(key, "right")
            if not press then
                return false
            end if
            if m.top.selectedButtonIndex < m.buttonCount - 1
                m.previouslySelectedButtonIndex = m.top.selectedButtonIndex
                m.top.selectedButtonIndex = m.top.selectedButtonIndex + 1
                return true
            end if
        end if
        if isStringEqual(key, "down")
            if not press then
                return false
            end if
            if isValid(m.extrasSlider) and m.extrasGrid.hasItems
                showSeriesExtras(m.extrasGrid)
                return true
            end if
        end if
    end if
    if not press then
        return false
    end if
    if m.extrasSlider.isInFocusChain()
        if isStringEqual(key, "back") then
            hideSeriesExtras()
            return true
        end if
        if isStringEqual(key, "up") and isSeriesExtrasTopRowFocused() then
            hideSeriesExtras()
            return true
        end if
    end if
    if key = "play" and m.extrasSlider.isInFocusChain()
        if isValid(m.extrasGrid.focusedItem) then
            m.top.quickPlayNode = m.extrasGrid.focusedItem
            return true
        end if
    end if
    return false
end function

sub confirmDeleteItem()
    params = {
        id: m.top.itemContent.id
    }
    m.global.sceneManager.callFunc("optionDialog", "delete_item", tr("Confirm Deletion?"), tr("Deleting this item will delete it from both the file system and your media library. Are you sure you wish to continue?"), [
        tr("No")
        tr("Delete")
    ], params)
end sub

sub setWatchedColor()
    if not isValid(m.watched) then
        return
    end if
    if m.top.itemContent.watched then
        m.watched.iconBlendColor = "#00A4DC"
    else
        m.watched.iconBlendColor = "#ffffff"
    end if
end sub

sub setFavoriteColor()
    if not isValid(m.favorite) then
        return
    end if
    if m.top.itemContent.favorite then
        m.favorite.iconBlendColor = "#EE3E54"
    else
        m.favorite.iconBlendColor = "#ffffff"
    end if
end sub

sub showSeriesInfo()
    itemData = m.top.itemContent.json
    info = []
    if isValidAndNotEmpty(itemData.Path) then
        info.push("Path: " + itemData.Path)
    end if
    if isValidAndNotEmpty(itemData.Id) then
        info.push("ID: " + itemData.Id)
    end if
    dialog = createObject("roSGNode", "Dialog")
    dialog.title = "Series Info"
    dialog.message = info.join(chr(10))
    dialog.buttons = [
        "OK"
    ]
    m.top.getScene().dialog = dialog
end sub

sub setBackdropImage(itemData as object)
    if not isValid(itemData) then
        return
    end if
    seriesId = chainLookupReturn(itemData, "Id", chainLookupReturn(itemData, "id", ""))
    if not isValidAndNotEmpty(seriesId) then
        return
    end if
    if isValidAndNotEmpty(itemData.BackdropImageTags)
        imageVersion = "Backdrop"
        imageTag = itemData.BackdropImageTags[0]
    else
        imageVersion = "Primary"
        imageTag = chainLookupReturn(itemData, "ImageTags.Primary", "")
    end if
    seriesBackground = m.top.findNode("seriesBackground")
    if not isValid(seriesBackground)
        seriesBackground = createObject("roSGNode", "Rectangle")
        seriesBackground.id = "seriesBackground"
        seriesBackground.width = 1920
        seriesBackground.height = 1080
        seriesBackground.color = "#020B2AFF"
        m.top.insertChild(seriesBackground, 0)
    end if
    seriesBackdrop = m.top.findNode("seriesBackdrop")
    if not isValid(seriesBackdrop)
        seriesBackdrop = createObject("roSGNode", "Poster")
        seriesBackdrop.id = "seriesBackdrop"
        seriesBackdrop.loadDisplayMode = "scaleToZoom"
        seriesBackdrop.translation = [
            0
            0
        ]
        seriesBackdrop.width = 1920
        seriesBackdrop.height = 1080
        seriesBackdrop.opacity = 0.3
        m.top.insertChild(seriesBackdrop, 1)
    end if
    seriesBackdrop.uri = ImageURL(seriesId, imageVersion, {
        "maxWidth": 1920
        "Tag": imageTag
    })
end sub
'//# sourceMappingURL=./TVSeriesDetails.brs.map