'import "pkg:/source/enums/ImageType.bs"
'import "pkg:/source/utils/misc.bs"


function LoginFlow()
    'Collect Jellyfin server and user information
    start_login:
    serverUrl = get_setting("server")
    if isValid(serverUrl)
        startOver = not session_server_UpdateURL(serverUrl)
    else
        startOver = true
    end if
    invalidServer = true
    if not startOver
        m.scene.isLoading = true
        invalidServer = ServerInfo().Error
        m.scene.isLoading = false
    end if
    m.serverSelection = "Saved"
    if startOver or invalidServer
        SendPerformanceBeacon("AppDialogInitiate") ' Roku Performance monitoring - Dialog Starting
        m.serverSelection = CreateServerGroup()
        SendPerformanceBeacon("AppDialogComplete") ' Roku Performance monitoring - Dialog Closed
        if m.serverSelection = "backPressed"
            m.global.sceneManager.callFunc("clearScenes")
            return false
        end if
        SaveServerList()
    end if
    serverVersion = ServerInfo().LookupCI("version")
    if isValidAndNotEmpty(serverVersion)
        ServerVersionCheck(serverVersion)
    end if
    activeUser = get_setting("active_user")
    if activeUser = invalid
        user_select:
        SendPerformanceBeacon("AppDialogInitiate") ' Roku Performance monitoring - Dialog Starting
        publicUsers = GetPublicUsers()
        numPubUsers = 0
        if isValid(publicUsers) then
            numPubUsers = publicUsers.count()
        end if
        savedUsers = getSavedUsers()
        numSavedUsers = savedUsers.count()
        ' unset_setting("userIgnoreList")
        userIgnoreListSetting = get_setting("userIgnoreList", "[]")
        userIgnoreList = ParseJson(userIgnoreListSetting)
        userIgnoreListArray = []
        for each ignoredUser in userIgnoreList
            userIgnoreListArray.push(ignoredUser.ID)
        end for
        if numPubUsers > 0 or numSavedUsers > 0
            publicUsersNodes = []
            publicUserIds = []
            ' load public users
            if numPubUsers > 0
                for each item in publicUsers
                    if inArray(userIgnoreListArray, item.id) then
                        continue for
                    end if
                    user = CreateObject("roSGNode", "PublicUserData")
                    user.isPublic = true
                    user.id = item.Id
                    user.name = item.Name
                    if isValid(item.PrimaryImageTag)
                        user.ImageURL = UserImageURL(user.id, {
                            "tag": item.PrimaryImageTag
                        })
                    end if
                    publicUsersNodes.push(user)
                    publicUserIds.push(user.id)
                end for
            end if
            ' load saved users for this server id
            if numSavedUsers > 0
                for each savedUser in savedUsers
                    if isValid(savedUser.serverId) and savedUser.serverId = m.global.session.server.id
                        ' only show unique userids on screen.
                        if not inArray(publicUserIds, savedUser.Id)
                            user = CreateObject("roSGNode", "PublicUserData")
                            user.isPublic = false
                            user.id = savedUser.Id
                            if isValid(savedUser.username)
                                user.name = savedUser.username
                            end if
                            user.ImageURL = UserImageURL(user.id)
                            publicUsersNodes.push(user)
                        end if
                    end if
                end for
            end if
            ' push all users to the user select view
            userSelected = CreateUserSelectGroup(publicUsersNodes)
            SendPerformanceBeacon("AppDialogComplete") ' Roku Performance monitoring - Dialog Closed
            if userSelected = "backPressed"
                session_server_Delete()
                unset_setting("server")
                goto start_login
            else if userSelected <> ""
                startLoadingSpinner()
                session_user_Update("name", userSelected)
                ' save userid to session
                for each user in publicUsersNodes
                    if user.name = userSelected
                        session_user_Update("id", user.id)
                        exit for
                    end if
                end for
                ' try to login with token from registry
                myToken = get_user_setting("token")
                if myToken <> invalid
                    ' check if token is valid
                    session_user_Update("authToken", myToken)
                    currentUser = AboutMe()
                    if currentUser = invalid
                        unset_user_setting("token")
                        unset_user_setting("username")
                    else
                        session_user_Login(currentUser, true)
                        LoadUserAbilities()
                        return true
                    end if
                else
                    print "No auth token found in registry for selected user"
                end if
                'Try to login without password. If the token is valid, we're done
                userData = get_token(userSelected, "")
                if isValid(userData)
                    session_user_Login(userData, true)
                    LoadUserAbilities()
                    return true
                else
                    print "Auth failed. Password required"
                end if
            end if
        else
            userSelected = ""
        end if
        stopLoadingSpinner()
        passwordEntry = CreateSigninGroup(userSelected, UserImageURL(m.global.session.user.id))
        SendPerformanceBeacon("AppDialogComplete") ' Roku Performance monitoring - Dialog Closed
        if passwordEntry = "backPressed"
            if numPubUsers > 0
                goto user_select
            else
                session_server_Delete()
                unset_setting("server")
                goto start_login
            end if
        end if
    else
        session_user_Update("id", activeUser)
        myUsername = get_user_setting("username")
        myAuthToken = get_user_setting("token")
        if isValid(myAuthToken) and isValid(myUsername)
            session_user_Update("authToken", myAuthToken)
            session_user_Update("name", myUsername)
            currentUser = AboutMe()
            if currentUser = invalid
                'Try to login without password. If the token is valid, we're done
                userData = get_token(myUsername, "")
                if isValid(userData)
                    session_user_Login(userData, true)
                    LoadUserAbilities()
                    return true
                else
                    print "Auth failed. Password required"
                    print "delete token and restart login flow"
                    unset_user_setting("token")
                    unset_user_setting("username")
                    goto start_login
                end if
            else
                session_user_Login(currentUser, true)
            end if
        else
            print "No auth token found in registry"
        end if
    end if
    if m.global.session.user.id = invalid or m.global.session.user.authToken = invalid
        unset_setting("active_user")
        session_user_Logout()
        goto start_login
    end if
    LoadUserAbilities()
    m.global.sceneManager.callFunc("clearScenes")
    return true
end function

sub ServerVersionCheck(systemVersion as string)
    meetsRequirements = serverVersionMeetsMinimumRequirements(systemVersion, ([
        10
        9
        0
    ]))
    if not meetsRequirements
        m.scene.isLoading = false
        stopLoadingSpinner()
        displayMinimumServerVersion = (bslib_toString(([
            10
            9
            0
        ])[0]) + "." + bslib_toString(([
            10
            9
            0
        ])[1]) + "." + bslib_toString(([
            10
            9
            0
        ])[2]))
        returnValue = show_dialog((bslib_toString(tr("The selected Jellyfin server uses version")) + " " + bslib_toString(systemVersion) + " " + bslib_toString(tr("which is not supported by this app. Please update the server to")) + " " + bslib_toString(displayMinimumServerVersion) + " " + bslib_toString(tr("or newer to use this app or install and use the Jellyfin Legacy app from Roku's Streaming Store")) + "."), [
            tr("Return to server select screen")
        ], 0)
        if isValid(returnValue)
            session_server_Delete()
            unset_setting("server")
            LoginFlow()
        end if
    end if
end sub

sub SaveServerList()
    'Save off this server to our list of saved servers for easier navigation between servers
    server = m.global.session.server.url
    saved = get_setting("saved_servers")
    if isValid(server)
        server = LCase(server) 'Saved server data is always lowercase
    end if
    entryCount = 0
    addNewEntry = true
    savedServers = {
        serverList: []
    }
    if isValid(saved)
        savedServers = ParseJson(saved)
        entryCount = savedServers.serverList.Count()
        if isValid(savedServers.serverList) and entryCount > 0
            for each item in savedServers.serverList
                if item.baseUrl = server
                    addNewEntry = false
                    exit for
                end if
            end for
        end if
    end if
    if addNewEntry
        if entryCount = 0
            set_setting("saved_servers", FormatJson({
                serverList: [
                    {
                        name: m.serverSelection
                        baseUrl: server
                        iconUrl: "pkg:/images/logo-icon120.jpg"
                        iconWidth: 120
                        iconHeight: 120
                    }
                ]
            }))
        else
            savedServers.serverList.Push({
                name: m.serverSelection
                baseUrl: server
                iconUrl: "pkg:/images/logo-icon120.jpg"
                iconWidth: 120
                iconHeight: 120
            })
            set_setting("saved_servers", FormatJson(savedServers))
        end if
    end if
end sub

sub DeleteFromServerList(urlToDelete)
    saved = get_setting("saved_servers")
    if isValid(urlToDelete)
        urlToDelete = LCase(urlToDelete)
    end if
    if isValid(saved)
        savedServers = ParseJson(saved)
        newServers = {
            serverList: []
        }
        for each item in savedServers.serverList
            if item.baseUrl <> urlToDelete
                newServers.serverList.Push(item)
            end if
        end for
        set_setting("saved_servers", FormatJson(newServers))
    end if
end sub

' Roku Performance monitoring
sub SendPerformanceBeacon(signalName as string)
    if m.global.app_loaded = false
        m.scene.signalBeacon(signalName)
    end if
end sub

function CreateServerGroup() as string
    screen = CreateObject("roSGNode", "SetServerScreen")
    m.global.sceneManager.callFunc("pushScene", screen)
    port = CreateObject("roMessagePort")
    if isValid(m.global.session.server.url)
        screen.serverUrl = m.global.session.server.url
    end if
    submitButton = screen.findNode("submit")
    submitButton.observeField("selected", port)
    screen.observeField("forgetServer", port)
    screen.observeField("backPressed", port)
    while true
        msg = wait(0, port)
        if type(msg) = "roSGScreenEvent" and msg.isScreenClosed()
            return "false"
        else if isNodeEvent(msg, "backPressed")
            return "backPressed"
        else if type(msg) = "roSGNodeEvent"
            node = msg.getNode()
            if node = "submit"
                m.scene.isLoading = true
                serverUrl = inferServerUrl(screen.serverUrl)
                isConnected = session_server_UpdateURL(serverUrl)
                serverInfoResult = invalid
                if isConnected
                    set_setting("server", serverUrl)
                    serverInfoResult = ServerInfo()
                    'If this is a different server from what we know, reset username/password setting
                    if m.global.session.server.url <> serverUrl
                        set_setting("username", "")
                        set_setting("password", "")
                    end if
                    set_setting("server", serverUrl)
                end if
                m.scene.isLoading = false
                if isConnected = false or serverInfoResult = invalid
                    ' Maybe don't unset setting, but offer as a prompt
                    ' Server not found, is it online? New values / Retry
                    screen.errorMessage = tr("Server not found, is it online?")
                    SignOut(false)
                else
                    if isValid(serverInfoResult.Error) and serverInfoResult.Error
                        ' If server redirected received, update the URL
                        if isValid(serverInfoResult.UpdatedUrl)
                            serverUrl = serverInfoResult.UpdatedUrl
                            isConnected = session_server_UpdateURL(serverUrl)
                            if isConnected
                                set_setting("server", serverUrl)
                                screen.visible = false
                                return ""
                            end if
                        end if
                        ' Display Error Message to user
                        message = tr("Error: ")
                        if isValid(serverInfoResult.ErrorCode)
                            message = message + "[" + serverInfoResult.ErrorCode.toStr() + "] "
                        end if
                        screen.errorMessage = message + tr(serverInfoResult.ErrorMessage)
                        SignOut(false)
                    else
                        screen.visible = false
                        if isValid(serverInfoResult.serverName)
                            return serverInfoResult.ServerName + " (Saved)"
                        else
                            return "Saved"
                        end if
                    end if
                end if
            else if msg.getField() = "forgetServer"
                serverPicker = screen.findNode("serverPicker")
                itemToDelete = serverPicker.content.getChild(serverPicker.itemFocused)
                urlToDelete = msg.GetData()
                if isValid(urlToDelete)
                    DeleteFromServerList(urlToDelete)
                    serverPicker.content.removeChild(itemToDelete)
                    serverPicker.setFocus(true)
                end if
            end if
        end if
    end while
    ' Just hide it when done, in case we need to come back
    screen.visible = false
    return ""
end function

function CreateUserSelectGroup(users = [])
    group = CreateObject("roSGNode", "UserSelect")
    m.global.sceneManager.callFunc("pushScene", group)
    port = CreateObject("roMessagePort")
    userIgnoreListSetting = get_setting("userIgnoreList", "[]")
    userIgnoreList = ParseJson(userIgnoreListSetting)
    group.hiddenUserList = userIgnoreList
    group.itemContent = users
    group.findNode("userRow").observeField("userSelected", port)
    group.observeField("forgetUser", port)
    group.observeField("hideUser", port)
    group.observeField("showUser", port)
    manualLoginButton = group.findNode("manualLogin")
    manualLoginButton.observeField("selected", port)
    group.observeField("backPressed", port)
    while true
        msg = wait(0, port)
        if type(msg) = "roSGScreenEvent" and msg.isScreenClosed()
            group.visible = false
            return -1
        else if isNodeEvent(msg, "backPressed")
            return "backPressed"
        else if type(msg) = "roSGNodeEvent" and msg.getField() = "forgetUser"
            returnValue = show_dialog(tr("Are you sure you want to forget this user?"), [
                tr("Yes")
                tr("No, Cancel")
            ], 1)
            if returnValue = 0
                forgetUserID = msg.GetData()
                userList = group.itemContent
                for i = userList.count() - 1 to 0 step -1
                    if userList[i].id = forgetUserID
                        userList.Delete(i)
                        group.itemContent = userList
                        exit for
                    end if
                end for
                registry_delete("token", forgetUserID)
                registry_delete("username", forgetUserID)
                registry_delete("serverId", forgetUserID)
            end if
        else if type(msg) = "roSGNodeEvent" and msg.getField() = "hideUser"
            returnValue = show_dialog("Are you sure you want to hide this user?", [
                "Yes"
                "No, Cancel"
            ], 1)
            if returnValue = 0
                hideUser = msg.GetData()
                userList = group.itemContent
                for i = userList.count() - 1 to 0 step -1
                    if userList[i].id = hideUser.id
                        userList.Delete(i)
                        group.itemContent = userList
                        exit for
                    end if
                end for
                ' Add user to ignore list
                userIgnoreListSetting = get_setting("userIgnoreList", "[]")
                userIgnoreList = ParseJson(userIgnoreListSetting)
                userIgnoreList.push({
                    id: hideUser.id
                    ImageURL: hideUser.ImageURL
                    isPublic: hideUser.isPublic
                    name: hideUser.name
                })
                set_setting("userIgnoreList", FormatJson(userIgnoreList))
                group.hiddenUserList = userIgnoreList
            end if
        else if type(msg) = "roSGNodeEvent" and msg.getField() = "showUser"
            showUser = msg.GetData()
            userList = group.itemContent
            ' Add user back to select user list
            user = CreateObject("roSGNode", "PublicUserData")
            user.name = showUser.name
            user.isPublic = showUser.isPublic
            user.id = showUser.id
            user.ImageURL = showUser.imageURL
            userList.push(user)
            group.itemContent = userList
            ' Remove user from hidden user list
            hiddenUserList = group.hiddenUserList
            for i = hiddenUserList.count() - 1 to 0 step -1
                if hiddenUserList[i].id = showUser.id
                    hiddenUserList.delete(i)
                    group.hiddenUserList = hiddenUserList
                    exit for
                end if
            end for
            ' Remove user from ignore list setting
            userIgnoreListSetting = get_setting("userIgnoreList", "[]")
            userIgnoreList = ParseJson(userIgnoreListSetting)
            for i = userIgnoreList.count() - 1 to 0 step -1
                if userIgnoreList[i].id = showUser.id
                    userIgnoreList.delete(i)
                    exit for
                end if
            end for
            set_setting("userIgnoreList", FormatJson(userIgnoreList))
        else if type(msg) = "roSGNodeEvent" and msg.getField() = "userSelected"
            return msg.GetData()
        else if type(msg) = "roSGNodeEvent" and msg.getField() = "itemSelected"
            if msg.getData() = 0
                return ""
            end if
        else if type(msg) = "roSGNodeEvent" and LCase(msg.getNode()) = "manuallogin"
            session_user_Update("id", "")
            return ""
        end if
    end while
    ' Just hide it when done, in case we need to come back
    group.visible = false
    return ""
end function

function CreateSigninGroup(user = "", profileImageUri = "")
    ' Get and Save Jellyfin user login credentials
    group = CreateObject("roSGNode", "SigninScene")
    group.user = user
    group.profileImageUri = profileImageUri
    m.global.sceneManager.callFunc("pushScene", group)
    port = CreateObject("roMessagePort")
    ' Add checkbox for saving credentials
    saveCredentials = group.findNode("saveCredentials")
    quickConnect = group.findNode("quickConnect")
    quickConnect.observeField("selected", port)
    button = group.findNode("submit")
    button.observeField("selected", port)
    config = group.findNode("configOptions")
    username = config.content.getChild(0)
    password = config.content.getChild(1)
    group.observeField("backPressed", port)
    while true
        msg = wait(0, port)
        if type(msg) = "roSGScreenEvent" and msg.isScreenClosed()
            group.visible = false
            return "false"
        else if isNodeEvent(msg, "backPressed")
            group.unobserveField("backPressed")
            group.backPressed = false
            return "backPressed"
        else if type(msg) = "roSGNodeEvent"
            node = msg.getNode()
            if isStringEqual(node, "submit")
                startLoadingSpinner()
                ' Validate credentials
                activeUser = get_token(username.value, password.value)
                if isValid(activeUser)
                    set_setting("saveCredentials", saveCredentials.checkedState[0].toStr())
                    if saveCredentials.checkedState[0] = true
                        ' save credentials
                        session_user_Login(activeUser, true)
                        set_user_setting("token", activeUser.token)
                        set_user_setting("username", username.value)
                    else
                        session_user_Login(activeUser)
                    end if
                    return "true"
                end if
                stopLoadingSpinner()
                group.alert = tr("Login attempt failed.")
            else if isStringEqual(node, "quickConnect")
                json = initQuickConnect()
                if json = invalid
                    group.alert = tr("Quick Connect not available.")
                else
                    ' Server user is talking to is at least 10.8 and has quick connect enabled...
                    m.quickConnectDialog = createObject("roSGNode", "QuickConnectDialog")
                    m.quickConnectDialog.saveCredentials = saveCredentials.checkedState[0]
                    m.quickConnectDialog.quickConnectJson = json
                    m.quickConnectDialog.title = tr("Quick Connect")
                    m.quickConnectDialog.message = [
                        tr("Here is your Quick Connect code: ") + json.Code
                        tr("(Dialog will close automatically)")
                    ]
                    m.quickConnectDialog.buttons = [
                        tr("Cancel")
                    ]
                    m.quickConnectDialog.observeField("authenticated", port)
                    dlgPalette = createObject("roSGNode", "RSGPalette")
                    dlgPalette.colors = {
                        DialogBackgroundColor: "#020B2A"
                        DialogFocusColor: chainLookupReturn(m.global.session, "user.settings.colorCursor", "#7B2FBE")
                        DialogFocusItemColor: "#ffffff"
                        DialogSecondaryTextColor: "#ffffff"
                        DialogSecondaryItemColor: "#c8fafa"
                        DialogTextColor: "#ffffff"
                    }
                    m.quickConnectDialog.palette = dlgPalette
                    m.scene.dialog = m.quickConnectDialog
                end if
            else if msg.getField() = "authenticated"
                authenticated = msg.getData()
                if authenticated
                    ' Quick connect authentication was successful...
                    return "true"
                else
                    m.global.sceneManager.callFunc("standardDialog", "Quick Connect Error", {
                        data: [
                            "<p>" + tr("There was an error authenticating via Quick Connect.") + "</p>"
                        ]
                    })
                end if
            end if
        end if
    end while
    ' Just hide it when done, in case we need to come back
    group.visible = false
    return ""
end function

function CreateHomeGroup()
    ' Main screen after logging in. Shows the user's libraries
    group = CreateObject("roSGNode", "Home")
    group.observeFieldScoped("selectedItem", m.port)
    group.observeField("quickPlayNode", m.port)
    sidepanel = group.findNode("options")
    sidepanel.observeField("closeSidePanel", m.port)
    new_options = []
    options_buttons = [
        {
            "title": "Change user"
            "id": "change_user"
        }
        {
            "title": "Change server"
            "id": "change_server"
        }
        {
            "title": "Sign out"
            "id": "sign_out"
        }
    ]
    for each opt in options_buttons
        o = CreateObject("roSGNode", "OptionsButton")
        o.title = tr(opt.title)
        o.id = opt.id
        o.observeField("userMenuOptionSelected", m.port)
        new_options.push(o)
    end for
    ' And a profile button
    user_node = CreateObject("roSGNode", "OptionsData")
    user_node.id = "active_user"
    user_node.title = tr("Profile")
    user_node.base_title = tr("Profile")
    user_options = []
    for each user in AvailableUsers()
        user_options.push({
            display: user.username + "@" + user.server
            value: user.id
        })
    end for
    user_node.choices = user_options
    user_node.value = m.global.session.user.id
    new_options.push(user_node)
    sidepanel.options = new_options
    return group
end function

function CreateMovieDetailsGroup(movie as object, preloadedMetadata = invalid as dynamic) as dynamic
    ' validate movie node
    if not isValid(movie) or not isValid(movie.id)
        traceStep("MOVIE_TRACE", "CreateMovieDetailsGroup invalid movie payload")
        stopLoadingSpinner()
        return invalid
    end if
    metadataMode = "deferred"
    if isValid(preloadedMetadata)
        metadataMode = "preloaded"
    end if
    traceStep("MOVIE_TRACE", "CreateMovieDetailsGroup start id=" + movie.id + " mode=" + metadataMode)
    ' start building MovieDetails view
    group = CreateObject("roSGNode", "MovieDetails")
    if not isValid(group)
        traceStep("MOVIE_TRACE", "CreateMovieDetailsGroup failed to create MovieDetails node id=" + movie.id)
        stopLoadingSpinner()
        return invalid
    end if
    group.observeField("quickPlayNode", m.port)
    overhangTitle = chainLookupReturn(movie, "title", chainLookupReturn(movie, "json.Name", chainLookupReturn(movie, "json.name", "")))
    if not isValid(overhangTitle) then
        overhangTitle = ""
    end if
    group.overhangTitle = overhangTitle
    group.optionsAvailable = false
    ' push scene asap (to prevent extra button presses when retriving series/movie info)
    traceStep("MOVIE_TRACE", "CreateMovieDetailsGroup pushScene start id=" + movie.id)
    m.global.sceneManager.callFunc("pushScene", group)
    traceStep("MOVIE_TRACE", "CreateMovieDetailsGroup pushScene done id=" + movie.id)
    group.observeField("refreshMovieDetailsData", m.port)
    ' watch for button presses
    group.observeField("buttonSelected", m.port)
    ' setup and load movie extras
    extras = group.findNode("extrasGrid")
    if isValid(extras)
        extras.observeFieldScoped("selectedItem", m.port)
    end if
    if isValid(preloadedMetadata)
        ' Data already available — populate immediately
        traceStep("MOVIE_TRACE", "CreateMovieDetailsGroup assigning preloaded metadata id=" + movie.id)
        group.itemContent = preloadedMetadata
    else
        ' Fallback: load metadata asynchronously inside the component
        stopLoadingSpinner()
        traceStep("MOVIE_TRACE", "CreateMovieDetailsGroup loadMovieById fallback id=" + movie.id)
        group.callFunc("loadMovieById", movie)
    end if
    ' done building MovieDetails view
    traceStep("MOVIE_TRACE", "CreateMovieDetailsGroup end id=" + movie.id)
    return group
end function

function getResummableItem(parentID as string) as object
    if not isValidAndNotEmpty(parentID) then
        return invalid
    end if
    ' Check if there is at least 1 resummable item
    data = api_useritems_GetResumeItems({
        parentId: parentID
        userid: m.global.session.user.id
        SortBy: "SortName"
        recursive: true
        SortOrder: "Ascending"
        Filters: "IsResumable"
        limit: 1
        EnableTotalRecordCount: false
    })
    if isValid(data) and isValidAndNotEmpty(data.Items) then
        return data.Items[0]
    end if
    return invalid
end function

function hasResummableEpisode(parentID as string) as boolean
    return isValid(getResummableItem(parentID))
end function

function hasUnplayedEpisode(parentID as string) as boolean
    if not isValidAndNotEmpty(parentID) then
        return false
    end if
    ' Check if there is at least 1 unplayed item
    data = api_items_Get({
        parentId: parentID
        userid: m.global.session.user.id
        SortBy: "SortName"
        recursive: true
        SortOrder: "Ascending"
        Filters: "IsUnplayed"
        limit: 1
        EnableTotalRecordCount: false
    })
    if isValid(data) and isValidAndNotEmpty(data.Items) then
        return true
    end if
    return false
end function

function hasNextUpEpisode(parentID as string) as boolean
    if not isValidAndNotEmpty(parentID) then
        return false
    end if
    ' Check if there is at least 1 next up item
    data = api_shows_GetNextUp({
        seriesId: parentID
        recursive: true
        SortBy: "DatePlayed"
        SortOrder: "Descending"
        ImageTypeLimit: 1
        UserId: m.global.session.user.id
        EnableRewatching: m.global.session.user.settings["ui.details.enablerewatchingnextup"]
        enableResumable: true
        DisableFirstEpisode: false
        limit: 1
        EnableTotalRecordCount: false
    })
    if isValid(data) and isValidAndNotEmpty(data.Items) then
        return true
    end if
    return false
end function

function CreateSeriesDetailsGroup(seriesID as string) as dynamic
    ' validate series node
    if not isValidAndNotEmpty(seriesID) then
        return invalid
    end if
    startLoadingSpinner()
    ' Get season data early in the function so we can check number of seasons.
    apiSeasonData = api_shows_GetSeasons(seriesID, {
        userId: m.global.session.user.id
        enableImageTypes: (bslib_toString("Primary") + ", " + bslib_toString("Backdrop") + ", " + bslib_toString("Thumb"))
        imageTypeLimit: 1
        enableTotalRecordCount: false
    })
    if not isChainValid(apiSeasonData, "items")
        stopLoadingSpinner()
        return invalid
    end if
    ' Divert to season details if user setting goStraightToEpisodeListing is enabled and only one season exists.
    if m.global.session.user.settings["ui.tvshows.goStraightToEpisodeListing"]
        if isChainValid(apiSeasonData, "items")
            if chainLookup(apiSeasonData, "items").count() = 1
                stopLoadingSpinner()
                return CreateSeasonDetailsGroupByID(seriesID, chainLookup(apiSeasonData, "items")[0].id)
            end if
        end if
    end if
    seasonData = CreateObject("roSGNode", "ContentNode")
    for each item in apiSeasonData.Items
        tmp = seasonData.createChild("TVSeasonData")
        tmp.json = item
        tmp.posterURL = api_items_GetImageURL(item.id, "Primary", 0, {
            "maxHeight": 320
            "maxWidth": 180
            "quality": "90"
        })
    end for
    apiSeriesData = api_items_GetByID(seriesID, {
        userId: m.global.session.user.id
        enableImageTypes: (bslib_toString("Primary") + ", " + bslib_toString("Backdrop") + ", " + bslib_toString("Thumb"))
        imageTypeLimit: 1
        enableTotalRecordCount: false
    })
    seriesData = CreateObject("roSGNode", "SeriesData")
    seriesData.json = apiSeriesData
    ' validate series meta data
    if not isValid(seriesData)
        stopLoadingSpinner()
        return invalid
    end if
    ' start building SeriesDetails view
    group = CreateObject("roSGNode", "TVSeriesDetails")
    resummableItem = getResummableItem(seriesID)
    displayResumeButton = isValid(resummableItem)
    group.displayResumeButton = displayResumeButton
    if displayResumeButton
        group.resumeTicks = resummableItem.UserData.PlaybackPositionTicks
    end if
    group.optionsAvailable = false
    ' push scene asap (to prevent extra button presses when retriving series/movie info)
    m.global.sceneManager.callFunc("pushScene", group)
    group.itemContent = seriesData
    group.seasonData = seasonData
    ' watch for button presses
    group.observeField("buttonSelected", m.port)
    group.observeField("playSeriesFromStart", m.port)
    group.observeField("seasonSelected", m.port)
    group.observeField("quickPlayNode", m.port)
    group.observeField("refreshSeasonDetailsData", m.port)
    ' setup and load series extras
    extras = group.findNode("extrasGrid")
    extras.observeFieldScoped("selectedItem", m.port)
    extras.callFunc("loadParts", seriesData.json)
    ' done building SeriesDetails view
    stopLoadingSpinner()
    return group
end function

' Shows details on selected artist. Bio, image, and list of available albums
function CreateArtistView(artist as object) as dynamic
    ' validate artist node
    if not isValid(artist) or not isValid(artist.id) then
        return invalid
    end if
    musicData = MusicAlbumList(artist.id)
    appearsOnData = AppearsOnList(artist.id)
    if (not isValid(musicData) or musicData.getChildCount() = 0) and (not isValid(appearsOnData) or appearsOnData.getChildCount() = 0)
        ' Just songs under artists...
        group = CreateObject("roSGNode", "AlbumView")
        group.pageContent = ItemMetaData(artist.id)
        ' Lookup songs based on artist id
        songList = GetSongsByArtist(artist.id)
        if not isValid(songList)
            ' Lookup songs based on folder parent / child relationship
            songList = MusicSongList(artist.id)
        end if
        if not isValid(songList)
            return invalid
        end if
        group.albumData = songList
        group.observeField("playSong", m.port)
        group.observeField("instantMixSelected", m.port)
    else
        ' User has albums under artists
        group = CreateObject("roSGNode", "ArtistView")
        group.pageContent = ItemMetaData(artist.id)
        group.musicArtistAlbumData = musicData
        group.musicArtistAppearsOnData = appearsOnData
        group.artistOverview = ArtistOverview(artist.name)
        group.observeField("musicAlbumSelected", m.port)
        group.observeField("playArtistSelected", m.port)
        group.observeField("instantMixSelected", m.port)
        group.observeField("appearsOnSelected", m.port)
        group.observeField("similarArtistSelected", m.port)
    end if
    group.observeField("quickPlayNode", m.port)
    m.global.sceneManager.callFunc("pushScene", group)
    overhang = group.getScene().findNode("overhang")
    if isValid(overhang)
        overhang.visible = true
        overhang.isVisible = true
    end if
    return group
end function

' Shows details on selected album. Description text, image, and list of available songs
function CreateAlbumView(album as object) as dynamic
    ' validate album node
    if not isValid(album) or not isValid(album.id) then
        return invalid
    end if
    group = CreateObject("roSGNode", "AlbumView")
    m.global.sceneManager.callFunc("pushScene", group)
    group.pageContent = ItemMetaData(album.id)
    group.albumData = MusicSongList(album.id)
    ' Watch for user clicking on a song
    group.observeField("playSong", m.port)
    ' Watch for user click on Instant Mix button on album
    group.observeField("instantMixSelected", m.port)
    ' Play Album
    group.observeField("playAlbumSelected", m.port)
    ' Shuffle Album
    group.observeField("shuffleAlbumSelected", m.port)
    return group
end function

' Shows details on selected playlist. Description text, image, and list of available items
sub CreatePlaylistView(playlist as object)
    ' validate playlist node
    if not isValid(playlist) or not isValid(playlist.id) then
        return
    end if
    group = CreateObject("roSGNode", "PlaylistView")
    m.global.sceneManager.callFunc("pushScene", group)
    group.pageContent = ItemMetaData(playlist.id)
    group.listData = PlaylistItemList(playlist.id)
    ' Watch for user clicking on an item
    group.observeField("playlistItemSelected", m.port)
end sub

function CreateSeasonDetailsGroup(series as object, season as object) as dynamic
    ' validate series node
    if not isValid(series) or not isValid(series.id) then
        return invalid
    end if
    ' validate season node
    if not isValid(season) or not isValid(season.id) then
        return invalid
    end if
    startLoadingSpinner()
    ' get season meta data
    seasonMetaData = ItemMetaData(season.id)
    ' validate season meta data
    if not isValid(seasonMetaData)
        stopLoadingSpinner()
        return invalid
    end if
    ' start building SeasonDetails view
    group = CreateObject("roSGNode", "TVSeasonDetails")
    resummableItem = getResummableItem(season.id)
    displayResumeButton = isValid(resummableItem)
    group.displayResumeButton = displayResumeButton
    if displayResumeButton
        group.resumeTicks = resummableItem.UserData.PlaybackPositionTicks
    end if
    group.optionsAvailable = false
    ' push scene asap (to prevent extra button presses when retriving series/movie info)
    m.global.sceneManager.callFunc("pushScene", group)
    group.seasonData = seasonMetaData
    group.objects = TVEpisodes(series.id, season.id)
    group.episodeObjects = group.objects
    group.observeField("refreshSeasonDetailsData", m.port)
    group.observeField("playSeasonFromStart", m.port)
    ' watch for button presses
    group.observeFieldScoped("selectedItem", m.port)
    group.observeField("quickPlayNode", m.port)
    ' finished building SeasonDetails view
    stopLoadingSpinner()
    return group
end function

function CreateSeasonDetailsGroupByID(seriesID as string, seasonID as string) as dynamic
    ' validate parameters
    if seriesID = "" or seasonID = "" then
        return invalid
    end if
    startLoadingSpinner()
    ' get season meta data
    seasonMetaData = ItemMetaData(seasonID)
    ' validate season meta data
    if not isValid(seasonMetaData)
        stopLoadingSpinner()
        return invalid
    end if
    ' start building SeasonDetails view
    group = CreateObject("roSGNode", "TVSeasonDetails")
    resummableItem = getResummableItem(seasonID)
    displayResumeButton = isValid(resummableItem)
    group.displayResumeButton = displayResumeButton
    if displayResumeButton
        group.resumeTicks = resummableItem.UserData.PlaybackPositionTicks
    end if
    group.optionsAvailable = false
    ' push scene asap (to prevent extra button presses when retriving series/movie info)
    group.seasonData = seasonMetaData
    group.objects = TVEpisodes(seriesID, seasonID)
    group.episodeObjects = group.objects
    group.observeField("refreshSeasonDetailsData", m.port)
    group.observeField("playSeasonFromStart", m.port)
    ' watch for button presses
    group.observeFieldScoped("selectedItem", m.port)
    group.observeField("quickPlayNode", m.port)
    ' don't wait for the extras button
    stopLoadingSpinner()
    m.global.sceneManager.callFunc("pushScene", group)
    ' finished building SeasonDetails view
    return group
end function

function CreateOtherLibrary(libraryItem as object) as dynamic
    ' validate libraryItem
    if not isValid(libraryItem) then
        return invalid
    end if
    group = CreateObject("roSGNode", "OtherLibrary")
    group.parentItem = libraryItem
    group.optionsAvailable = true
    group.observeFieldScoped("selectedItem", m.port)
    group.observeField("quickPlayNode", m.port)
    return group
end function

function CreateLiveTVLibraryView(libraryItem as object) as dynamic
    ' validate libraryItem
    if not isValid(libraryItem) then
        return invalid
    end if
    group = CreateObject("roSGNode", "LiveTVLibraryView")
    group.parentItem = libraryItem
    group.optionsAvailable = true
    group.observeFieldScoped("selectedItem", m.port)
    group.observeField("quickPlayNode", m.port)
    return group
end function

function CreateVisualLibraryScene(libraryItem as object, mediaType as string) as dynamic
    ' validate libraryItem
    if not isValid(libraryItem) then
        return invalid
    end if
    group = CreateObject("roSGNode", "VisualLibraryScene")
    group.mediaType = mediaType
    group.parentItem = libraryItem
    group.observeFieldScoped("selectedItem", m.port)
    group.observeField("quickPlayNode", m.port)
    return group
end function

function CreateMusicLibraryView(libraryItem as object) as dynamic
    ' validate libraryItem
    if not isValid(libraryItem) then
        return invalid
    end if
    group = CreateObject("roSGNode", "MusicLibraryView")
    group.parentItem = libraryItem
    group.optionsAvailable = true
    group.observeFieldScoped("selectedItem", m.port)
    group.observeField("quickPlayNode", m.port)
    return group
end function

function CreateBookLibraryView(libraryItem as object) as dynamic
    ' validate libraryItem
    if not isValid(libraryItem) then
        return invalid
    end if
    group = CreateObject("roSGNode", "AudioBookLibraryView")
    group.parentItem = libraryItem
    group.optionsAvailable = true
    group.observeFieldScoped("selectedItem", m.port)
    group.observeField("quickPlayNode", m.port)
    return group
end function

function CreateSearchPage()
    ' Search + Results Page
    group = CreateObject("roSGNode", "searchResults")
    group.observeField("quickPlayNode", m.port)
    options = group.findNode("searchRow")
    options.observeField("itemSelected", m.port)
    return group
end function

function CreatePersonView(personData as object) as dynamic
    ' validate personData node
    if not isValid(personData) or not isValid(personData.id) then
        return invalid
    end if
    startLoadingSpinner()
    ' get person meta data
    personMetaData = ItemMetaData(personData.id)
    ' validate season meta data
    if not isValid(personMetaData)
        stopLoadingSpinner()
        return invalid
    end if
    ' start building Person View
    person = CreateObject("roSGNode", "PersonDetails")
    ' push scene asap (to prevent extra button presses when retriving series/movie info)
    m.global.SceneManager.callFunc("pushScene", person)
    person.itemContent = personMetaData
    person.setFocus(true)
    ' watch for button presses
    person.observeFieldScoped("selectedItem", m.port)
    person.observeFieldScoped("buttonSelected", m.port)
    ' finished building Person View
    stopLoadingSpinner()
    return person
end function

'Opens dialog asking user if they want to resume video or start playback over only on the home screen
sub playbackOptionDialog(time as longinteger, meta as object)
    resumeData = [
        tr("Resume playing at ") + ticksToHuman(time) + "."
        tr("Start over from the beginning.")
    ]
    group = m.global.sceneManager.callFunc("getActiveScene")
    if LCase(group.subtype()) = "home"
        if LCase(meta.type) = "episode"
            resumeData.push(tr("Go to series"))
            resumeData.push(tr("Go to season"))
            resumeData.push(tr("Go to episode"))
        end if
    end if
    stopLoadingSpinner()
    m.global.sceneManager.callFunc("optionDialog", "playback", tr("Playback Options"), [], resumeData, {
        id: ""
    })
end sub
'//# sourceMappingURL=./ShowScenes.brs.map