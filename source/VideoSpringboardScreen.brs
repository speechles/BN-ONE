'**********************************************************
'** createVideoSpringboardScreen
'** Credit: Plex Roku https://github.com/plexinc/roku-client-public
'**********************************************************

Function createVideoSpringboardScreen(context, index, viewController) As Object

    obj = createBaseSpringboardScreen(context, index, viewController)

    obj.SetupButtons = videoSetupButtons
    obj.GetMediaDetails = videoGetMediaDetails
    obj.baseHandleMessage = obj.HandleMessage
    obj.HandleMessage = handleVideoSpringboardScreenMessage

	obj.ContinuousPlay = false

    obj.checkChangesOnActivate = false
    obj.refreshOnActivate = false
    obj.closeOnActivate = false
    obj.Activate = videoActivate

	obj.DeleteItem = springboardDeleteItem
	obj.CancelLiveTvTimer = springboardCancelTimer
	obj.RecordLiveTvProgram = springboardRecordProgram
	obj.ShowStreamsDialog = springboardShowStreamsDialog
	obj.ShowMoreDialog = springboardShowMoreDialog
	obj.ShowFilmography = springboardShowFilmography
	
	obj.PlayOptions = {}

	obj.Screen.SetDescriptionStyle("movie")
	obj.Cleanup = baseStopAudioPlayer
	NoStop = FirstOf(RegRead("prefStopThemeMusic"),"0")
	LastSeries = FirstOf(getGlobalVar("LastSeries"),"")
	if obj.Item.seriesName <> invalid and obj.Item.seriesName <> ""
		AddThis = obj.Item.seriesName
	else
		AddThis = obj.Item.Title
	end if
	if NoStop = "0" OR AudioPlayer().IsPlaying = false
		if firstOf(RegRead("prefThemeMusic"), "yes") = "yes" AND LastSeries <> AddThis
			AudioPlayer().PlayThemeMusic(obj.Item)
			GetGlobalAA().AddReplace("LastSeries", AddThis)
		end if
	end if

    return obj

End Function

'**************************************************************
'** videoSetupButtons
'**************************************************************

Sub videoSetupButtons()
    m.ClearButtons()

	video = m.metadata
	cast = 0
	LastSeries = FirstOf(getGlobalVar("LastSeries"),"")
	NoStop = FirstOf(RegRead("prefStopThemeMusic"),"0")
	if NOT video.seriesName <> invalid
		if NOT LastSeries = video.Title
    			if firstOf(RegRead("prefThemeMusic"), "yes") = "yes" then
 				AudioPlayer().PlayThemeMusic(video)
				GetGlobalAA().AddReplace("LastSeries", video.Title)
			end if
		end if
	else
		if NOT LastSeries = video.seriesName
			GetGlobalAA().AddReplace("LastSeries", video.seriesName)
    			if firstOf(RegRead("prefThemeMusic"), "yes") = "yes" then
 				AudioPlayer().PlayThemeMusic(video)
			end if
		end if
	end if
		
	if video.ContentType = "Program" And video.PlayAccess = "Full"
		if canPlayProgram(video)
			m.AddButton("Play", "play")
		end if
		if video.TimerId <> invalid
			m.AddButton("Cancel Recording", "cancelrecording")
			
        	else if canRecordProgram(video)
			m.AddButton("Schedule Recording", "record")
		end if

	else if (video.LocationType <> "Virtual" or video.ContentType = "TvChannel") And video.PlayAccess = "Full"

		' This screen is also used for books and games, so don't show a play button
		if video.MediaType = "Video" then
			if video.BookmarkPosition <> 0 then
				time = tostr(formatTime(video.BookmarkPosition))
				m.AddButton("Resume from " + time, "resume")
				m.AddButton("Play from beginning", "play")
			else
				m.AddButton("Play", "play")
			end if
		end if

		if video.Chapters <> invalid and video.Chapters.Count() > 0
			m.AddButton("Play from scene", "scenes")
		end if

		if video.LocalTrailerCount <> invalid and video.LocalTrailerCount > 0
			if video.LocalTrailerCount > 1
				m.AddButton("Trailers", "trailers")
				cast = 1
			else
				m.AddButton("Trailer", "trailer")
				cast = 1
			end if
		end if
		audioStreams = []
		subtitleStreams = []

		if video.StreamInfo <> invalid then
			for each stream in video.StreamInfo.MediaSource.MediaStreams
				if stream.Type = "Audio" then audioStreams.push(stream)
				if stream.Type = "Subtitle" then subtitleStreams.push(stream)
			end For
		end if

		if audioStreams.Count() > 1 Or subtitleStreams.Count() > 0
			m.AddButton("Audio & Subtitles ...", "streams")
		end if
		m.audioStreams = audioStreams
		m.subtitleStreams = subtitleStreams
	end if

    	if m.screen.CountButtons() < 1 and video.ContentType <> "Person" and video.LocationType <> "Virtual"
		m.AddButton("Open", "open")
    	end if

	' Check for people
	if video.People <> invalid and video.People.Count() > 0 and cast = 0 then

		if video.MediaType = "Video" then
			m.AddButton("Cast & Crew", "cast")
		else
			m.AddButton("People", "people")
		end If
	end if
	if video.ContentType = "Person"
		m.AddButton("Filmography", "filmography")
		if Video.IsFavorite then
			m.AddButton("Remove this person as a Favorite", "removefavorite")
		else
			m.AddButton("Mark this person as a Favorite", "markfavorite")
		end if
	end if

	if video.ContentType = "Playlist" and video.MediaType = "Video"
		m.AddButton("View Playlist Items", "viewplaylist")
	end if
	if m.screen.CountButtons() < 5 and Video.FullDescription <> invalid 'and  Video.FullDescription <> "" and Video.FullDescription.len() > 50 then
		m.AddButton("Show Overview/Info", "description")
	end if
	' rewster: TV Program recording does not need a more button, and displaying it stops the back button from appearing on programmes that have past
	if video.ContentType <> "Program"
    		versionArr = getGlobalVar("rokuVersion")
		If CheckMinimumVersion(versionArr, [6, 1]) then
	    		surroundSound = getGlobalVar("SurroundSound")
	    		audioOutput51 = getGlobalVar("audioOutput51")
	    		surroundSoundDCA = getGlobalVar("audioDTS")
		else
			' legacy
	    		surroundSound = SupportsSurroundSound(false, false)

	    		audioOutput51 = getGlobalVar("audioOutput51")
	    		surroundSoundDCA = surroundSound AND audioOutput51 'AND (RegRead("fivepointoneDCA", "preferences", "1") = "1")
	    		surroundSound = surroundSound AND audioOutput51 'AND (RegRead("fivepointone", "preferences", "1") = "1")
		end if
		audioDDPlus = FirstOf(getGlobalVar("audioDDPlus"), false)
		AH = ""
		if SurroundSound then
			if audioDDPlus then
				AH = AH + " DD+"
			else if audioOutput51 then
				AH = AH + " DD"
			end if
			if SurroundSoundDCA then
				AH = AH + " DTS"
			end if

		else
			AH = " Stereo"
		end if
		private = FirstOf(regRead("prefprivate"),"0")
		if private = "1" then
			AH = " PRIVATE"
		end if
		Extras = "(" + FirstOf(regRead("prefPlayMethod"),"Auto") + " @ " + firstOf(regread("prefmaxframe"), "30") + "fps)"
		if AH <> invalid and AH <> "" then
			 Extras = Extras + AH
		end if
		GetGlobalAA().AddReplace("adddelete", "0")
		if m.screen.CountButtons() < 5
    			' delete
			DeleteAll = firstOf(RegRead("prefDelAll"), "0")
    			if video.CanDelete and DeleteAll = "1" Then
        			m.AddButton("Delete Item", "delete")
				GetGlobalAA().AddReplace("adddelete", "1")
    			end if
		end if

		m.AddButton("More ... " + Extras, "more")
	end if

	if m.buttonCount = 0
		m.AddButton("Back", "back")
	end if
End Sub

'**********************************************************
'** canPlayProgram
'**********************************************************

Function canPlayProgram(item as Object) As Boolean

	startDateString = item.StartDate
	endDateString = item.EndDate
	
	if startDateString = invalid or endDateString = invalid then return false
	
    ' Current Time
    nowTime = CreateObject("roDateTime")
    nowTime.ToLocalTime()
    nowTimeSeconds = nowTime.AsSeconds()

    ' Start Time
    startTime = CreateObject("roDateTime")
    startTime.FromISO8601String(startDateString)
    startTime.ToLocalTime()

    ' End Time
    endTime = CreateObject("roDateTime")
    endTime.FromISO8601String(endDateString)
    endTime.ToLocalTime()

    return nowTimeSeconds >= startTime.AsSeconds() And nowTimeSeconds < endTime.AsSeconds()
	
End Function

'**********************************************************
'** canRecordProgram
'**********************************************************

Function canRecordProgram(item as Object) As Boolean

	endDateString = item.EndDate
	
	if endDateString = invalid then return false
	
    ' Current Time
    nowTime = CreateObject("roDateTime")
    nowTime.ToLocalTime()

    ' End Time
    endTime = CreateObject("roDateTime")
    endTime.FromISO8601String(endDateString)
    endTime.ToLocalTime()

    return nowTime.AsSeconds() < endTime.AsSeconds()
	
End Function

'**************************************************************
'** videoGetMediaDetails
'**************************************************************

Sub videoGetMediaDetails(content)

    m.metadata = GetFullItemMetadata(content, false, {})
	streaminfo = invalid
	if m.metadata <> invalid then streamInfo = m.metadata.StreamInfo
	
	if streamInfo <> invalid then
		m.PlayOptions.SubtitleStreamIndex = streamInfo.SubtitleStreamIndex
		m.PlayOptions.AudioStreamIndex = streamInfo.AudioStreamIndex
		m.PlayOptions.MediaSourceId = streamInfo.MediaSource.Id
	end if

End Sub

'**************************************************************
'** videoActivate
'**************************************************************

Sub videoActivate(priorScreen)

    if m.closeOnActivate then
        m.Screen.Close()
        return
    end if

    if m.checkChangesOnActivate AND priorScreen.Changes <> invalid then

        m.checkChangesOnActivate = false

        if priorScreen.Changes.DoesExist("continuous_play") then
            m.ContinuousPlay = (priorScreen.Changes["continuous_play"] = "1")
            priorScreen.Changes.Delete("continuous_play")
        end if

        if NOT priorScreen.Changes.IsEmpty() then
            m.Refresh(true)
        end if
    end if

    if m.refreshOnActivate then
	
		m.refreshOnActivate = false
		
        if m.ContinuousPlay AND (priorScreen.isPlayed = true) then
		
            m.GotoNextItem()
			m.PlayOptions = {}
			m.PlayOptions.PlayStart = 0
            
			m.ViewController.CreatePlayerForItem([m.metadata], 0, m.PlayOptions)
        else
            m.Refresh(true)

			m.refreshOnActivate = false
        end if
    end if
End Sub

'**************************************************************
'** handleVideoSpringboardScreenMessage
'**************************************************************

Function handleVideoSpringboardScreenMessage(msg) As Boolean

    handled = false

    if type(msg) = "roSpringboardScreenEvent" then

		item = GetFullItemMetadata(m.metadata, false, {})
		if item <> invalid then itemId = item.Id
		viewController = m.ViewController
		screen = m

        if msg.isButtonPressed() then

            handled = true
            buttonCommand = m.buttonCommands[str(msg.getIndex())]
            Debug("Button command: " + tostr(buttonCommand))

            if buttonCommand = "play" then

		if firstOf(m.PlayOptions.HasSelection, false) = false then
			m.PlayOptions = {}
		end if		
                m.PlayOptions.PlayStart = 0
				m.ViewController.CreatePlayerForItem([item], 0, m.PlayOptions)

                ' Refresh play data after playing.
                m.refreshOnActivate = true

            else if buttonCommand = "resume" then

		if firstOf(m.PlayOptions.HasSelection, false) = false then
			m.PlayOptions = {}
		end if	
                m.PlayOptions.PlayStart = item.BookmarkPosition
		m.ViewController.CreatePlayerForItem([item], 0, m.PlayOptions)

                ' Refresh play data after playing.
                m.refreshOnActivate = true

            else if buttonCommand = "scenes" then
                newScreen = createVideoChaptersScreen(viewController, item, m.PlayOptions)
		newScreen.ScreenName = "Chapters" + itemId
                viewController.InitializeOtherScreen(newScreen, [item.Title, "Scenes"])
		newScreen.Show()

	    else if buttonCommand = "viewplaylist"
                newScreen = createPlaylistScreen(viewController, item)
		newScreen.ScreenName = "Playlist" + itemId
                viewController.InitializeOtherScreen(newScreen, [item.Title, "Playlist"])
		newScreen.Show()
            else if buttonCommand = "trailer" then
                options = {
			PlayStart: 0
			intros: false
		}
		m.ViewController.CreatePlayerForItem(getLocalTrailers(item.Id), 0, options)
            else if buttonCommand = "trailers" then
                newScreen = createLocalTrailersScreen(viewController, item)
		newScreen.ScreenName = "Trailers" + itemId
                viewController.InitializeOtherScreen(newScreen, [item.Title, "Trailers"])
		newScreen.Show()	
            else if buttonCommand = "cancelrecording" then
		m.CancelLiveTvTimer(item)
	    else if buttonCommand = "description" then
		if item.FullDescription <> "" 
        		newScreen = createTextDescriptionScreen(m.ViewController, item)
			newScreen.ScreenName = "Text" + itemId
        		m.ViewController.InitializeOtherScreen(newScreen, [item.Title,"Overview"])
		else
			GetGlobalAA().AddReplace("theitem", item)
        		newScreen = createMediaInfoScreen(m.ViewController)
			newScreen.ScreenName = "MediaInfo" + item.Id
        		m.ViewController.InitializeOtherScreen(newScreen, [""])
		end if
		newScreen.Show()
		return true
    	    else if buttonCommand = "delete" then
		springboardDeleteItem(item)
		return true
    	    else if buttonCommand = "open" then
		GetViewController().CreateScreenForItem(Item, 0, [item.Title])
		return true
    	    else if buttonCommand = "playme" then
		GetViewController().CreateScreenForItem(Item, 0, [item.Title])
		return true
            else if buttonCommand = "streams" then
                m.ShowStreamsDialog(item)
            else if buttonCommand = "record" then
                m.RecordLiveTvProgram(item)
            else if buttonCommand = "filmography" then
                m.ShowFilmography(item)
    	    else if buttonCommand = "cast" then
        	newScreen = createPeopleScreen(m.ViewController, item)
		newScreen.ScreenName = "People" + itemId
        	m.ViewController.InitializeOtherScreen(newScreen, [item.Title, "Cast & Crew"])
		newScreen.Show()
        	return true
    	    else if buttonCommand = "people" then
        	newScreen = createPeopleScreen(m.ViewController, item)
		newScreen.ScreenName = "People" + itemId
        	m.ViewController.InitializeOtherScreen(newScreen, [item.Title, "People"])
		newScreen.Show()
        	return true				
            else if buttonCommand = "more" then
                m.ShowMoreDialog(item)
	    ' rewster: handle the back button
	    else if buttonCommand = "back" then
		m.ViewController.PopScreen(m)
    	    else if buttonCommand = "removefavorite" then
		screen.refreshOnActivate = true
		result = postFavoriteStatus(itemId, false)
		if result then
			createDialog("Favorites Changed", item.Title + " has been removed from your favorites.", "OK", true)
		else
			createDialog("Favorites Error!", item.Title + " has NOT been removed from your favorites.", "OK", true)
		end if
		return true
	    else if buttonCommand = "markfavorite" then
		screen.refreshOnActivate = true
		result = postFavoriteStatus(itemId, true)
		if result then
			createDialog("Favorites Changed", item.Title + " has been added to your favorites.", "OK", true)
		else
			createDialog("Favorites Error!", item.Title + " has NOT been added to your favorites.", "OK", true)
		end if
		return true
            else
                handled = false
            end if
        end if
    end if

	return handled OR m.baseHandleMessage(msg)

End Function

'**********************************************************
'** createVideoChaptersScreen
'**********************************************************

Function createVideoChaptersScreen(viewController as Object, video As Object, playOptions) As Object

	' Dummy up an item
    obj = CreatePosterScreen(viewController, video, "flat-episodic-16x9")
	obj.GetDataContainer = getChaptersDataContainer

	obj.baseHandleMessage = obj.HandleMessage
	obj.HandleMessage = handleChaptersScreenMessage

    return obj
	
End Function

Function handleChaptersScreenMessage(msg) as Boolean

	handled = false

    if type(msg) = "roPosterScreenEvent" then

        if msg.isListItemSelected() then

            index = msg.GetIndex()
            content = m.contentArray[m.focusedList].content
            selected = content[index]

			item = m.Item

			startPosition = selected.StartPosition

			playOptions = {
				PlayStart: startPosition,
				intros: false
			}

            m.ViewController.CreatePlayerForItem([item], 0, playOptions)

        end if
			
    end if

	return handled or m.baseHandleMessage(msg)

End Function

Function getChaptersDataContainer(viewController as Object, item as Object) as Object

	obj = CreateObject("roAssociativeArray")
	obj.names = []
	obj.keys = []
	obj.items = item.Chapters

	return obj

End Function

'**********************************************************
'** createSpecialFeaturesScreen
'**********************************************************

Function createSpecialFeaturesScreen(viewController as Object, item As Object) As Object

	' TODO: Add option to poster screen to play item directly when selected

	obj = CreatePosterScreen(viewController, item, "flat-episodic-16x9")
	obj.GetDataContainer = getSpecialFeaturesDataContainer
	obj.playOnSelection = true

	return obj
	
End Function

Function getSpecialFeaturesDataContainer(viewController as Object, item as Object) as Object

	items = getSpecialFeatures(item.Id)

	if items = invalid
		return invalid
	end if

	obj = CreateObject("roAssociativeArray")
	obj.names = []
	obj.keys = []
	obj.items = items

	return obj

End Function

'**********************************************************
'** createAdditionalScreen
'**********************************************************

Function createAdditionalScreen(viewController as Object, item As Object) As Object

	' TODO: Add option to poster screen to play item directly when selected

	obj = CreatePosterScreen(viewController, item, "flat-episodic-16x9")
	obj.GetDataContainer = getAdditionalDataContainer
	obj.playOnSelection = true

	return obj
	
End Function

Function getAdditionalDataContainer(viewController as Object, item as Object) as Object

	items = getAdditionalParts(item.Id)

	if items = invalid
		return invalid
	end if

	obj = CreateObject("roAssociativeArray")
	obj.names = []
	obj.keys = []
	obj.items = items.items

	return obj

End Function

'**********************************************************
'** createPlaylistScreen
'**********************************************************

Function createPlaylistScreen(viewController as Object, item As Object) As Object

	' TODO: Add option to poster screen to play item directly when selected

	obj = CreatePosterScreen(viewController, item, "flat-episodic-16x9")
	obj.GetDataContainer = getPlaylistDataContainer
	obj.playOnSelection = true

	return obj
	
End Function

Function getPlaylistDataContainer(viewController as Object, item as Object) as Object

	items = getPlaylistParts(item.Id)

	if items = invalid
		return invalid
	end if

	obj = CreateObject("roAssociativeArray")
	obj.names = []
	obj.keys = []
	obj.items = items.items

	return obj

End Function

'**********************************************************
'** createLocalTrailersScreen
'**********************************************************

Function createLocalTrailersScreen(viewController as Object, item As Object) As Object

	' TODO: Add option to poster screen to play item directly when selected

	obj = CreatePosterScreen(viewController, item, "flat-episodic-16x9")
	obj.GetDataContainer = getLocalTrailersDataContainer
	obj.playOnSelection = true

	return obj

End Function


Function getLocalTrailersDataContainer(viewController as Object, item as Object) as Object

	items = getLocalTrailers(item.Id)

	if items = invalid
		return invalid
	end if

	obj = CreateObject("roAssociativeArray")
	obj.names = []
	obj.keys = []
	obj.items = items

	return obj

End Function

'**********************************************************
'** createTextDescriptionScreen
'**********************************************************

function createTextDescriptionScreen(viewController as Object, item as Object) as Object

	GetGlobalAA().AddReplace("theitem", item)
	obj = CreateObject("roAssociativeArray")
	initBaseScreen(obj, viewController)
	contenttype = item.contenttype
    	screen = CreateObject("roParagraphScreen")
	screen.SetMessagePort(obj.Port)
    	screen.SetTitle(item.title)
	screen.SetBreadCrumbText(item.Title,"Overview")
	if contenttype = "Episode" and item.SeriesName <> invalid
		screen.AddHeaderText(item.SeriesName+":"+chr(10)+item.Title)
	else if item.Tagline <> invalid
		screen.AddHeaderText(item.Title+chr(10)+item.Tagline)
	else
		screen.AddHeaderText(item.Title)
	end if
	reg = CreateObject("roRegex", chr(13), "")
	text = reg.ReplaceAll(item.fulldescription,"")
	reg = CreateObject("roRegex", chr(10), "")
	text = reg.ReplaceAll(text," ")
	screen.AddParagraph(text)
	screen.AddParagraph(" ")
    	screen.AddButton(1, "OK")
	if item.mediasources <> invalid and item.mediasources[0] <> invalid and item.LocationType <> "Virtual"
    		screen.AddButton(2, "Media Information")
	end if
    	screen.Show()

	obj.Screen = screen
	obj.HandleMessage = paraHandleMessage

  	return obj
End Function

Function paraHandleMessage(msg) As Boolean
	item = FirstOf(GetGlobalVar("theitem"),"")
  	handled = false
  	if type(msg) = "roParagraphScreenEvent" then
    		handled = true
    		if msg.isScreenClosed() then
      			m.ViewController.PopScreen(m)
		else if msg.isButtonPressed() then
			if msg.GetIndex() = 2
        			newScreen = createMediaInfoScreen(m.ViewController)
				newScreen.ScreenName = "MediaInfo" + item.Id
        			m.ViewController.InitializeOtherScreen(newScreen, [""])
				newScreen.Show()
			end if
			m.Screen.Close()
    		end if
	end if
	return handled
End Function

'**********************************************************
'** createMediaInfoScreen
'**********************************************************

function createMediaInfoScreen(viewController as Object) as Object
	item = FirstOf(GetGlobalVar("theitem"),"")
	obj = CreateObject("roAssociativeArray")
	initBaseScreen(obj, viewController)
    	screen = CreateObject("roTextScreen")
	screen.SetMessagePort(obj.Port)
    	screen.SetTitle("Media Information")
	screen.SetHeaderText("Media Sources")
	screen.SetBreadCrumbText(item.Title,"Media Information")
	di = CreateObject("roDeviceInfo")
	version = di.GetVersion()
	major = Mid(version, 3, 1).toInt()
	debug("::Media Information:: "+item.Title)
	text = "--- Media Details for "+ Item.Title + " ---"+chr(10)
	for each mediasection in item.mediasources[0]
		if left(type(item.mediasources[0][mediasection]),2) <> "ro"
			text = text + mediasection  + ": " + tostr(item.mediasources[0][mediasection]) + chr(10)
		end if
	end for
	text = text + chr(10)
	count = 0
	for each mediasource in item.mediasources[0].MediaStreams
		text = text + "---- Media Source # "+tostr(count)+" ----" + chr(10)
		count = count + 1
		for each mediaitem in mediasource
			text = text + mediaitem + ": " + tostr(mediasource[mediaitem]) + chr(10)
		end for
		text = text + chr(10)
	end for
	if major >= 7
		text = text + chr(10) + "---- OS7 Compatibility ----"+chr(10)
		di = CreateObject("roDeviceInfo")
		for each mediasource in item.mediasources[0].MediaStreams
			if mediasource.Type = "Video"
				codec = lcase(mediasource.codec)
				if codec = "h264"
					codec = "mpeg4 avc"
				else if codec = "mpeg1video"
					codec = "mpeg1"
				else if codec = "mpeg2video"
					codec = "mpeg2"
				end if
				if mediasource.level <> invalid
					l = tostr(mediasource.level)
					level = left(l,l.len()-1) + "." + right(l,1)
				else
					level = ""
				end if
				if codec <> ""
					if mediasource.profile <> invalid
						profile = lcase(mediasource.profile)
					else
						profile = ""
					end if
					container = ""
					if item.mediasources[0] <> invalid
						if item.mediasources[0].container <> invalid
							container = lcase(item.mediasources[0].container)
						end if
					end if
					attrib = {
						Codec: codec
						Profile: profile
						Level: level
						Container: container
					}
					for each i in attrib
						text = text + "[Has Video] "+i+": "
						m = attrib[i]
						if type(m) = "roString"
							text = text +m
						else if type(m) = "roInteger" or type(m) = "roInt"
							text = text + itostr(m)
						else if type(m) = "roBoolean"
							text = text + tostr(m)
						end if
						text = text + chr(10)
					end for
					d = di.CanDecodeVideo(attrib)
					for each i in d
						text = text + "[Can Decode Video] "+i+": "
						m = d[i]
						if type(m) = "roArray"
							for each j in m
								if type(j) = "roString"
									text = text +"'"+j+"' "
								else if type(j) = "roInteger" or type(j) = "roInt"
									text = text + "'"+itostr(j)+"' "
								end if
							end for
							text = text + chr(8) + chr(10)
						else if type(m) = "roString"
							text = text + m + chr(10)
						else if type(m) = "roInteger" or type(m) = "roInt"
							text = text + itostr(m) + chr(10)
						else if type(m) = "roBoolean"
							text = text + tostr(m) + chr(10)
						else
							text = text + chr(10)
						end if
					end for
				end if
			else if mediasource.Type = "Audio"
				if mediasource.bitrate <> invalid
					bitrate = Int(mediasource.bitrate / 1000)
				else
					bitrate = ""
				end if
				if mediasource.profile <> invalid
					profile = lcase(mediasource.profile)
				else
					profile = ""
				end if
				container = ""
				if item.mediasources[0] <> invalid
					if item.mediasources[0].container <> invalid
						container = lcase(item.mediasources[0].container)
					end if
				end if
					
				attrib = {
					Codec: lcase(mediasource.codec)
					Bitrate: bitrate
					Container: container
					ChCnt: mediasource.channels
					Profile: profile
					SampleRate: mediasource.samplerate
				}
				for each i in attrib
					text = text + "[Has Audio] "+i+": "
					m = attrib[i]
					if type(m) = "roString"
						text = text +m
					else if type(m) = "roInteger" or type(m) = "roInt"
						text = text + itostr(m)
					else if type(m) = "roBoolean"
						text = text + tostr(m)
					end if
					text = text + chr(10)
				end for
				d = di.CanDecodeAudio(attrib)
				for each i in d
					text = text + "[Can Decode Audio] "+i+": "
					m = d[i]
					if type(m) = "roArray"
						for each j in m
							if type(j) = "roString"
								text = text +"'"+j+ "' "
							else if type(j) = "roInteger" or type(j) = "roInt"
								text = text + "'"+itostr(j) + "' "
							end if
						end for
						text = text + chr(10)
					else if type(m) = "roString"
						text = text + m + chr(10)
					else if type(m) = "roInteger" or type(m) = "roInt"
						text = text + itostr(m) + chr(10)
					else if type(m) = "roBoolean"
						text = text + tostr(m) + chr(10)
					else
						text = text + chr(10)
					end if
				end for

			end if
		end for
	end if

	'lines = text.Split(chr(10))
	'for each line in lines
		screen.AddText(text)
	'end for
    	screen.AddButton(1, "OK")
    	screen.Show()

	obj.Screen = screen
	obj.HandleMessage = textMediaHandleMessage

  	return obj
End Function

Function textMediaHandleMessage(msg) As Boolean
  	handled = false
  	if type(msg) = "roTextScreenEvent" then
    		handled = true
    		if msg.isScreenClosed() then
      			m.ViewController.PopScreen(m)
		else if msg.isButtonPressed() then
			m.Screen.Close()
    		end if
	end if
	return handled
End Function

'**********************************************************
'** createDeviceInfoScreen
'**********************************************************

function createDevicenfoScreen(viewController as Object) as Object
	obj = CreateObject("roAssociativeArray")
	initBaseScreen(obj, viewController)
    	screen = CreateObject("roTextScreen")
	screen.SetMessagePort(obj.Port)
    	screen.SetTitle("Device Information")
	screen.SetHeaderText("About Your Device")

	text = ""
	di = CreateObject("roDeviceInfo")
	if FindMemberFunction(di, "GetVersion") <> invalid then
		if di.GetVersion() <> invalid
			version = di.GetVersion()
			major = Mid(version, 3, 1).toInt()
		else
			major = 7
		end if
	else
		major = 7
	end if

	if FindMemberFunction(di, "GetModel") <> invalid then
		if di.GetModel() <> invalid
			text = text + "Model: "+ di.GetModel() + chr(10)
		end if
	end if


	if FindMemberFunction(di, "GetModelDisplayName") <> invalid then
		if di.GetModelDisplayName() <> invalid
			text = text + "Model Display Name: "+ di.GetModelDisplayName() + chr(10)
		end if
	end if

	if FindMemberFunction(di, "GetModelDetails") <> invalid then
		if di.GetModelDetails() <> invalid
			d = di.GetModelDetails()
			for each i in d
				text = text + "[Model Details] "+i+": "+d[i]+chr(10)
			end for
		end if
	end if

	if FindMemberFunction(di, "GetVersion") <> invalid then
		if di.GetVersion() <> invalid
			text = text + "Version: "+ di.GetVersion() + chr(10)
		end if
	end if

	if FindMemberFunction(di, "GetDeviceUniqueId") <> invalid then
		if di.GetDeviceUniqueId() <> invalid
			text = text + "Device Unique ID: " + di.GetDeviceUniqueId() + chr(10)
		end if
	end if

	if FindMemberFunction(di, "GetFriendlyName") <> invalid then
		if di.GetFriendlyName() <> invalid
			text = text + "Friendly Name: " + di.GetFriendlyName() + chr(10)
		end if
	end if

	if FindMemberFunction(di, "GetAdvertisingId") <> invalid then
		if di.GetAdvertisingId() <> invalid
			text = text + "Adversting ID: " + di.GetAdvertisingId() + chr(10)
		end if
	end if

	if FindMemberFunction(di, "IsAdIdTrackingDisabled") <> invalid then
		if di.IsAdIdTrackingDisabled() <> invalid
			text = text + "Is AD ID Tracking Disabled: " + tostr(di.IsAdIdTrackingDisabled()) + chr(10)
		end if
	end if

	if FindMemberFunction(di, "GetPublisherId") <> invalid then
		if di.GetPublisherId() <> invalid
			text = text + "Publisher ID: " + di.GetPublisherId() + chr(10)
		end if
	end if

	if FindMemberFunction(di, "GetDisplayType") <> invalid then
		if di.GetDisplayType() <> invalid
			text = text + "Display Type: " + di.GetDisplayType() + chr(10)
		end if
	end if

	if FindMemberFunction(di, "GetDisplayMode") <> invalid then
		if di.GetDisplayMode() <> invalid
			text = text + "Display Mode: " + di.GetDisplayMode() + chr(10)
		end if
	end if

	if FindMemberFunction(di, "GetDisplayAspectRatio") <> invalid then
		if di.GetDisplayAspectRatio() <> invalid
			text = text + "Display Aspect Ratio: " + di.GetDisplayAspectRatio() + chr(10)
		end if
	end if

	if FindMemberFunction(di, "GetDisplaySize") <> invalid then
		if di.GetDisplaySize() <> invalid
			d = di.GetDisplaySize()
			for each i in d
				text = text + "[Display SIze] "+i+": "+itostr(d[i])+chr(10)
			end for
		end if
	end if

	if major >= 7

	    if FindMemberFunction(di, "GetDisplayProperties") <> invalid then
		if di.GetDisplayProperties() <> invalid
			d = di.GetDisplayProperties()
			for each i in d
				m = d[i]
				if type(m) = "roString"
					text = text + "[Display Properties] "+i+": "+m+chr(10)
				else if type(m) = "roInt"
					text = text + "[Display Properties] "+i+": "+itostr(m)+chr(10)
				else if type(m) = "roBoolean"
					text = text + "[Display Properties] "+i+": "+tostr(m)+chr(10)
				end if
			end for
		end if
	    end if

	    if FindMemberFunction(di, "GetSupportedGraphicsResolutions") <> invalid then
		if di.GetSupportedGraphicsResolutions() <> invalid
			d = di.GetSupportedGraphicsResolutions()
			for each h in d
				for each i in h
					m = h[i]
					if type(m) = "roString"
						text = text + "[Supported Graphics Resolution] "+i+": "+m+chr(10)
					else if type(m) = "roInt"
						text = text + "[Supported Graphics Resolution] "+i+": "+itostr(m)+chr(10)
					else if type(m) = "roBoolean"
						text = text + "[Supported Graphics Resolution] "+i+": "+tostr(m)+chr(10)
					end if
				end for
			end for
		end if
	    end if
	end if

	if FindMemberFunction(di, "GetTimeZone") <> invalid then
		if di.GetTimeZone() <> invalid
			text = text + "TimeZone: "+ di.GetTimeZone() + chr(10)
		end if
	end if

	if FindMemberFunction(di, "GetIPAddrs") <> invalid then
		if di.GetIPAddrs() <> invalid
			d = di.GetIPAddrs()
			for each i in d
				text = text + "[IP Address] "+i+": "+d[i]+chr(10)
			end for
		end if
	end if

	if FindMemberFunction(di, "GetCurrentLocale") <> invalid then
		if di.GetCurrentLocale() <> invalid
			text = text + "Current Locale: "+ di.GetCurrentLocale() + chr(10)
		end if
	end if

	if FindMemberFunction(di, "GetCountryCode") <> invalid then
		if di.GetCountryCode() <> invalid
			text = text + "Country Code: "+ di.GetCountryCode() + chr(10)
		end if
	end if

	if FindMemberFunction(di, "GetVideoMode") <> invalid then
		if di.GetVideoMode() <> invalid
			text = text + "Video Mode: "+ di.GetVideoMode() + chr(10)
		end if
	end if

	if FindMemberFunction(di, "GetAudioOutputChannel") <> invalid then
		if di.GetAudioOutputChannel() <> invalid
			text = text + "Audio Output Channel: "+ di.GetAudioOutputChannel() + chr(10)
		end if
	end if

	if FindMemberFunction(di, "GetLinkStatus") <> invalid then
		if di.GetLinkStatus() <> invalid
			text = text + "Link Status: "+ tostr(di.GetLinkStatus()) + chr(10)
		end if
	end if

	if FindMemberFunction(di, "GetCaptionsMode") <> invalid then
		if di.GetCaptionsMode() <> invalid
			text = text + "Captions Mode: "+ di.GetCaptionsMode() + chr(10)
		end if
	end if

	if FindMemberFunction(di, "GetVideoMode") <> invalid then
		if di.GetVideoMode() <> invalid
			text = text + "Video Mode: "+ di.GetVideoMode() + chr(10)
		end if
	end if

	if FindMemberFunction(di, "GetConnectionType") <> invalid then
		if di.GetConnectionType()  <> invalid
			text = text + "Connection Type: "+ di.GetConnectionType() + chr(10)
		end if
	end if

	if FindMemberFunction(di, "GetGetExternalIp") <> invalid then
		if di.GetExternalIp() <> invalid
			text = text + "External IP: "+ di.GetExternalIp() + chr(10)
		end if
	end if

	if FindMemberFunction(di, "GetConnectionInfo") <> invalid then
		if di.GetConnectionInfo()  <> invalid
			d = di.GetConnectionInfo() 
			for each i in d
				m = d[i]
				if type(m) = "roString"
					text = text + "[Connection Info] "+i+": "+m+chr(10)
				else if type(m) = "roInt"
					text = text + "[Connection Info] "+i+": "+itostr(m)+chr(10)
				else if type(m) = "roBoolean"
					text = text + "[Connection Info] "+i+": "+tostr(m)+chr(10)
				end if
			end for
		end if
	end if

	if FindMemberFunction(di, "GetAudioDecodeInfo") <> invalid then
		if di.GetAudioDecodeInfo() <> invalid
			d = di.GetAudioDecodeInfo()
			for each i in d
				text = text + "[Audio Decode Info] "+i+": "+d[i]+chr(10)
			end for
		end if
	end if

	if major >= 7

	    if FindMemberFunction(di, "GetDrmInfo") <> invalid then
		if di.GetDrmInfo() <> invalid
			d = di.GetDrmInfo()
			for each i in d
				text = text + "[DRM Info] "+i+": "+d[i]+chr(10)
			end for
			text = text + "Sound Effects Volume: "+ itostr(di.GetSoundEffectsVolume())  + chr(10)
		end if
	    end if

	    if FindMemberFunction(di, "GetUIResolution") <> invalid then
		if di.GetUIResolution() <> invalid
			d = di.GetUIResolution()
			for each i in d
				m = d[i]
				if type(m) = "roString"
					text = text + "[UI Resolution] "+i+": "+m+chr(10)
				else if type(m) = "roInt"
					text = text + "[UI Resolution] "+i+": "+itostr(m)+chr(10)
				else if type(m) = "roBoolean"
					text = text + "[UI Resolution] "+i+": "+tostr(m) + chr(10)
				end if
			end for
		end if
	    end if

	end if

	screen.SetBreadCrumbText("","Device Information")
	debug("::Device Information::")

	screen.AddText(text)
    	screen.AddButton(1, "OK")
    	screen.Show()

	obj.Screen = screen
	obj.HandleMessage = textDeviceHandleMessage

  	return obj
End Function

Function textDeviceHandleMessage(msg) As Boolean
  	handled = false
  	if type(msg) = "roTextScreenEvent" then
    		handled = true
    		if msg.isScreenClosed() then
      			m.ViewController.PopScreen(m)
		else if msg.isButtonPressed() then
			m.Screen.Close()
    		end if
	end if
	return handled
End Function


'**********************************************************
'** createDebugLogScreen
'**********************************************************

function createDebugLogScreen(viewController as Object) as Object

	obj = CreateObject("roAssociativeArray")
	initBaseScreen(obj, viewController)
    	screen = CreateObject("roTextScreen")
	screen.SetMessagePort(obj.Port)
    	screen.SetTitle("Debug Logs")
	screen.SetBreadCrumbText("","Debug Logs")
	screen.SetHeaderText("Debug Logs")
    	text = ReadAsciiFile("tmp:/embylog.txt")
	'lines = text.Split(chr(10))
	'for each line in lines
		screen.AddText(text)
	'end for
    	screen.AddButton(1, "OK")
    	screen.AddButton(2, "Clear logs")
    	screen.Show()

	obj.Screen = screen
	obj.HandleMessage = textHandleMessage

  	return obj
End Function

Function textHandleMessage(msg) As Boolean
  	handled = false
  	if type(msg) = "roTextScreenEvent" then
    		handled = true
    		if msg.isScreenClosed() then
      			m.ViewController.PopScreen(m)
		else if msg.isButtonPressed() then
			if msg.GetIndex() = 2 then WriteAsciiFile("tmp:/embylog.txt","")
			m.Screen.Close()
    		end if
	end if
	return handled
End Function

'**********************************************************
'** createPeopleScreen
'**********************************************************

function createPeopleScreen(viewController as Object, item as Object) as Object

    obj = CreatePosterScreen(viewController, item, "arced-poster")

	obj.GetDataContainer = getItemPeopleDataContainer

    return obj
end function

Function getItemPeopleDataContainer(viewController as Object, item as Object) as Object

    items = convertItemPeopleToMetadata(item.People)

    if items = invalid
        return invalid
    end if

	obj = CreateObject("roAssociativeArray")
	obj.names = []
	obj.keys = []
	obj.items = items

	return obj

End Function


'**********************************************************
'** createSimilarScreen
'**********************************************************

Function createSimilarScreen(viewController as Object, item as Object) As Object
	names = ["Movies","Shows"]
	if item.SeriesId <> invalid
		keys = [item.seriesid,item.seriesid]
	else
		keys = [item.id,item.id]
	end if

	loader = CreateObject("roAssociativeArray")
	loader.getUrl = getsimilarScreenUrl
	loader.parsePagedResult = parseSimilarScreenResult
	screen = createPaginatedGridScreen(viewController, names, keys, loader, "mixed-aspect-ratio", 50, 50)
        screen.SetDescriptionVisible(true)
	screen.displayDescription = 1
	return screen

End Function

Function getSimilarScreenUrl(row as Integer, id as String) as String

    	' URL
    	url = GetServerBaseUrl()
	query = {}
	
	if row = 0
		url = url  + "/Movies/" + HttpEncode(id) + "/Similar?recursive=true"
		include = "Movie"
	else
		url = url  + "/Shows/" + HttpEncode(id) + "/Similar?recursive=true"
		include = "Series"
	end if

	query.AddReplace("SortBy", "SortName")
	query.AddReplace("sortorder", "Ascending")
	query.AddReplace("fields", "Overview")
	query.AddReplace("userid", getGlobalVar("user").Id)
	query.AddReplace("IncludeItemTypes", include)
	'query.AddReplace("ImageTypeLimit", "1")
	'query.AddReplace("ParentId", m.parentId)
	for each key in query
		url = url + "&" + key +"=" + HttpEncode(query[key])
	end for
    return url
End Function

Function parseSimilarScreenResult(row as Integer, id as string, startIndex as Integer, json as String) as Object
	response = parseItemsResponse(json, 0, "mixed-aspect-ratio-portrait")
	if response.TotalCount > 50 then response.TotalCount = 50
	return response
End Function

Sub springboardShowFilmography(item)
	newScreen = createFilmographyScreen(m.viewController, item)
	newScreen.ScreenName = "Filmography" + item.Id		
	m.ViewController.InitializeOtherScreen(newScreen, [item.Title, "Filmography"])
	newScreen.Show()
End Sub

Sub createFavoritesDialog(item)

    dlg = createBaseDialog()
    dlg.Title = "Favorites Options"
    dlg.openParentDialog = true
    seriesName = item.seriesName
    if seriesName <> invalid and seriesName.len() > 25 then seriesName = left(seriesName,25) + "..."

    if item.ParentIndexNumber <> invalid then
      if item.IsFavorite then
        dlg.SetButton("removefavorite", "Remove Season " + tostr(item.ParentIndexNumber) + ", Episode " + tostr(item.IndexNumber) + " as a Favorite")
      else
        dlg.SetButton("markfavorite", "Mark Season " + tostr(item.ParentIndexNumber) + ", Episode " + tostr(item.IndexNumber) + " as a Favorite")
      end if
    else
      if item.IsFavorite then
	dlg.SetButton("removefavorite", "Remove as Favorite")
      else
	dlg.SetButton("markfavorite", "Mark as Favorite")
      end if
    end if


    'if item.parentIndexNumber <> invalid then
	'dlg.SetButton("markfavoriteseason", "Mark Season " + tostr(item.ParentIndexNumber) + " as a Favorite")
	'dlg.SetButton("removefavoriteseason", "Remove Season " + tostr(item.ParentIndexNumber) + " as a Favorite")
    'end if

    if item.SeriesName <> invalid then
	sh = getVideoMetadata(item.seriesId)
	if sh.isFavorite
		dlg.SetButton("removefavoriteseries", "Remove " + tostr(seriesName) + " as a Favorite")
	else
		dlg.SetButton("markfavoriteseries", "Mark " + tostr(seriesName) + " as a Favorite")
	end if
    end if

	dlg.item = item
	dlg.parentScreen = m.parentScreen

	dlg.HandleButton = handleFavoritesOptionsButton

    dlg.SetButton("close", "Close This Window")
    dlg.Show()
End Sub

Function handleFavoritesOptionsButton(command, data) As Boolean
	item = m.item
	itemId = item.Id
	screen = m

    if command = "removefavorite" then
		screen.refreshOnActivate = true
		m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
		result = postFavoriteStatus(itemId, false)
		if item.ParentIndexNumber <> invalid
			text = item.Title + chr(10) + "Season " + tostr(item.ParentIndexNumber) + ", Episode " + tostr(item.IndexNumber) + " of " + item.SeriesName
		else
			text = FirstOf(item.Title, "The episode")
		end if
		if result then
			createDialog("Favorites Changed", text + " has been removed from your favorites.", "OK", true)
		else
			createDialog("Favorites Error!", text + " has NOT been removed from your favorites.", "OK", true)
		end if
		m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
		return true
    else if command = "markfavorite" then
		screen.refreshOnActivate = true
		m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
		result = postFavoriteStatus(itemId, true)
		if item.ParentIndexNumber <> invalid
			text = item.Title + chr(10) + "Season " + tostr(item.ParentIndexNumber) + ", Episode " + tostr(item.IndexNumber) + " of " + item.SeriesName
		else
			text = FirstOf(item.Title, "The episode")
		end if
		if result then
			createDialog("Favorites Changed", text + " has been added to your favorites.", "OK", true)
		else
			createDialog("Favorites Error!", text + " has NOT been added to your favorites.", "OK", true)
		end if
		m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
		return true
    else if command = "removefavoriteseries" then
		screen.refreshOnActivate = true
		m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
		result = postFavoriteStatus(item.SeriesId, false)
		if result then
			createDialog("Favorites Changed", FirstOf(item.SeriesName, "The series") + " has been removed from your favorites.", "OK", true)
		else
			createDialog("Favorites Error!", FirstOf(item.SeriesName, "The series") + " has NOT been removed from your favorites.", "OK", true)
		end if
		m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
        	return true
    else if command = "markfavoriteseries" then
		screen.refreshOnActivate = true
		m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
		result = postFavoriteStatus(item.SeriesId, true)
		if result then
			createDialog("Favorites Changed", FirstOf(item.SeriesName, "The series") + " has been added to your favorites.", "OK", true)
		else
			createDialog("Favorites Error!", FirstOf(item.SeriesName, "The series") + " has NOT been added to your favorites.", "OK", true)
		end if
		m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
        	return true
    else if command = "close" then
		m.Screen.Close()
		return true
    end if
    return false
End Function

Sub createGoToDialog(item)

    dlg = createBaseDialog()
    dlg.Title = "Go To Options"
    dlg.openParentDialog = true

    if item.SeriesName <> invalid then
    	series = item.SeriesName
    	if series.len() > 25 then series = left(series,25) + "..."
	dlg.SetButton("series", "-> Go To " + FirstOf(series, "The series"))
    end if
    if item.Studios <> invalid and item.Studios.count() > 0
    	studio = item.Studios[0].Name
    	if studio.len() > 25 then series = left(studio,25) + "..."
	dlg.SetButton("studio", "-> Go To " + FirstOf(studio, "The studio"))
    end if
    if item.SeriesStudio <> invalid
    	studio = item.SeriesStudio
    	if studio.len() > 25 then series = left(studio,25) + "..."
	dlg.SetButton("network", "-> Go To " + FirstOf(studio, "The network"))
    end if
    if item.SeriesName <> invalid or item.contenttype = "Movie" or item.contenttype = "BoxSet" or item.contenttype = "Trailer"
	dlg.SetButton("similar", "-> Go To Similar Titles")
    end if
    musicstop = FirstOf(GetGlobalVar("musicstop"),"0")
    if AudioPlayer().Context <> invalid and musicstop = "0"
	dlg.SetButton("nowplaying", "-> Go To Now Playing")
	dlg.SetButton("jump","-> Go To Track List ("+tostr(AudioPlayer().Context.count())+" tracks)")
    end if
    dlg.SetButton("home", "-> Go To Home Screen")
    dlg.SetButton("preferences", "-> Go To Preferences")
    dlg.SetButton("search", "-> Go To Search Screen")
    dlg.SetButton("also", "-> Go To Also Watching")
    dlg.SetButton("close", "Close This Window")
    dlg.item = item
    dlg.parentScreen = m.parentScreen
    dlg.HandleButton = handleGoToOptionsButton
    dlg.Show()
End Sub

Function handleGoToOptionsButton(returned, data) As Boolean
	item = m.item
	itemId = item.Id
	screen = m

    if returned = "nowplaying"
	m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
	m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
	'screen.refreshOnActivate = true
        dummyItem = CreateObject("roAssociativeArray")
        dummyItem.ContentType = "audio"
        dummyItem.Key = "nowplaying"
        GetViewController().CreateScreenForItem(dummyItem, invalid, ["Now Playing"])
	return true

    else if returned = "home"
	'screen.refreshOnActivate = true
	while m.ViewController.screens.Count() > 0
		m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
	end while
	m.ViewController.CreateHomeScreen()
	return true

    else if returned = "jump"
	m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
	m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
	dummyItem = CreateObject("roAssociativeArray")
	dummyItem.ContentType = "MusicList"
	dummyItem.Key = "List"
	GetViewController().CreateScreenForItem(dummyItem, invalid, ["Now Playing"])
	return true

    else if returned = "preferences"
	m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
	m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
	'screen.refreshOnActivate = true
        dummyItem = CreateObject("roAssociativeArray")
        dummyItem.ContentType = "Preferences"
        dummyItem.Key = "Preferences"
        GetViewController().CreateScreenForItem(dummyItem, invalid, ["Preferences"])
	return true

    else if returned = "search"
	m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
	m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
	'screen.refreshOnActivate = true
        dummyItem = CreateObject("roAssociativeArray")
        dummyItem.ContentType = "Search"
        dummyItem.Key = "Search"
        GetViewController().CreateScreenForItem(dummyItem, invalid, ["Search"])
        return true

    else if returned = "also"
	m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
	m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
	'screen.refreshOnActivate = true
        dummyItem = CreateObject("roAssociativeArray")
        dummyItem.ContentType = "AlsoWatching"
        dummyItem.Key = "AlsoWatching"
        GetViewController().CreateScreenForItem(dummyItem, invalid, ["Also Watching"])
        return true

    else if returned = "series"
	m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
	m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
	'screen.refreshOnActivate = true
	series = getVideoMetadata(m.item.seriesId)
	series.ContentType = "Series"
	series.MediaType = "Series"
        GetViewController().CreateScreenForItem([series], 0, ["Shows", Series.Title])
        return true

    else if returned = "network"
	m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
	m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
	'screen.refreshOnActivate = true
	dummyItem = CreateObject("roAssociativeArray")
	dummyItem.ContentType = "SeriesStudios"
	dummyItem.MediaType = "Network"
	dummyItem.id = item.id
	dummyItem.Studio = item.SeriesStudio
        GetViewController().CreateScreenForItem(dummyItem, 0, ["Networks", item.SeriesStudio])
        return true

    else if returned = "studio"
	m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
	m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
	dummyItem = CreateObject("roAssociativeArray")
	dummyItem.ContentType = "MoviesStudios"
	dummyItem.MediaType = "Studio"
	dummyItem.id = item.id
	dummyItem.Studio = item.Studios[0].Name
        GetViewController().CreateScreenForItem(dummyItem, 0, ["Studios", item.Studios[0].Name])
        return true

    else if returned = "similar"
	m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
	m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
        newScreen = createSimilarScreen(m.ViewController, item)
	newScreen.ScreenName = "Similar" + itemId
	if item.SeriesName <> invalid
		m.ViewController.InitializeOtherScreen(newScreen, ["Similar To", item.SeriesName])
	else
		m.ViewController.InitializeOtherScreen(newScreen, ["Similar To", item.Title])
	end if
	newScreen.Show()
        return true

    else if returned = "close"
	m.Screen.Close()
    end if

    return false
End Function

Sub springboardShowMoreDialog(item)
    dlg = createBaseDialog()
    dlg.Title = "More Options"
    DeleteAll = firstOf(RegRead("prefDelAll"), "0")

	if item.MediaType = "Video" or item.MediaType = "Game" then 

		if item.MediaType = "Video" and item.BookmarkPosition <> 0 then
			time = tostr(formatTime(item.BookmarkPosition))
			dlg.SetButton("markplayed", "Clear the Resume Point of " + time)
		else if item.Watched
			dlg.SetButton("markunplayed", "Mark as Unplayed")
		else
			dlg.SetButton("markplayed", "Mark as Played")
		end if
	end if

    if item.SeriesName <> invalid then
    	dlg.SetButton("favorites", "Change Favorites ...")
    else if item.ContentType <> "Person"
	if item.IsFavorite
		dlg.SetButton("removefavorite", "Remove as Favorite")
	else
		dlg.SetButton("markfavorite", "Mark as Favorite")
	end if
    end if

    ' delete
    if item.CanDelete and DeleteAll = "1" Then
	da = FirstOf(getGlobalVar("adddelete"), "1")
	if da = "1"
		GetGlobalAA().AddReplace("adddelete", "0")
	else
        	dlg.SetButton("delete", "Delete Item")
	end if
    end if

    ' Check for people
    if item.People <> invalid and item.People.Count() > 0

	if item.MediaType = "Video" then
		if item.LocalTrailerCount <> invalid and item.LocalTrailerCount > 0
			dlg.SetButton("cast", "Cast & Crew")
		end if
	else
		dlg.SetButton("people", "People")
	end If
    end if
   if item.SeriesName <> invalid then
	sh = getVideoMetadata(item.seriesId)
	if sh.People <> invalid and sh.People.Count() > 0
		dlg.SetButton("maincast", "Main Cast & Crew")
	end if
    end if

    ' Check for special features
    if item.SpecialFeatureCount <> invalid and item.SpecialFeatureCount > 0
        dlg.SetButton("specials", "Special Features")
    end if

	' check for additonal parts
        if item <> invalid
		if item.id <> invalid
 			if item.contenttype <> "Program" and item.contenttype <> "Recording"
				additional = getAdditionalParts(item.Id)
				if additional <> invalid and additional.totalcount <> invalid and additional.totalcount > 0
					dlg.SetButton("addition", "Additional Parts")
				end if
			end if
		end if
	end if

	dlg.item = item
	dlg.parentScreen = m

	dlg.HandleButton = handleMoreOptionsButton

	dlg.SetButton("goto", "-> Go To ...")

	if (item.LocationType <> "Virtual" or item.ContentType = "TvChannel") And item.PlayAccess = "Full" and item.MediaType = "Video" then
		force = FirstOf(regRead("prefPlayMethod"),"Auto")
		private = FirstOf(regRead("prefprivate"),"0")
		'if force <> "DirectPlay" then 
		'	dlg.SetButton("DirectPlay", "* Force DirectPlay")
		'else
		'	dlg.SetButton("DirectPlay", "* Force DirectPlay [Selected]")
		'end if

		if left(force,6) <> "Direct" then 
			dlg.SetButton("Direct", "* Force Direct")
		else
			dlg.SetButton("Direct", "* Force Direct [Selected]")
		end if

		if force <> "Transcode" then 
			dlg.SetButton("Transcode", "* Force Transcode")
		else
			dlg.SetButton("Transcode", "* Force Transcode [Selected]")
		end if

		if force <> "Trans-DS" then 
			dlg.SetButton("Trans-DS", "* Force Transcode w/o Stream Copy")
		else
			dlg.SetButton("Trans-DS", "* Force Transcode w/o Stream Copy [Selected]")
		end if

		if force = "Auto" and private = "0" then 
			dlg.SetButton("Auto", "* Use Auto-Detection [Selected]")
		else
			dlg.SetButton("Auto", "* Use Auto-Detection")
		end if

		if force = "Auto" and private = "1" then 
			dlg.SetButton("Auto2", "* Use Auto-Detection Private [Selected]")
		else 
			dlg.SetButton("Auto2", "* Use Auto-Detection Private")
		end if
	end if
    dlg.SetButton("close", "Close This Window")
    dlg.Show()

End Sub

Function handleMoreOptionsButton(command, data) As Boolean

	item = m.item
	itemId = item.Id
	screen = m.parentScreen

    if command = "favorites" then
	screen.refreshOnActivate = true
	createFavoritesDialog(item)

    else if command = "goto" then
	screen.refreshOnActivate = true
	createGoToDialog(item)

    else if command = "cast" then
        newScreen = createPeopleScreen(m.ViewController, item)
	newScreen.ScreenName = "People" + itemId
        m.ViewController.InitializeOtherScreen(newScreen, [item.Title, "Cast & Crew"])
	newScreen.Show()
        return true
    else if command = "maincast" then
	series = getVideoMetadata(m.item.seriesId)
        newScreen = createPeopleScreen(m.ViewController, series)
	newScreen.ScreenName = "People" + itemId
        m.ViewController.InitializeOtherScreen(newScreen, [item.Title, "Cast & Crew"])
	newScreen.Show()
        return true
    else if command = "people" then
	newScreen = createPeopleScreen(m.ViewController, item)
	newScreen.ScreenName = "People" + itemId
	m.ViewController.InitializeOtherScreen(newScreen, [item.Title, "People"])
	newScreen.Show()
	return true
    else if command = "markunplayed" then
	screen.refreshOnActivate = true
	postWatchedStatus(itemId, false)
	return true
    else if command = "markfavorite" then
	screen.refreshOnActivate = true
	result = postFavoriteStatus(itemId, true)
	if item.ParentIndexNumber <> invalid
		text = item.Title + chr(10) + "Season " + tostr(item.ParentIndexNumber) + ", Episode " + tostr(item.IndexNumber) + " of " + item.SeriesName
	else
		text = FirstOf(item.Title, "The item")
	end if
	if result then
		createDialog("Favorites Changed", text + " has been added to your favorites.", "OK", true)
	else
		createDialog("Favorites Error!", text + " has NOT been added to your favorites.", "OK", true)
	end if
        return true
    else if command = "removefavorite" then
	screen.refreshOnActivate = true
	result = postFavoriteStatus(itemId, false)
	if item.ParentIndexNumber <> invalid
		text = item.Title + chr(10) + "Season " + tostr(item.ParentIndexNumber) + ", Episode " + tostr(item.IndexNumber) + " of " + item.SeriesName
	else
		text = FirstOf(item.Title, "The item")
	end if
	if result then
		createDialog("Favorites Changed", text + " has been removed from your favorites.", "OK", true)
	else
		createDialog("Favorites Error!", text + " has NOT been removed from your favorites.", "OK", true)
	end if
        return true
    else if command = "markplayed" then
	screen.refreshOnActivate = true
	postWatchedStatus(itemId, true)
	return true
    else if command = "specials" then
        newScreen = createSpecialFeaturesScreen(m.ViewController, item)
	newScreen.ScreenName = "Specials" + itemId
	m.ViewController.InitializeOtherScreen(newScreen, [item.Title, "Special Features"])
	newScreen.Show()
	return true
    else if command = "addition" then
        newScreen = createAdditionalScreen(m.ViewController, item)
	newScreen.ScreenName = "Additional" + itemId
	m.ViewController.InitializeOtherScreen(newScreen, [item.Title, "Additional Parts"])
	newScreen.Show()
	return true
    else if command = "delete" then
	springboardDeleteItem(item)
	m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
	return true
    else if left(command,6) = "Direct" or left(command,5) = "Trans" or command = "Auto" then
	regWrite("prefPlayMethod",command)
	regwrite("prefprivate", "0")
	getDeviceProfile()
	m.Screen.Close()
	screen.refreshOnActivate = true
	return true
    else if command = "Auto2" then
	regWrite("prefPlayMethod","Auto")
	regwrite("prefprivate", "1")
	getDeviceProfile()
	m.Screen.Close()
	screen.refreshOnActivate = true
	return true
    else if command = "homescreen"
	while m.ViewController.screens.Count() > 0
		m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
	end while
	m.ViewController.CreateHomeScreen()
	return true
    else if command = "close" then
	m.Screen.Close()
	return true
    end if
	
    return false

End Function

Sub springboardShowStreamsDialog(item)

    createAudioAndSubtitleDialog(m.audioStreams, m.subtitleStreams, m.PlayOptions)
End Sub

'******************************************************
' createAudioAndSubtitleDialog
'******************************************************

Sub createAudioAndSubtitleDialog(audioStreams, subtitleStreams, playOptions)

    Debug ("createAudioAndSubtitleDialog")
	Debug ("Current AudioStreamIndex: " + tostr(playOptions.AudioStreamIndex))
	Debug ("Current SubtitleStreamIndex: " + tostr(playOptions.SubtitleStreamIndex))
	
    if audioStreams.Count() > 1 or subtitleStreams.Count() > 0
		dlg = createBaseDialog()
		dlg.Title = "Audio & Subtitles"

		dlg.HandleButton = handleAudioAndSubtitlesButton

		dlg.audioStreams = audioStreams
		dlg.subtitleStreams = subtitleStreams
		dlg.playOptions = playOptions

		dlg.SetButton("audio", "Audio ...")
		dlg.SetButton("subtitles", "Subtitles ...")
		dlg.SetButton("close", "Close This Window")

		dlg.Show(true)

    end if

End Sub

Function handleAudioAndSubtitlesButton(command, data) As Boolean

	if command = "audio" then

		createStreamSelectionDialog("Audio", m.audioStreams, m.subtitleStreams, m.playOptions, true)
        return true

    else if command = "subtitles" then

		createStreamSelectionDialog("Subtitle", m.audioStreams, m.subtitleStreams, m.playOptions, true)
        return true

    else if command = "close" then

		return true

    end if

    return true
End Function

Sub createStreamSelectionDialog(streamType, audioStreams, subtitleStreams, playOptions, openParentDialog)

	dlg = createBaseDialog()
	dlg.Title = "Select " + streamType
	dlg.HandleButton = handleStreamSelectionButton
	dlg.streamType = streamType
	dlg.audioStreams = audioStreams
	dlg.subtitleStreams = subtitleStreams
	dlg.playOptions = playOptions
	dlg.openParentDialog = openParentDialog
	if streamType = "Subtitle" then 
		streams = subtitleStreams
		currentIndex = playOptions.SubtitleStreamIndex

		title = "None"
		if currentIndex = invalid or currentIndex = -1 then title = title + " [Selected]"
		dlg.SetButton("none", title)
	else
		streams = audioStreams
		currentIndex = playOptions.AudioStreamIndex
	end If
	for each stream in streams
		' dialog maxes out at 10 buttons
		' springboard maxes out at 6 buttons
		' -- credit waldonnis
		if dlg.Buttons.Count() < 9
			if streamType = "Subtitle"
				if stream.IsExternal
					title = "External "
				else
					title = "Internal "
				end if
				title = title + UCase(stream.Codec)
				name = firstOf(stream.Language, "Unknown L")
				title = title + " [" + UCase(left(name,1))+right(name,name.len()-1) +"]"
				' Append (F) to denote a forced subtitle stream
				if stream.isForced
					title = title + " (Forced)"
				else if stream.isDefault
					title = title + " (Default)"
				end if
			else if streamType = "Audio"
				' Show stream title (if present), codec, channel layout and
				' bracketed language in the audio stream list
				title = firstOf(stream.Codec, "Unknown C")
				if toStr(stream.Codec) = "dca"
					title = "dts"
				else
					title = toStr(stream.Codec)
				end if
				chanlay = firstOf(stream.ChannelLayout, "")
				if chanlay <> "" then chanlay = UCase(left(chanlay,1))+right(chanlay,chanlay.len()-1)
				title = UCase(title) + " " + chanlay

				' Show stream title if present in addition to the codec/layout
				if (type(stream.Title) = "String") and (Len(stream.Title) > 0)
					title = stream.Title + " (" + title + ")"
				end if
				lang = firstof(stream.Language, "Unknown L")
				lang = UCase(left(lang,1))+right(lang,lang.len()-1)
				title = title + " [" + lang + "]"
				if stream.isForced
					title = title + " (Forced)"
				else if stream.isDefault
					title = title + " (Default)"
				end if
			end if
			if currentIndex = stream.Index then title = title + " [Selected]"
			dlg.SetButton(tostr(stream.Index), title)
		end if
	end For
	dlg.SetButton("close", "Cancel")
	dlg.Show(true)
End Sub

Function handleStreamSelectionButton(command, data) As Boolean

    if command = "none" then

		m.playOptions.HasSelection = true
		
		if m.streamType = "Audio" then
			m.playOptions.AudioStreamIndex = -1
		else
			m.playOptions.SubtitleStreamIndex = -1
		end If

		if m.openParentDialog = true then createAudioAndSubtitleDialog(m.audioStreams, m.subtitleStreams, m.playOptions)

        return true
    else if command = "close" or command = invalid then

		if m.openParentDialog = true then createAudioAndSubtitleDialog(m.audioStreams, m.subtitleStreams, m.playOptions)
        return true

	else if command <> invalid then

		m.playOptions.HasSelection = true
		
		if m.streamType = "Audio" then
			m.playOptions.AudioStreamIndex = command.ToInt()
		else
			m.playOptions.SubtitleStreamIndex = command.ToInt()
		end If

		if m.openParentDialog = true then createAudioAndSubtitleDialog(m.audioStreams, m.subtitleStreams, m.playOptions)

		return true
    end if

    return false
End Function

'******************************************************
' Cancel Timer Dialog
'******************************************************

Function showCancelLiveTvTimerDialog()
	return showContextViewMenuYesNoDialog("Confirm Action", "Are you sure you wish to cancel this recording?")
End Function


'******************************************************
' Delete Recording Dialog
'******************************************************

Function showDeleteRecordingDialog(item)
	return showContextViewMenuYesNoDialog("Confirm Action", "Are you sure you wish to permanently delete " +item.Title+" from your library?")
End Function

Sub springboardDeleteItem(item)
	if showDeleteRecordingDialog(item) = "1" then
        	deleteLiveTvRecording(item)
		m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
	end if
End Sub

Sub springboardCancelTimer(item)
	m.refreshOnActivate = true

	if showCancelLiveTvTimerDialog() = "1" then
        cancelLiveTvTimer(item.TimerId)
		m.Refresh(true)
	end if
End Sub

Sub springboardRecordProgram(item)
	m.refreshOnActivate = true

    timerInfo = getDefaultLiveTvTimer(item.Id)
    createLiveTvTimer(timerInfo)
	
	m.Refresh(true)
End Sub
