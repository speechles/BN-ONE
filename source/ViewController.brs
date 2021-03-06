'*
'* A controller for managing the stack of screens that have been displayed.
'* By centralizing this we can better support things like destroying and
'* recreating views and breadcrumbs. It also provides a single place that
'* can take an item and figure out which type of screen should be shown
'* so that logic doesn't have to be in each individual screen type.
'*

Function createViewController() As Object
	controller = CreateObject("roAssociativeArray")

	controller.breadcrumbs = CreateObject("roArray", 10, true)
	controller.screens = CreateObject("roArray", 10, true)

	controller.GlobalMessagePort = CreateObject("roMessagePort")
    
	controller.CreateHomeScreen = vcCreateHomeScreen
	controller.CreateScreenForItem = vcCreateScreenForItem
	controller.ShowInitialScreen = vcShowInitialScreen
	controller.CreateTextInputScreen = vcCreateTextInputScreen
	controller.CreateEnumInputScreen = vcCreateEnumInputScreen
	controller.CreateContextMenu = vcCreateContextMenu
    
	controller.CreatePhotoPlayer = vcCreatePhotoPlayer
	controller.CreateVideoPlayer = vcCreateVideoPlayer
	controller.CreatePlayerForItem = vcCreatePlayerForItem
	controller.IsVideoPlaying = vcIsVideoPlaying

 	theme = FirstOf(RegRead("prefTheme"), "1").ToInt()
	if theme = 1 then
		controller.getDefaultTheme = vcGetDefaultTheme
	else
		controller.getDefaultTheme = vcGetStockTheme
	end if

	controller.loadUserTheme = vcLoadUserTheme

	controller.onSignedIn = vcOnSignedIn
	controller.logout = vcLogout
	
	' An object containing information about the current custom theme (if any)
	controller.themeMetadata = invalid
	
	controller.getThemeImageUrl = vcGetThemeImageUrl
	
	controller.getPort = vcGetPort

	controller.InitializeOtherScreen = vcInitializeOtherScreen
	controller.AssignScreenID = vcAssignScreenID
	controller.PushScreen = vcPushScreen
	controller.PopScreen = vcPopScreen
	controller.IsActiveScreen = vcIsActiveScreen

	controller.afterCloseCallback = invalid
	controller.CloseScreenWithCallback = vcCloseScreenWithCallback
	controller.CloseScreen = vcCloseScreen

	controller.Show = vcShow
	controller.UpdateScreenProperties = vcUpdateScreenProperties
	controller.AddBreadcrumbs = vcAddBreadcrumbs

	controller.DestroyGlitchyScreens = vcDestroyGlitchyScreens
	
	' Even with the splash screen, we still need a facade for memory purposes
	' and a clean exit.
	controller.facade = CreateObject("roGridScreen")
	controller.facade.Show()

	controller.nextScreenId = 1
	controller.nextTimerId = 1

	controller.PendingRequests = {}
	controller.RequestsByScreen = {}
	controller.StartRequest = vcStartRequest
	controller.StartRequestIgnoringResponse = vcStartRequestIgnoringResponse
	controller.CancelRequests = vcCancelRequests

	controller.SocketListeners = {}
	controller.AddSocketListener = vcAddSocketListener

	controller.Timers = {}
	controller.TimersByScreen = {}
	controller.AddTimer = vcAddTimer

	controller.SystemLog = CreateObject("roSystemLog")
	controller.SystemLog.SetMessagePort(controller.GlobalMessagePort)
	controller.SystemLog.EnableType("bandwidth.minute")

	controller.backButtonTimer = createTimer()
	controller.backButtonTimer.SetDuration(60000, true)

	' Stuff the controller into the global object
	m.ViewController = controller

	' Initialize things that run in the background
	'AppManager().AddInitializer("viewcontroller")
	InitWebServer(controller)
	AudioPlayer()
	return controller
End Function

Sub vcAddSocketListener(socket, listener)
	m.SocketListeners[socket.GetID().tostr()] = listener
End Sub

Function GetViewController()
	return m.ViewController
End Function

Sub doInitialConnection()
	result = ConnectionManager().connectInitial()
	Debug ("connectInitial returned State of " + firstOf(result.State, ""))
	Debug ("connectInitial returned ConnectionMode of " + firstOf(result.ConnectionMode, ""))
	navigateFromConnectionResult(result)
	
End Sub

Sub navigateFromConnectionResult(result)
	Debug ("Processing ConnectionResult State of " + result.State)
	if result.State = "ServerSignIn" then
		server = result.Servers[0]
		Debug ("ServerSignIn Id: " + firstOf(server.Id, ""))
		Debug ("ServerSignIn Name: " + firstOf(server.Name, ""))
		Debug ("ServerSignIn LocalAddress: " + firstOf(server.LocalAddress, ""))
		Debug ("ServerSignIn RemoteAddress: " + firstOf(server.RemoteAddress, ""))
		Debug ("ServerSignIn ManualAddress: " + firstOf(server.ManualAddress, ""))
		serverUrl = firstOf(server.LocalAddress, "")
		if result.ConnectionMode = "Remote" then
			serverUrl = firstOf(server.RemoteAddress, "")
		else if result.ConnectionMode = "Manual" then
			serverUrl = firstOf(server.ManualAddress, "")
		end if
		showLoginScreen(GetViewController(), serverUrl)
	else if result.State = "ServerSelection" then
		showServerListScreen(GetViewController())
	else if result.State = "SignedIn" then
		server = result.Servers[0]
		Debug ("SignedIn Id: " + firstOf(server.Id, ""))
		Debug ("SignedIn UserId: " + firstOf(server.UserId, ""))
		Debug ("SignedIn AccessToken: " + firstOf(server.AccessToken, ""))
		Debug ("SignedIn Name: " + firstOf(server.Name, ""))
		Debug ("SignedIn LocalAddress: " + firstOf(server.LocalAddress, ""))
		Debug ("SignedIn RemoteAddress: " + firstOf(server.RemoteAddress, ""))
		Debug ("ServerSignIn ManualAddress: " + firstOf(server.ManualAddress, ""))
		serverUrl = firstOf(server.LocalAddress, "")
		if result.ConnectionMode = "Remote" then
			serverUrl = firstOf(server.RemoteAddress, "")
		else if result.ConnectionMode = "Manual" then
			serverUrl = firstOf(server.ManualAddress, "")
		end if
		GetViewController().onSignedIn(server.Id, serverUrl, server.UserId)
	else if result.State = "ConnectSignIn" then
	
		signInContext = {
			ContentType: "ConnectSignIn"
		}
        GetViewController().createScreenForItem(signInContext, 0, ["Connect"], true)
	end if
End Sub

Sub vcShowInitialScreen()
	wizardKey = "wizardcomplete"
	wizardValue = "4"
	if firstOf(RegRead(wizardKey), "0") <> wizardValue then
	
		item = {
			ContentType: "Welcome"
		}
		screen = m.createScreenForItem([item], 0, ["Welcome"])
	
		RegWrite(wizardKey, wizardValue)
	else
		doInitialConnection()
	end if
End Sub

Sub showLoginScreen(viewController as Object, serverUrl as String)
	screen = CreateLoginScreen(viewController, serverUrl, 0)
	screen.ScreenName = "Login"
	viewController.InitializeOtherScreen(screen, ["Please Sign In"])
	screen.Screen.SetBreadcrumbEnabled(true)
	screen.Show()
End Sub

Sub vcOnSignedIn(serverId, serverUrl, localUserId)

	if firstOf(serverId, "") = "" then
		Debug("Empty serverId passed into OnSignedIn!")
		return
	end if

	if firstOf(serverUrl, "") = "" then
		Debug("Empty serverUrl passed into OnSignedIn!")
		return
	end if

	if firstOf(localUserId, "") = "" then
		Debug("Empty localUserId passed into OnSignedIn!")
		return
	end if

	RegWrite("currentServerId", serverId)

	if firstOf(RegRead("currentServerId"), "") <> serverId then
		Debug("currentServerId doesnt match RegRead result!")
		return
	end if

	m.serverUrl = serverUrl
	postCapabilities()
	userProfile = getUserProfile(localUserId)
	' If unable to get user profile, delete saved user and redirect to login
	if userProfile = invalid
		m.Logout()
		return
	end if
	GetGlobalAA().AddReplace("user", userProfile)	
	if firstOf(RegRead("prefRememberUser"), "yes") <> "yes" and ConnectionManager().isLoggedIntoConnect() = false
		' do not remember user
		ConnectionManager().DeleteServerData(serverId, "UserId")
	else
		' remember user, announce connected dialog
		if userprofile <> invalid then
			username = userprofile.Title
			if userprofile.IsAdmin then username = username + " *ADMIN*"
   			 loadingDialog = CreateObject("roOneLineDialog")
    			loadingDialog.SetTitle("Welcome Back, " + username + "!")
    			loadingDialog.ShowBusyAnimation()
    			loadingDialog.Show()
		end if
	end if
	while m.screens.Count() > 0
		m.PopScreen(m.screens[m.screens.Count() - 1])
	end while
	m.Home = m.CreateHomeScreen()
	if firstOf(RegRead("prefRememberUser"), "yes") = "yes" then loadingDialog.Close()
	peepsnames = GetAlsoWatchingNames()
	if peepsnames <> ""
		if keepAlsoWatching(peepsnames) = "0"
		loadingDialog = CreateObject("roOneLineDialog")
		loadingDialog.SetTitle("Removing Also Watching users...")
		loadingDialog.ShowBusyAnimation()
		loadingDialog.Show()
			sessionId = GetSessionId()
			if sessionId <> invalid
				r = CreateObject("roRegex", ",", "")
				debug("Sessions Also Watching users: "+peepsnames)
				peepsid = GetAlsoWatching()
				for each id in r.split(peepsid)
					result = postAlsoWatchingStatus(id, false, sessionId)
				end for
			end if
		loadingDialog.close()
		m.home.refreshBreadcrumb()
		end if
	end if
End Sub

Function keepAlsoWatching(peepsnames)
	return showContextViewMenuYesNoDialog("Also Watching", "There are users marked as also watching this session. Are the users below still watching too?"+chr(10)+chr(10)+peepsnames+chr(10))
end Function

Sub vcLogout()
	Debug("Logout")
	ConnectionManager().logout()
	'RegDelete("UserId")
	RegDelete("currentServerId")
	' For now, until there's a chance to break the initial screen workflow into separate pieces
	m.ShowInitialScreen()
End Sub

Function vcCreateHomeScreen()
	screen = createHomeScreen(m)
	screen.ScreenName = "Home"
	m.InitializeOtherScreen(screen, invalid)
	screen.Screen.SetBreadcrumbEnabled(true)
	screen.refreshBreadcrumb()
	screen.Show()
	return screen
End Function

Function vcGetDefaultTheme() as Object

	color1 = firstOf(RegRead("theme_color1"), "#33CCFF")
	color2 = firstOf(RegRead("theme_color2"), "#75FF75")
	color3 = firstOf(RegRead("theme_color3"), "#FFFFFF")
	color4 = firstOf(RegRead("theme_color4"), "#FFFFFF")
	border = firstOf(RegRead("theme_border"), "1")

	theme = {

        '*** HD Styles ****
        OverhangSliceHD: "pkg:/images/themes/default/hd-header-slice.png"
        OverhangLogoHD: "pkg:/images/themes/default/hd-logo.png"
        OverhangOffsetHD_X: "80"
        OverhangOffsetHD_Y: "30"

        FilterBannerSliceHD: "pkg:/images/themes/default/hd-filter-banner.png"
        FilterBannerActiveHD: "pkg:/images/themes/default/hd-filter-active.png"
        FilterBannerInactiveHD: "pkg:/images/themes/default/hd-filter-inactive.png"

        GridScreenLogoHD: "pkg:/images/themes/default/hd-logo.png"
        GridScreenOverhangSliceHD: "pkg:/images/themes/default/hd-header-slice.png"
        GridScreenLogoOffsetHD_X: "80"
        GridScreenLogoOffsetHD_Y: "30"
        GridScreenOverhangHeightHD: "120"


        '*** SD Styles ****

        OverhangSliceSD: "pkg:/images/themes/default/hd-header-slice.png"
        OverhangLogoSD: "pkg:/images/themes/default/sd-logo.png"
        OverhangOffsetSD_X: "20"
        OverhangOffsetSD_Y: "20"

        FilterBannerSliceSD: "pkg:/images/themes/default/sd-filter-banner.png"
        FilterBannerActiveSD: "pkg:/images/themes/default/sd-filter-active.png"
        FilterBannerInactiveSD: "pkg:/images/themes/default/sd-filter-inactive.png"

        GridScreenLogoSD: "pkg:/images/themes/default/sd-logo.png"
        GridScreenOverhangSliceSD: "pkg:/images/themes/default/hd-header-slice.png"
        GridScreenLogoOffsetSD_X: "20"
        GridScreenLogoOffsetSD_Y: "20"
        GridScreenOverhangHeightSD: "83"
		
	DialogTitleText: color4
	DialogBodyText: color3

        '*** Common Styles ****

        BackgroundColor: "#000000"

        BreadcrumbTextLeft: color2
        BreadcrumbTextRight: color1
        BreadcrumbDelimiter: "#ffffff"

	ButtonMenuNormalText: "#333333"
	ButtonNormalColor: "#333333"

        ParagraphHeaderText: color1
        ParagraphBodyText: color4

        PosterScreenLine1Text: color2
        PosterScreenLine2Text: color1
        EpisodeSynopsisText: color3

        ListItemText: color1
        ListItemHighlightText: color2
        ListScreenDescriptionText: color2
        ListScreenTitleColor: color3
        ListScreenHeaderText: color4

	SearchHeaderText: color4

        CounterTextLeft: color2
        CounterTextRight: color1
        CounterSeparator: "#ffffff"

	ButtonHighlightColor: color1
	ButtonMenuHighlightText: color2
	ButtonMenuNormalText: color1
	ButtonNormalColor: color2

        TextScreenBodyBackgroundColor: "#000000"
	TextScreenBodyText: color3
	TextScreenScrollThumbColor: color1
	TextScreenScrollBarColor: color2

        FilterBannerActiveColor: color2
        FilterBannerInactiveColor: color1
        FilterBannerSideColor: "#808080"

        GridScreenBackgroundColor: "#000000"
	GridScreenMessageColor: color3
        GridScreenListNameColor: "#ffffff"
	GridScreenRetrievingColor: "#ffffff"
        GridScreenDescriptionTitleColor: "#000000"
        'GridScreenDescriptionDateColor: "#ffffff"
        GridScreenDescriptionSynopsisColor: "#000000"
        'GridScreenDescriptionRuntimeColor: "#ffffff"

        SpringboardActorColor: color1

        SpringboardAlbumColor: color2
        'SpringboardAlbumLabel: "#ffffff"
        SpringboardAlbumLabelColor: color1

        SpringboardAllow6Buttons: "true"

        SpringboardArtistColor: color2
        'SpringboardArtistLabel: "#ffffff"
        SpringboardArtistLabelColor: color1

        SpringboardDirectorColor: color1
        SpringboardDirectorLabelColor: color2
        'SpringboardDirectorPrefixText: "#ffffff"

        SpringboardGenreColor: color4
        SpringboardRuntimeColor: color1
        SpringboardSynopsisColor: color3
        SpringboardTitleText: color4

	ThemeType: "generic-dark"
	}
	' add custom border if selected
	if border = "1" then
		theme.AddReplace("GridScreenFocusBorderHD", "pkg:/images/themes/default/hd-border-flat-landscape.png")
		theme.AddReplace("GridScreenBorderOffsetHD", "(-34,-19)")
	else
		theme.AddReplace("GridScreenFocusBorderHD", "")
		theme.AddReplace("GridScreenBorderOffsetHD", "")
	end if

	return theme
	
End Function

Function vcGetStockTheme() as Object
	border = firstOf(RegRead("theme_border"), "1")

	theme = {

        '*** HD Styles ****
        OverhangSliceHD: "pkg:/images/themes/stock/hd-header-slice.png"
        OverhangLogoHD: "pkg:/images/themes/stock/hd-logo.png"
        OverhangOffsetHD_X: "80"
        OverhangOffsetHD_Y: "30"

        FilterBannerSliceHD: "pkg:/images/themes/stock/hd-filter-banner.png"
        FilterBannerActiveHD: "pkg:/images/themes/stock/hd-filter-active.png"
        FilterBannerInactiveHD: "pkg:/images/themes/stock/hd-filter-inactive.png"

        GridScreenLogoHD: "pkg:/images/themes/stock/hd-logo.png"
        GridScreenOverhangSliceHD: "pkg:/images/themes/stock/hd-header-slice.png"
        GridScreenLogoOffsetHD_X: "80"
        GridScreenLogoOffsetHD_Y: "30"
        GridScreenOverhangHeightHD: "120"
        'GridScreenFocusBorderHD: "pkg:/images/themes/stock/hd-border-flat-landscape.png"
        'GridScreenBorderOffsetHD: "(-34,-19)"

        '*** SD Styles ****

        OverhangSliceSD: "pkg:/images/themes/stock/hd-header-slice.png"
        OverhangLogoSD: "pkg:/images/themes/stock/sd-logo.png"
        OverhangOffsetSD_X: "20"
        OverhangOffsetSD_Y: "20"

        FilterBannerSliceSD: "pkg:/images/themes/stock/sd-filter-banner.png"
        FilterBannerActiveSD: "pkg:/images/themes/stock/sd-filter-active.png"
        FilterBannerInactiveSD: "pkg:/images/themes/stock/sd-filter-inactive.png"

        GridScreenLogoSD: "pkg:/images/themes/stock/sd-logo.png"
        GridScreenOverhangSliceSD: "pkg:/images/themes/stock/hd-header-slice.png"
        GridScreenLogoOffsetSD_X: "20"
        GridScreenLogoOffsetSD_Y: "20"
        GridScreenOverhangHeightSD: "83"
		
	DialogTitleText: "#000000"
	DialogBodyText: "#333333"

        '*** Common Styles ****

        BackgroundColor: "#181818"

        BreadcrumbTextLeft: "#dfdfdf"
        BreadcrumbTextRight: "#eeeeee"
        BreadcrumbDelimiter: "#eeeeee"

	ButtonMenuNormalText: "#333333"
	ButtonNormalColor: "#333333"

        TextScreenBodyBackgroundColor: "#000000"
	TextScreenBodyText: "#ffffff"
	TextScreenScrollThumbColor: "#ffffff"
	TextScreenScrollBarColor: "#bbbbbb"

        ParagraphHeaderText: "#ffffff"
        ParagraphBodyText: "#dfdfdf"

        PosterScreenLine1Text: "#ffffff"
        PosterScreenLine2Text: "#bbbbbb"
        EpisodeSynopsisText: "#dfdfdf"

        'ListItemText: "#dfdfdf"
        'ListItemHighlightText: "#ffffff"
        'ListScreenDescriptionText: "#9a9a9a"
        ListScreenTitleColor: "#ffffff"
        ListScreenHeaderText: "#ffffff"

        CounterTextLeft: "#ffffff"
        CounterTextRight: "#ffffff"
        CounterSeparator: "#ffffff"

        FilterBannerActiveColor: "#ffffff"
        FilterBannerInactiveColor: "#cccccc"
        FilterBannerSideColor: "#cccccc"

        GridScreenBackgroundColor: "#181818"
        'GridScreenListNameColor: "#ffffff"
        'GridScreenDescriptionTitleColor: "#ffffff"
        'GridScreenDescriptionDateColor: "#ffffff"
        'GridScreenDescriptionSynopsisColor: "#ffffff"
        'GridScreenDescriptionRuntimeColor: "#ffffff"

        SpringboardActorColor: "#9a9a9a"

        SpringboardAlbumColor: "#ffffff"
        SpringboardAlbumLabel: "#ffffff"
        SpringboardAlbumLabelColor: "#ffffff"

        SpringboardAllow6Buttons: "true"

        SpringboardArtistColor: "#ffffff"
        'SpringboardArtistLabel: "#ffffff"
        SpringboardArtistLabelColor: "#ffffff"

        SpringboardDirectorColor: "#ffffff"
        SpringboardDirectorLabelColor: "#181818"
        'SpringboardDirectorPrefixText: "#ffffff"

        SpringboardGenreColor: "#ffffff"
        SpringboardRuntimeColor: "#ffffff"
        SpringboardSynopsisColor: "#dfdfdf"
        SpringboardTitleText: "#ffffff"

        ThemeType: "generic-dark"
	}
	if border = "1" then
		theme.AddReplace("GridScreenFocusBorderHD", "pkg:/images/themes/stock/hd-border-flat-landscape.png")
		theme.AddReplace("GridScreenBorderOffsetHD", "(-34,-19)")
	else
		theme.AddReplace("GridScreenFocusBorderHD", "")
		theme.AddReplace("GridScreenBorderOffsetHD", "")
	end if

	return theme
	
End Function

Function vcGetThemeImageUrl(name as String) as String

	url = invalid
	
	if m.themeMetadata <> invalid then
		url = getImageUrlFromThemeMetadata(m.themeMetadata)
	end if
	
	if url = invalid then
		url = vcGetDefaultThemeImageUrl(name)
	end if
	
	return url

End Function

Function getImageUrlFromThemeMetadata(themeMetadata as Object) as String

	' TODO: loop through the images of the custom theme, and if found, build the full url and return it
	url = invalid
	
	return url

End Function

Function vcGetDefaultThemeImageUrl(name as String) as String

	theme = FirstOf(RegRead("prefTheme"), "1").ToInt()
	if theme = 1 then
		url = "pkg:/images/themes/default/" + name
	else
		url = "pkg:/images/themes/stock/" + name
	end if
	return url

End Function

Sub vcLoadUserTheme()

	themeMetadata = getCustomTheme()
	m.themeMetadata = themeMetadata
	
	theme = m.getDefaultTheme()
	
	if themeMetadata <> invalid then
	
		' Override theme properties with values from themeMetadata
		if themeMetadata.Options <> invalid then
			for each key in themeMetadata.Options
				theme.AddReplace(key, themeMetadata.Options[key])
			end for
		end If
		
	end if
	
	' Set background Color
	GetGlobalAA().AddReplace("backgroundColor", theme.BackgroundColor)

	app = CreateObject("roAppManager")
	app.SetTheme( theme )
	
End Sub

Function getCustomTheme() as Object

	' TODO: Figure out current user id
	' TODO: Get saved theme id based on current user id
	' TODO: Download theme metadata from server based on theme id
	' Return invalid if none, or if anything fails
	theme = invalid
	
	return theme
	
End Function

Sub vcShow()

	m.loadUserTheme()
	
	ConnectionManager().setAppInfo("Roku BN", getGlobalVar("channelVersion", "Unknown"))
	
	m.ShowInitialScreen()

    timeout = 0
    while m.screens.Count() > 0
        m.WebServer.prewait()
        msg = wait(timeout, m.GlobalMessagePort)
        if msg <> invalid then
            ' Printing debug information about every message may be overkill
            ' regardless, but note that URL events don't play by the same rules,
            ' and there's no ifEvent interface to check for. Sigh.
            'if GetInterface(msg, "ifUrlEvent") = invalid AND GetInterface(msg, "ifSocketEvent") = invalid then
                'Debug("Processing " + type(msg) + " (top of stack " + type(m.screens.Peek().Screen) + "): " + tostr(msg.GetType()) + ", " + tostr(msg.GetIndex()) + ", " + tostr(msg.GetMessage()))
            'end if

            for i = m.screens.Count() - 1 to 0 step -1
                if m.screens[i].HandleMessage(msg) then exit for
            end for

            ' Process URL events. Look up the request context and call a
            ' function on the listener.
            if type(msg) = "roUrlEvent" AND msg.GetInt() = 1 then
                id = msg.GetSourceIdentity().tostr()
                requestContext = m.PendingRequests[id]
                if requestContext <> invalid then
                    m.PendingRequests.Delete(id)
                    if requestContext.Listener <> invalid then
                        requestContext.Listener.OnUrlEvent(msg, requestContext)
                    end if
                    requestContext = invalid
                end if
            else if type(msg) = "roSocketEvent" then
                listener = m.SocketListeners[msg.getSocketID().tostr()]
                if listener <> invalid then
                    listener.OnSocketEvent(msg)
                    listener = invalid
                else
                    ' Assume it was for the web server (it won't hurt if it wasn't)
                    m.WebServer.postwait()
                end if
            else if type(msg) = "roAudioPlayerEvent" then
                AudioPlayer().HandleMessage(msg)
            else if type(msg) = "roSystemLogEvent" then
                msgInfo = msg.GetInfo()
                if msgInfo.LogType = "bandwidth.minute" then
                    GetGlobalAA().AddReplace("bandwidth", msgInfo.Bandwidth)
                end if
            else if msg.isRemoteKeyPressed() and msg.GetIndex() = 10 then
                m.CreateContextMenu()
            end if
        end if

        ' Check for any expired timers
        timeout = 0
        for each timerID in m.Timers
            timer = m.Timers[timerID]
            if timer.IsExpired() then
                timer.Listener.OnTimerExpired(timer)
            end if

            ' Make sure we set a timeout on the wait so we'll catch the next timer
            remaining = timer.RemainingMillis()
            if remaining > 0 AND (timeout = 0 OR remaining < timeout) then
                timeout = remaining
            end if
        next
    end while

    closeChannel = true

    ' Exit confirmation?
    if FirstOf(RegRead("prefExit"),"1") = "1" then
	username = ""
	user = getGlobalVar("user")
	if user <> invalid then
		username = user.Title
		if user.IsAdmin then username = username + " *ADMIN*"
	end if
    	port = CreateObject("roMessagePort")
    	dialog = CreateObject("roMessageDialog")
    	dialog.SetMessagePort(port) 
    	dialog.SetTitle("GoodBye, " + username + "?")
	dialog.SetText( +"Are you sure you want to exit the emby app completely?")

    	dialog.AddButton(1, "Yes")
    	dialog.AddButton(2, "No")
    	dialog.EnableBackButton(false)
    	dialog.Show()

    	closeChannel = false

    	' for now this will be a blocking request. The control has been stopped, so the 
    	' channel is not listening anymore more onHandle events. 
    	' pretty basic while loop - button index 2 will cancel the close/exit
    	while True
        	dlgMsg = wait(0, dialog.GetMessagePort())
        	if type(dlgMsg) = "roMessageDialogEvent"
            		if dlgMsg.isButtonPressed()
                		if dlgMsg.GetIndex() = 1
                    			closeChannel = true
                		end if
                		exit while
            		else if dlgMsg.isScreenClosed()
                		exit while
            		end if
		end if
    	end while 
    	dialog.Close()

     end if

    ' user chose not to exit, we need to set the profileExit invalid, recreate the 
    ' homescreen, refresh the homescreen and start control again
    if NOT closeChannel then 
       m.Home = m.CreateHomeScreen()
       m.Home.loader.refreshdata()
       m.Show()
    else

    	dialog = CreateObject("roMessageDialog")
    	dialog.SetTitle("GoodBye " + username + "!")
	dialog.SetText("                Emby will be here waiting for you to return."+chr(10)+"                        ^_^   Thanks for using Emby!   ^_^" + chr(10) + "                I always knew you were super cool like that." + chr(10) + chr(10) + "                                        Special Thanks:" + chr(10) + "          @shaefurr for his help cleaning up the graphics!!!" + chr(10) + "         @waldonnis for his help with audio and subtitles!!!" + chr(10) + "       @Grace1313 you are such a little suck up cheerleader!!" + chr(10) + "          @CBers and @Happy2Play for their endless help!!!")
    	dialog.Show()
	sleep(3500)
	dialog.Close()

    	' Clean up some references on the way out
    	AudioPlayer().Cleanup()
    	m.Home = invalid
    	m.WebServer = invalid
    	m.Timers.Clear()
    	m.PendingRequests.Clear()
    	m.SocketListeners.Clear()

    	Debug("Finished global message loop")
    end if
End Sub

Function vcGetPort()
	return m.GlobalMessagePort
End Function

Sub InitWebServer(vc)

    ' Initialize some globals for the web server
    globals = CreateObject("roAssociativeArray")
    globals.pkgname = "Emby"
    globals.maxRequestLength = 4000
    globals.idletime = 60
    globals.wwwroot = "tmp:/"
    globals.index_name = "index.html"
    globals.serverName = "Emby"
    AddGlobals(globals)
    MimeType()
    HttpTitle()
    
	ClassReply().AddHandler("/emby/message/MoveUp", ProcessNavigationMoveUp)
	ClassReply().AddHandler("/emby/message/MoveRight", ProcessNavigationMoveRight)
	ClassReply().AddHandler("/emby/message/MoveLeft", ProcessNavigationMoveLeft)
	ClassReply().AddHandler("/emby/message/MoveDown", ProcessNavigationMoveDown)
	ClassReply().AddHandler("/emby/message/Select", ProcessNavigationSelect)
	ClassReply().AddHandler("/emby/message/GoHome", ProcessNavigationHome)
	ClassReply().AddHandler("/emby/message/Back", ProcessNavigationBack)
	ClassReply().AddHandler("/emby/message/GoToSettings", ProcessNavigationSettings)
	ClassReply().AddHandler("/emby/message/GoToSearch", ProcessNavigationSearch)
	ClassReply().AddHandler("/emby/message/SendString", ProcessApplicationSetText)
	ClassReply().AddHandler("/emby/message/DisplayMessage", ProcessApplicationDisplayText)
	ClassReply().AddHandler("/emby/message/ShowNowPlaying", ProcessApplicationSetText)
	ClassReply().AddHandler("/emby/message/Ping", ProcessPingRequest)
	ClassReply().AddHandler("/emby/message/ServerRestarting", ProcessPingRequest)
	ClassReply().AddHandler("/emby/message/ServerShuttingDown", ProcessPingRequest)
	ClassReply().AddHandler("/emby/message/RestartRequired", ProcessPingRequest)
	ClassReply().AddHandler("/emby/message/Stop", ProcessPlaybackStop)
	ClassReply().AddHandler("/emby/message/Pause", ProcessPlaybackPause)
	ClassReply().AddHandler("/emby/message/PlayPause", ProcessPlaybackPlayPause)
	ClassReply().AddHandler("/emby/message/Unpause", ProcessPlaybackPlay)
	ClassReply().AddHandler("/emby/message/NextTrack", ProcessPlaybackSkipNext)
	ClassReply().AddHandler("/emby/message/PreviousTrack", ProcessPlaybackSkipPrevious)
	ClassReply().AddHandler("/emby/message/Seek", ProcessPlaybackSeekTo)
	ClassReply().AddHandler("/emby/message/Rewind", ProcessPlaybackStepBack)
	ClassReply().AddHandler("/emby/message/FastForward", ProcessPlaybackStepForward)
	ClassReply().AddHandler("/emby/message/DisplayContent", ProcessDisplayContent)

	ClassReply().AddHandler("/emby/message/PlayNow", ProcessPlaybackPlayMedia)
	ClassReply().AddHandler("/emby/message/PlayNext", ProcessPingRequest)
	ClassReply().AddHandler("/emby/message/PlayLast", ProcessPingRequest)
	
	ClassReply().AddHandler("/emby/message/SetAudioStreamIndex", ProcessSetAudioStreamIndexRequest)
	ClassReply().AddHandler("/emby/message/SetSubtitleStreamIndex", ProcessSetSubtitleStreamIndexRequest)

    vc.WebServer = InitServer({msgPort: vc.GlobalMessagePort, port: 8324})
End Sub

Function ProcessPingRequest() As Boolean
   	
	m.simpleOK("")
	return true

End Function

Function ProcessSetAudioStreamIndexRequest() As Boolean
   	
	player = VideoPlayer()

	if player <> invalid then
	
		index = m.request.query["Index"]
		
		if index <> invalid and index <> "" then
			player.SetAudioStreamIndex(index.ToInt())
		end if
        
	end If

	m.simpleOK("")
	return true

End Function

Function ProcessSetSubtitleStreamIndexRequest() As Boolean
   	
	player = VideoPlayer()

	if player <> invalid then
	
		index = m.request.query["Index"]
		
		if index <> invalid and index <> "" then
			player.SetSubtitleStreamIndex(index.ToInt())
		end if
        
	end If

	m.simpleOK("")
	return true

End Function

Function ProcessDisplayContent() As Boolean
	
	itemId = m.request.query["ItemId"]
	
	item = getVideoMetadata(itemId)
	
	GetViewController().CreateScreenForItem([item], 0, [item.Title], true)
	
	m.simpleOK("")
	return true

End Function

Function ProcessDisplayMessage() As Boolean
	
	m.simpleOK("")
	return true

End Function

Function ProcessNavigationSettings() As Boolean
   	
	item = {
		Title: "Preferences"
		ContentType: "Preferences"
	}
	
	GetViewController().CreateScreenForItem([item], 0, [item.Title], true)
	
	m.simpleOK("")
	return true

End Function

Function ProcessNavigationSearch() As Boolean
   	
	item = {
		Title: "Search"
		ContentType: "Search"
	}
	
	GetViewController().CreateScreenForItem([item], 0, [item.Title], true)
	
	m.simpleOK("")
	return true

End Function

Function ConvertTicksParamToMs(ticks = invalid) as Integer

	Debug ("Parsing seek param: " + tostr(ticks))
	
	ticks = firstOf(ticks, "0")
	
	' 1 second = 1000 ms = 10000 ticks
	while ticks.Len() < 4
		ticks = ticks + "0"
	end while
	
	ms = ticks.Left(ticks.Len() - 4)
	
	return ms.ToInt()
	
End function

Function ProcessPlaybackPlayMedia() As Boolean

	ids = m.request.query["ItemIds"].tokenize(",")
	
	startPosition = ConvertTicksParamToMs(m.request.query["StartPositionTicks"])

	context = []
	index = 0
	
	for each i in ids
	
		if index = 0 then
		
			item = getVideoMetadata(ids[index])
			context.push(item)
			
		else
			item = {
				Id: ids[index]
			}
			
			context.push(item)
			
		end if
		
		index = index + 1
	end for
	
	startPosition = startPosition / 1000
	
	playOptions = {
		PlayStart: startPosition
	}
	
	Debug("Passing PlayStart to VideoPlayer: " + tostr(playOptions.PlayStart))
	
    GetViewController().CreatePlayerForItem(context, 0, playOptions, true)

    m.simpleOK("")
    return true

End Function

Function ProcessPlaybackSeekTo() As Boolean

    offset = ConvertTicksParamToMs(m.request.query["SeekPositionTicks"])

    if AudioPlayer().IsPlaying then
        AudioPlayer().Seek(offset)
    else

		player = VideoPlayer()

		if player <> invalid then
            player.Seek(offset)
		else 
			
		end If
    end if

    m.simpleOK("")
    return true
End Function

Function ProcessPlaybackSkipNext() As Boolean

    ' Try to deal with the command directly, falling back to ECP.
    if AudioPlayer().IsPlaying then
        AudioPlayer().Next()
    else

		player = VideoPlayer()

		if player <> invalid then
			player.Next()
		else 
			player = PhotoPlayer()
			if player <> invalid then 
				player.Next()
			else
				SendEcpCommand("Fwd")
			end if
		end If
    end if

    m.simpleOK("")
    return true
End Function

Function ProcessPlaybackSkipPrevious() As Boolean

    ' Try to deal with the command directly, falling back to ECP.
    if AudioPlayer().IsPlaying then
        AudioPlayer().Prev()
    else

		player = VideoPlayer()

		if player <> invalid then
			player.Prev()
		else 
			player = PhotoPlayer()
			if player <> invalid then 
				player.Prev()
			else
				SendEcpCommand("Rev")
			end if
		end If
    end if

    m.simpleOK("")
    return true
End Function

Function ProcessPlaybackStepBack() As Boolean

    ' Try to deal with the command directly, falling back to ECP.
    if AudioPlayer().IsPlaying then
        AudioPlayer().Seek(-15000, true)
    else

		player = VideoPlayer()

		if player <> invalid then
			SendEcpCommand("InstantReplay")
		else 
			
		end If
    end if

    m.simpleOK("")
    return true
End Function

Function ProcessPlaybackStepForward() As Boolean

    player = invalid
    
	' Try to deal with the command directly, falling back to ECP.
    if AudioPlayer().IsPlaying then
        player = AudioPlayer()
    else
		player = VideoPlayer()
    end if

    if player <> invalid then
        player.Seek(15000, true)
    end if

    m.simpleOK("")
    return true
End Function

Function ProcessPlaybackPause() As Boolean

    ' Try to deal with the command directly, falling back to ECP.
    if AudioPlayer().IsPlaying then
        AudioPlayer().Pause()
    else

		player = VideoPlayer()

		if player <> invalid then
			player.Pause()
		else 
			player = PhotoPlayer()
			if player <> invalid then player.Pause()

		end If
    end if

    m.simpleOK("")
    return true
End Function

Function ProcessPlaybackPlayPause() As Boolean

	if AudioPlayer().IsPlaying then
		AudioPlayer().Pause()
	else if AudioPlayer().IsPaused then
		AudioPlayer().Resume()
	else
		player = VideoPlayer()
		if player <> invalid
			if player.playState = "paused"
				player.resume()
			else
				player.Pause()
			end if
		else
			player = PhotoPlayer()
			if player <> invalid
				if player.isPaused
					player.Play()
				else
					player.Pause()
				end if
			end if
		end if
	end if

	m.simpleOK("")
	return true

End Function

Function ProcessPlaybackPlay() As Boolean

    ' Try to deal with the command directly, falling back to ECP.
    if AudioPlayer().IsPlaying then
        AudioPlayer().Resume()
    else

		player = VideoPlayer()

		if player <> invalid then
			player.Resume()
		else 
			player = PhotoPlayer()
			if player <> invalid then 
				player.Resume()
			else
				SendEcpCommand("Play")
			end if
		end If
    end if

    m.simpleOK("")
    return true
End Function

Function ProcessPlaybackStop() As Boolean

    ' Try to deal with the command directly, falling back to ECP.
    if AudioPlayer().IsPlaying then
        AudioPlayer().Stop()
    else

		player = VideoPlayer()

		if player <> invalid then
			player.Stop()
		else 
			player = PhotoPlayer()
			if player <> invalid then player.Stop()

		end If
    end if

    m.simpleOK("")
    return true

End Function

Function ProcessNavigationMoveRight() As Boolean

    SendEcpCommand("Right")
	
	m.simpleOK("")
	return true

End Function

Function ProcessNavigationMoveLeft() As Boolean

    SendEcpCommand("Left")
	
	m.simpleOK("")
	return true

End Function

Function ProcessNavigationMoveDown() As Boolean

    SendEcpCommand("Down")
	
	m.simpleOK("")
	return true

End Function

Function ProcessNavigationMoveUp() As Boolean

    SendEcpCommand("Up")
	
	m.simpleOK("")
	return true

End Function

Sub ProcessNavigationSelect() As Boolean

    SendEcpCommand("Select")
	
	m.simpleOK("")
	return true
	
End Sub

Sub ProcessNavigationHome() As Boolean

    context = CreateObject("roAssociativeArray")
    context.OnAfterClose = CloseScreenUntilHomeVisible
    context.OnAfterClose()

    m.simpleOK("")
	return true
	
End Sub

Sub ProcessNavigationBack() As Boolean

    ' Sending an ECP back can potentially exit the app, so leave it up to the
    ' ViewController to close the active screen.
    GetViewController().CloseScreen(true)
	
	m.simpleOK("")
	return true
	
End Sub

Function ProcessApplicationSetText() As Boolean

    screen = GetViewController().screens.Peek()

    if type(screen.SetText) = "roFunction" then
        value = firstOf(m.request.query["String"], "")
        NowPlayingManager().textFieldContent = value
        screen.SetText(value, true)
    else
	value = firstOf(m.request.query["String"], "")
        createDialog("Message from the server", strReplace(tostr(value),"+"," "), "Got It", true)
    end if

    m.simpleOK("")
    return true
	
End Function

Function ProcessApplicationDisplayText() As Boolean
	header = firstOf(m.request.query["Header"], "")
	text = firstOf(m.request.query["Text"], "")
        createDialog(strReplace(tostr(header),"+"," "), strReplace(tostr(text),"+"," "), "Got It", true)
	m.simpleOK("")
	return true
End Function

Function ProcessNavigationMusic() As Boolean

    dummyItem = CreateObject("roAssociativeArray")
    dummyItem.ContentType = "audio"
    dummyItem.Key = "nowplaying"
    GetViewController().CreateScreenForItem(dummyItem, invalid, ["Now Playing"])

    m.simpleOK("")
    return true
End Function

Sub SendEcpCommand(command)
    GetViewController().StartRequestIgnoringResponse("http://127.0.0.1:8060/keypress/" + command, "", "txt")
End Sub

Sub vcInitializeOtherScreen(screen, breadcrumbs)
    m.AddBreadcrumbs(screen, breadcrumbs)
    m.UpdateScreenProperties(screen)
    m.PushScreen(screen)
End Sub

Sub vcAssignScreenID(screen)
    if screen.ScreenID = invalid then
        screen.ScreenID = m.nextScreenId
        m.nextScreenId = m.nextScreenId + 1
    end if
End Sub

Function vcStartRequest(urlTransferObject, listener, context, body=invalid, method = invalid) As Boolean

    urlTransferObject.SetPort(m.GlobalMessagePort)
    context.Listener = listener
    context.Request = urlTransferObject

    if method = "post" then
        started = urlTransferObject.AsyncPostFromString(body)
    else if body = invalid then
        started = urlTransferObject.AsyncGetToString()
    else
        started = urlTransferObject.AsyncPostFromString(body)
    end if

    if started then
        id = urlTransferObject.GetIdentity().tostr()
        m.PendingRequests[id] = context

        if listener <> invalid then
            screenID = listener.ScreenID.tostr()
            if NOT m.RequestsByScreen.DoesExist(screenID) then
                m.RequestsByScreen[screenID] = []
            end if
            ' Screen ID's less than 0 are fake screens that won't be popped until
            ' the app is cleaned up, so no need to waste the bytes tracking them
            ' here.
            if listener.ScreenID >= 0 then m.RequestsByScreen[screenID].Push(id)
        end if

        return true
    else
        return false
    end if
End Function

Sub vcStartRequestIgnoringResponse(url, body=invalid, contentType="xml")
    request = CreateURLTransferObject(url)
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")

    if body <> invalid then
        request.AddHeader("Content-Type", MimeType(contentType))
    end if

    context = CreateObject("roAssociativeArray")
    context.requestType = "ignored"

    m.StartRequest(request, invalid, context, body)
End Sub

Sub vcPushScreen(screen)
    m.AssignScreenID(screen)
    screenName = firstOf(screen.ScreenName, type(screen.Screen))
    
	Debug("Pushing screen " + tostr(screen.ScreenID) + " onto view controller stack - " + screenName)
    m.screens.Push(screen)
End Sub

Sub vcPopScreen(screen)
    if screen.Cleanup <> invalid then screen.Cleanup()

    ' Try to clean up some potential circular references
    screen.Listener = invalid
    if screen.Loader <> invalid then
        screen.Loader.Listener = invalid
        screen.Loader = invalid
    end if

    if screen.ScreenID = invalid OR m.screens.Peek().ScreenID = invalid then
        Debug("Trying to pop screen a screen without a screen ID!")
        Return
    end if

    callActivate = true
    screenID = screen.ScreenID.tostr()
    if screen.ScreenID <> m.screens.Peek().ScreenID then
        Debug("Trying to pop screen that doesn't match the top of our stack!")

        ' This is potentially indicative of something very wrong, which we may
        ' not be able to recover from. But it also happens when we launch a new
        ' screen from a dialog and try to pop the dialog after the new screen
        ' has been put on the stack. If we don't remove the screen from the
        ' stack, things will almost certainly go wrong (seen one crash report
        ' likely caused by this). So we might as well give it a shot.

        for i = m.screens.Count() - 1 to 0 step -1
            if screen.ScreenID = m.screens[i].ScreenID then
                Debug("Removing screen " + screenID + " from middle of stack!")
                m.screens.Delete(i)
                exit for
            end if
        next
        callActivate = false
    else
        Debug("Popping screen " + screenID + " and cleaning up " + tostr(screen.NumBreadcrumbs) + " breadcrumbs")
        m.screens.Pop()
        for i = 0 to screen.NumBreadcrumbs - 1
            m.breadcrumbs.Pop()
        next
    end if

    ' Clean up any requests initiated by this screen
    m.CancelRequests(screen.ScreenID)

    ' Clean up any timers initiated by this screen
    timers = m.TimersByScreen[screenID]
    if timers <> invalid then
        for each timerID in timers
            timer = m.Timers[timerID]
            timer.Active = false
            timer.Listener = invalid
            m.Timers.Delete(timerID)
        next
        m.TimersByScreen.Delete(screenID)
    end if

    ' Let the new top of the stack know that it's visible again. If we have
    ' no screens on the stack, but we didn't just close the home screen, then
    ' we haven't shown the home screen yet. Show it now.
    if m.Home <> invalid AND screen.screenID = m.Home.ScreenID then
        Debug("Popping home screen")
        while m.screens.Count() > 1
            m.PopScreen(m.screens.Peek())
        end while
        m.screens.Pop()
		
    else if m.screens.Count() = 0 then
		if screen.goHomeOnPop <> false then
			m.Home = m.CreateHomeScreen()
		end if
		
    else if callActivate then
        newScreen = m.screens.Peek()
        screenName = firstOf(newScreen.ScreenName, type(newScreen.Screen))
        Debug("Top of stack is once again: " + screenName)
        
		newScreen.Activate(screen)
    end if

    ' If some other screen requested this close, let it know.
    if m.afterCloseCallback <> invalid then
        callback = m.afterCloseCallback
        m.afterCloseCallback = invalid
        callback.OnAfterClose()
    end if
End Sub

Function vcIsActiveScreen(screen) As Boolean
    return m.screens.Peek().ScreenID = screen.ScreenID
End Function


Function vcCreateScreenForItem(context, contextIndex, breadcrumbs, show=true) As Dynamic

	' cleanup unused screens to speed up responses
	RunGarbageCollector()

	Debug("Entered CreateScreenForItem")

    if type(context) = "roArray" then
        item = context[contextIndex]
    else
        item = context
    end if
    item.indexnumber = 1
    contentType = item.ContentType
    itemId = item.Id
    debug("::CreateScreenForItem:: Type "+FirstOf(contentType,"Invalid"))
    screen = invalid

	' SPEED UP SHIT!!
	'RunGarbageCollector()


    ' NOTE: We don't support switching between them as a preference, but
    ' the poster screen can be used anywhere the grid is used below. By
    ' default the poster screen will try to decide whether or not to
    ' include the filter bar that makes it more grid like, but it can
    ' be forced by setting screen.FilterMode = true.

    screenName = invalid

	if contentType = "Preferences" then
	
        	screen = createPreferencesScreen(m)
        	screenName = "Preferences"

	else if contentType = "Search" then

        	screen = createSearchScreen(m)
        	screenName = "Search"

	else if contentType = "Logout" then
		peepsnames = GetAlsoWatching()
		if peepsnames <> ""
			sessionId = GetSessionId()
			if sessionId <> invalid
				r = CreateObject("roRegex", ",", "")
				for each id in r.split(peepsnames)
					result = postAlsoWatchingStatus(id, false, sessionId)
				end for
			end if
		end if
		GetGlobalAA().AddReplace("peepsnames", invalid)
        	m.Logout()

	else if contentType = "UserLogout" then
		peepsnames = GetAlsoWatching()
		if peepsnames <> ""
			sessionId = GetSessionId()
			if sessionId <> invalid
				r = CreateObject("roRegex", ",", "")
				for each id in r.split(peepsnames)
					result = postAlsoWatchingStatus(id, false, sessionId)
				end for
			end if
		end if
		GetGlobalAA().AddReplace("peepsnames", invalid)
		'serverId = RegRead("currentServerId")
		'ConnectionManager().DeleteServerData(serverId, "UserId")
		base = GetServerBaseUrl()
		reg = CreateObject("roRegex", "/emby", "")
		baseurl = reg.ReplaceAll(base,"")
		screen = CreateLoginScreen(m, baseurl, 0)
		ScreenName = "Login"
		breadcrumbs = ["", "Please Sign In"]

    else if contentType = "ChangeServer" then
		peepsnames = GetAlsoWatching()
		if peepsnames <> ""
			sessionId = GetSessionId()
			if sessionId <> invalid
				r = CreateObject("roRegex", ",", "")
				for each id in r.split(peepsnames)
					result = postAlsoWatchingStatus(id, false, sessionId)
				end for
			end if
		end if
		GetGlobalAA().AddReplace("peepsnames", invalid)
        	screen = createServerListScreen(m)
		ScreenName = "Server List"

    else if contentType = "AlsoWatching" then
		base = GetServerBaseUrl()
		reg = CreateObject("roRegex", "/emby", "")
		baseurl = reg.ReplaceAll(base,"")
		screen = CreateLoginScreen(m, baseurl, 1)
		ScreenName = "Also Watching"

    else if contentType = "Welcome" then

        	screen = createServerFirstRunSetupScreen(m)
        	screenName = "Welcome"

	else if contentType = "DeviceInfo" then
		screen = createDevicenfoScreen(m)
        	screenName = "DebugInfo"

	else if contentType = "DebugLogs" then
		screen = createDebugLogScreen(m)
        	screenName = "DebugLogs"

	else if contentType = "ConnectSignIn" then

        	screen = createConnectSignInScreen(m)
        	screenName = "ConnectSignIn"

	else if contentType = "ViewFavorites" then
		screen = createFavConLibraryScreen(m, "0", "1")
        	screenName = "Favorites"
		breadcrumbs = ["View All","Favorites"]

	else if contentType = "ContinueWatching" then
		screen = createFavConLibraryScreen(m, "0", "0")
        	screenName = "Continue Playing"
		breadcrumbs = ["View All","Continue Playing"]

	else if contentType = "ViewLatest" then
		screen = createFavConLibraryScreen(m, "0", "2")
        	screenName = "Latest"
		breadcrumbs = ["View 100","Latest Added"]

	else if contentType = "ViewNewest" then
		screen = createFavConLibraryScreen(m, "0", "6")
        	screenName = "Newest"
		breadcrumbs = ["View 100","Latest Premieres"]

	else if contentType = "ViewRandom" then
		screen = createFavConLibraryScreen(m, "0", "3")
        	screenName = "Random"
		breadcrumbs = ["View 100","Random"]

	else if contentType = "ViewRecent" then
		screen = createFavConLibraryScreen(m, "0", "4")
        	screenName = "Recently Watched"
		breadcrumbs = ["View 100","Recently Played"]

	else if contentType = "ViewFrequent" then
		screen = createFavConLibraryScreen(m, "0", "5")
        	screenName = "Frequently Played"
		breadcrumbs = ["View 100","Frequently Played"]

	else if contentType = "TVLibrary" then
		screen = createTvLibraryScreen(m, itemId)
        	screenName = "TVLibrary"

    else if contentType = "MovieLibrary" then
		screen = createMovieLibraryScreen(m, itemId)
        	screenName = "MovieLibrary"

    else if contentType = "HomeMovieLibrary" then
		screen = createHomeMovieLibraryScreen(m, itemId)
        	screenName = "HomeMovieLibrary"

    else if contentType = "LocalTrailers" then
		m.TrailerOverview = item.description
		screen = createLocalTrailersScreen(m, item)
		ScreenName = "All Trailers" + FirstOf(item.Id,"")

    else if item.MediaType = "Video" or item.MediaType = "Game" or item.MediaType = "Book" or contentType = "ItemPerson" or contentType = "Person" or contentType = "Program" then
		Debug ("Calling createVideoSpringboardScreen")
		screen = createVideoSpringboardScreen(context, contextIndex, m)
		screenName = "VideoSpringboardScreen" + itemId

    else if contentType = "MovieGenre" then
		screen = createMovieGenreScreen(m, item.Title, item.ParentId)
		screenName = "MovieGenre " + item.Title

    else if contentType = "MovieAlphabet" then
		screen = createMovieAlphabetScreen(m, itemId, item.ParentId)
        	screenName = "MovieAlphabet " + itemId

    else if contentType = "TvGenre" then
		screen = createTvGenreScreen(m, item.Title, item.ParentId)
		screenName = "TvGenre " + item.Title

    else if contentType = "TvStudio" then
		screen = createTvStudioScreen(m, item.Title, item.ParentId)
		screenName = "TvStudio " + item.Title

    else if contentType = "MovieStudio" then
		screen = createMovieStudioScreen(m, item.Title, item.ParentId)
		screenName = "MovieStudio " + item.Title

    else if contentType = "TvAlphabet" then
		screen = createTvAlphabetScreen(m, itemId, item.ParentId)
        	screenName = "TvAlphabet " + itemId

    else if contentType = "HomeVideoAlphabet" then
		screen = createHomeVideoAlphabetScreen(m, itemId, item.ParentId)
        	screenName = "HomeVideoAlphabet " + itemId

    else if contentType = "FolderAlphabet" then
		screen = createFolderAlphabetScreen(m, itemId, item.ParentId)
        	screenName = "FolderAlphabet " + itemId

    else if contentType = "PhotoAlphabet" then
		screen = createPhotoAlphabetScreen(m, itemId, item.ParentId)
        	screenName = "PhotoAlphabet " + itemId

    else if contentType = "Series" then
		screen = createTvSeasonsScreen(m, item)
        	screenName = "Series " + itemId

    else if contentType = "SeriesStudios" then
		screen = createTvStudioScreen(m, item.Studio, item.ParentId)
        	screenName = "Networks " + itemId

    else if contentType = "MoviesStudios" then
		screen = createMovieStudioScreen(m, item.Studio, item.ParentId)
        	screenName = "Studios " + itemId

    else if contentType = "LiveTVChannels" then
		screen = createLiveTvChannelsScreen(m)
		screenName = "LiveTVChannels"

    else if contentType = "LiveTVFavoriteGuide" then
		screen = createLiveTvGuideScreen(m)
		screenName = "LiveTVFavoriteGuide"

    else if contentType = "LiveTVRecordings" then
		screen = createLiveTvRecordingsScreen(m)
		screenName = "LiveTVRecordings"

    else if contentType = "MusicList" then
		screen = createMusicListScreen(m,AudioPlayer().Context)
		for x = 0 to AudioPlayer().context.count()-1
			HideSpeakerIcon(screen, x)
		next
		if AudioPlayer().IsPlaying
			screen.prevIconIndex = AudioPlayer().CurIndex
			ShowSpeakerIcon(screen, AudioPlayer().CurIndex)
        	else if AudioPlayer().isPaused
            		screen.prevIconIndex = AudioPlayer().CurIndex
			ShowPauseIcon(screen, AudioPlayer().CurIndex)
		end if
		screen.SetFocusedItem(AudioPlayer().CurIndex)
		screenName = "MusicList"

    else if contentType = "MusicLibrary" then
		screen = createMusicLibraryScreen(m, itemId)
		screenName = "MusicLibrary"

    else if contentType = "MusicArtist" then
		screen = createMusicItemSpringboardScreen(context, contextIndex, m)
        	screenName = "MusicArtist " + itemId

    else if contentType = "MusicAlbum" then
		screen = createMusicItemSpringboardScreen(context, contextIndex, m)
        	screenName = "MusicAlbum " + itemId

    else if contentType = "MusicGenre" then
		screen = createMusicItemSpringboardScreen(context, contextIndex, m)
        	screenName = "MusicGenre " + itemId

    else if contentType = "MusicStudio" then
		screen = createMusicItemSpringboardScreen(context, contextIndex, m)
        	screenName = "MusicStudio " + itemId

    else if contentType = "Studio" then
		screen = createStudioSearchScreen(m, item.Title)
		screenName = "StudioSearch " + item.Title

    else if contentType = "Genre" then
		screen = createGenreSearchScreen(m, item.Title)
		screenName = "GenreSearch " + item.Title
		
    else if contentType = "Playlist" and item.MediaType = "Audio" then
		screen = createMusicSongsScreen(m, item, contextIndex)
        	screenName = "Playlist " + itemId

    else if contentType = "Audio" and item.MediaType = "Audio" then
    		if type(context) = "roArray" then
			title = item.Title
			artist = item.Artist
			c = []
			for each item in context
				if item.contentType = "Audio" and item.MediaType = "Audio" then
					c.push(item)
				end if
			end for
			count = 0
			for each item in c
				if item.artist = artist and item.title = title
					ci = count
				end if
				count = count + 1
			end for
			screen = createAudioSearchScreen(m, c, ci)
		else
			screen = createAudioSpringboardScreen([context], 0, m)
			if screen = invalid then return invalid
		end if
        	screenName = "Tracks"
		breadcrumbs = ["Tracks"]

    else if contentType = "MusicFavorite" then
		screen = createMusicSongsScreen(m, item, contextIndex)
        	screenName = "Favorite Tracks"
		breadcrumbs = ["", "Favorite Tracks"]

    else if contentType = "RecentlyPlayed" then
		screen = createMusicSongsScreen(m, item, contextIndex-2)
        	screenName = "Recently Played Tracks"
		breadcrumbs = ["", "Recently Played Tracks"]

    else if contentType = "MostPlayed" then
		screen = createMusicSongsScreen(m, item, contextIndex-2)
        	screenName = "Most Played Tracks"
		breadcrumbs = ["", "Frequently Played Tracks"]

    else if contentType = "AudioSearch" then
		screen = createAudioSearchScreen(m, context, contextIndex)
        	screenName = "Search Tracks"
		breadcrumbs = ["Tracks"]

    else if contentType <> invalid and left(contentType,12) = "AudioPodcast"
		screen = createAudioSearchScreen(m, context, contextIndex)
		if right(contentType,5) = "Search"
        		screenName = "SearchPodcasts"
			breadcrumbs = ["Search Podcasts"]
		else
        		screenName = "Podcasts"
			breadcrumbs = ["Podcasts"]
		end if

    else if contentType = "emby" then
		if AppExists(QueryApps(), "44191")
			Debug ("Sending message to roku to launch emby official app.")
			LaunchApp("44191")
		else
			Debug ("Sending message to roku to install emby official app.")
			InstallApp("44191")
		end if

    else if contentType = "embybeta" then
		if AppExists(QueryApps(), "43157")
			Debug ("Sending message to roku to launch emby beta app.")
			LaunchApp("43157")
		else
			Debug ("Sending message to roku to install emby beta app.")
			InstallApp("43157")
		end if

    else if contentType = "netflix" then
		Debug ("Sending message to roku to launch netflix.")
		LaunchApp("12")

    else if contentType = "amazoninstant" then
		Debug ("Sending message to roku to launch amazon instant video.")
		LaunchApp("13")

    else if contentType = "hulu" then
		Debug ("Sending message to roku to launch hulu.")
		LaunchApp("2285")

    else if contentType = "youtube" then
		Debug ("Sending message to roku to launch youtube.")
		LaunchApp("837")

    else if contentType = "googleplay" then
		Debug ("Sending message to roku to launch google play movies.")
		LaunchApp("50025")

    else if contentType = "xtv" then
		Debug ("Sending message to roku to launch xtv iptv.")
		LaunchApp("81444")

    else if contentType = "slingtv" then
		Debug ("Sending message to roku to launch slingtv.")
		LaunchApp("46041")

    else if contentType = "hbonow" then
		Debug ("Sending message to roku to launch hbo now.")
		LaunchApp("61322")

    else if contentType = "showtime" then
		Debug ("Sending message to roku to launch showtime.")
		LaunchApp("8838")

    else if contentType = "vudu" then
		Debug ("Sending message to roku to vudu.")
		LaunchApp("13842")

    else if contentType = "pbs" then
		Debug ("Sending message to roku to launch pbs.")
		LaunchApp("23353")

    else if contentType = "acorntv" then
		Debug ("Sending message to roku to launch acorn tv.")
		LaunchApp("14295")

    else if contentType = "plutotv" then
		Debug ("Sending message to roku to launch pluto tv.")
		LaunchApp("74519")

    else if contentType = "pandora" then
		Debug ("Sending message to roku to launch pandora.")
		LaunchApp("28")

    else if contentType = "tunein" then
		Debug ("Sending message to roku to launch tunein radio.")
		LaunchApp("1453")

    else if contentType = "tvtuner" then
		Debug ("Sending message to roku to launch RokuTV Tuner.")
		LaunchApp("tvinput.dtv")
		
    else if contentType = "MusicAlbumAlphabet" then
		screen = createMusicAlbumsAlphabetScreen(m, itemId, item.ParentId)
		screenName = "MusicAlbumAlphabet " + itemId

    else if contentType = "MusicArtistAlphabet" then
		screen = createMusicArtistsAlphabetScreen(m, itemId, item.ParentId)
		screenName = "MusicArtistAlphabet " + itemId

    else if contentType = "Channel" or contentType = "ChannelFolderItem" then
        	screen = createChannelScreen(m, item)
        	screenName = "Channel " + itemId

    else if contentType = "MediaFolder" or contentType = "PhotoFolder" or contentType = "Folder" or contentType = "BoxSet" or item.IsFolder = true then
		screen = createFolderScreen(m, item)
		screenName = "Folder " + itemId

    else if item.MediaType = "Photo" then
	
        'if right(item.key, 8) = "children" then
            'screen = createPosterScreen(item, m)
            'screenName = "Photo Poster"
        'else
            screen = createPhotoSpringboardScreen(context, contextIndex, m)
            screenName = "Photo Springboard"
        'end if

    else if contentType = "RecordingGroup" then
		screen = createLiveTvRecordingGroupsScreen(m, item)
		screenName = "RecordingGroup " + itemId

    else if item.key = "nowplaying" or contentType = "NowPlaying" then
		if AudioPlayer().ContextScreenID = m.screens.Peek().ScreenID then
			screen = invalid
		else
			AudioPlayer().ContextScreenID = m.nextScreenId
			screen = createAudioSpringboardScreen(AudioPlayer().Context, AudioPlayer().CurIndex, m)
			screenName = "Now Playing"
			breadcrumbs = [screenName, ""]
		end if
		if screen = invalid then return invalid
    else if item.MediaType = "Audio" then
		screen = createAudioSpringboardScreen(context, contextIndex, m)
		if screen = invalid then return invalid
		screenName = "Audio Springboard"
    else if contentType = "keyboard" then
		screen = createKeyboardScreen(m, item)
		screenName = "Keyboard"
    else if contentType = "search" then
		screen = createSearchScreen(item, m)
		screenName = "Search"
    else if item.searchTerm <> invalid then

		screen = createSearchResultsScreen(m, item.searchTerm)
		screenName = "Search Results"

    else if item.settings = "1"
		screen = createSettingsScreen(item, m)
		screenName = "Settings"

    else
		Debug ("Encountered unknown type ("+FirstOf(contentType,"Invalid")+") in CreateScreenForItem")
    end if

    if screen <> invalid then
		if screenName = invalid then
			screenName = type(screen.Screen) + " " + firstOf(contentType, "unknown")
		end if

		screen.ScreenName = screenName

		m.AddBreadcrumbs(screen, breadcrumbs)
		m.UpdateScreenProperties(screen)
		m.PushScreen(screen)

		if show then screen.Show()
		return screen
	end If

	return invalid

End Function

Function vcCreateTextInputScreen(title, heading, breadcrumbs, initialValue="", secure=false) As Dynamic
    screen = createKeyboardScreen(m, invalid, title, heading, initialValue, secure)
    screen.ScreenName = "Keyboard: " + tostr(heading)

    m.AddBreadcrumbs(screen, breadcrumbs)
    m.UpdateScreenProperties(screen)
    m.PushScreen(screen)

    return screen
End Function

Function vcCreateEnumInputScreen(options, selected, heading, breadcrumbs, show=true) As Dynamic
    screen = createEnumScreen(options, selected, m)
    screen.ScreenName = "Enum: " + tostr(heading)

    if heading <> invalid then
        screen.Screen.SetHeader(heading)
    end if

    m.AddBreadcrumbs(screen, breadcrumbs)
    m.UpdateScreenProperties(screen)
    m.PushScreen(screen)

    if show then screen.Show()

    return screen
End Function

Function vcCreateContextMenu()

	screen = m.screens.Peek()
	
	skip = FirstOf(getGlobalVar("AudioConflict"),"0")
	menuShown = screen.createContextMenu()

	'if skip = "1" and menuShown = true
	'	skip = "0"
	'	GetGlobalAA().AddReplace("AudioConflict","0")
	'end if

	if menuShown = false or (menuShown = true and skip = "0") then
		' Our context menu is only relevant if the audio player has content.
		if AudioPlayer().ContextScreenID = invalid then return invalid
		return AudioPlayer().ShowContextMenu()
	end If

End Function

Function vcCreatePhotoPlayer(context, contextIndex=invalid, show=true, shuffled=false)
    
	screen = createPhotoPlayerScreen(context, contextIndex, m, shuffled)
    screen.ScreenName = "Photo Player"

    m.AddBreadcrumbs(screen, invalid)
    m.UpdateScreenProperties(screen)
    m.PushScreen(screen)

    if show then screen.Show()

    return screen
End Function

Function vcCreateVideoPlayer(context, contextIndex, playOptions, remote, show=true)
    
	' Stop any background audio first since video will now play
	player = AudioPlayer()
	if player.Isplaying
		player.Stop()
		player.Isplaying = false
		player.Ispaused = false
	end if
	' stop any video before playing another video over it (fixes remote-control issue)
    	if NowPlayingManager().location <> invalid 
		if NowPlayingManager().location = "fullScreenVideo"
			m.PopScreen(m.screens[m.screens.Count() - 1])
		end if
    	end if
	screen = createVideoPlayerScreen(context, contextIndex, playOptions, m, remote)
	screen.ScreenName = "Video Player"

	m.AddBreadcrumbs(screen, invalid)
	m.UpdateScreenProperties(screen)
	m.PushScreen(screen)

	if show then screen.Show()

	return screen
End Function

Function GetContextForPlayback(context, contextIndex) as Object

	obj = {
		context: context
		contextIndex: contextIndex
	}
	
	item = context[contextIndex]
	
	itemType = firstOf(item.ContentType, item.Type)
	Debug ("GetContextForPlayback " + itemType)
	
    if itemType = "MusicArtist" then
	
		' URL
		url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?IncludeItemTypes=Audio&Recursive=true&SortBy=SortName&ArtistIds=" + HttpEncode(item.Id) + "&ImageTypeLimit=1"

		' Prepare Request
		request = HttpRequest(url)
		request.ContentType("json")
		request.AddAuthorization()

		' Execute Request
		response = request.GetToStringWithTimeout(10)
		
		if response <> invalid
			obj.context= parseItemsResponse(response, 0, "two-row-flat-landscape-custom").Items
			obj.contextIndex = 0
		end if
		
    'else if itemType = "MusicAlbum" then
			'obj.context = musicGetSongsForItem(item)
			'obj.context = MusicMetadata.GetAlbumSongs(item.id)
			'obj.contextIndex = 0
	
		' URL
		'url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?IncludeItemTypes=Audio&Recursive=true&SortBy=SortName&ParentId=" + HttpEncode(item.Id) + "&ImageTypeLimit=1"

		' Prepare Request
		'request = HttpRequest(url)
		'request.ContentType("json")
		'request.AddAuthorization()

		' Execute Request
		'response = request.GetToStringWithTimeout(10)
		'if response <> invalid

			'obj.context= parseItemsResponse(response, 0, "two-row-flat-landscape-custom").Items
			'obj.contextIndex = 0
		'end if
		
    else if itemType = "PhotoAlbum" then
	
		' URL
		url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?IncludeItemTypes=Photo&SortBy=SortName&ParentId=" + HttpEncode(item.Id) + "&ImageTypeLimit=1"

		' Prepare Request
		request = HttpRequest(url)
		request.ContentType("json")
		request.AddAuthorization()

		' Execute Request
		response = request.GetToStringWithTimeout(10)
		if response <> invalid

			obj.context=  parseItemsResponse(response, 0, "two-row-flat-landscape-custom").Items
			obj.contextIndex = 0
		end if
		
    else if itemType = "Playlist" then
	
		' URL
		url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?ParentId=" + HttpEncode(item.Id) + "&ImageTypeLimit=1"

		' Prepare Request
		request = HttpRequest(url)
		request.ContentType("json")
		request.AddAuthorization()

		' Execute Request
		response = request.GetToStringWithTimeout(10)
		if response <> invalid

			obj.context=  parseItemsResponse(response, 0, "two-row-flat-landscape-custom").Items
			obj.contextIndex = 0
		end if	
		
    else if itemType = "MusicGenre" then
	
		' URL
		url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?IncludeItemTypes=Audio&Recursive=true&SortBy=SortName&Genres=" + HttpEncode(item.Title)

		' Prepare Request
		request = HttpRequest(url)
		request.ContentType("json")
		request.AddAuthorization()

		' Execute Request
		response = request.GetToStringWithTimeout(10)
		if response <> invalid

			obj.context=  parseItemsResponse(response, 0, "two-row-flat-landscape-custom").Items
			obj.contextIndex = 0
		end if
	end if	
		
	return obj
	
End Function

Function ShouldWeShuffle(count, series,item,index) As Integer
	port = CreateObject("roMessagePort")
	dialog = CreateObject("roMessageDialog")
	dialog.SetMessagePort(port)
	dialog.SetTitle("Continuous Play")
	cin = FirstOf(RegRead("prefcustominorder"),"3").toInt()
	text = "How do you want these "+Pluralize(count, "item")+" Played?"+chr(10)
	if series = "yes"
		if item.SeriesName.len() > 40
			SeriesName = left(item.SeriesName,40)+"..."
		else
			SeriesName = item.SeriesName
		end if
		text = text + +"Selected: "+itostr(index+1)+" - "+SeriesName+chr(10)
		epi = ""
        	'if item.ParentIndexNumber <> invalid
		'	epi = epi + "Season "+ itostr(item.ParentIndexNumber)
		'end if
		'if item.IndexNumber <> invalid
		'	if epi <> "" then epi = epi + " / "
		'	epi = epi + "Episode " + itostr(item.IndexNumber)
		'
		'	' Add Double Episode Number
		'	if item.IndexNumberEnd <> invalid
		'		epi = epi + "-" + itostr(item.IndexNumberEnd)
		'	end if
        	'end if
		'if epi <> "" then text = text + epi + chr(10)
	else
		text = text + "Selected: "+itostr(index+1)+chr(10)
	end if
	if item.title.len() > 50
		title = left(item.title,50) + "..."
	else
		title = item.title
	end if
	text = text + title
	dialog.SetText(text)
	dialog.AddButton(5, "Play Selected")
	dialog.AddButton(1, "In Order from "+itostr(index+1)+" to "+itostr(count))
	plus2 = index + cin
	if plus2 < count
		dialog.AddButton(7, "Custom In-Order from "+itostr(index+1)+" to "+itostr(plus2))
	end if
	if series = "yes"
		dialog.AddButton(6, "Play Entire Series from Selected Episode")
	end if
	dialog.AddButton(2, "Shuffle All "+itostr(count))
	if series = "yes" then dialog.AddButton(3, "Shuffle Entire Selected Series")
	dialog.AddButton(4, "Cancel")
	dialog.EnableBackButton(false)
	dialog.Show()
	reply = 1
	While True
		dlgMsg = wait(0, dialog.GetMessagePort())
		If type(dlgMsg) = "roMessageDialogEvent"
			if dlgMsg.isButtonPressed()
				reply = dlgMsg.GetIndex()
				exit while
			end if
		end if
	end while
	dialog.close()
	return reply
End Function

Function vcCreatePlayerForItem(context, contextIndex, playOptions, remote = false)

	obj = GetContextForPlayback(context, contextIndex)
	context = obj.context
	contextIndex = obj.contextIndex
	item = context[contextIndex]

	if item.MediaType = "Photo"
		return m.CreatePhotoPlayer(context, contextIndex)
	else if item.MediaType = "Audio"
        	screen = m.CreateScreenForItem(context, contextIndex, invalid)
		if item.contentType <> "MusicFavorite" and item.contentType <> "AudioSearch" and item.contentType <> "Audio"
			if contextIndex <> invalid and contextIndex <> 0 then contextIndex = ContextIndex - 2
		end if
    		if type(context) = "roArray" then
			title = item.Title
			artist = item.Artist
			c = []
			for each item in context
				if item.contentType = "Audio" and item.MediaType = "Audio" then
					c.push(item)
				end if
			end for
			count = 0
			for each item in c
				if item.artist = artist and item.title = title
					ci = count
					contextIndex = ci
				end if
				count = count + 1
			end for
		end if
		if screen <> invalid and screen.playFromIndex <> invalid
			if AudioPlayer().isPlaying then AudioPlayer().Stop() 
			screen.playFromIndex(contextIndex)
			screen.SetFocusedItem(contextIndex)
			return screen
		end if
	else if item.MediaType = "MusicAlbum" then
        	'screen = createMusicListScreen(m,Context)
		'if screen <> invalid
			'if AudioPlayer().isPlaying then AudioPlayer().Stop() 
			'screen.playFromIndex(0)
			'screen.SetFocusedItem(0)
			'return screen
		'end if
    	else if item.MediaType = "Video"
		
		if context.count() > 1 and remote = false and firstOf(RegRead("prefContPlay"), "yes") = "yes"
			seriesId = item.SeriesId
			if SeriesId <> "" and SeriesId <> invalid
				series = "yes"
			else
				series = "no"
			end if
			shuf = false
			result = ShouldWeShuffle(context.count(),series,item,contextIndex)
			if result = 2
				shuf = true
   				loadingDialog = CreateObject("roOneLineDialog")
    				loadingDialog.SetTitle("Shuffling "+tostr(context.count())+ " Videos")
    				loadingDialog.ShowBusyAnimation()
    				loadingDialog.Show()
				contextIndex2 = Rnd(context.count())-1
				contextIndex = ShuffleArray(context, contextIndex2)
    				loadingDialog.close()
			else if result = 3
				shuf = true
   				loadingDialog = CreateObject("roOneLineDialog")
    				loadingDialog.SetTitle("Getting all episodes of "+item.seriesName)
    				loadingDialog.ShowBusyAnimation()
    				loadingDialog.Show()
				response = getAllEpisodes(seriesId)
				if response <> invalid
					context = parseItemsResponse(response, 0, "two-row-flat-landscape-custom").Items
					contextIndex2 = Rnd(context.count())-1
					contextIndex = ShuffleArray(context,contextIndex2)
    					loadingDialog.close()
				else
					result = 4
				end if
			else if result = 7
				cin = FirstOf(RegRead("prefcustominorder"),"3").toInt()
				c = context : context = []
				for x = 0 to cin-1
					context.push(c[contextIndex+x])
				end for
				contextIndex = 0
			else if result = 5
				shuf = false
				playOptions = {
					PlayStart: context[0].BookmarkPosition
				}
				context = [context[contextIndex]]
				contextIndex = 0
			else if result = 6
				shuf = false
   				loadingDialog = CreateObject("roOneLineDialog")
    				loadingDialog.SetTitle("Getting all episodes of "+item.seriesName)
    				loadingDialog.ShowBusyAnimation()
    				loadingDialog.Show()
				response = getAllEpisodes(seriesId)
				list = parseItemsResponse(response, 0, "two-row-flat-landscape-custom").Items
				contextIndex = 0
				context = []
				smatch = 0
				ematch = 0
				for each i in list
					if smatch = 0
						if item.ParentIndexNumber <> invalid
							if item.ParentIndexNumber = i.ParentIndexNumber then smatch = 1
						else
							if NOT i.ParentIndexNumber <> invalid then smatch = 1
						end if
					end if
					if smatch = 1
						if ematch = 0
							if item.IndexNumber <> invalid
								if item.IndexNumber = i.IndexNumber then ematch = 1
							else
								if NOT i.IndexNumber <> invalid then ematch = 1
							end if
						end if
					end if
					if ematch = 1 and smatch = 1
						context.push(i)
					end if
				end for
    				loadingDialog.close()
			end if
		else if left(firstOf(RegRead("prefContPlay"), "yes"), 2) = "no"
			shuf = false
			context = [context[contextIndex]]
			if right(firstOf(RegRead("prefContPlay"), "yes"), 1) = "+"
				playOptions = {
					PlayStart: context[0].BookmarkPosition
				}
			end if
			contextIndex = 0
			result = 0
		else
			result = 0
			shuf = false
		end if
		if result <> 4
			reply = m.CreateVideoPlayer(context, contextIndex, playOptions, remote)
			if shuf then UnshuffleArray(context,contextIndex2)
			return reply
		end if
    	else
        	Debug("Not sure how to play item of type " + tostr(item.ContentType))
        	return m.CreateScreenForItem(context, contextIndex, invalid)
    	end if
End Function

Function vcIsVideoPlaying() As Boolean
    return VideoPlayer() <> invalid
End Function


Sub vcCancelRequests(screenID)
    requests = m.RequestsByScreen[screenID.tostr()]
    if requests <> invalid then
        for each requestID in requests
            request = m.PendingRequests[requestID]
            if request <> invalid then request.Request.AsyncCancel()
            m.PendingRequests.Delete(requestID)
        next
        m.RequestsByScreen.Delete(screenID.tostr())
    end if
End Sub

Sub vcCloseScreenWithCallback(callback)
    m.afterCloseCallback = callback
    m.screens.Peek().Screen.Close()
End Sub

Sub vcCloseScreen(simulateRemote)
    ' Unless the visible screen is the home screen.
    if m.Home <> invalid AND NOT m.IsActiveScreen(m.Home) then
        ' Our one complication is the screensaver, which we can't know anything
        ' about. So if we're simulating the remote control and haven't been
        ' called in a while, send an ECP back. Otherwise, directly close our
        ' top screen.
        if m.backButtonTimer.IsExpired() then
            SendEcpCommand("Back")
        else
            m.screens.Peek().Screen.Close()
        end if
    end if
End Sub

Sub vcAddBreadcrumbs(screen, breadcrumbs)
    ' Add the breadcrumbs to our list and set them for the current screen.
    ' If the current screen specified invalid for the breadcrubms then it
    ' doesn't want any breadcrumbs to be shown. If it specified an empty
    ' array, then the current breadcrumbs will be shown again.

	if screen <> invalid
		screenType = type(screen.Screen)
		if breadcrumbs = invalid then
			screen.NumBreadcrumbs = 0
			return
		end if

		' Special case for springboard screens, don't show the current title
		' in the breadcrumbs.
		if screenType = "roSpringboardScreen" AND breadcrumbs.Count() > 0 then
			breadcrumbs.Pop()
		end if

		if breadcrumbs.Count() = 0 AND m.breadcrumbs.Count() > 0 then
			count = m.breadcrumbs.Count()
			if count >= 2 then
				breadcrumbs = [m.breadcrumbs[count-2], m.breadcrumbs[count-1]]
			else
				breadcrumbs = [m.breadcrumbs[0]]
			end if

			m.breadcrumbs.Append(breadcrumbs)
			screen.NumBreadcrumbs = breadcrumbs.Count()
		else
			for each b in breadcrumbs
				m.breadcrumbs.Push(tostr(b))
			next
			screen.NumBreadcrumbs = breadcrumbs.Count()
		end if
	end if
End Sub

Sub vcUpdateScreenProperties(screen)

	bread2 = invalid 
	
    if screen.NumBreadcrumbs <> 0 then
        count = m.breadcrumbs.Count()
        if count >= 2 then
            enableBreadcrumbs = true
            bread1 = m.breadcrumbs[count-2]
            bread2 = m.breadcrumbs[count-1]
        else if count = 1 then
            enableBreadcrumbs = true
            bread1 = ""
            bread2 = m.breadcrumbs[0]
        else
            enableBreadcrumbs = false
        end if
    else
        enableBreadcrumbs = false
    end if

    screenType = type(screen.Screen)
    ' Different screen types don't support breadcrumbs with the same functions
    if screenType = "roGridScreen" OR screenType = "roPosterScreen" OR screenType = "roSpringboardScreen" then
        if enableBreadcrumbs then
            screen.Screen.SetBreadcrumbEnabled(true)
            screen.Screen.SetBreadcrumbText(bread1, bread2)
        else
            screen.Screen.SetBreadcrumbEnabled(false)
        end if
    else if screenType = "roSearchScreen" then
        if enableBreadcrumbs then
            screen.Screen.SetBreadcrumbText(bread1, bread2)
        end if
    else if screenType = "roListScreen" then
        if bread2 <> invalid
            ' SetBreadcrumbText is not available on legacy devices
            if left(firstOf(getGlobalVar("rokuModelNumber"), 0),2).toInt() < 31 
                screen.Screen.SetTitle(bread2)
            else
                screen.Screen.SetBreadcrumbText(bread2,"")
            end if
        end if
    else if screenType = "roListScreen" OR screenType = "roKeyboardScreen" OR screenType = "roParagraphScreen" then
        if enableBreadcrumbs then
            screen.Screen.SetTitle(bread2)
        end if
    else

        Debug("Not sure what to do with breadcrumbs on screen type: " + tostr(screenType))
    end if
End Sub

Sub vcAddTimer(timer, listener)
    timer.ID = m.nextTimerId.tostr()
    m.nextTimerId = m.NextTimerId + 1
    timer.Listener = listener
    m.Timers[timer.ID] = timer

    screenID = listener.ScreenID.tostr()
    if NOT m.TimersByScreen.DoesExist(screenID) then
        m.TimersByScreen[screenID] = []
    end if
    m.TimersByScreen[screenID].Push(timer.ID)
End Sub

Sub CloseScreenUntilHomeVisible()
    vc = GetViewController()

    if vc.Home = invalid OR NOT vc.IsActiveScreen(vc.Home) then
        vc.CloseScreenWithCallback(m)
    end if
End Sub

Sub vcDestroyGlitchyScreens()
    ' The audio player / grid screen glitch only affects older firmware versions.
    versionArr = getGlobalVar("rokuVersion")
    if versionArr[0] >= 4 then return

    for each screen in m.screens
        if screen.DestroyAndRecreate <> invalid then
            Debug("Destroying screen " + tostr(screen.ScreenID) + " to work around glitch")
            screen.DestroyAndRecreate()
        end if
    next
End Sub
