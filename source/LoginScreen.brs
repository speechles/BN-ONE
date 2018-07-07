'**********************************************************
'** CreateLoginScreen
'**********************************************************

Function CreateLoginScreen(viewController as Object, serverUrl as String, screenType as Integer) as Object

	' Dummy up an item
	item = CreateObject("roAssociativeArray")

	if screenType = 0
		GetGlobalAA().AddReplace("alsowatch", "0")
		item.Title = "Login"
	else
		GetGlobalAA().AddReplace("alsowatch", "1")
		item.Title = "Also Watching"
	end if

	item.serverUrl = serverUrl
	
    ' Show login tiles - common convention is square images
    screen = CreatePosterScreen(viewController, item, "arced-square")

	screen.baseHandleMessage = screen.HandleMessage
	screen.HandleMessage = handleLoginScreenMessage

	screen.GetDataContainer = getLoginScreenDataContainer

	screen.OnUserInput = onLoginScreenUserInput

	screen.serverUrl = serverUrl
	screen.showPasswordInput = loginScreenShowPasswordInput
	screen.showUsernameInput = loginScreenShowUsernameInput

    return screen
End Function

Function handleLoginScreenMessage(msg) as Boolean

	handled = false

	viewController = m.ViewController

    if type(msg) = "roPosterScreenEvent" then

        if msg.isListItemSelected() then

			handled = true

            index = msg.GetIndex()
            content = m.contentArray[m.focusedList].content
            selectedProfile = content[index]
			serverUrl = m.serverUrl

            if selectedProfile.ContentType = "user"

                if selectedProfile.HasPassword

					m.showPasswordInput(selectedProfile.Title)

                else
				
					OnPasswordEntered(serverUrl, selectedProfile.Title, "")
					
                end if

            else if selectedProfile.ContentType = "manual"
				
		m.showUsernameInput()

            else if selectedProfile.ContentType = "server"
				
		showServerListScreen(viewController)
				
	    else if selectedProfile.ContentType = "ConnectSignIn"

		viewController.createScreenForItem(content, index, ["Connect"], true)

            else if selectedProfile.ContentType = "Registry"

		deleteReg ("")
		showServerListScreen(viewController)

            else if selectedProfile.ContentType = "Left"

		peepsids = GetAlsoWatching()
		peepsnames = GetAlsoWatchingNames()
		if peepsids <> ""
			sessionId = GetSessionId()
			if sessionId <> invalid
				r = CreateObject("roRegex", ",", "")
				for each id in r.split(peepsids)
					result = postAlsoWatchingStatus(id, false, sessionId)
				end for
			end if
		end if
		createDialog("Also Watching", "All Users ("+peepsnames+") have been removed from your session.", "OK", true)
		m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
            else

                'return 2
				viewController.ShowInitialScreen()

            end if

        end if
    end if

	if handled = false then
		handled = m.baseHandleMessage(msg)
	end If

	return handled

End Function

Sub loginScreenShowUsernameInput()

	screen = m.ViewController.CreateTextInputScreen(invalid, "Enter Username", ["Enter Username"], "", false)
	screen.ValidateText = OnRequiredTextValueEntered
	screen.Show(true)

	value = screen.Text
	
	if value <> invalid and value <> "" then
		m.showPasswordInput(value)
	end if
	
End Sub


Sub loginScreenShowPasswordInput(usernameText as String)

	m.usernameText = usernameText

	screen = m.ViewController.CreateTextInputScreen(invalid, "Enter Password", ["Enter Password"], "", true)
	screen.Listener = m
	screen.inputType = "password"
	screen.Show()

End Sub

Sub onLoginScreenUserInput(value, screen)

	Debug ("onLoginScreenUserInput")

	if screen.inputType = "password" then
		
		Debug ("onLoginScreenUserInput - password")

		OnPasswordEntered(m.serverUrl, m.usernameText, firstOf(value, ""))

	end if

End Sub

Sub OnPasswordEntered(serverUrl, usernameText, passwordText)
	debug(serverurl + " " + usernameText + " " + passwordText)
	Debug ("OnPasswordEntered")

	' Check password
	authResult = authenticateUser(serverUrl, usernameText, passwordText)

	If authResult <> invalid
		if GetGlobalVar("alsowatch") = "1" then
			' count of the users also watching
			peepsnames = GetAlsoWatching()
			r = CreateObject("roRegex", authResult.User.Id, "")
			if r.ismatch(peepsnames) 
				createDialog("Also Watching Error!", usernameText + " is already added to your session.", "OK", true)
			else
				sessionId = GetSessionId()
				if sessionId <> invalid
					result = postAlsoWatchingStatus(authResult.User.Id, true, sessionId)
					if result then
						createDialog("Also Watching", usernameText + " has been added to your session.", "OK", true)
					end if
				end if
			end if
			m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
		else		
			ConnectionManager().SetServerData(authResult.ServerId, "AccessToken", authResult.AccessToken)
			ConnectionManager().SetServerData(authResult.ServerId, "UserId", authResult.User.Id)
		
			GetViewController().onSignedIn(authResult.ServerId, serverUrl, authResult.User.Id)
		end if
	Else
		ShowPasswordFailed()
	End If

End Sub

'******************************************************
' Show Password Failed
'******************************************************

Sub ShowPasswordFailed()

    title = "Login Failed"
    message = "Invalid username or password. Please try again."

    dlg = createBaseDialog()
    dlg.Title = title
	dlg.Text = message
    dlg.SetButton("back", "Back")
    dlg.Show(true)
	
End Sub

Function getLoginScreenDataContainer(viewController as Object, item as Object) as Object

    profiles = getPublicUserProfiles(item.serverUrl)

    if profiles = invalid
        return invalid
    end if
	if GetGlobalVar("alsowatch") = "0" then
		' Support manual login. 
		manualLogin = {
			Title: "Manual Login"
			ContentType: "manual"
			ShortDescriptionLine1: "Manual Login"
			HDPosterUrl: viewController.getThemeImageUrl("hd-default-user.png"),
			SDPosterUrl: viewController.getThemeImageUrl("hd-default-user.png")
		}
		profiles.Push( manualLogin )
    
		' Add Server Tile (eventually move this)
		switchServer = {
			Title: "Select Server"
			ContentType: "server"
			ShortDescriptionLine1: "Select Server"
			HDPosterUrl: viewController.getThemeImageUrl("hd-switch-server.png"),
			SDPosterUrl: viewController.getThemeImageUrl("hd-switch-server.png")
		}
    		profiles.Push( switchServer )

		if ConnectionManager().isLoggedIntoConnect() = false then
			' Add Server Tile (eventually move this)
			connect = {
				Title: "Sign in with Emby Connect"
				ContentType: "ConnectSignIn"
				ShortDescriptionLine1: "Sign in with Emby Connect"
				HDPosterUrl: viewController.getThemeImageUrl("hd-connectsignin.jpg"),
				SDPosterUrl: viewController.getThemeImageUrl("hd-connectsignin.jpg")
			}
			profiles.Push( connect )
		end if

		registry = {
			Title: "Reset Registry"
			ContentType: "Registry"
			ShortDescriptionLine1: "Clear Registry"
			ShortDescriptionLine2: "Wipe all settings"
			HDPosterUrl: viewController.getThemeImageUrl("hd-trash.png"),
			SDPosterUrl: viewController.getThemeImageUrl("hd-trash.png")
		}
    		profiles.Push( registry )
	else
		' Support also watching reset
		gone = {
			Title: "Remove all users"
			ContentType: "Left"
			ShortDescriptionLine1: "Remove All Users"
			ShortDescriptionLine2: "Nobody else is watching"
			HDPosterUrl: viewController.getThemeImageUrl("hd-default-userleft.png"),
			SDPosterUrl: viewController.getThemeImageUrl("hd-default-userleft.png")
		}
		profiles.Push( gone )
	end if
	
	obj = CreateObject("roAssociativeArray")
	obj.names = []
	obj.keys = []
	obj.items = profiles

	return obj

End Function