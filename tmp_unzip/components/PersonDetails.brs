'import "pkg:/source/api/baserequest.bs"
'import "pkg:/source/api/Image.bs"
'import "pkg:/source/enums/AnimationState.bs"
'import "pkg:/source/enums/ColorPalette.bs"
'import "pkg:/source/utils/config.bs"
'import "pkg:/source/utils/controlStyle.bs"
'import "pkg:/source/utils/misc.bs"



sub init()
    m.dscr = m.top.findNode("description")
    m.overviewBackground = m.top.findNode("overviewBackground")
    m.dscrBorder = m.top.findNode("dscrBorder")
    m.nameLabel = m.top.findNode("name")
    m.lifeInfo = m.top.findNode("lifeInfo")
    m.creditInfo = m.top.findNode("creditInfo")
    m.vidsList = m.top.findNode("extrasGrid")
    m.gridAnime = m.top.findNode("gridAnime")
    m.gridTranslationInterp = m.top.findNode("gridTranslationInterp")
    if isValid(m.vidsList)
        m.vidsList.observeField("targetTranslationY", "onExtrasTargetTranslationYChanged")
    end if
    m.btnGrp = m.top.findNode("buttons")
    m.btnGrp.observeField("escape", "onButtonGroupEscaped")
    m.favBtn = m.top.findNode("favorite-button")
    m.mainGroup = m.top.findNode("main_group")
    m.extrasGrp = m.top.findNode("extrasGrp")
    m.personDetailsSlider = m.top.findNode("personDetailsSlider")
    m.personDetailsSliderInterp = m.top.findNode("personDetailsSliderInterp")
    m.personExtrasClosing = false
    if isValid(m.personDetailsSlider)
        m.personDetailsSlider.observeField("state", "onPersonDetailsSliderStateChanged")
    end if
    m.defaultMainGroupTranslation = [
        60
        180
    ]
    if isValid(m.mainGroup)
        m.defaultMainGroupTranslation = [
            m.mainGroup.translation[0]
            m.mainGroup.translation[1]
        ]
    end if
    m.personExtrasActive = false
    m.personExtrasPadding = 24
    m.extrasPanelOpenY = 306
    m.extrasPanelClosedY = 972
    m.extrasPanelFocusedOpacity = 0.85
    m.extrasPanelRestOpacity = 0.65
    if isValid(m.extrasGrp)
        m.extrasGrp.opacity = 0.78
        ' JellyRock port: keep the extras tray reading like the same dark surface as the person bio card.
        m.extrasGrp.color = "#121212E6"
    end if
    m.top.optionsAvailable = false
    setDescriptionVisualState(false)
end sub

sub loadPerson()
    deactivatePersonExtrasLayout()
    if not isValid(m.top.itemContent) or not isValid(m.top.itemContent.json) then
        return
    end if
    item = m.top.itemContent
    itemData = item.json
    m.top.Id = itemData.id
    if isValid(m.nameLabel)
        m.nameLabel.Text = itemData.Name
    end if
    updatePersonMetadata(itemData)
    if itemData.Overview <> invalid and itemData.Overview <> ""
        m.dscr.text = itemData.Overview
    else
        m.dscr.text = tr("Biographical information for this person is not currently available.")
    end if
    m.dscr.horizAlign = "left"
    m.dscr.vertAlign = "top"
    if item.posterURL <> invalid and item.posterURL <> ""
        m.top.findnode("personImage").uri = item.posterURL
    else
        m.top.findnode("personImage").uri = "pkg:/images/baseline_person_white_48dp.png"
    end if
    m.vidsList.callFunc("loadPersonVideos", m.top.Id)
    setFavoriteColor()
    if not m.favBtn.hasFocus() then
        dscrShowFocus()
    end if
end sub

sub updatePersonMetadata(itemData as object)
    if isValid(m.lifeInfo)
        lifeText = buildPersonLifeText(itemData)
        m.lifeInfo.text = lifeText
        m.lifeInfo.visible = lifeText <> ""
    end if
    if isValid(m.creditInfo)
        creditText = buildPersonCreditsText(itemData)
        m.creditInfo.text = creditText
        m.creditInfo.visible = creditText <> ""
    end if
end sub

function buildPersonLifeText(itemData as object) as string
    birthIso = chainLookupReturn(itemData, "PremiereDate", "")
    if birthIso = invalid or birthIso = "" then
        return ""
    end if
    birthDate = CreateObject("roDateTime")
    birthDate.FromISO8601String(birthIso)
    lifeText = birthDate.AsDateString("short-month-no-weekday")
    compareDate = CreateObject("roDateTime")
    deathIso = chainLookupReturn(itemData, "EndDate", "")
    if deathIso <> invalid and deathIso <> ""
        deathDate = CreateObject("roDateTime")
        deathDate.FromISO8601String(deathIso)
        lifeText = lifeText + " - " + deathDate.AsDateString("short-month-no-weekday")
        compareDate = deathDate
    end if
    age = getAgeInYears(birthDate, compareDate)
    if age > 0
        lifeText = lifeText + " · " + formatCountLabel(age, "year old", "years old")
    end if
    return lifeText
end function

function buildPersonCreditsText(itemData as object) as string
    parts = []
    movieCount = lookupPersonCount(itemData, "MovieCount")
    episodeCount = lookupPersonCount(itemData, "EpisodeCount")
    if movieCount > 0
        parts.push(formatCountLabel(movieCount, "movie", "movies"))
    end if
    if episodeCount > 0
        parts.push(formatCountLabel(episodeCount, "episode", "episodes"))
    end if
    return parts.join(" · ")
end function

function lookupPersonCount(itemData as object, fieldName as string) as integer
    countValue = chainLookupReturn(itemData, fieldName, invalid)
    if countValue = invalid
        countValue = chainLookupReturn(itemData, "ItemCounts." + fieldName, invalid)
    end if
    return toInteger(countValue)
end function

function toInteger(value as dynamic) as integer
    if value = invalid then
        return 0
    end if
    return int(val(value.ToStr()))
end function

function formatCountLabel(count as integer, singular as string, plural as string) as string
    label = singular
    if count <> 1
        label = plural
    end if
    return stri(count).trim() + " " + label
end function

function getAgeInYears(startDate as object, endDate as object) as integer
    if not isValid(startDate) or not isValid(endDate) then
        return 0
    end if
    age = endDate.getYear() - startDate.getYear()
    if endDate.getMonth() < startDate.getMonth()
        age--
    else if endDate.getMonth() = startDate.getMonth()
        if endDate.getDayOfMonth() < startDate.getDayOfMonth()
            age--
        end if
    end if
    if age < 0 then
        return 0
    end if
    return age
end function

sub dscrShowFocus()
    m.dscr.setFocus(true)
    group = m.global.sceneManager.callFunc("getActiveScene")
    group.lastFocus = m.dscr
    setDescriptionVisualState(true)
end sub

sub setDescriptionVisualState(isFocused as boolean)
    if isValid(m.dscr)
        if isFocused then
            m.dscr.opacity = 1.0
        else
            m.dscr.opacity = 0.72
        end if
    end if
    if isValid(m.overviewBackground)
        if isFocused then
            m.overviewBackground.color = "#020B2AE6"
        else
            m.overviewBackground.color = "#55020B2A"
        end if
    end if
    if isValid(m.dscrBorder)
        if isFocused then
            m.dscrBorder.color = getControlAccentColor("#7B2FBE")
        else
            m.dscrBorder.color = "0x00000000"
        end if
    end if
end sub

sub showPersonExtras()
    if m.personExtrasActive then
        return
    end if
    m.personExtrasClosing = false
    updatePersonDetailsAnimationTarget()
    activatePersonExtrasLayout()
    vertSlider = m.top.findNode("VertSlider")
    extrasFader = m.top.findNode("extrasFader")
    pplAnime = m.top.findNode("pplAnime")
    if isValid(m.personDetailsSlider)
        m.personDetailsSlider.reverse = false
        m.personDetailsSlider.control = "start"
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
end sub

sub hidePersonExtras()
    if not m.personExtrasActive
        deactivatePersonExtrasLayout()
        return
    end if
    vertSlider = m.top.findNode("VertSlider")
    extrasFader = m.top.findNode("extrasFader")
    pplAnime = m.top.findNode("pplAnime")
    m.personExtrasClosing = true
    setPersonDetailsSlideToDefault()
    if isValid(m.personDetailsSlider)
        m.personDetailsSlider.reverse = false
        m.personDetailsSlider.control = "start"
    else
        deactivatePersonExtrasLayout()
        m.personExtrasClosing = false
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

sub onExtrasTargetTranslationYChanged()
    if not isValid(m.vidsList) then
        return
    end if
    currentY = m.vidsList.translation[1]
    targetY = m.vidsList.targetTranslationY
    if abs(currentY - targetY) < 1 then
        return
    end if
    xPos = m.vidsList.translation[0]
    if isValid(m.gridTranslationInterp)
        m.gridTranslationInterp.keyValue = [
            [
                xPos
                currentY
            ]
            [
                xPos
                targetY
            ]
        ]
    end if
    if isValid(m.gridAnime)
        m.gridAnime.control = "start"
    end if
end sub

sub activatePersonExtrasLayout()
    if m.personExtrasActive then
        return
    end if
    m.personExtrasActive = true
end sub

sub deactivatePersonExtrasLayout()
    if isValid(m.personDetailsSlider)
        m.personDetailsSlider.control = "stop"
    end if
    if isValid(m.mainGroup)
        m.mainGroup.translation = [
            m.defaultMainGroupTranslation[0]
            m.defaultMainGroupTranslation[1]
        ]
    end if
    m.personExtrasActive = false
end sub

sub updatePersonDetailsAnimationTarget()
    if not isValid(m.mainGroup) then
        return
    end if
    currentY = m.mainGroup.translation[1]
    mainRect = m.mainGroup.boundingRect()
    screenBottom = currentY + mainRect.y + mainRect.height
    targetY = currentY + ((m.extrasPanelOpenY - m.personExtrasPadding) - screenBottom)
    if targetY > currentY
        targetY = currentY
    end if
    setPersonDetailsSlideTarget(targetY)
end sub

sub setPersonDetailsSlideTarget(targetY as float)
    if not isValid(m.personDetailsSliderInterp) or not isValid(m.mainGroup) then
        return
    end if
    currentX = m.mainGroup.translation[0]
    currentY = m.mainGroup.translation[1]
    m.personDetailsSliderInterp.keyValue = [
        [
            currentX
            currentY
        ]
        [
            currentX
            targetY
        ]
    ]
end sub

sub setPersonDetailsSlideToDefault()
    if not isValid(m.personDetailsSliderInterp) or not isValid(m.mainGroup) then
        return
    end if
    currentX = m.mainGroup.translation[0]
    currentY = m.mainGroup.translation[1]
    m.personDetailsSliderInterp.keyValue = [
        [
            currentX
            currentY
        ]
        [
            m.defaultMainGroupTranslation[0]
            m.defaultMainGroupTranslation[1]
        ]
    ]
end sub

function isPersonExtrasTopRowFocused() as boolean
    if not isValid(m.vidsList) then
        return false
    end if
    if isValid(m.vidsList.rowItemFocused) and m.vidsList.rowItemFocused.Count() > 0
        return m.vidsList.rowItemFocused[0] = 0
    end if
    return m.vidsList.itemFocused = 0
end function

sub onPersonDetailsSliderStateChanged()
    if not m.personExtrasClosing then
        return
    end if
    if not isValid(m.personDetailsSlider) then
        return
    end if
    if not isStringEqual(m.personDetailsSlider.state, "stopped") then
        return
    end if
    deactivatePersonExtrasLayout()
    m.personExtrasClosing = false
end sub

sub onButtonGroupEscaped()
    key = m.btnGrp.escape
    if key = "down"
        dscrShowFocus()
    end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then
        return false
    end if
    if m.personExtrasClosing then
        return true
    end if
    if key = "OK"
        if m.dscr.hasFocus()
            createFullDscrDlg()
            return true
        end if
        if isValid(m.favBtn) and m.favBtn.isInFocusChain()
            m.top.buttonSelected = "favorite-button"
            return true
        end if
        return false
    end if
    if key = "back"
        if isValid(m.vidsList) and m.vidsList.isInFocusChain()
            hidePersonExtras()
            dscrShowFocus()
            return true
        end if
        m.global.sceneManager.callfunc("popScene")
        return true
    end if
    if key = "down"
        if m.dscr.hasFocus()
            setDescriptionVisualState(false)
            m.vidsList.setFocus(true)
            group = m.global.sceneManager.callFunc("getActiveScene")
            group.lastFocus = m.vidsList
            showPersonExtras()
            return true
        else if isValid(m.favBtn) and m.favBtn.isInFocusChain()
            dscrShowFocus()
            return true
        end if
    else if key = "up"
        if m.dscr.hasFocus()
            m.favBtn.setFocus(true)
            group = m.global.sceneManager.callFunc("getActiveScene")
            group.lastFocus = m.favBtn
            setDescriptionVisualState(false)
            return true
        else if m.vidsList.isInFocusChain() and isPersonExtrasTopRowFocused()
            hidePersonExtras()
            dscrShowFocus()
            return true
        end if
    end if
    return false
end function

sub setFavoriteColor()
    fave = m.top.itemContent.favorite
    fave_button = m.top.findNode("favorite-button")
    if not isValid(fave_button) then
        return
    end if
    if fave <> invalid and fave
        fave_button.text = tr("Favorite")
        if fave_button.hasField("isButtonSelected") then
            fave_button.isButtonSelected = true
        end if
    else
        fave_button.text = tr("Set Favorite")
        if fave_button.hasField("isButtonSelected") then
            fave_button.isButtonSelected = false
        end if
    end if
    if fave_button.hasField("iconBlendColor") then
        fave_button.iconBlendColor = "#ffffff"
    end if
    if fave_button.hasField("focusIconBlendColor") then
        fave_button.focusIconBlendColor = "#ffffff"
    end if
end sub

sub createFullDscrDlg()
    if isAllValid([
        m.top.itemContent.json.Name
        m.dscr.text
    ])
        m.global.sceneManager.callFunc("standardDialog", m.top.itemContent.json.Name, {
            data: [
                "<p>" + m.dscr.text + "</p>"
            ]
        })
    end if
end sub

function shortDate(isoDate) as string
    myDate = CreateObject("roDateTime")
    myDate.FromISO8601String(isoDate)
    return myDate.AsDateString("short-month-no-weekday")
end function
'//# sourceMappingURL=./PersonDetails.brs.map