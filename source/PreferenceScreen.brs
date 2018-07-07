'**********************************************************
'** createPreferencesScreen
'**********************************************************

Function createPreferencesScreen(viewController as Object) as Object

    ' Create List Screen
    screen = CreateListScreen(viewController)

	screen.baseHandleMessage = screen.HandleMessage
	screen.HandleMessage = handlePreferencesScreenMessage

	screen.Activate = preferencesActivate

    ' Refresh Preference Screen
    RefreshPreferencesPage(screen)

	return screen

End Function

Function handlePreferencesScreenMessage(msg) as Boolean

	handled = false

	viewController = m.ViewController
	screen = m

    ' Fetch / Refresh Preference Screen
    If type(msg) = "roListScreenEvent" Then

		If msg.isListItemSelected() Then

			handled = true
		
			preferenceList = GetPreferenceList()

            if preferenceList[msg.GetIndex()].ContentType = "exit"
                
				m.Screen.Close()

            else

				m.lastIndex = msg.GetIndex()

				prefType	= preferenceList[msg.GetIndex()].PrefType
					
				' Get Preference Functions
				preferenceFunctions = [
					GetTextPreference,
					GetPreferenceVideoQuality,
					GetPreferenceVideoQuality,
					GetPreferenceVideoQuality,
					GetPreferenceResolution,
					GetPreferenceVPlayerTimeout,
					GetPreferenceOptionsRow,
					GetPreferenceContinuous,
					GetPreferenceBlingPlace,
					GetPreferenceQuickJumpRow,
					GetPreferenceStopMusic,
					GetPreferenceStopMusic,
					GetPreferenceStopMusic,
					GetPreferenceGenreStudio,
					GetPreferenceSearchMax,
					GetPreferenceEpisodesMax,
					GetPreferenceFallbackRetry,
					GetPreferenceCustominOrder,
					GetPreferenceTVThemeMusic,
					GetPreferenceTVThemeMusicRepeat,
					GetPreferenceTVThemeMusicRepeat,
					GetPreferenceTVThemeMusicRepeat,
					GetPreferenceRememberUser,
					GetPreferenceExit,
					GetPreferenceExit,
					GetPreferenceInteraction,
					GetPreferenceDelEps,
					GetPreferenceShowClock,
					GetPreferenceShowClock,
					GetPreferenceLatest,
					GetPreferenceEnhancedImages,
					GetPreferenceMediaIndicators,
					GetPreferenceShowClock,
                    			GetPreferenceTimeFormat,
					GetPreferenceShowMiss,
					GetPreferenceShowUp,
					GetPreferenceUseTwoDesc,
					GetPreferenceDetailStats,
					GetPreferenceSlideshow,
					GetPreferenceSlideDuration,
					GetPreferenceEnableTrueHD,
					GetPreferenceDDPlus,
					GetPreferenceDDPlus,
					GetPreferenceMaxRefs,
					GetPreferenceMaxLevel,
					GetPreferenceEnableTrueHD,
					GetPreferencedirectFlash,
					GetPreferenceDTStoAC3,
					GetPreferenceOnlyh264,
					GetPreferenceOnlyAAC,
					GetPreferenceTransAC3,
					GetPreferenceTransAC3,
					GetPreferenceConvAAC,
					GetPreferenceforceSurround,
					GetPreferenceMaxFrame,
					GetPreferenceTheme,
					GetPreferenceColor1,
					GetPreferenceColor2,
					GetPreferenceColor3,
					GetPreferenceColor3,		
					GetPreferenceBorder

				]

				if (prefType = "custom") then
					' Call custom function
					preferenceFunctions[msg.GetIndex()](viewController, preferenceList[msg.GetIndex()])
				else
					prefName    = preferenceList[msg.GetIndex()].Id
					shortTitle  = preferenceList[msg.GetIndex()].ShortTitle
					itemOptions = preferenceFunctions[msg.GetIndex()]()

					' Show Item Options Screen
					newScreen = createItemOptionsScreen(viewController, shortTitle, prefName, itemOptions)
					newScreen.ScreenName = "ItemOptions"
					viewController.InitializeOtherScreen(newScreen, [shortTitle])
					newScreen.Show()


				endif

            end if

        End If
    End If

	if handled = false then
		handled = m.baseHandleMessage(msg)
	end If

	return handled

End Function


'**********************************************************
'** gridActivate
'**********************************************************

Sub preferencesActivate(priorScreen)
    if m.popOnActivate then
        m.ViewController.PopScreen(m)
        return
    else if m.closeOnActivate then
        if m.Screen <> invalid then
            m.Screen.Close()
        else
            m.ViewController.PopScreen(m)
        end if
        return
    end if

    ' If our screen was destroyed by some child screen, recreate it now
    if m.Screen = invalid then

    else
		RefreshPreferencesPage(m)

		m.Screen.SetFocusedListItem(m.lastIndex)
    end if

    if m.Facade <> invalid then m.Facade.Close()
End Sub

'**********************************************************
'** Get A Text Preference Value
'**********************************************************
Function GetTextPreference(viewController, options as Object)

	listener = CreateObject("roAssociativeArray")
	listener.OnUserInput = textScreenCallback
	listener.optionId = options.ID

	screen = viewController.CreateTextInputScreen(options.ShortTitle, options.ShortDescriptionLine1, [options.ShortTitle], firstOf(regRead(options.ID),""), false)
	screen.Listener = listener

	screen.Show()

End Function


Function textScreenCallback(value, screen) As Boolean

    if value <> invalid
        if m.optionId = "prefTwoDesc" or m.optionId = "prefDetailStats" then
		regUserWrite(m.optionId, value)
	else
		regWrite(m.optionId, value)
	end if
    end if

	return true
	
End Function

'**********************************************************
'** Show Item Options
'**********************************************************

Function createItemOptionsScreen(viewController as Object, title As String, itemId As String, list As Object) as Object

    ' Create List Screen
    screen = CreateListScreen(viewController)

	screen.itemId = itemId

	screen.baseHandleMessage = screen.HandleMessage
	screen.HandleMessage = handleItemOptionsScreenMessage

    ' Set Content
    screen.SetHeader(title)
    screen.SetContent(list)

    return screen

End Function

Function handleItemOptionsScreenMessage(msg) as Boolean

	handled = false

    ' Fetch / Refresh Preference Screen
    If type(msg) = "roListScreenEvent" Then

        If msg.isListItemSelected() Then

			handled = true

			index = msg.GetIndex()
			list = m.contentArray

            prefSelected = list[index].Id

            ' Save New Preference
            if m.ItemId = "prefTwoDesc" or m.ItemId = "prefDetailStats" or m.ItemId = "prefRemWatch" or m.ItemId = "preflatest" or m.ItemId = "prefRemWatchSug" or m.ItemId = "prefepisodesmax" then
		regUserWrite(m.ItemId, prefSelected)
	    else
		if m.ItemId = "prefTheme" or m.Itemid = "theme_color1" OR m.ItemId = "theme_color2" or m.Itemid = "theme_color3" OR m.ItemId = "theme_color4" or m.ItemId = "theme_border" or m.itemId = "prefOptionsRow" or m.itemId = "prefQuickJumpRow"
			if m.ItemId = "prefTheme" or m.ItemId = "theme_border" or m.itemId = "prefOptionsRow"
				while m.ViewController.screens.Count() > 0
					m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
				end while
			end if
			t = FirstOf(RegRead("prefTheme"),"1")
			RegWrite(m.itemId, prefSelected)
			if t = "1" then
				m.getDefaultTheme = vcGetDefaultTheme
			else
				m.getDefaultTheme = vcGetStockTheme
			end if
			themeMetadata = m.getDefaultTheme()
			app = CreateObject("roAppManager")
			if themeMetadata <> invalid then
			  ' Override theme properties with values from themeMetadata
			    for each key in themeMetadata
			      app.ClearThemeAttribute(key)
			    end for
			end if

			'app = CreateObject("roAppManager")
			if m.ItemId = "prefTheme" then t = prefSelected
			if  t = "1" then
				m.getDefaultTheme = vcGetDefaultTheme
			else
				m.getDefaultTheme = vcGetStockTheme
			end if
		        theme = m.getDefaultTheme()
    			' Set background Color
    			GetGlobalAA().AddReplace("backgroundColor", theme.BackgroundColor)
				ui = CreateObject("roImageCanvas")
				ui.SetLayer(0, {Color: "#000000"})
				ui.show ()
				sleep(1)
				CreateObject("roAppManager").SetTheme(theme)
			if m.ItemId = "prefTheme" or m.ItemId = "theme_border" or m.itemId = "prefOptionsRow" or m.Itemid = "prefQuickJumpRow"
				m.ViewController.CreateHomeScreen()
				'm.viewcontroller.Home = m.viewcontroller.CreateHomeScreen()
			end if
		else if m.ItemId = "prefDelAll" then
			user = getGlobalVar("user")
			if user.isAdmin then
				RegWrite(m.itemId, prefSelected)
			else
				createDialog("Permission Error!", "You must be marked as an administrative user in order to change the delete option. Please see an administrator.", "OK", true)
			end if
	    	else if m.ItemId = "prefRememberUser"
			if prefSelected = "no" then
				if showRememberDialog() = "1" then
					RegWrite(m.itemId, prefSelected)
					'while m.ViewController.screens.Count() > 0
						'm.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
					'end while
					'm.viewcontroller.Logout()
				end if
			else
				RegWrite(m.itemId, prefSelected)
			end if
	    	else if m.ItemId = "prefinteraction"
			if prefSelected = "0" then
				user = getGlobalVar("user")
				if user.isAdmin then
					RegWrite(m.itemId, prefSelected)
				else
					createDialog("Permission Error!", "You must be marked as an administrative user in order to disable the Interaction Timeout. Please see an administrator.", "OK", true)
				end if
			else
				RegWrite(m.itemId, prefSelected)
			end if
		else
			RegWrite(m.itemId, prefSelected)
		end if

	    end if

	m.Screen.Close()

        End If
    End If

	if handled = false then
		handled = m.baseHandleMessage(msg)
	end If

	return handled

End Function

Function showRememberDialog()
	return showContextViewMenuYesNoDialog("Don't Remember User?", "Are you sure you want to always use a login screen?" + chr(10))
End Function

'**********************************************************
'** Refresh Preferences Page
'**********************************************************

Function RefreshPreferencesPage(screen As Object) As Object

    ' Get Data
    preferenceList = GetPreferenceList()

    ' Show Screen
    screen.SetContent(preferenceList)

    return preferenceList
End Function


'**********************************************************
'** Get Selected Preference
'**********************************************************

Function GetSelectedPreference(list As Object, selected) as String

    if validateParam(list, "roArray", "GetSelectedPreference") = false return -1

    index = 0
    defaultIndex = 0

    For each itemData in list
        ' Find Default Index
        If itemData.IsDefault Then
            defaultIndex = index
        End If

        If itemData.Id = selected Then
            return itemData.Title
        End If

        index = index + 1
    End For

    ' Nothing selected, return default item
    return list[defaultIndex].Title
End Function


'**********************************************************
'** Get Main Preferences List
'**********************************************************

Function GetPreferenceList() as Object

	viewController = GetViewController()
	device = CreateObject("roDeviceInfo")
	modelName = device.GetModelDisplayName()

	' Get device software version
	version = device.GetVersion()
	major = Mid(version, 3, 1).toInt()
	minor = Mid(version, 5, 2).toInt()
	build = Mid(version, 8, 5).toInt()

	displayname = FirstOf(RegRead("prefDisplayName"),"")
	if displayname = ""
		displayname = firstOf(GetGlobalVar("rokuModelName"), "Unknown")
	end if

	' firmware 6
	if (major >=6 and minor >= 1) or major >= 7 then
		text1 = "Your device will correctly handle this automatically."
		text2 = "Firmware 6.1 and higher. Leave as NO!"
	else
		text1 = "Do you have 5.1 Surround sound, but only in Dolby?"
		text2 = "NO DTS? You MUST enable this"
	end if
	
    preferenceList = [
        {
            Title: modelName + " Display Name: " + displayname,
            ShortTitle: "Name your " + modelName + ".",
            ID: "prefDisplayName",
            ContentType: "pref",
			PrefType: "custom",
            ShortDescriptionLine1: "What is the name of this " + modelName + "?",
            ShortDescriptionLine2: "Leave blank = roku.com name",
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Local Quality: " + GetSelectedPreference(GetPreferenceVideoQuality(), RegRead("prefVideoQuality")),
            ShortTitle: "Maximum local video quality?",
            ID: "prefVideoQuality",
            ContentType: "pref",
			PrefType: "list",
            ShortDescriptionLine1: "What is the maximum quality of local video streams?",
            ShortDescriptionLine2: "Low values can cause transcoding!",
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Remote Quality: " + GetSelectedPreference(GetPreferenceVideoQuality(), RegRead("prefremoteVideoQuality")),
            ShortTitle: "Maximum remote video quality?",
            ID: "prefremoteVideoQuality",
            ContentType: "pref",
			PrefType: "list",
            ShortDescriptionLine1: "What is the maximum quality of remote video streams?",
            ShortDescriptionLine2: "Low values can cause transcoding!",
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "LiveTV Quality: " + GetSelectedPreference(GetPreferenceVideoQuality(), RegRead("preflivetvVideoQuality")),
            ShortTitle: "Maximum livetv video quality?",
            ID: "preflivetvVideoQuality",
            ContentType: "pref",
			PrefType: "list",
            ShortDescriptionLine1: "What is the maximum quality of liveTV video streams?",
            ShortDescriptionLine2: "Low values can cause transcoding!",
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Stream Resolution: " + GetSelectedPreference(GetPreferenceResolution(), firstOf(RegRead("prefreso"), "auto")),
            ShortTitle: "Stream Resolution?",
            ID: "prefreso",
            ContentType: "pref",
            PrefType: "list",
            ShortDescriptionLine1: "Maximum resolution allowed when transcoding?",
            ShortDescriptionLine2: "Auto, 1080p or 720p"
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "VideoPlayer Timeout: " + GetSelectedPreference(GetPreferenceVPlayerTimeout(), RegRead("prefvtimeout")),
            ShortTitle: "VideoPlayer Timeout",
            ID: "prefvtimeout",
            ContentType: "pref",
			PrefType: "list",
            ShortDescriptionLine1: "What is the maximum timeout for the videoplayer?",
            ShortDescriptionLine2: "Set this higher if you have issues",
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Options Row: " + GetSelectedPreference(GetPreferenceOptionsRow(), RegRead("prefOptionsRow")),
            ShortTitle: "Options Row Placement",
            ID: "prefOptionsRow",
            ContentType: "pref",
			PrefType: "list",
            ShortDescriptionLine1: "Where should the Options row be located?",
            ShortDescriptionLine2: "Top, Bottom, or Both",
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Continuous Play: " + GetSelectedPreference(GetPreferenceContinuous(), RegRead("prefContPlay")),
            ShortTitle: "Allow Continuous Play?",
            ID: "prefContPlay",
            ContentType: "pref",
			PrefType: "list",
            ShortDescriptionLine1: "Should Continuous Play be used in app?",
            ShortDescriptionLine2: "YES, NO, NO+Resume",
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Options Buttons: " + GetSelectedPreference(GetPreferenceBlingPlace(), RegRead("prefBlingPlace")),
            ShortTitle: "Options Buttons Placement",
            ID: "prefBlingPlace",
            ContentType: "pref",
			PrefType: "list",
            ShortDescriptionLine1: "Which ordering for the Options buttons should be used?",
            ShortDescriptionLine2: "Original or Bling",
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Quick Launch Row: " + GetSelectedPreference(GetPreferenceQuickJumpRow(), RegRead("prefQuickJumpRow")),
            ShortTitle: "Allow Quick Launch",
            ID: "prefQuickJumpRow",
            ContentType: "pref",
			PrefType: "list",
            ShortDescriptionLine1: "Show a Quicklaunch Row to launch other apps?",
            ShortDescriptionLine2: "Yes or No",
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Enable Debug: " + GetSelectedPreference(GetPreferenceStopMusic(), RegRead("prefenabledebug")),
            ShortTitle: "Enable Debug?",
            ID: "prefenabledebug",
            ContentType: "pref",
			PrefType: "list",
            ShortDescriptionLine1: "Would you like to enable debug logging?",
            ShortDescriptionLine2: "Help troubleshoot the app!",
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Stop Music: " + GetSelectedPreference(GetPreferenceStopMusic(), RegRead("prefStopMusic")),
            ShortTitle: "Stop Music?",
            ID: "prefStopMusic",
            ContentType: "pref",
			PrefType: "list",
            ShortDescriptionLine1: "Stop music when leaving the Music Screen?",
            ShortDescriptionLine2: "No lets music keep playing!",
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Stop Theme Music: " + GetSelectedPreference(GetPreferenceStopMusic(), RegRead("prefStopThemeMusic")),
            ShortTitle: "Stop Music?",
            ID: "prefStopThemeMusic",
            ContentType: "pref",
			PrefType: "list",
            ShortDescriptionLine1: "Stop music when leaving the each Screen?",
            ShortDescriptionLine2: "No lets music keep playing!",
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Genre/Studio/Artist Max: " + GetSelectedPreference(GetPreferenceGenreStudio(), RegRead("prefgenrestudio")),
            ShortTitle: "Genre/Studio/Artist Max?",
            ID: "prefgenrestudio",
            ContentType: "pref",
			PrefType: "list",
            ShortDescriptionLine1: "How many tracks should appear when using by genre/studio/artist?",
            ShortDescriptionLine2: "Higher values = Longer loading",
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Search Max: " + GetSelectedPreference(GetPreferenceSearchMax(), RegRead("prefsearchmax")),
            ShortTitle: "Search Max?",
            ID: "prefsearchmax",
            ContentType: "pref",
			PrefType: "list",
            ShortDescriptionLine1: "How many items per row should the search screen return?",
            ShortDescriptionLine2: "Higher values = Longer loading",
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Episodes Max: " + GetSelectedPreference(GetPreferenceEpisodesMax(), RegUserRead("prefepisodesmax")),
            ShortTitle: "Episodes Max?",
            ID: "prefepisodesmax",
            ContentType: "pref",
			PrefType: "list",
            ShortDescriptionLine1: "How many episodes should the latest view return?",
            ShortDescriptionLine2: "Higher values = Longer loading",
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Fallback Retries: " + GetSelectedPreference(GetPreferenceFallbackRetry(), RegRead("preffallbackretry")),
            ShortTitle: "Fallback on Error Retries?",
            ID: "preffallbackretry",
            ContentType: "pref",
			PrefType: "list",
            ShortDescriptionLine1: "How many errors should the videoplayer work through?",
            ShortDescriptionLine2: "Higher values = More retries",
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Custom In-Order: " + GetSelectedPreference(GetPreferenceCustominOrder(), RegRead("prefcustominorder")),
            ShortTitle: "Custom In-Order Items?",
            ID: "prefcustominorder",
            ContentType: "pref",
			PrefType: "list",
            ShortDescriptionLine1: "How many items play for your custom in-order button?",
            ShortDescriptionLine2: "This affects continuous play",
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Play Theme Music: " + GetSelectedPreference(GetPreferenceTVThemeMusic(), RegRead("prefThemeMusic")),
            ShortTitle: "Play Theme Music?",
            ID: "prefThemeMusic",
            ContentType: "pref",
			PrefType: "list",
            ShortDescriptionLine1: "Play theme music while browsing the library?",
            ShortDescriptionLine2: "This can interfere with the music player!",
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Repeat Theme Music: " + GetSelectedPreference(GetPreferenceTVThemeMusicRepeat(), RegRead("prefThemeMusicLoop")),
            ShortTitle: "Repeat Theme Music?",
            ID: "prefThemeMusicLoop",
            ContentType: "pref",
			PrefType: "list",
            ShortDescriptionLine1: "Repeat theme music while browsing the library?",
            ShortDescriptionLine2: "This can interfere with the music player!",
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
	{
            Title: "Disable Cinema Mode: " + GetSelectedPreference(GetPreferenceTVThemeMusicRepeat(), RegRead("prefDisableCinema")),
            ShortTitle: "Disable Cinema Mode?",
            ID: "prefDisableCinema",
            ContentType: "pref",
			PrefType: "list",
            ShortDescriptionLine1: "Would you like to disable cinema mode?",
            ShortDescriptionLine2: "no trailer/intro preplay",
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Abbreviate Runtimes: " + GetSelectedPreference(GetPreferenceTVThemeMusicRepeat(), RegRead("prefAbbreviate")),
            ShortTitle: "Abbreviate Runtimes?",
            ID: "prefAbbreviate",
            ContentType: "pref",
			PrefType: "list",
            ShortDescriptionLine1: "Abbreviate runtimes when shown?",
            ShortDescriptionLine2: "NO 1:15:04 | YES 1h15m",
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Remember User: " + GetSelectedPreference(GetPreferenceRememberUser(), RegRead("prefRememberUser")),
            ShortTitle: "Remember User?",
            ID: "prefRememberUser",
            ContentType: "pref",
			PrefType: "list",
            ShortDescriptionLine1: "Remember the current logged in user?",
            ShortDescriptionLine2: "Next time the server remembers you",
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Confirm Before Exit: " + GetSelectedPreference(GetPreferenceExit(), RegRead("prefExit")),
            ShortTitle: "Confirm Before Exit?",
            ID: "prefExit",
            ContentType: "pref",
			PrefType: "list",
            ShortDescriptionLine1: "Confirm YES with a dialog before exiting?",
            ShortDescriptionLine2: "No accidental exits",
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Reset Play Method: " + GetSelectedPreference(GetPreferenceExit(), RegRead("prefResetMethod")),
            ShortTitle: "Reset Play Method?",
            ID: "prefResetMethod",
            ContentType: "pref",
			PrefType: "list",
            ShortDescriptionLine1: "Reset the play method when exiting the video player?",
            ShortDescriptionLine2: "Reset to Auto Detection",
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Interaction Timeout: " + GetSelectedPreference(GetPreferenceInteraction(), RegRead("prefinteraction")),
            ShortTitle: "Interaction Timeout?",
            ID: "prefinteraction",
            ContentType: "pref",
			PrefType: "list",
            ShortDescriptionLine1: "How long to play videos before interaction is required?",
            ShortDescriptionLine2: "Inactivity Timer",
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Allow Delete: " + GetSelectedPreference(GetPreferenceDelEps(), RegRead("prefDelAll")),
            ShortTitle: "Allow Delete?",
            ID: "prefDelAll",
            ContentType: "pref",
			PrefType: "list",
            ShortDescriptionLine1: "Allow for PERMANENTLY deleting items from your entire media library?",
            ShortDescriptionLine2: "USE THIS AT YOUR OWN RISK!",
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Hide Latest Items: " + GetSelectedPreference(GetPreferenceShowClock(), RegUserRead("prefRemWatch")),
            ShortTitle: "Hide watched items from latest?",
            ID: "prefRemWatch",
            ContentType: "pref",
			PrefType: "list",
            ShortDescriptionLine1: "Hide watched items from latest?",
            ShortDescriptionLine2: "No means watched are visible",
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Hide Suggested Items: " + GetSelectedPreference(GetPreferenceShowClock(), RegUserRead("prefRemWatchSug")),
            ShortTitle: "Hide watched items from suggested?",
            ID: "prefRemWatchSug",
            ContentType: "pref",
			PrefType: "list",
            ShortDescriptionLine1: "Hide watched items from suggested?",
            ShortDescriptionLine2: "No means watched are visible",
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Latest Row: " + GetSelectedPreference(GetPreferenceLatest(), RegUserRead("preflatest")),
            ShortTitle: "Which Fetch for Latest?",
            ID: "preflatest",
            ContentType: "pref",
			PrefType: "list",
            ShortDescriptionLine1: "Choose which URL will populate your latest row?",
            ShortDescriptionLine2: "For ADVANCED users",
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Use CoverArt: " + GetSelectedPreference(GetPreferenceEnhancedImages(), RegRead("prefEnhancedImages")),
            ShortTitle: "Use CoverArt?",
            ID: "prefEnhancedImages",
            ContentType: "pref",
			PrefType: "list",
            ShortDescriptionLine1: "Use Enhanced Images such as Cover Art?",
            ShortDescriptionLine2: "This requires being a supporter",
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Use Media Indicators: " + GetSelectedPreference(GetPreferenceMediaIndicators(), RegRead("prefMediaIndicators")),
            ShortTitle: "Use Media Indicators?",
            ID: "prefMediaIndicators",
            ContentType: "pref",
			PrefType: "list",
            ShortDescriptionLine1: "Use visible media indicators on images?",
            ShortDescriptionLine2: "See played and percent played",
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Show Clock: " + GetSelectedPreference(GetPreferenceShowClock(), RegRead("prefShowClock")),
            ShortTitle: "Show Clock?",
            ID: "prefShowClock",
            ContentType: "pref",
            PrefType: "list",
            ShortDescriptionLine1: "Show or hide clock?",
            ShortDescriptionLine2: "Creates a Homescreen clock",
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Time Format: " + GetSelectedPreference(GetPreferenceTimeFormat(), RegRead("prefTimeFormat")),
            ShortTitle: "Time Format",
            ID: "prefTimeFormat",
            ContentType: "pref",
            PrefType: "list",
            ShortDescriptionLine1: "Use 12h or 24h time format?",
            ShortDescriptionLine2: "Affects Homescreen and Last on",
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Show Missing Seasons: " + GetSelectedPreference(GetPreferenceShowMiss(), RegRead("prefShowMiss")),
            ShortTitle: "Show Missing Seasons?",
            ID: "prefShowMiss",
            ContentType: "pref",
            PrefType: "list",
            ShortDescriptionLine1: "Use Missing Seasons?",
            ShortDescriptionLine2: "Show Seasons with all episodes missing",
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Show Upcoming Seasons: " + GetSelectedPreference(GetPreferenceShowUp(), RegRead("prefShowUp")),
            ShortTitle: "Show Upcoming Seasons?",
            ID: "prefShowUp",
            ContentType: "pref",
            PrefType: "list",
            ShortDescriptionLine1: "Use Upcoming Seasons?",
            ShortDescriptionLine2: "Show Seasons with all episodes upcoming",

            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Enhanced Descriptions: " + GetSelectedPreference(GetPreferenceUseTwoDesc(), RegUserRead("prefTwoDesc")),
            ShortTitle: "Use enhanced descriptions?",
            ID: "prefTwoDesc",
            ContentType: "pref",
            PrefType: "list",
            ShortDescriptionLine1: "Use enhanced descriptions to give extra detail?",
            ShortDescriptionLine2: "This does not affect poster images",

            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Detailed Statistics: " + GetSelectedPreference(GetPreferenceDetailStats(), RegUserRead("prefDetailStats")),
            ShortTitle: "Use detailed statistics?",
            ID: "prefDetailStats",
            ContentType: "pref",
            PrefType: "list",
            ShortDescriptionLine1: "Allow descriptions to contain statistics?",
            ShortDescriptionLine2: "Shows Mediatype, Watched, Last On",

            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Slideshow Overlay: " + GetSelectedPreference(GetPreferenceSlideshow(), firstOf(RegRead("slideshow_overlay"), "2500")),
            ShortTitle: "Slideshow Overlay",
            ID: "slideshow_overlay",
            ContentType: "pref",
            PrefType: "list",
            ShortDescriptionLine1: "How many seconds to show the overlay during a slideshow?",
            ShortDescriptionLine2: "Choosing 0 disables the overlay",
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Slideshow Period: " + GetSelectedPreference(GetPreferenceSlideDuration(), firstOf(RegRead("slideshow_duration"), "6")),
            ShortTitle: "Slideshow Period",
            ID: "slideshow_period",
            ContentType: "pref",
            PrefType: "list",
            ShortDescriptionLine1: "How many seconds to show each slide during a slideshow?",
            ShortDescriptionLine2: "Lower is faster, Higher is slower",
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Enable HD Audio Test: " + GetSelectedPreference(GetPreferenceEnableTrueHD(), firstOf(RegRead("truehdtest"), "0")),
            ShortTitle: "Dolby TrueHD/DTS-HD 7.1 pass-thru?",
            ID: "truehdtest",
            ContentType: "pref",
            PrefType: "list",
            ShortDescriptionLine1: "Would you like to enable Dolby TrueHD/DTS-HD 7.1 pass-thru test?",
            ShortDescriptionLine2: "This is for newer roku models.",
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "DD+ Pass-Through: " + GetSelectedPreference(GetPreferenceDDPlus(), firstOf(RegRead("prefddplus"), "1")),
            ShortTitle: "Allow DD+ Pass-Through?",
            ID: "prefddplus",
            ContentType: "pref",
            PrefType: "list",
            ShortDescriptionLine1: "Allow DD+ Pass-Through if detected?",
            ShortDescriptionLine2: "Auto or Off",
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "AAC Downsample: " + GetSelectedPreference(GetPreferenceDDPlus(), firstOf(RegRead("prefaac2"), "1")),
            ShortTitle: "AAC Downsample?",
            ID: "prefaac2",
            ContentType: "pref",
            PrefType: "list",
            ShortDescriptionLine1: "Allow AAC 5.1 to be downsampled by the device if detected?",
            ShortDescriptionLine2: "Auto or Off",
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Maximum RefFrames: " + GetSelectedPreference(GetPreferenceMaxRefs(), firstOf(RegRead("prefmaxrefs"), "12")),
            ShortTitle: "Max Ref frames for h264?",
            ID: "prefmaxrefs",
            ContentType: "pref",
            PrefType: "list",
            ShortDescriptionLine1: "What is the maximum reference frames allowed for auto-detection?",
            ShortDescriptionLine2: "Min=5, Max=16",
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "h264 MAX Transcode Level: " + GetSelectedPreference(GetPreferenceMaxLevel(), firstOf(RegRead("prefmaxlevel"), "51")),
            ShortTitle: "Max Transcode Level for h264?",
            ID: "prefmaxlevel",
            ContentType: "pref",
            PrefType: "list",
            ShortDescriptionLine1: "What is the maximum level you wish to set for h264 transcoding?",
            ShortDescriptionLine2: "This can help rokuTV",
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "h264/MPEG4 in 4k: " + GetSelectedPreference(GetPreferenceEnableTrueHD(), firstOf(RegRead("prefgo4k"), "0")),
            ShortTitle: "Pass 4k in h264/MPEG4?",
            ID: "prefgo4k",
            ContentType: "pref",
            PrefType: "list",
            ShortDescriptionLine1: "Would you like to enable 4k resolution to pass thru in h264 and MPEG4?",
            ShortDescriptionLine2: "This is for newer roku models."
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Auto Direct-Play Flash: " + GetSelectedPreference(GetPreferencedirectFlash(), firstOf(RegRead("prefdirectFlash"), "0")),
            ShortTitle: "Direct-Play Flash Video?",
            ID: "prefdirectFlash",
            ContentType: "pref",
            PrefType: "list",
            ShortDescriptionLine1: "Do you want to automatically direct-play flash video?",
            ShortDescriptionLine2: "This may not work correctly"
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Convert DTS to AC3: " + GetSelectedPreference(GetPreferenceDTStoAC3(), firstOf(RegRead("prefDTStoAC3"), "0")),
            ShortTitle: "Convert DTS to AC3?",
            ID: "prefDTStoAC3",
            ContentType: "pref",
            PrefType: "list",
            ShortDescriptionLine1: text1,
            ShortDescriptionLine2: text2,
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Convert MPEG4 to h264: " + GetSelectedPreference(GetPreferenceOnlyh264(), firstOf(RegRead("prefonlyh264"), "1")),
            ShortTitle: "Convert non-MKV MPEG4 to h264?",
            ID: "prefonlyh264",
            ContentType: "pref",
            PrefType: "list",
            ShortDescriptionLine1: "Use only h264 when transcoding non-MKV containers?",
            ShortDescriptionLine2: "NO allows MPEG4 to direct stream"
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Convert MP2/MP3 to AAC: " + GetSelectedPreference(GetPreferenceOnlyAAC(), firstOf(RegRead("prefonlyAAC"), "1")),
            ShortTitle: "Convert MP2/MP3 to AAC?",
            ID: "prefonlyAAC",
            ContentType: "pref",
            PrefType: "list",
            ShortDescriptionLine1: "Use only AAC when transcoding?",
            ShortDescriptionLine2: "NO allows MP2/MP3 to direct stream"
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Unknown Audio: " + GetSelectedPreference(GetPreferenceTransAC3(), firstOf(RegRead("prefTransAC3"), "aac")),
            ShortTitle: "Which Codec to use?",
            ID: "prefTransAC3",
            ContentType: "pref",
            PrefType: "list",
            ShortDescriptionLine1: "If Audio isnt known which codec should be used to transcode?",
            ShortDescriptionLine2: "Use AAC, MP3, or AC3"
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Default Audio: " + GetSelectedPreference(GetPreferenceTransAC3(), firstOf(RegRead("prefDefAudio"), "aac")),
            ShortTitle: "Which Codec to use?",
            ID: "prefDefAudio",
            ContentType: "pref",
            PrefType: "list",
            ShortDescriptionLine1: "What is the default audio codec for transcoding?",
            ShortDescriptionLine2: "Use AAC, MP3, or AC3"
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Convert AAC to MP3: " + GetSelectedPreference(GetPreferenceConvAAC(), firstOf(RegRead("prefConvAAC"), "aac")),
            ShortTitle: "Convert AAC to MP3?",
            ID: "prefConvAAC",
            ContentType: "pref",
            PrefType: "list",
            ShortDescriptionLine1: "When Transcoding, force AAC to MP3?",
            ShortDescriptionLine2: "Always use MP3 instead of AAC"
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Force Surround: " + GetSelectedPreference(GetPreferenceforceSurround(), firstOf(RegRead("prefforceSurround"), "0")),
            ShortTitle: "Force Surround Sound?",
            ID: "prefforceSurround",
            ContentType: "pref",
            PrefType: "list",
            ShortDescriptionLine1: "Force Surround Sound AC3 when transcoding?",
            ShortDescriptionLine2: "Convert AAC to AC3"
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Max Framerate: " + GetSelectedPreference(GetPreferenceMaxFrame(), firstOf(RegRead("prefmaxframe"), "30")),
            ShortTitle: "What is the Max Framerate?",
            ID: "prefmaxframe",
            ContentType: "pref",
            PrefType: "list",
            ShortDescriptionLine1: "What is the maximum framerate you want used for direct play?",
            ShortDescriptionLine2: "30 is recommended"
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Theme: " + GetSelectedPreference(GetPreferenceTheme(), RegRead("prefTheme")),
            ShortTitle: "Choose the theme used.",
            ID: "prefTheme",
            ContentType: "pref",
	    PrefType: "list",
            ShortDescriptionLine1: "Which theme do wish to use?",
            ShortDescriptionLine2: "Choosing resets view to the homescreen",
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Theme Color 1: " + GetSelectedPreference(GetPreferenceColor1(), firstOf(RegRead("theme_color1"), "#33CCFF")),
            ShortTitle: "Theme Color 1",
            ID: "theme_color1",
            ContentType: "pref",
	    PrefType: "list",
            ShortDescriptionLine1: "What color would you like for 1?",
            ShortDescriptionLine2: "Affects homescreen, among others",
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Theme Color 2: " + GetSelectedPreference(GetPreferenceColor2(), firstOf(RegRead("theme_color2"), "#75FF75")),
            ShortTitle: "Theme Color 2",
            ID: "theme_color2",
            ContentType: "pref",
			PrefType: "list",
            ShortDescriptionLine1: "What color would you like for 2?",
            ShortDescriptionLine2: "Affects homescreen, among others",
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Theme Color 3: " + GetSelectedPreference(GetPreferenceColor3(), firstOf(RegRead("theme_color3"), "#FFFFFF")),
            ShortTitle: "Theme Color 3",
            ID: "theme_color3",
            ContentType: "pref",
			PrefType: "list",
            ShortDescriptionLine1: "What color would you like for 3?",
            ShortDescriptionLine2: "Affects Title on description page",
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Theme Color 4: " + GetSelectedPreference(GetPreferenceColor3(), firstOf(RegRead("theme_color4"), "#FFFFFF")),
            ShortTitle: "Theme Color 4",
            ID: "theme_color4",
            ContentType: "pref",
			PrefType: "list",
            ShortDescriptionLine1: "What color would you like for 4?",
            ShortDescriptionLine2: "Affects Description on description page",
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        },
        {
            Title: "Theme Border: " + GetSelectedPreference(GetPreferenceBorder(), firstOf(RegRead("theme_border"), "1")),
            ShortTitle: "Theme Border",
            ID: "theme_border",
            ContentType: "pref",
			PrefType: "list",
            ShortDescriptionLine1: "Would you like a glowing border or the standard border?",
            ShortDescriptionLine2: "This will reset view back to the homescreen",
            HDBackgroundImageUrl: viewController.getThemeImageUrl("hd-preferences-lg.png"),
            SDBackgroundImageUrl: viewController.getThemeImageUrl("sd-preferences-lg.png")
        }
    ]

    return preferenceList
End Function


'**********************************************************
'** Get Preference Options
'**********************************************************

Function GetPreferenceVideoQuality() as Object
    prefOptions = [
        {
            Title: "3.2 Mbps HD [default]",
            Id: "3200",
            IsDefault: true
        },
        {
            Title: "70.0 Mbps UHD",
            Id: "70000",
            IsDefault: false
        },
        {
            Title: "65.0 Mbps UHD",
            Id: "65000",
            IsDefault: false
        },
        {
            Title: "60.0 Mbps UHD",
            Id: "60000",
            IsDefault: false
        },
        {
            Title: "55.0 Mbps UHD",
            Id: "55000",
            IsDefault: false
        },
        {
            Title: "50.0 Mbps UHD",
            Id: "50000",
            IsDefault: false
        },
        {
            Title: "45.0 Mbps UHD",
            Id: "45000",
            IsDefault: false
        },
        {
            Title: "40.0 Mbps UHD",
            Id: "40000",
            IsDefault: false
        },
        {
            Title: "35.0 Mbps UHD",
            Id: "35000",
            IsDefault: false
        },
        {
            Title: "30.0 Mbps HD",
            Id: "30000",
            IsDefault: false
        },
        {
            Title: "25.0 Mbps HD",
            Id: "25000",
            IsDefault: false
        },
        {
            Title: "20.0 Mbps HD",
            Id: "20000",
            IsDefault: false
        },
        {
            Title: "19 Mbps HD",
            Id: "19000",
            IsDefault: false
        },
        {
            Title: "18 Mbps HD",
            Id: "18000",
            IsDefault: false
        },
        {
            Title: "17 Mbps HD",
            Id: "17000",
            IsDefault: false
        },
        {
            Title: "16 Mbps HD",
            Id: "16000",
            IsDefault: false
        },
        {
            Title: "15 Mbps HD",
            Id: "15000",
            IsDefault: false
        },
        {
            Title: "14 Mbps HD",
            Id: "14000",
            IsDefault: false
        },
        {
            Title: "13 Mbps HD",
            Id: "13000",
            IsDefault: false
        },
        {
            Title: "12 Mbps HD",
            Id: "12000",
            IsDefault: false
        },
        {
            Title: "11 Mbps HD",
            Id: "11000",
            IsDefault: false
        },
        {
            Title: "10 Mbps HD",
            Id: "10000",
            IsDefault: false
        },
        {
            Title: "9 Mbps HD",
            Id: "9000",
            IsDefault: false
        },
        {
            Title: "8 Mbps HD",
            Id: "8000",
            IsDefault: false
        },
        {
            Title: "7 Mbps HD",
            Id: "7000",
            IsDefault: false
        },
        {
            Title: "6 Mbps HD",
            Id: "6000",
            IsDefault: false
        },
        {
            Title: "5 Mbps HD",
            Id: "5000",
            IsDefault: false
        },
        {
            Title: "4.5 Mbps HD",
            Id: "4500",
            IsDefault: false
        },
        {
            Title: "4 Mbps HD",
            Id: "4000",
            IsDefault: false
        },
        {
            Title: "3.5 Mbps HD",
            Id: "3500",
            IsDefault: false
        },
        {
            Title: "3 Mbps HD",
            Id: "3000",
            IsDefault: false
        },
        {
            Title: "2.75 Mbps HD",
            Id: "2750",
            IsDefault: false
        },
        {
            Title: "2.5 Mbps HD",
            Id: "2500",
            IsDefault: false
        },
        {
            Title: "2.25 Mbps HD",
            Id: "2250",
            IsDefault: false
        },
        {
            Title: "2.0 Mbps HD",
            Id: "2000",
            IsDefault: false
        },
        {
            Title: "1.75 Mbps HD",
            Id: "1750",
            IsDefault: false
        },
        {
            Title: "1.5 Mbps HD",
            Id: "1500",
            IsDefault: false
        },
        {
            Title: "1.25 Mbps HD",
            Id: "1250",
            IsDefault: false
        },
        {
            Title: "1 Mbps HD",
            Id: "1000",
            IsDefault: false
        },
        {
            Title: "750 Kbps SD",
            Id: "750",
            IsDefault: false
        },
        {
            Title: "500 Kbps SD",
            Id: "500",
            IsDefault: false
        }
    ]

    return prefOptions
End Function

Function GetPreferenceDDPlus() as Object
    prefOptions = [
        {
            Title: "Auto [default]",
            Id: "1",
            IsDefault: true
        },
        {
            Title: "Off",
            Id: "0",
            IsDefault: false
        }
    ]

    return prefOptions
End Function

Function GetPreferenceMaxRefs() as Object
    prefOptions = [
        {
            Title: "12 [default]",
            Id: "12",
            IsDefault: true
        },
        {
            Title: "5",
            Id: "5",
            IsDefault: false
        },
        {
            Title: "8",
            Id: "8",
            IsDefault: false
        },
        {
            Title: "15",
            Id: "15",
            IsDefault: false
        },
        {
            Title: "16",
            Id: "16",
            IsDefault: false
        }
    ]

    return prefOptions
End Function

Function GetPreferenceMaxLevel() as Object
    prefOptions = [
        {
            Title: "51 [default]",
            Id: "51",
            IsDefault: true
        },
        {
            Title: "50",
            Id: "50",
            IsDefault: false
        },
        {
            Title: "41",
            Id: "41",
            IsDefault: false
        },
        {
            Title: "40",
            Id: "40",
            IsDefault: false
        }
    ]

    return prefOptions
End Function

Function GetPreferenceResolution() as Object
    prefOptions = [
        {
            Title: "Auto [default]",
            Id: "auto",
            IsDefault: true
        },
        {
            Title: "1080p",
            Id: "1080p",
            IsDefault: false
        },
        {
            Title: "720p",
            Id: "720p",
            IsDefault: false
        }
    ]

    return prefOptions
End Function 

Function GetPreferenceOptionsRow() as Object
    prefOptions = [
        {
            Title: "Top [default]",
            Id: "0",
            IsDefault: true
        },
        {
            Title: "Bottom",
            Id: "1",
            IsDefault: false
        },
        {
            Title: "Both",
            Id: "2",
            IsDefault: false
        }
    ]

    return prefOptions
End Function


Function GetPreferenceBlingPlace() as Object
    prefOptions = [
        {
            Title: "Original [default]",
            Id: "0",
            IsDefault: true
        },
        {
            Title: "Bling",
            Id: "1",
            IsDefault: false
        }
    ]

    return prefOptions
End Function

Function GetPreferenceQuickJumpRow() as Object
    prefOptions = [
        {
            Title: "No [default]",
            Id: "0",
            IsDefault: true
        },
        {
            Title: "Yes",
            Id: "1",
            IsDefault: false
        }
    ]

    return prefOptions
End Function

Function GetPreferenceStopMusic() as Object
    prefOptions = [
        {
            Title: "No [default]",
            Id: "false",
            IsDefault: true
        },
        {
            Title: "Yes",
            Id: "true",
            IsDefault: false
        }
    ]

    return prefOptions
End Function

Function GetPreferenceTVThemeMusic() as Object
    prefOptions = [
        {
            Title: "Yes [default]",
            Id: "yes",
            IsDefault: true
        },
        {
            Title: "No",
            Id: "no",
            IsDefault: false
        }
    ]

    return prefOptions
End Function

Function GetPreferenceTheme() as Object
    prefOptions = [
        {
            Title: "Emby Blue Neon Night [default]",
            Id: "1",
            IsDefault: true
        },
        {
            Title: "Emby Standard",
            Id: "0",
            IsDefault: false
        }
    ]

    return prefOptions
End Function

Function GetPreferenceUseTwoDesc() as Object
    prefOptions = [
        {
            Title: "Yes [default]",
            Id: "1",
            IsDefault: true
        },
        {
            Title: "No",
            Id: "0",
            IsDefault: false
        }
    ]

    return prefOptions
End Function

Function GetPreferenceDetailStats() as Object
    prefOptions = [
        {
            Title: "Yes [default]",
            Id: "1",
            IsDefault: true
        },
        {
            Title: "No",
            Id: "0",
            IsDefault: false
        }
    ]

    return prefOptions
End Function

Function GetPreferenceShowMiss() as Object
    prefOptions = [
        {
            Title: "Yes [default]",
            Id: "true",
            IsDefault: true
        },
        {
            Title: "No",
            Id: "false",
            IsDefault: false
        }
    ]

    return prefOptions
End Function

Function GetPreferenceShowUp() as Object
    prefOptions = [
        {
            Title: "Yes [default]",
            Id: "true",
            IsDefault: true
        },
        {
            Title: "No",
            Id: "false",
            IsDefault: false
        }
    ]

    return prefOptions
End Function

Function GetPreferenceTVThemeMusicRepeat() as Object
    prefOptions = [
        {
            Title: "No [default]",
            Id: "no",
            IsDefault: true
        },
        {
            Title: "Yes",
            Id: "yes",
            IsDefault: false
        }
    ]

    return prefOptions
End Function

Function GetPreferenceContinuous() as Object
    prefOptions = [
        {
            Title: "Yes [default]",
            Id: "yes",
            IsDefault: true
        },
        {
            Title: "No",
            Id: "no",
            IsDefault: false
        },
        {
            Title: "No with Resume",
            Id: "no+",
            IsDefault: false
        }

    ]

    return prefOptions
End Function

Function GetPreferenceRememberUser() as Object
    prefOptions = [
        {
            Title: "Yes [default]",
            Id: "yes",
            IsDefault: true
        },
        {
            Title: "No",
            Id: "no",
            IsDefault: false
        }
    ]

    return prefOptions
End Function

Function GetPreferenceExit() as Object
    prefOptions = [
        {
            Title: "Yes [default]",
            Id: "1",
            IsDefault: true
        },
        {
            Title: "No",
            Id: "0",
            IsDefault: false
        }
    ]

    return prefOptions
End Function

Function GetPreferenceDelEps() as Object
    prefOptions = [
        {
            Title: "No [default]",
            Id: "0",
            IsDefault: true
        },
        {
            Title: "Yes",
            Id: "1",
            IsDefault: false
        }
    ]

    return prefOptions
End Function

Function GetPreferenceInteraction() as Object
    prefOptions = [
        {
            Title: "5 hours [default]",
            Id: "18000",
            IsDefault: true
        },
        {
            Title: "4 hours",
            Id: "14400",
            IsDefault: false
        },
        {
            Title: "3 hours",
            Id: "10800",
            IsDefault: false
        },
        {
            Title: "2 hours",
            Id: "7200",
            IsDefault: false
        },
        {
            Title: "1 hour",
            Id: "3600",
            IsDefault: false
        },
        {
            Title: "30 minutes",
            Id: "1800",
            IsDefault: false
        },
        {
            Title: "5 minutes (test)",
            Id: "300",
            IsDefault: false
        },
        {
            Title: "30 seconds (test)",
            Id: "30",
            IsDefault: false
        },
        {
            Title: "Disabled",
            Id: "0",
            IsDefault: false
        }
    ]

    return prefOptions
End Function

Function GetPreferenceEnhancedImages() as Object
    prefOptions = [
        {
            Title: "Yes [default]",
            Id: "yes",
            IsDefault: true
        },
        {
            Title: "No",
            Id: "no",
            IsDefault: false
        }
    ]

    return prefOptions
End Function

Function GetPreferenceMediaIndicators() as Object
    prefOptions = [
        {
            Title: "Yes [default]",
            Id: "yes",
            IsDefault: true
        },
        {
            Title: "No",
            Id: "no",
            IsDefault: false
        }
    ]

    return prefOptions
End Function

Function GetPreferenceShowClock() as Object
    prefOptions = [
        {
            Title: "Yes [default]",
            Id: "yes", 
            IsDefault: true
        },
        {
            Title: "No",
            Id: "no",
            IsDefault: false
        }
    ]

    return prefOptions
End Function

Function GetPreferenceTimeFormat() as Object
    prefOptions = [
        {
            Title: "12h [default]",
            Id: "12h",
            IsDefault: true
        },
        {
            Title: "24h",
            Id: "24h",
            IsDefault: false
        }
    ]

    return prefOptions
End Function

Function GetPreferenceVPlayerTimeout() as Object
    prefOptions = [
        {
            Title: "30s [default]",
            Id: "30",
            IsDefault: true
        },
        {
            Title: "45s",
            Id: "45",
            IsDefault: false
        },
        {
            Title: "1m",
            Id: "60",
            IsDefault: false
        },
        {
            Title: "1m15s",
            Id: "75",
            IsDefault: false
        },
        {
            Title: "1m30s",
            Id: "90",
            IsDefault: false
        },
        {
            Title: "1m45s",
            Id: "105",
            IsDefault: false
        },
        {
            Title: "2m",
            Id: "120",
            IsDefault: false
        },
        {
            Title: "2m30s",
            Id: "150",
            IsDefault: false
        },
        {
            Title: "3m",
            Id: "180",
            IsDefault: false
        },
        {
            Title: "3m30s",
            Id: "210",
            IsDefault: false
        },
        {
            Title: "4m",
            Id: "240",
            IsDefault: false
        }
    ]

    return prefOptions
End Function

Function GetPreferenceSlideshow() as Object
    prefOptions = [
        {
            Title: "2.5 seconds [default]",
            Id: "2500",
            IsDefault: true
        },
        {
            Title: "0 (Never Show)",
            Id: "0",
            IsDefault: false
        },
        {
            Title: "1 second",
            Id: "1000",
            IsDefault: false
        },
        {
            Title: "2 seconds",
            Id: "2000",
            IsDefault: false
        },
        {
            Title: "5 seconds",
            Id: "5000",
            IsDefault: false
        }
    ]

    return prefOptions
End Function

Function GetPreferenceSlideDuration() as Object
    prefOptions = [
        {
            Title: "6 seconds [default]",
            Id: "6",
            IsDefault: true
        },
        {
            Title: "20 seconds",
            Id: "20",
            IsDefault: false
        },
        {
            Title: "15 seconds",
            Id: "15",
            IsDefault: false
        },
        {
            Title: "10 seconds",
            Id: "10",
            IsDefault: false
        },
        {
            Title: "8 seconds",
            Id: "8",
            IsDefault: false
        },
        {
            Title: "4 seconds",
            Id: "4",
            IsDefault: false
        },
        {
            Title: "2 seconds",
            Id: "2",
            IsDefault: false
        }
    ]

    return prefOptions
End Function

Function GetPreferenceEnableTrueHD() as Object
    prefOptions = [
        {
            Title: "No [default]",
            Id: "0",
            IsDefault: true
        },
        {
            Title: "Yes",
            Id: "1", 
            IsDefault: false
        }
    ]

    return prefOptions
End Function

Function GetPreferenceDTStoAC3() as Object
    prefOptions = [
        {
            Title: "No [default]",
            Id: "0",
            IsDefault: true
        },
        {
            Title: "Yes",
            Id: "1",
            IsDefault: false
        }
    ]

    return prefOptions
End Function

Function GetPreferenceOnlyh264() as Object
    prefOptions = [
        {
            Title: "Yes [default]",
            Id: "1",
            IsDefault: true
        },
        {
            Title: "No",
            Id: "0",
            IsDefault: false
        }
    ]

    return prefOptions
End Function

Function GetPreferenceLatest() as Object
    prefOptions = [
        {
            Title: "/items [default]",
            Id: "0",
            IsDefault: true
        },
        {
            Title: "/items/latest",
            Id: "1",
            IsDefault: false
        },
        {
            Title: "/items/latest + Group",
            Id: "2",
            IsDefault: false
        }
    ]

    return prefOptions
End Function

Function GetPreferencedirectFlash() as Object
    prefOptions = [
        {
            Title: "No [default]",
            Id: "0",
            IsDefault: true
        },
        {
            Title: "Yes",
            Id: "1",
            IsDefault: false
        }
    ]

    return prefOptions
End Function

Function GetPreferenceOnlyAAC() as Object
    prefOptions = [
        {
            Title: "Yes [default]",
            Id: "1",
            IsDefault: true
        },
        {
            Title: "No",
            Id: "0",
            IsDefault: false
        }
    ]

    return prefOptions
End Function

Function GetPreferenceTransAC3() as Object
    prefOptions = [
        {
            Title: "Use AAC audio [default]",
            Id: "aac",
            IsDefault: true
        },
        {
            Title: "Use MP3",
            Id: "mp3",
            IsDefault: false
        },
        {
            Title: "Use AC3",
            Id: "ac3",
            IsDefault: false
        }
    ]
    return prefOptions
End Function


Function GetPreferenceforceSurround() as Object
    prefOptions = [
        {
            Title: "No [default]",
            Id: "0",
            IsDefault: true
        },
        {
            Title: "Yes",
            Id: "1",
            IsDefault: false
        }
    ]
    return prefOptions
End Function

Function GetPreferenceFallbackRetry() as Object
    prefOptions = [
        {
            Title: "1 [default]",
            Id: "1",
            IsDefault: true
        },
        {
            Title: "0 [none]",
            Id: "0",
            IsDefault: false
        },
        {
            Title: "2",
            Id: "2",
            IsDefault: false
        },
        {
            Title: "3",
            Id: "3",
            IsDefault: false
        },
        {
            Title: "5",
            Id: "5",
            IsDefault: false
        },
        {
            Title: "7",
            Id: "7",
            IsDefault: false
        },
        {
            Title: "99 [max]",
            Id: "99",
            IsDefault: false
        }
    ]
    return prefOptions
End Function

Function GetPreferenceCustominOrder() as Object
    prefOptions = [
        {
            Title: "3 [default]",
            Id: "3",
            IsDefault: true
        },
        {
            Title: "7",
            Id: "7",
            IsDefault: false
        },
        {
            Title: "6",
            Id: "6",
            IsDefault: false
        },
        {
            Title: "5",
            Id: "5",
            IsDefault: false
        },
        {
            Title: "4",
            Id: "4",
            IsDefault: false
        },
        {
            Title: "2",
            Id: "2",
            IsDefault: false
        }
    ]
    return prefOptions
End Function

Function GetPreferenceGenreStudio() as Object
    prefOptions = [
        {
            Title: "200 [default]",
            Id: "200",
            IsDefault: true
        },
        {
            Title: "50",
            Id: "50",
            IsDefault: false
        },
        {
            Title: "100",
            Id: "100",
            IsDefault: false
        },
        {
            Title: "300",
            Id: "300",
            IsDefault: false
        },
        {
            Title: "400",
            Id: "400",
            IsDefault: false
        },
        {
            Title: "500",
            Id: "500",
            IsDefault: false
        },
        {
            Title: "1000",
            Id: "1000",
            IsDefault: false
        },
        {
            Title: "1500",
            Id: "1500",
            IsDefault: false
        },
        {
            Title: "2000",
            Id: "2000",
            IsDefault: false
        },
        {
            Title: "2500",
            Id: "2500",
            IsDefault: false
        },
        {
            Title: "5000",
            Id: "5000",
            IsDefault: false
        },
        {
            Title: "0 (No Limit)",
            Id: "0",
            IsDefault: false
        }

    ]

    return prefOptions
End Function

Function GetPreferenceSearchMax() as Object
    prefOptions = [
        {
            Title: "50 [default]",
            Id: "50",
            IsDefault: true
        },
        {
            Title: "25",
            Id: "25",
            IsDefault: false
        },
        {
            Title: "75",
            Id: "75",
            IsDefault: false
        },
        {
            Title: "100",
            Id: "100",
            IsDefault: false
        },
        {
            Title: "125",
            Id: "125",
            IsDefault: false
        },
        {
            Title: "150",
            Id: "150",
            IsDefault: false
        },
        {
            Title: "175",
            Id: "175",
            IsDefault: false
        },
        {
            Title: "200",
            Id: "200",
            IsDefault: false
        },
        {
            Title: "250",
            Id: "250",
            IsDefault: false
        },
        {
            Title: "300",
            Id: "300",
            IsDefault: false
        },
        {
            Title: "350",
            Id: "350",
            IsDefault: false
        },
        {
            Title: "500",
            Id: "500",
            IsDefault: false
        }

    ]

    return prefOptions
End Function

Function GetPreferenceEpisodesMax() as Object
    prefOptions = [
        {
            Title: "100 [default]",
            Id: "100",
            IsDefault: true
        },
        {
            Title: "200",
            Id: "200",
            IsDefault: false
        },
        {
            Title: "300",
            Id: "300",
            IsDefault: false
        },
        {
            Title: "400",
            Id: "400",
            IsDefault: false
        },
        {
            Title: "500",
            Id: "500",
            IsDefault: false
        },
        {
            Title: "750",
            Id: "750",
            IsDefault: false
        },
        {
            Title: "1000",
            Id: "1000",
            IsDefault: false
        },
        {
            Title: "1500",
            Id: "1500",
            IsDefault: false
        }

    ]

    return prefOptions
End Function

Function GetPreferenceInstantMix() as Object
    prefOptions = [
        {
            Title: "100 [default]",
            Id: "100",
            IsDefault: true
        },
        {
            Title: "50",
            Id: "50",
            IsDefault: false
        },
        {
            Title: "200",
            Id: "200",
            IsDefault: false
        },
        {
            Title: "300",
            Id: "300",
            IsDefault: false
        },
        {
            Title: "400",
            Id: "400",
            IsDefault: false
        },
        {
            Title: "500",
            Id: "500",
            IsDefault: false
        },
        {
            Title: "1000",
            Id: "1000",
            IsDefault: false
        },
        {
            Title: "1500",
            Id: "1500",
            IsDefault: false
        },
        {
            Title: "2000",
            Id: "2000",
            IsDefault: false
        },
        {
            Title: "2500",
            Id: "2500",
            IsDefault: false
        },
        {
            Title: "5000",
            Id: "5000",
            IsDefault: false
        }

    ]

    return prefOptions
End Function

Function GetPreferenceMaxFrame() as Object
    prefOptions = [
        {
            Title: "30 fps [default]",
            Id: "30",
            IsDefault: true
        },
        {
            Title: "31 fps",
            Id: "31",
            IsDefault: false
        },
        {
            Title: "60 fps",
            Id: "60",
            IsDefault: false
        },
        {
            Title: "61 fps",
            Id: "61",
            IsDefault: false
        }
    ]

    return prefOptions
End Function

Function GetPreferenceConvAAC() as Object
    prefOptions = [
        {
            Title: "No [default]",
            Id: "aac",
            IsDefault: true
        },
        {
            Title: "Yes",
            Id: "mp3",
            IsDefault: false
        }
    ]
    return prefOptions
End Function

Function GetPreferenceColor1() as Object
    prefOptions = [
        {
            Title: "Neon Blue  [default]",
            Id: "#33CCFF",
            IsDefault: true
        },
        {
            Title: "Neon Green",
            Id: "#75FF75",
            IsDefault: true
        },
        {
            Title: "Hot Pink",
            Id: "#FF69B4",
            IsDefault: false
        },
        {
            Title: "Deep Pink",
            Id: "#FF1493",
            IsDefault: false
        },
        {
            Title: "Orchid",
            Id: "#DA70D6",
            IsDefault: false
        },
        {
            Title: "Plum",
            Id: "#DDA0DD",
            IsDefault: false
        },
        {
            Title: "Purple",
            Id: "#9B30FF",
            IsDefault: false
        },
        {
            Title: "Slate Blue",
            Id: "#6A5ACD",
            IsDefault: false
        },
        {
            Title: "Blue",
            Id: "#0000FF",
            IsDefault: false
        },
        {
            Title: "Royal Blue",
            Id: "#4169E1",
            IsDefault: false
        },
        {
            Title: "Slate Gray",
            Id: "#708090",
            IsDefault: false
        },
        {
            Title: "Dodger Blue",
            Id: "#1E90FF",
            IsDefault: false
        },
        {
            Title: "Steel Blue",
            Id: "#4682B4",
            IsDefault: false
        },
        {
            Title: "Deep Sky Blue",
            Id: "#00BFFF",
            IsDefault: false
        },
        {
            Title: "Blue Violet",
            Id: "#8A2BE2",
            IsDefault: false
        },
        {
            Title: "CornFlower Blue",
            Id: "#6495ED",
            IsDefault: false
        },
        {
            Title: "Crimson",
            Id: "#DC143C",
            IsDefault: false
        },
        {
            Title: "Spring Green",
            Id: "#00FF7F",
            IsDefault: false
        },
        {
            Title: "Emerald Green",
            Id: "#00C957",
            IsDefault: false
        },
        {
            Title: "Forest Green",
            Id: "#228B22",
            IsDefault: false
        },
        {
            Title: "Chartreuse",
            Id: "#7FFF00",
            IsDefault: false
        },
        {
            Title: "Yellow",
            Id: "#FFFF00",
            IsDefault: false
        },
        {
            Title: "Gold",
            Id: "#FFD700",
            IsDefault: false
        },
        {
            Title: "Goldrenrod",
            Id: "#DAA520",
            IsDefault: false
        },
        {
            Title: "Orange",
            Id: "#FFA500",
            IsDefault: false
        },
        {
            Title: "Carrot",
            Id: "#ED9121",
            IsDefault: false
        },
        {
            Title: "Chocolate",
            Id: "#D2691E",
            IsDefault: false
        },
        {
            Title: "Sienna",
            Id: "#A0522D",
            IsDefault: false
        },
        {
            Title: "Fuchsia",
            Id: "#FF00FF",
            IsDefault: false
        },
        {
            Title: "Salmon",
            Id: "#FF8C69",
            IsDefault: false
        },
        {
            Title: "Green",
            Id: "#008000",
            IsDefault: false
        },
        {
            Title: "Green Yellow",
            Id: "#ADFF2F",
            IsDefault: false
        },
        {
            Title: "Lawn Green",
            Id: "#7CFC00",
            IsDefault: false
        },
        {
            Title: "Lime",
            Id: "#00FF00",
            IsDefault: false
        },
        {
            Title: "Lime Green",
            Id: "#32CD32",
            IsDefault: false
        },
        {
            Title: "Medium Blue",
            Id: "#0000CD",
            IsDefault: false
        },
        {
            Title: "Medium Purple",
            Id: "#9370DB",
            IsDefault: false
        },
        {
            Title: "Medium Spring Green",
            Id: "#00FA9A",
            IsDefault: false
        },
        {
            Title: "Medium Violet Red",
            Id: "#C71585",
            IsDefault: false
        }, 
        {
            Title: "Olive",
            Id: "#808000",
            IsDefault: false
        },
        {
            Title: "OrangeRed",
            Id: "#FF4500",
            IsDefault: false
        },
        {
            Title: "Pale Green",
            Id: "#98FB98",
            IsDefault: false
        },
        {
            Title: "Pale Violet Red",
            Id: "#DB7093",
            IsDefault: false
        },
        {
            Title: "Peach Puff",
            Id: "#FFDAB9",
            IsDefault: false
        },
        {
            Title: "Rebecca Purple",
            Id: "#663399",
            IsDefault: false
        },
        {
            Title: "Saddle Brown",
            Id: "#8B4513",
            IsDefault: false
        },
        {
            Title: "Sandy Brown",
            Id: "#F4A460",
            IsDefault: false
        },
        {
            Title: "Seashell",
            Id: "#FFF5EE",
            IsDefault: false
        },
        {
            Title: "SeaGreen",
            Id: "#2E8B57",
            IsDefault: false
        },
        {
            Title: "Silver",
            Id: "#C0C0C0",
            IsDefault: false
        },
        {
            Title: "Thistle",
            Id: "#D8BFD8",
            IsDefault: false
        },
        {
            Title: "Wheat",
            Id: "#F5DEB3",
            IsDefault: false
        },
        {
            Title: "Tomato",
            Id: "#FF6347",
            IsDefault: false
        },
        {
            Title: "Rosy Brown",
            Id: "#BC8F8F",
            IsDefault: false
        },
        {
            Title: "Brown",
            Id: "#A52A2A",
            IsDefault: false
        },
        {
            Title: "Teal",
            Id: "#388E8E",
            IsDefault: false
        },
        {
            Title: "Beet",
            Id: "#8E388E",
            IsDefault: false
        },
        {
            Title: "Maroon",
            Id: "#800000",
            IsDefault: false
        },
        {
            Title: "Coral",
            Id: "#F08080",
            IsDefault: false
        },
        {
            Title: "Magenta",
            Id: "#FF00FF",
            IsDefault: false
        },
        {
            Title: "White",
            Id: "#FFFFFF",
            IsDefault: false
        },
        {
            Title: "Neon Blue  [default]",
            Id: "#33CCFF",
            IsDefault: true
        }
    ]

    return prefOptions
End Function

Function GetPreferenceColor2() as Object
    prefOptions = [
        {
            Title: "Neon Green [default]",
            Id: "#75FF75",
            IsDefault: true
        },
        {
            Title: "Neon Blue",
            Id: "#33CCFF",
            IsDefault: false
        },
        {
            Title: "Hot Pink",
            Id: "#FF69B4",
            IsDefault: false
        },
        {
            Title: "Deep Pink",
            Id: "#FF1493",
            IsDefault: false
        },
        {
            Title: "Orchid",
            Id: "#DA70D6",
            IsDefault: false
        },
        {
            Title: "Plum",
            Id: "#DDA0DD",
            IsDefault: false
        },
        {
            Title: "Purple",
            Id: "#9B30FF",
            IsDefault: false
        },
        {
            Title: "Slate Blue",
            Id: "#6A5ACD",
            IsDefault: false
        },
        {
            Title: "Blue",
            Id: "#0000FF",
            IsDefault: false
        },
        {
            Title: "Royal Blue",
            Id: "#4169E1",
            IsDefault: false
        },
        {
            Title: "Slate Gray",
            Id: "#708090",
            IsDefault: false
        },
        {
            Title: "Dodger Blue",
            Id: "#1E90FF",
            IsDefault: false
        },
        {
            Title: "Steel Blue",
            Id: "#4682B4",
            IsDefault: false
        },
        {
            Title: "Deep Sky Blue",
            Id: "#00BFFF",
            IsDefault: false
        },
        {
            Title: "Blue Violet",
            Id: "#8A2BE2",
            IsDefault: false
        },
        {
            Title: "CornFlower Blue",
            Id: "#6495ED",
            IsDefault: false
        },
        {
            Title: "Crimson",
            Id: "#DC143C",
            IsDefault: false
        },
        {
            Title: "Spring Green",
            Id: "#00FF7F",
            IsDefault: false
        },
        {
            Title: "Emerald Green",
            Id: "#00C957",
            IsDefault: false
        },
        {
            Title: "Forest Green",
            Id: "#228B22",
            IsDefault: false
        },
        {
            Title: "Chartreuse",
            Id: "#7FFF00",
            IsDefault: false
        },
        {
            Title: "Yellow",
            Id: "#FFFF00",
            IsDefault: false
        },
        {
            Title: "Gold",
            Id: "#FFD700",
            IsDefault: false
        },
        {
            Title: "Goldrenrod",
            Id: "#DAA520",
            IsDefault: false
        },
        {
            Title: "Orange",
            Id: "#FFA500",
            IsDefault: false
        },
        {
            Title: "Carrot",
            Id: "#ED9121",
            IsDefault: false
        },
        {
            Title: "Chocolate",
            Id: "#D2691E",
            IsDefault: false
        },
        {
            Title: "Sienna",
            Id: "#A0522D",
            IsDefault: false
        },
        {
            Title: "Fuchsia",
            Id: "#FF00FF",
            IsDefault: false
        },
        {
            Title: "Salmon",
            Id: "#FF8C69",
            IsDefault: false
        },
        {
            Title: "Green",
            Id: "#008000",
            IsDefault: false
        },
        {
            Title: "Green Yellow",
            Id: "#ADFF2F",
            IsDefault: false
        },
        {
            Title: "Lawn Green",
            Id: "#7CFC00",
            IsDefault: false
        },
        {
            Title: "Lime",
            Id: "#00FF00",
            IsDefault: false
        },
        {
            Title: "Lime Green",
            Id: "#32CD32",
            IsDefault: false
        },
        {
            Title: "Medium Blue",
            Id: "#0000CD",
            IsDefault: false
        },
        {
            Title: "Medium Purple",
            Id: "#9370DB",
            IsDefault: false
        },
        {
            Title: "Medium Spring Green",
            Id: "#00FA9A",
            IsDefault: false
        },
        {
            Title: "Medium Violet Red",
            Id: "#C71585",
            IsDefault: false
        }, 
        {
            Title: "Olive",
            Id: "#808000",
            IsDefault: false
        },
        {
            Title: "OrangeRed",
            Id: "#FF4500",
            IsDefault: false
        },
        {
            Title: "Pale Green",
            Id: "#98FB98",
            IsDefault: false
        },
        {
            Title: "Pale Violet Red",
            Id: "#DB7093",
            IsDefault: false
        },
        {
            Title: "Peach Puff",
            Id: "#FFDAB9",
            IsDefault: false
        },
        {
            Title: "Rebecca Purple",
            Id: "#663399",
            IsDefault: false
        },
        {
            Title: "Saddle Brown",
            Id: "#8B4513",
            IsDefault: false
        },
        {
            Title: "Sandy Brown",
            Id: "#F4A460",
            IsDefault: false
        },
        {
            Title: "Seashell",
            Id: "#FFF5EE",
            IsDefault: false
        },
        {
            Title: "SeaGreen",
            Id: "#2E8B57",
            IsDefault: false
        },
        {
            Title: "Silver",
            Id: "#C0C0C0",
            IsDefault: false
        },
        {
            Title: "Thistle",
            Id: "#D8BFD8",
            IsDefault: false
        },
        {
            Title: "Wheat",
            Id: "#F5DEB3",
            IsDefault: false
        },
        {
            Title: "Tomato",
            Id: "#FF6347",
            IsDefault: false
        },
        {
            Title: "Rosy Brown",
            Id: "#BC8F8F",
            IsDefault: false
        },
        {
            Title: "Brown",
            Id: "#A52A2A",
            IsDefault: false
        },
        {
            Title: "Teal",
            Id: "#388E8E",
            IsDefault: false
        },
        {
            Title: "Beet",
            Id: "#8E388E",
            IsDefault: false
        },
        {
            Title: "Maroon",
            Id: "#800000",
            IsDefault: false
        },
        {
            Title: "Coral",
            Id: "#F08080",
            IsDefault: false
        },
        {
            Title: "Magenta",
            Id: "#FF00FF",
            IsDefault: false
        },
        {
            Title: "White",
            Id: "#FFFFFF",
            IsDefault: false
        },
        {
            Title: "Neon Green [default]",
            Id: "#75FF75",
            IsDefault: true
        }
    ]

    return prefOptions
End Function

Function GetPreferenceColor3() as Object
    prefOptions = [
        {
            Title: "White [default]",
            Id: "#FFFFFF",
            IsDefault: true
        },
        {
            Title: "Neon Green",
            Id: "#75FF75",
            IsDefault: true
        },
        {
            Title: "Neon Blue",
            Id: "#33CCFF",
            IsDefault: false
        },
        {
            Title: "Hot Pink",
            Id: "#FF69B4",
            IsDefault: false
        },
        {
            Title: "Deep Pink",
            Id: "#FF1493",
            IsDefault: false
        },
        {
            Title: "Orchid",
            Id: "#DA70D6",
            IsDefault: false
        },
        {
            Title: "Plum",
            Id: "#DDA0DD",
            IsDefault: false
        },
        {
            Title: "Purple",
            Id: "#9B30FF",
            IsDefault: false
        },
        {
            Title: "Slate Blue",
            Id: "#6A5ACD",
            IsDefault: false
        },
        {
            Title: "Blue",
            Id: "#0000FF",
            IsDefault: false
        },
        {
            Title: "Royal Blue",
            Id: "#4169E1",
            IsDefault: false
        },
        {
            Title: "Slate Gray",
            Id: "#708090",
            IsDefault: false
        },
        {
            Title: "Dodger Blue",
            Id: "#1E90FF",
            IsDefault: false
        },
        {
            Title: "Steel Blue",
            Id: "#4682B4",
            IsDefault: false
        },
        {
            Title: "Deep Sky Blue",
            Id: "#00BFFF",
            IsDefault: false
        },
        {
            Title: "Blue Violet",
            Id: "#8A2BE2",
            IsDefault: false
        },
        {
            Title: "CornFlower Blue",
            Id: "#6495ED",
            IsDefault: false
        },
        {
            Title: "Crimson",
            Id: "#DC143C",
            IsDefault: false
        },
        {
            Title: "Spring Green",
            Id: "#00FF7F",
            IsDefault: false
        },
        {
            Title: "Emerald Green",
            Id: "#00C957",
            IsDefault: false
        },
        {
            Title: "Forest Green",
            Id: "#228B22",
            IsDefault: false
        },
        {
            Title: "Chartreuse",
            Id: "#7FFF00",
            IsDefault: false
        },
        {
            Title: "Yellow",
            Id: "#FFFF00",
            IsDefault: false
        },
        {
            Title: "Gold",
            Id: "#FFD700",
            IsDefault: false
        },
        {
            Title: "Goldrenrod",
            Id: "#DAA520",
            IsDefault: false
        },
        {
            Title: "Orange",
            Id: "#FFA500",
            IsDefault: false
        },
        {
            Title: "Carrot",
            Id: "#ED9121",
            IsDefault: false
        },
        {
            Title: "Chocolate",
            Id: "#D2691E",
            IsDefault: false
        },
        {
            Title: "Sienna",
            Id: "#A0522D",
            IsDefault: false
        },
        {
            Title: "Fuchsia",
            Id: "#FF00FF",
            IsDefault: false
        },
        {
            Title: "Salmon",
            Id: "#FF8C69",
            IsDefault: false
        },
        {
            Title: "Green",
            Id: "#008000",
            IsDefault: false
        },
        {
            Title: "Green Yellow",
            Id: "#ADFF2F",
            IsDefault: false
        },
        {
            Title: "Lawn Green",
            Id: "#7CFC00",
            IsDefault: false
        },
        {
            Title: "Lime",
            Id: "#00FF00",
            IsDefault: false
        },
        {
            Title: "Lime Green",
            Id: "#32CD32",
            IsDefault: false
        },
        {
            Title: "Medium Blue",
            Id: "#0000CD",
            IsDefault: false
        },
        {
            Title: "Medium Purple",
            Id: "#9370DB",
            IsDefault: false
        },
        {
            Title: "Medium Spring Green",
            Id: "#00FA9A",
            IsDefault: false
        },
        {
            Title: "Medium Violet Red",
            Id: "#C71585",
            IsDefault: false
        }, 
        {
            Title: "Olive",
            Id: "#808000",
            IsDefault: false
        },
        {
            Title: "OrangeRed",
            Id: "#FF4500",
            IsDefault: false
        },
        {
            Title: "Pale Green",
            Id: "#98FB98",
            IsDefault: false
        },
        {
            Title: "Pale Violet Red",
            Id: "#DB7093",
            IsDefault: false
        },
        {
            Title: "Peach Puff",
            Id: "#FFDAB9",
            IsDefault: false
        },
        {
            Title: "Rebecca Purple",
            Id: "#663399",
            IsDefault: false
        },
        {
            Title: "Saddle Brown",
            Id: "#8B4513",
            IsDefault: false
        },
        {
            Title: "Sandy Brown",
            Id: "#F4A460",
            IsDefault: false
        },
        {
            Title: "Seashell",
            Id: "#FFF5EE",
            IsDefault: false
        },
        {
            Title: "SeaGreen",
            Id: "#2E8B57",
            IsDefault: false
        },
        {
            Title: "Silver",
            Id: "#C0C0C0",
            IsDefault: false
        },
        {
            Title: "Thistle",
            Id: "#D8BFD8",
            IsDefault: false
        },
        {
            Title: "Wheat",
            Id: "#F5DEB3",
            IsDefault: false
        },
        {
            Title: "Tomato",
            Id: "#FF6347",
            IsDefault: false
        },
        {
            Title: "Rosy Brown",
            Id: "#BC8F8F",
            IsDefault: false
        },
        {
            Title: "Brown",
            Id: "#A52A2A",
            IsDefault: false
        },
        {
            Title: "Teal",
            Id: "#388E8E",
            IsDefault: false
        },
        {
            Title: "Beet",
            Id: "#8E388E",
            IsDefault: false
        },
        {
            Title: "Maroon",
            Id: "#800000",
            IsDefault: false
        },
        {
            Title: "Coral",
            Id: "#F08080",
            IsDefault: false
        },
        {
            Title: "Magenta",
            Id: "#FF00FF",
            IsDefault: false
        },
        {
            Title: "White [default]",
            Id: "#FFFFFF",
            IsDefault: true
        }
    ]

    return prefOptions
End Function

Function GetPreferenceBorder() as Object
    prefOptions = [
        {
            Title: "Glowing [default]",
            Id: "1",
            IsDefault: true
        },
        {
            Title: "Standard",
            Id: "0",
            IsDefault: false
        }
    ]

    return prefOptions
End Function