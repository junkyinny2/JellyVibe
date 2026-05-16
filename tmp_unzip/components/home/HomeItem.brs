'import "pkg:/source/api/baserequest.bs"
'import "pkg:/source/api/Image.bs"
'import "pkg:/source/enums/AnimationControl.bs"
'import "pkg:/source/enums/ColorPalette.bs"
'import "pkg:/source/enums/ItemType.bs"
'import "pkg:/source/enums/PosterLoadStatus.bs"
'import "pkg:/source/enums/SeriesStatus.bs"
'import "pkg:/source/enums/String.bs"
'import "pkg:/source/utils/config.bs"
'import "pkg:/source/utils/controlStyle.bs"
'import "pkg:/source/utils/misc.bs"

sub init()
    findNodes()
    m.itemPoster.observeField("loadStatus", "onPosterLoadStatusChanged")
    setColors()
end sub

sub setColors()
    if not isAllValid([
        m.itemProgress
        m.itemProgressBackground
        m.backdrop
    ]) then
        findNodes()
    end if
    if isValid(m.itemProgress)
        m.itemProgress.color = chainLookupReturn(m.global.session, "user.settings.colorHomeRowItemProgress", "#6F7FB7")
    end if
    if isValid(m.itemProgressBackground)
        m.itemProgressBackground.color = chainLookupReturn(m.global.session, "user.settings.colorHomeRowItemProgressBackground", "0x00000090")
    end if
    if isValid(m.backdrop)
        m.backdrop.blendColor = chainLookupReturn(m.global.session, "user.settings.colorHomeRowItemBackground", "#020B2A")
    end if
    if isValid(m.focusOutline)
        m.focusOutline.blendColor = getControlAccentColor("#7B2FBE")
    end if
end sub

sub findNodes()
    initItemText()
    initItemPoster()
    initItemTextExtra()
    initBackdrop()
    initItemIcon()
    m.itemProgress = m.top.findNode("progress")
    m.itemProgressBackground = m.top.findNode("progressBackground")
    m.playedIndicator = m.top.findNode("playedIndicator")
    m.showProgressBarAnimation = m.top.findNode("showProgressBar")
    m.showProgressBarField = m.top.findNode("showProgressBarField")
    m.overlaidTitle = m.top.findNode("overlaidTitle")
    m.posterGroup = m.top.findNode("posterGroup")
    m.itemShadow = m.top.findNode("itemShadow")
    m.focusOutline = m.top.findNode("focusOutline")
    m.focusAnimation = m.top.findNode("focusAnimation")
    m.translationInterpolator = m.top.findNode("translationInterpolator")
    m.shadowTranslationInterpolator = m.top.findNode("shadowTranslationInterpolator")
end sub

sub initItemText()
    m.itemText = m.top.findNode("itemText")
    if isValid(m.itemText)
        m.itemText.color = chainLookupReturn(m.global.session, "user.settings.colorHomeRowItemTitle", "#ffffff")
    end if
end sub

sub initItemPoster()
    m.itemPoster = m.top.findNode("itemPoster")
end sub

sub initItemTextExtra()
    m.itemTextExtra = m.top.findNode("itemTextExtra")
    if isValid(m.itemTextExtra)
        m.itemTextExtra.color = chainLookupReturn(m.global.session, "user.settings.colorHomeRowItemSubtitle", "#777777")
    end if
end sub

sub initBackdrop()
    m.backdrop = m.top.findNode("backdrop")
end sub

sub initItemIcon()
    m.itemIcon = m.top.findNode("itemIcon")
    if not isValid(m.itemIcon) then
        return
    end if
    m.itemIcon.blendcolor = chainLookupReturn(m.global.session, "user.settings.colorHomeMyListIcon", "#ffffff")
end sub

sub itemContentChanged()
    itemData = m.top.itemContent
    if not isValid(itemData) then
        return
    end if
    localGlobal = m.global
    if isValid(m.playedIndicator)
        m.playedIndicator.data = {
            played: chainLookupReturn(itemData, "json.UserData.Played", false)
            unplayedCount: chainLookupReturn(itemData, "json.UserData.UnplayedItemCount", 0)
        }
    end if
    itemData.AddReplace("Title", itemData.LookupCI("name"))
    setColors()
    initItemIcon()
    initItemText()
    initItemTextExtra()
    ' validate to prevent crash
    if not isValid(m.itemPoster) then
        initItemPoster()
    end if
    if not isValid(m.backdrop) then
        initBackdrop()
    end if
    if not isValid(m.itemIcon) then
        initItemIcon()
    end if
    m.itemPoster.width = itemData.imageWidth
    m.itemPoster.height = 261 ' Match HomeRowItemSizes.bs height
    m.backdrop.width = itemData.imageWidth
    m.backdrop.height = 261
    m.itemTextExtra.width = itemData.imageWidth
    m.itemTextExtra.visible = true
    m.itemTextExtra.text = ""
    m.itemTextExtra.font.size = 22
    m.itemText.maxWidth = itemData.imageWidth
    m.itemText.height = 34
    m.itemText.font.size = 25
    m.itemText.horizAlign = "left"
    m.itemText.vertAlign = "bottom"
    m.backdrop.width = itemData.imageWidth
    ' Ensure shadow size matches poster
    width = itemData.imageWidth
    height = 261 ' Fixed height for HomeRow items
    m.itemShadow.width = width
    m.itemShadow.height = height
    if isValid(m.focusOutline)
        m.focusOutline.width = itemData.imageWidth + 12
        m.focusOutline.height = height + 12
        m.focusOutline.translation = [
            -6
            -6
        ]
    end if
    if isAllValid([
        m.itemIcon
        itemData.iconUrl
    ])
        m.itemIcon.uri = itemData.iconUrl
    end if
    if isValid(itemData.type) then
        itemDataType = LCase(itemData.type)
    else
        itemDataType = ""
    end if
    if inArray([
        "collectionfolder"
        "userview"
        "channel"
        "folder"
    ], itemDataType)
        displayCollectionInfo(itemData)
        return
    end if
    playedIndicatorLeftPosition = m.itemPoster.width - 60
    m.playedIndicator.translation = [
        playedIndicatorLeftPosition
        0
    ]
    ' "Program" is from clicking on an "On Now" item on the Home Screen
    if itemDataType = "program"
        displayProgramInfo(itemData)
        return
    end if
    if inArray([
        "episode"
        "recording"
    ], itemDataType)
        displayEpisodeInfo(localGlobal, itemData)
        return
    end if
    if inArray([
        "movie"
        "musicvideo"
    ], itemDataType)
        displayMovieInfo(itemData)
        return
    end if
    if itemDataType = "video"
        displayVideoInfo(itemData)
        return
    end if
    if itemDataType = "boxset"
        displayBoxsetInfo(itemData)
        return
    end if
    if itemDataType = "series"
        displaySeriesInfo(itemData)
        return
    end if
    if itemDataType = "musicalbum"
        displayMusicAlbumInfo(itemData)
        return
    end if
    if itemDataType = "audiobook"
        displayAudioBookInfo(itemData)
        return
    end if
    if inArray([
        "musicartist"
        "audio"
    ], itemDataType)
        displayAudioInfo(itemData)
        return
    end if
    if itemDataType = "tvchannel"
        displayTVChannelInfo(itemData)
        return
    end if
    if itemDataType = "season"
        displaySeasonInfo(itemData)
        return
    end if
    if itemDataType = "photo"
        displayPhotoInfo(itemData)
        return
    end if
    if itemDataType = "photoalbum"
        displayPhotoAlbumInfo(itemData)
        return
    end if
    print ("Unhandled Home Item Type " + bslib_toString(itemDataType))
end sub

sub displayCollectionInfo(itemData as object)
    m.itemText.text = "" ' keep row label empty for libraries
    m.overlaidTitle.text = itemData.name
    m.overlaidTitle.visible = true
    if isValidAndNotEmpty(itemData.iconUrl)
        m.itemIcon.uri = itemData.iconUrl
    end if
    if isValidAndNotEmpty(itemData.widePosterURL)
        m.itemPoster.uri = itemData.widePosterURL
    else
        m.itemPoster.uri = itemData.posterURL
    end if
end sub

sub displayPhotoAlbumInfo(itemData as object)
    m.itemText.text = itemData.name
    m.itemPoster.uri = ImageURL(itemData.LookupCI("id"))
    ' subtext
    if isValid(itemData.json.ChildCount)
        m.itemTextExtra.text = itemData.json.ChildCount.ToStr().trim() + " items"
    end if
end sub

sub displayPhotoInfo(itemData as object)
    m.itemText.text = itemData.name
    m.itemPoster.uri = ImageURL(itemData.LookupCI("id"))
    ' subtext
    if isValidAndNotEmpty(itemData.json)
        if isValid(itemData.json.ProductionYear)
            m.itemTextExtra.text = itemData.json.ProductionYear.ToStr().trim()
        end if
        if isValidAndNotEmpty(itemData.json.Album)
            if m.itemTextExtra.text = ""
                m.itemTextExtra.text = tr("Album") + ": " + itemData.json.Album.trim()
            else
                m.itemTextExtra.text = m.itemTextExtra.text + " - " + tr("Album") + ": " + itemData.json.Album.trim()
            end if
        end if
    end if
end sub

sub displaySeasonInfo(itemData as object)
    m.itemText.text = itemData.json.SeriesName
    m.itemTextExtra.text = itemData.name
    m.itemPoster.uri = ImageURL(itemData.LookupCI("id"))
end sub

sub displayTVChannelInfo(itemData as object)
    m.itemText.text = itemData.name
    m.itemTextExtra.text = itemData.json.AlbumArtist
    m.itemPoster.uri = ImageURL(itemData.LookupCI("id"))
end sub

sub displayAudioInfo(itemData as object)
    m.itemText.text = itemData.name
    m.itemTextExtra.text = itemData.json.AlbumArtist
    m.itemPoster.uri = ImageURL(itemData.LookupCI("id"))
end sub

sub displayAudioBookInfo(itemData as object)
    if itemData.PlayedPercentage > 0
        drawProgressBar(itemData)
    end if
    m.itemText.text = itemData.name
    m.itemTextExtra.text = itemData.json.AlbumArtist
    m.itemPoster.uri = ImageURL(itemData.LookupCI("id"))
end sub

sub displayMusicAlbumInfo(itemData as object)
    m.itemText.text = itemData.name
    m.itemTextExtra.text = itemData.json.AlbumArtist
    m.itemPoster.uri = itemData.posterURL
end sub

sub displaySeriesInfo(itemData as object)
    m.itemText.text = itemData.name
    if itemData.usePoster
        if itemData.imageWidth = 180 then
            m.itemPoster.uri = itemData.posterURL
        else
            m.itemPoster.uri = itemData.widePosterURL
        end if
    else
        m.itemPoster.uri = itemData.thumbnailURL
    end if
    textExtra = ""
    if isValid(itemData.json.ProductionYear)
        textExtra = StrI(itemData.json.ProductionYear).trim()
    end if
    ' Set Years Run for Extra Text
    if isValid(itemData.json.Status)
        if LCase(itemData.json.Status) = "continuing"
            textExtra = textExtra + " - Present"
        else if LCase(itemData.json.Status) = "ended" and isValid(itemData.json.EndDate)
            textExtra = textExtra + " - " + LEFT(itemData.json.EndDate, 4)
        end if
    end if
    m.itemTextExtra.text = textExtra
end sub

sub displayBoxsetInfo(itemData as object)
    m.itemText.text = itemData.name
    m.itemPoster.uri = itemData.posterURL
    ' Set small text to number of items in the collection
    if isChainValid(itemData, "json.ChildCount")
        m.itemTextExtra.text = StrI(itemData.json.ChildCount).trim() + " item"
        if itemData.json.ChildCount > 1
            m.itemTextExtra.text += "s"
        end if
    end if
end sub

sub displayVideoInfo(itemData as object)
    m.itemText.text = itemData.name
    if itemData.PlayedPercentage > 0
        drawProgressBar(itemData)
    end if
    if itemData.imageWidth = 180 then
        m.itemPoster.uri = itemData.posterURL
    else
        m.itemPoster.uri = itemData.thumbnailURL
    end if
end sub

sub displayMovieInfo(itemData as object)
    m.itemText.text = itemData.name
    if itemData.PlayedPercentage > 0
        drawProgressBar(itemData)
    end if
    ' Use best image, but fallback to secondary if it's empty
    if (itemData.imageWidth = 180 and itemData.posterURL <> "") or itemData.thumbnailURL = ""
        m.itemPoster.uri = itemData.posterURL
    else
        m.itemPoster.uri = itemData.thumbnailURL
    end if
    ' Set Release Year and Age Rating for Extra Text
    textExtra = ""
    if isValid(itemData.json.ProductionYear)
        textExtra = StrI(itemData.json.ProductionYear).trim()
    end if
    if isValid(itemData.json.OfficialRating)
        if textExtra = ""
            textExtra = itemData.json.OfficialRating
        else
            textExtra = (bslib_toString(textExtra) + " - " + bslib_toString(itemData.json.OfficialRating))
        end if
    end if
    m.itemTextExtra.text = textExtra
end sub

sub displayProgramInfo(itemData as object)
    m.itemText.Text = itemData.json.name
    m.itemTextExtra.Text = itemData.json.ChannelName
    if itemData.usePoster then
        m.itemPoster.uri = itemData.thumbnailURL
    else
        m.itemPoster.uri = ImageURL(itemData.json.ChannelId)
    end if
    m.itemPoster.loadDisplayMode = "scaleToFill"
    ' Set Episode title if available
    if isValid(itemData.json.EpisodeTitle)
        m.itemTextExtra.text = itemData.json.EpisodeTitle
    end if
end sub

sub displayEpisodeInfo(localGlobal as object, itemData as object)
    if isChainValid(itemData, "json.SeriesName")
        m.itemText.text = itemData.json.SeriesName
    end if
    if isValid(itemData.LookupCI("PlayedPercentage"))
        if itemData.LookupCI("PlayedPercentage") > 0
            drawProgressBar(itemData)
        end if
    end if
    episodeimagesnextupSetting = chainLookup(localGlobal, "session.user.settings.ui-general-episodeimagesnextup")
    ' Default to wide poster image
    m.itemPoster.uri = itemData.LookupCI("widePosterURL")
    if isValid(episodeimagesnextupSetting)
        if isStringEqual(episodeimagesnextupSetting, "webclient")
            useEpisodeImagesInNextUpAndResumeSetting = chainLookup(localGlobal, "session.user.Configuration.useEpisodeImagesInNextUpAndResume")
            if isValid(useEpisodeImagesInNextUpAndResumeSetting) and useEpisodeImagesInNextUpAndResumeSetting
                m.itemPoster.uri = itemData.LookupCI("thumbnailURL")
            else
                m.itemPoster.uri = itemData.LookupCI("widePosterURL")
            end if
        else if isStringEqual(episodeimagesnextupSetting, "show")
            m.itemPoster.uri = itemData.LookupCI("widePosterURL")
        else if isStringEqual(episodeimagesnextupSetting, "episode")
            m.itemPoster.uri = itemData.LookupCI("thumbnailURL")
        end if
    end if
    ' Set Series and Episode Number for Extra Text
    extraPrefix = ""
    if isChainValid(itemData, "json.ParentIndexNumber")
        extraPrefix = "S" + StrI(itemData.json.ParentIndexNumber).trim()
    end if
    if isChainValid(itemData, "json.IndexNumber")
        extraPrefix = extraPrefix + "E" + StrI(itemData.json.IndexNumber).trim()
    end if
    if extraPrefix.len() > 0
        extraPrefix = extraPrefix + " - "
    end if
    if isValid(m.itemTextExtra)
        m.itemTextExtra.text = extraPrefix + itemData.LookupCI("name")
    end if
end sub

'
' Draws and animates item progress bar
sub drawProgressBar(itemData)
    if not isValid(itemData.LookupCI("imageWidth")) then
        return
    end if
    m.itemProgressBackground.width = itemData.LookupCI("imageWidth")
    m.itemProgressBackground.visible = true
    m.showProgressBarField.keyValue = [
        0
        m.itemPoster.width * (itemData.PlayedPercentage / 100)
    ]
    m.showProgressBarAnimation.control = "start"
end sub

'
' Enable title scrolling based on item Focus
sub focusChanged()
    if m.top.itemHasFocus then
        m.itemText.repeatCount = - 1
    else
        m.itemText.repeatCount = 0
    end if
    if m.top.itemHasFocus
        if m.top.focusPercent > 0
            applyFocusVisual(m.top.focusPercent)
        else
            ' Fallback when parent doesn't drive focusPercent.
            applyFocusVisual(1)
        end if
    else
        applyFocusVisual(0)
    end if
end sub

' focusPercent 0.0 to 1.0
sub onFocusPercentChange()
    applyFocusVisual(m.top.focusPercent)
end sub

sub onWidthChanged()
    ' Update focusOutline width if it's already visible
    if isValid(m.focusOutline) and m.top.focusPercent > 0
        m.focusOutline.width = m.itemPoster.width + 12
    end if
end sub

sub onHeightChanged()
    ' Update focusOutline height if it's already visible
    if isValid(m.focusOutline) and m.top.focusPercent > 0
        m.focusOutline.height = m.itemPoster.height + 12
    end if
end sub

sub applyFocusVisual(percent as float)
    clampedPercent = percent
    if clampedPercent < 0 then
        clampedPercent = 0
    end if
    if clampedPercent > 1 then
        clampedPercent = 1
    end if
    if isValid(m.focusOutline)
        m.focusOutline.opacity = clampedPercent
        ' Tighten focus ring to only surround the poster, not the title text
        m.focusOutline.width = m.itemPoster.width + 12
        m.focusOutline.height = m.itemPoster.height + 12
        m.focusOutline.translation = [
            -6
            -6
        ]
    end if
    m.itemShadow.opacity = 0.6 * clampedPercent
end sub

'Hide backdrop and icon when poster loaded
sub onPosterLoadStatusChanged()
    if m.itemPoster.loadStatus = "failed"
        thisItemType = chainLookupReturn(m.top.itemContent, "json.type", "")
        ' If loading the album poster image failed, try loading the artist image
        if isStringEqual(thisItemType, "musicalbum")
            params = {
                tag: m.top.itemContent.json.parentbackdropimagetags
                maxHeight: 261
                maxWidth: 261
            }
            artistPrimaryImageURL = ImageURL(m.top.itemContent.json.parentbackdropitemid, "Primary", params)
            ' Check if we've already tried to fall back to the artist image
            if isStringEqual(m.itemPoster.uri, artistPrimaryImageURL) then
                return
            end if
            m.itemPoster.uri = artistPrimaryImageURL
            return
        end if
        ' If loading the episode poster image failed, try loading the series image
        if isStringEqual(thisItemType, "episode")
            params = {
                tag: m.top.itemContent.json.parentbackdropimagetags
                maxHeight: 261
                maxWidth: 261
            }
            seriesPrimaryImageURL = ImageURL(m.top.itemContent.json.parentbackdropitemid, "Primary", params)
            ' Check if we've already tried to fall back to the series image
            if isStringEqual(m.itemPoster.uri, seriesPrimaryImageURL) then
                return
            end if
            m.itemPoster.uri = seriesPrimaryImageURL
            return
        end if
        ' Wide Poster failed to load, try poster url
        if isStringEqual(m.itemPoster.uri, m.top.itemContent.widePosterURL)
            m.itemPoster.uri = m.top.itemContent.posterURL
            return
        end if
        ' Thumbnail failed to load, try poster url
        if isStringEqual(m.itemPoster.uri, m.top.itemContent.thumbnailURL)
            m.itemPoster.uri = m.top.itemContent.posterURL
            return
        end if
        ' Poster url has failed. Show blank backdrop
        m.backdrop.visible = true
        m.itemIcon.visible = true
        return
    end if
    if m.itemPoster.loadStatus = "ready" and m.itemPoster.uri <> ""
        m.backdrop.visible = false
        m.itemIcon.visible = false
        if isValid(m.overlaidTitle) then
            m.overlaidTitle.visible = false
        end if
    else
        m.backdrop.visible = true
        m.itemIcon.visible = true
        if isValid(m.overlaidTitle) then
            m.overlaidTitle.visible = true
        end if
    end if
end sub
'//# sourceMappingURL=./HomeItem.brs.map