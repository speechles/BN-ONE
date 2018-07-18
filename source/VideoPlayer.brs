'*
'* A wrapper around a video player that implements our screen interface.
'*

'** Credit: Plex Roku https://github.com/plexinc/roku-client-public

'**********************************************************
'** getPlayConfiguration
'**********************************************************

Function getPlayConfiguration(context, contextIndex, playOptions, remote = false)
	if NOT remote
		if context.count() > 1
			loadingDialog = CreateObject("roOneLineDialog")
			loadingDialog.SetTitle("Verifying "+tostr(context.count())+" Items are playable...")
			loadingDialog.ShowBusyAnimation()
			loadingDialog.Show()
		end if
		list = []
		initialItem = context[contextIndex]
		if initialitem <> invalid then initialItem.PlayOptions = playOptions
		DisableCinema = FirstOf(RegRead("prefDisableCinema"),"no")
		if DisableCinema = "no" and playOptions.PlayStart = 0 and playOptions.intros <> false
			intros = getVideoIntros(initialItem.Id)
			if intros <> invalid
				for each i in intros.Items		
					i.PlayOptions = {}
					list.push(i)
				end for
			end if
		end if
		currentIndex = 0
		purgedItems = 0
		addedItems = 0
	
		for each i in context	
			if currentIndex >= contextIndex and i <> invalid and i.locationtype <> invalid
				if i.contenttype = "Program" or (i.contentType <> "Program" and i.locationtype <> "Virtual")
					addedItems = addedItems + 1
					list.push(i)
					if i.id <> invalid
 						if i.contenttype <> "Program" and i.contenttype <> "Recording"
							additional = getAdditionalParts(i.Id)
        						if additional <> invalid and additional.totalcount <> invalid and additional.totalcount > 0
								for each i in additional.Items		
									i.PlayOptions = {}
									list.push(i)
								end for
							end if
						end if
					end if
				else
					purgedItems = purgedItems + 1
				end if
			end if	
			currentIndex = currentIndex + 1
		end for
		debug(":::Configuration::: Video Player - Total "+tostr(context.count())+" - Skipped "+tostr(purgedItems)+" - Added "+tostr(addedItems))

		if context.count() > 1 then loadingDialog.close()
	else
		list = []
		for each i in context
			i.PlayOptions = playOptions
			list.push(i)
		end for
		debug(":::Configuration via Remote::: Video Player - Total "+tostr(context.count()))
	end if
	GetGlobalAA().AddReplace("playbackerror", "0")
	return {
		Context: list
		CurIndex: 0
	}
End Function

Function createVideoPlayerScreen(context, contextIndex, playOptions, viewController, remote = false)
	obj = CreateObject("roAssociativeArray")
	initBaseScreen(obj, viewController)
	playConfig = getPlayConfiguration(context, contextIndex, playOptions, remote)
	obj.Context = playConfig.Context
	obj.CurIndex = playConfig.CurIndex
	obj.Show = videoPlayerShow
	obj.HandleMessage = videoPlayerHandleMessage
	obj.OnTimerExpired = videoPlayerOnTimerExpired
	obj.CreateVideoPlayer = videoPlayerCreateVideoPlayer
	obj.StartTranscodeSessionRequest = videoPlayerStartTranscodeSessionRequest
	obj.OnUrlEvent = videoPlayerOnUrlEvent
	obj.pingTimer = invalid
	obj.lastPosition = 0
	obj.isPlayed = false
	obj.playbackError = false
	obj.changeStream = false
	obj.underrunCount = 0
	obj.interactionTimeout = FirstOf(regread("prefinteraction"), "18000").ToInt()
	obj.shown = invalid
	obj.timelineTimer = invalid
	obj.progressTimer = invalid
	obj.sleepTimer = invalid
	obj.kickTimer = invalid
	obj.playState = "buffering"
	obj.bufferingTimer = createTimer()
	obj.LastProgressReportTime = 0
	obj.ShowPlaybackError = videoPlayerShowPlaybackError
	obj.UpdateNowPlaying = videoPlayerUpdateNowPlaying
	obj.Pause = videoPlayerPause
	obj.Resume = videoPlayerResume
	obj.Next = videoPlayerNext
	obj.Prev = videoPlayerPrev
	obj.Stop = videoPlayerStop
	obj.Seek = videoPlayerSeek
	obj.SetAudioStreamIndex = videoPlayerSetAudioStreamIndex
	obj.SetSubtitleStreamIndex = videoPlayerSetSubtitleStreamIndex
	obj.ReportPlayback = videoPlayerReportPlayback
	obj.ConstructVideoItem = videoPlayerConstructVideoItem
	obj.StopTranscoding = videoPlayerStopTranscoding
	return obj
End Function

Function VideoPlayer()
	' If the active screen is a slideshow, return it. Otherwise, invalid.
	screen = GetViewController().screens.Peek()
	if type(screen.Screen) = "roVideoScreen" then
		return screen
	else
		return invalid
	end if
End Function

Sub videoPlayerShow()
	' We only fall back automatically if we originally tried to Direct Play
	' and the preference allows fallback. One potential quirk is that we do
	' fall back if there was progress on the Direct Play attempt. This should
	' be quite uncommon, but if something happens part way through the file
	' that the device can't handle, we at least give transcoding (from there)
	' a shot.

	' SPEED UP SHIT!!
	RunGarbageCollector()

	if m.playbackError then
		createDialog("Playback Error!", "Error while playing video, nothing left to fall back to. Cannot continue.", "OK", true)
		Debug("Error while playing video, nothing left to fall back to")
		m.ShowPlaybackError("")
		m.Screen = invalid
		m.popOnActivate = true
	else
		item = m.Context[m.CurIndex]
		if item <> invalid
			if item.PlayOptions <> invalid
				m.PlayOptions = item.PlayOptions
			else
				m.PlayOptions = {}
			end if	
			m.Screen = m.CreateVideoPlayer(item, m.PlayOptions)
		end if
	end if
	m.changeStream = false
	if m.Screen <> invalid then
		if m.IsTranscoded then
			Debug("Starting to play transcoded video")
		else
			Debug("Starting to direct play video")
		end if
		Debug("Playback url: " + m.VideoItem.Stream.Url)
		BreakKeyframes = FirstOf(RegRead("prefBreakKeyframes"),"false")
		if BreakKeyframes = "true"
			m.VideoItem.Stream.Url = m.VideoItem.Stream.Url.Replace("BreakOnNonKeyFrames=False","BreakOnNonKeyFrames=True")
			Debug("Adjusted Playback url: " + m.VideoItem.Stream.Url)
		end if
		m.timelineTimer = createTimer()
		m.timelineTimer.Name = "timeline"
		m.timelineTimer.SetDuration(15000, true)
		m.ViewController.AddTimer(m.timelineTimer, m)
		m.progressTimer = createTimer()
		m.progressTimer.Name = "progress"
		m.progressTimer.SetDuration(2000, true)
		m.progressTimer.Active = false
		m.ViewController.AddTimer(m.progressTimer, m)
		m.Screen.Show()
		NowPlayingManager().location = "fullScreenVideo"
	else
		m.ViewController.PopScreen(m)
		NowPlayingManager().location = "navigation"
	end if
End Sub

Function videoPlayerCreateVideoPlayer(item, playOptions)
	Debug("MediaPlayer::playVideo: Displaying video: " + tostr(item.title))
	if item.IsPlaceHolder = true then
		m.ShowPlaybackError("PlaceHolder")
		return invalid
	end if
	videoItem = m.ConstructVideoItem(item, playOptions)
	if videoItem = invalid or videoItem.Stream = invalid then
		createDialog("Playback Error!", "No videoItem or VideoItem.Stream found. (invalid)", "OK", true)
		return invalid
	end if
	timeout = FirstOf(RegRead("prefvtimeout"),"30").toInt()
	player = CreateObject("roVideoScreen")
	player.SetConnectionTimeout(timeout)
	player.SetMessagePort(m.Port)
	player.SetPositionNotificationPeriod(1)
	player.EnableCookies()

	pberr = GetGlobalVar("playbackerror", "0").toInt()
	if pberr < 1
		' Reset these
		m.isPlayed = false
		m.lastPosition = 0
		m.playbackError = false
		m.changeStream = false
		m.underrunCount = 0
		m.errorCount = 0
		m.timelineTimer = invalid
		m.progressTimer = invalid
	end if
	m.playState = "buffering"
	m.IsTranscoded = videoItem.StreamInfo.PlayMethod = "Transcode"
	m.videoItem = videoItem
	if m.IsTranscoded then
        	cookie = StartTranscodingSession(videoItem.Stream.Url)
        	if cookie <> invalid then
            		player.AddHeader("Cookie", cookie)
		end if
		m.playMethod = "Transcode"	
	else
		m.playMethod = "DirectStream"
	end if
	addBifInfo(videoItem)
	m.canSeek = videoItem.StreamInfo.CanSeek
	Debug ("Setting PlayStart to " + tostr(playOptions.PlayStart))
	m.Playstart = playOptions.PlayStart
	videoItem.PlayStart = playOptions.PlayStart
	if Instr(0, videoItem.Stream.Url, "https:") <> 0 then 
		player.setCertificatesFile("common:/certs/ca-bundle.crt")
	end if
	videoItem.ReleaseDate = videoItem.ReleaseDate + chr(10)
	player.SetContent(videoItem)
	versionArr = getGlobalVar("rokuVersion")
	if CheckMinimumVersion(versionArr, [4, 9]) AND videoItem.SubtitleUrl <> invalid then
		player.ShowSubtitle(true)
	end if
	return player
End Function

Sub addBifInfo(item)
	itemId = item.Id
	mediaSourceId = item.StreamInfo.MediaSource.Id
	if IsBifServiceAvailable(item) = true then
		item.HDBifUrl = GetServerBaseUrl() + "/Videos/" + itemId + "/index.bif?width=320&mediaSourceId=" + mediaSourceId
		item.SDBifUrl = GetServerBaseUrl() + "/Videos/" + itemId + "/index.bif?width=240&mediaSourceId=" + mediaSourceId
	end if
End Sub

Function IsBifServiceAvailable(item)
	if item.ServerId = invalid then
		return false
	end if
	viewController = GetViewController()
	if viewController.serverPlugins = invalid then
		viewController.serverPlugins = CreateObject("roAssociativeArray")
	end if
	if viewController.serverPlugins[item.ServerId] = invalid then
		viewController.serverPlugins[item.ServerId] = getInstalledPlugins()
	end if
	if viewController.serverPlugins[item.ServerId] <> invalid then
		for each serverPlugin in viewController.serverPlugins[item.ServerId]
			if serverPlugin.Name = "Roku Thumbnails" then
				return true
			end if
		end for
	end if
	return false
End Function

Sub videoPlayerShowPlaybackError(code)
	dialog = createBaseDialog()
	dialog.Title = "Video Unavailable"
	if code = "PlaceHolder" then
		dialog.Text = "The content chosen is not playable from this device."
	else
		dialog.Text = "We're unable to play this video, make sure the server is running and has access to this video."
	end if
	dialog.Show()
End Sub

Function videoPlayerHandleMessage(msg) As Boolean
	handled = false
	event = "::roVideoScreenEvent - "
	if type(msg) = "roVideoScreenEvent" then
		handled = true
		if msg.isScreenClosed() then
			GetGlobalAA().AddReplace("bandwidth", invalid)
			m.timelineTimer.Active = false
			m.playState = "stopped"
			Debug(event + "isScreenClosed: position -> " + tostr(m.lastPosition))
			t = FirstOf(regRead("prefPlayMethod"),"Auto")
			if m.playbackError
				pberr = GetGlobalVar("playbackerror", "0").toInt()
				GetGlobalAA().AddReplace("playbackerror", tostr(pberr + 1))
				ThrowError = FirstOf(RegRead("preffallbackretry"),"1").toInt()
				if pberr >= ThrowError
					if m.Context.Count() = 1
						GetGlobalAA().AddReplace("playbackerror", "0")
						if t = "DirectPlay" then
							createDialog("Playback Error!", "The Video Player has closed prematurely. Your play method is Force DirectPlay. Forcing DirectPlay is NOT supported on the roku at this time."+chr(10)+chr(10)+"Change your play method to FORCE DIRECTSTREAM or one of the USE AUTO DETECTION choices. Sorry."+chr(10), "OK", true)
						else if left(t,4) = "Auto" then
							createDialog("Playback Error!", "The Video Player has closed prematurely. Your play method is Use Auto Detection. This error can be caused by a corrupt video stream, or a corrupt item in your library."+chr(10)+chr(10)+"If you are sure the item is not corrupt then please report this video on emby forums so that we can help diagnose your playback error. Thank you and apologies for the issue."+chr(10), "OK", true)
						else if t = "Direct" then
							createDialog("Playback Error!", "The Video Player has closed prematurely. Your play method is Force Direct. Change the play method to one of the USE AUTO DETECTION choices and try again."+chr(10), "OK", true)
						else
							createDialog("Playback Error!", "The Video Player has closed prematurely. Your play method is Force Transcoding. Change the play method to one of the USE AUTO DETECTION choices and try again."+chr(10), "OK", true)
						end if
					else
						m.isPlayed = true
						m.playbackError = false
						item = m.Context[m.CurIndex]
    						dialog = CreateObject("roMessageDialog")
    						dialog.SetTitle("Playback Error!")
						if left(t,4) = "Auto" then
							tt = "Auto-Detection"
						else
							tt = "Force "+t
						end if
						dialog.SetText("Skipping Unplayable Item:"+chr(10)+item.title+chr(10)+"Your play method is "+tt+" which failed.")
						if pberr > 0
							dialog.SetText("Fallback to force transcoding also failed.")
						end if
						debug("::Warning:: Skipping Unplayable Item: "+item.title+". Play method is "+tt)
    						dialog.Show()
						GetGlobalAA().AddReplace("playbackerror", "0")
						sleep(1500)
						dialog.Close()

					end if
				else
					if m.lastposition = 0 and m.PlayStart <> invalid then m.lastposition = m.PlayStart
					Force = FirstOf(regRead("prefPlayMethod"), "Auto")
					m.playbackError = false
					m.isTranscoded = true
					if m.Context[m.CurIndex].PlayOptions <> invalid
						m.Context[m.CurIndex].PlayOptions.PlayStart = m.lastPosition
					end if
					regWrite("prefPlayMethod", "Transcode")
					debug("::Warning:: Falling back to transcoding")
					m.show()
					regWrite("prefPlayMethod", Force)

					return true
				end if
			end if
			NowPlayingManager().location = "navigation"
			m.ReportPlayback("stop")
			m.UpdateNowPlaying()
			if m.isPlayed = true AND m.Context.Count() > (m.CurIndex + 1)
				GetGlobalAA().AddReplace("playbackerror", "0")
				m.CurIndex = m.CurIndex + 1
				m.Facade = CreateObject("roPosterScreen")
				m.Facade.Show()
				m.Show()
			else if m.changeStream
				m.changeStream = false
				m.Show()
			else
				pm = FirstOf(regRead("prefPlayMethod"), "Auto")
				rm = FirstOf(regRead("prefResetMethod"), "1")
				if pm <> "Auto" and rm = "1"
					regWrite("prefPlayMethod", "Auto")
					regWrite("prefprivate", "0")
				end if
				if m.KeepAliveDialog <> invalid
					m.KeepAliveDialog.close()
				end if
				if m.TimeoutTimer <> invalid
					m.TimeoutTimer = invalid
				end if
				m.ViewController.PopScreen(m)
			end if
		else if msg.isStatusMessage() then
			a$ = itostr(msg.GetIndex()) : b$ = itostr(msg.GetData())
			Debug(event + "Video Status: " + a$ + " " + b$)
		else if msg.isButtonPressed()
			a$ = FirstOf(msg.GetIndex(),"Invalid") : b$ = FirstOf(msg.GetData(),"Invalid")
			Debug(event + "Button Pressed: " + a$ + " " + b$)
		else if msg.isStreamStarted() then
			Debug(event + "isStreamStarted: position -> " + tostr(m.lastPosition))
			i = msg.GetInfo()
			if i.IsUnderrun then
                		m.underrunCount = m.underrunCount + 1
                		if m.underrunCount = 4 then
                    			Debug ("Video is underrun")
                		end if
            		end if
			if m.lastPosition = 0 then m.ReportPlayback("start")
			GetGlobalAA().AddReplace("streambitrate", tostr(i.StreamBitrate))
			m.VideoItem.rokuStreamBitrate = i.StreamBitrate
			m.StartTranscodeSessionRequest()
			'if m.lastPosition >= 0 then updateVideoHUD(m,m.lastPosition)
		else if msg.isPlaybackPosition() then
			if m.bufferingTimer <> invalid then
                		m.bufferingTimer = invalid
			end if
			m.lastPosition = msg.GetIndex()
			Debug(event + "isPlaybackPosition: set progress -> " + tostr(m.lastPosition))
			m.playState = "playing"
			m.progressTimer.Active = true
			m.ReportPlayback("progress")
			m.UpdateNowPlaying(true)
			if m.lastPosition <> invalid and m.lastPosition >= 0 then updateVideoHUD(m,m.lastPosition)
		else if msg.isRequestFailed() then
			mess = msg.GetMessage()
			Debug(event + "isRequestFailed - message = " + tostr(mess))
			Debug(event + "isRequestFailed - data = " + tostr(msg.GetData()))
			Debug(event + "isRequestFailed - index = " + tostr(msg.GetIndex()))
			m.playbackError = true
    			dialog = CreateObject("roMessageDialog")
    			dialog.SetTitle("Video Playback Error!")
			dialog.SetText("A fatal playback error has occured:"+chr(10)+tostr(mess)+chr(10))
			dialog.Show()
			sleep(1500)
			dialog.Close()
		else if msg.isPaused() then
			Debug(event + "isPaused: position -> " + tostr(m.lastPosition))
			m.playState = "paused"
			m.progressTimer.Active = true
			m.ReportPlayback("progress", true)
			m.UpdateNowPlaying()
        	else if msg.isResumed() then
			Debug(event + "isResumed")
			m.playState = "playing"
			m.progressTimer.Active = true
			m.ReportPlayback("progress", true)
			m.UpdateNowPlaying()
        	else if msg.isPartialResult() then
			Debug(event + "isPartialResult: position -> " + tostr(m.lastPosition))
			m.progressTimer.Active = false
			if m.changeStream = false then 
				m.playState = "stopped"
				'm.ReportPlayback("stop")
				'm.UpdateNowPlaying()
			else
				if m.IsTranscoded then m.StopTranscoding()
			end if
		else if msg.isStreamSegmentInfo() then
			Debug(event + "HLS Segment info: " + tostr(msg.GetType()) + " msg: " + tostr(msg.GetMessage()))
		else if msg.isFullResult() then
			Debug(event + "isFullResult: position -> " + tostr(m.lastPosition))
			m.progressTimer.Active = false
			m.playState = "stopped"
			'm.ReportPlayback("stop")
			'm.UpdateNowPlaying()
			m.isPlayed = true
		else if msg.GetType() = 31 then
			segInfo = msg.GetInfo()
			Debug(event + "Downloaded segment " + tostr(segInfo.Sequence) + " in " + tostr(segInfo.DownloadDuration) + "ms (" + tostr(segInfo.SegSize) + " bytes, buffer is now " + tostr(segInfo.BufferLevel) + "/" + tostr(segInfo.BufferSize))
		else if msg.GetType() = 27 then
			Debug(event + "HLS Segment info: " + tostr(msg.GetType()) + " msg: " + tostr(msg.GetMessage()))
		else
			Debug(event + "Unknown event: " + tostr(msg.GetType()) + " msg: " + tostr(msg.GetMessage()))
		end if
	end if

	if m.InteractionTimeout <> 0 and NOT m.shown <> invalid
		if TimeSinceLastKeyPress() > m.interactionTimeout
			if ShowKeepAliveDialog() = 2
				m.shown = true
				m.playState = "stopped"
				m.stop()
				'CEC = CreateObject("roCecInterface")
				'HexBytes=CreateObject("roByteArray")
				'Power_Off_SAS \x40\x0D
				'HexBytes.fromhexstring("400D")
				'CEC.SendRawMessage(HexBytes)
			else
				m.shown = invalid
			end if
		end if
	end if

	return handled
End Function

Function TimeSinceLastKeyPress() as integer
    device = CreateObject("roDeviceInfo")
    return device.TimeSinceLastKeyPress()
End Function

Function ShowKeepAliveDialog() As Integer
	port = CreateObject("roMessagePort")
	dialog = CreateObject("roMessageDialog")
	dialog.SetMessagePort(port)
	dialog.SetTitle("Action Required!")
	dialog.UpdateText("Are you still here?"+chr(10)+"Are you awake?"+chr(10)+chr(10)+"You have 60 seconds to reply or the video player closes.")
	dialog.AddButton(1, "Yes, I am here!")
	dialog.EnableBackButton(false)
	dialog.Show()
	m.KeepAliveDialog = dialog
	m.TimeoutTimer = CreateObject("roTimespan")
	m.TimeoutTimer.mark()
	reply = 1
	While True
		dlgMsg = wait(1000, dialog.GetMessagePort())
		If type(dlgMsg) = "roMessageDialogEvent"
			if dlgMsg.isButtonPressed()
				if dlgMsg.GetIndex() = 1
					exit while
				end if
			end if
		end if
		if m.TimeoutTimer.TotalSeconds() > 60
			reply = 2
			exit while
		end if
		dialog.UpdateText("Are you still here?"+chr(10)+"Are you awake?"+chr(10)+chr(10)+"You have "+ tostr(60 - m.TimeoutTimer.TotalSeconds()) + " seconds to reply or the video player closes.")		
	end while
	dialog.close()
	return reply
End Function

Sub videoPlayerReportPlayback(action as String, forceReport = false)
	m.progressTimer.Mark()
	isPaused = false
	if m.playState = "paused" then 
		isPaused = true
	end if
	position = m.lastPosition
	playOptions = m.PlayOptions	
	nowSeconds = CreateObject("roDateTime").AsSeconds()
	if action = "progress" and forceReport = false then
		secondsSinceLastProgressReport = nowSeconds - m.LastProgressReportTime
		
		if secondsSinceLastProgressReport < 3
			return
		end if
		
	end if
	m.LastProgressReportTime = nowSeconds
	reportPlayback(m.videoItem.Id, "Video", action, m.playMethod, isPaused, m.canSeek, position, m.videoItem.StreamInfo.MediaSource.Id, m.videoItem.StreamInfo.PlaySessionId, m.videoItem.StreamInfo.LiveStreamId, m.videoItem.StreamInfo.AudioStreamIndex, m.videoItem.StreamInfo.SubtitleStreamIndex)
End Sub

Sub videoPlayerPause()
	if m.Screen <> invalid then
		m.Screen.Pause()
	end if
End Sub

Sub videoPlayerResume()
	if m.Screen <> invalid then
		m.Screen.Resume()
	end if
End Sub

Sub videoPlayerNext()
    if m.Screen <> invalid then
	index = m.CurIndex
	if (index+1) < m.Context.count()
		index = index +1
		m.changeStream = true
		m.CurIndex = index
        	m.Screen.Close()
	end if
    end if
End Sub

Sub videoPlayerPrev()
    if m.Screen <> invalid then
	index = m.CurIndex
	if index > 0
		index = index -1
		m.changeStream = true
		m.CurIndex = index
        	m.Screen.Close()
	else if index = 0
		m.changeStream = true
		m.Screen.Close()
	end if
    end if
End Sub

Sub videoPlayerSetAudioStreamIndex(index)
    if m.Screen <> invalid then
		item = m.Context[m.CurIndex]
		if item.PlayOptions <> invalid
			item.PlayOptions.AudioStreamIndex = index
			position = m.lastPosition
			playOptions = m.PlayOptions	
			item.PlayOptions.PlayStart = position
			m.changeStream = true
        		m.Screen.Close()
		end if
    end if
End Sub

Sub videoPlayerSetSubtitleStreamIndex(index)
    if m.Screen <> invalid then
		item = m.Context[m.CurIndex]
		if item.PlayOptions <> invalid
			item.PlayOptions.SubtitleStreamIndex = index
			position = m.lastPosition
			playOptions = m.PlayOptions	
			item.PlayOptions.PlayStart = position
			m.changeStream = true
			m.Screen.Close()
		end if
    end if
End Sub

Sub videoPlayerStop()
	if m.Screen <> invalid then
		m.Screen.Close()
	end if
End Sub

Sub videoPlayerSeek(offset, relative=false)
	if m.Screen <> invalid then
		if relative then
			offset = offset + (1000 * m.lastPosition)
			if offset < 0 then offset = 0
		end if
		if m.playState = "paused" then
			m.Screen.Resume()
			m.Screen.Seek(offset)
		else
			m.Screen.Seek(offset)
		end if
	end if
End Sub

Sub videoPlayerStartTranscodeSessionRequest()
	if m.IsTranscoded then
		context = CreateObject("roAssociativeArray")
		context.requestType = "transcode"
		request = HttpRequest(GetServerBaseUrl() + "/Sessions?deviceId=" + getGlobalVar("rokuUniqueId", "Unknown"))
		request.AddAuthorization()
		request.ContentType("json")
		m.ViewController.StartRequest(request.Http, m, context)
	end if
End Sub

Sub videoPlayerOnUrlEvent(msg, requestContext)
	if requestContext.requestType = "transcode" then
		if msg.GetResponseCode() = 200 then
			response = normalizeJson(msg.GetString())
			sessions     = ParseJSON(response)
			DisplayTranscodingInfo(m, m.videoItem, sessions)
		end if
	end if
	if m.lastPosition <> invalid and m.lastPosition >= 0 then updateVideoHUD(m,m.lastPosition)
End Sub

Sub DisplayTranscodingInfo(screen, item, sessions)
	for each i in sessions
		tag = ""
		if item.TagLine <> invalid
			'tag = tag + item.TagLine + chr(10)
		end if
		if item.SeriesName <> invalid
			tag = tag + item.SeriesName
		end if
		if item.ParentIndexNumber <> invalid
			if tag <> "" then tag = tag + chr(10)
			tag = tag + "Season " + tostr(item.ParentIndexNumber)
		end if
		if item.IndexNumber <> invalid
			if tag <> "" then tag = tag + " / "
			tag = tag + "Episode " + tostr(item.IndexNumber)
			' Add Double Episode Number
			if item.IndexNumberEnd <> invalid
				tag = tag +  "-" + itostr(item.IndexNumberEnd)
			end if
		end if
		if tag <> "" then tag = tag + chr(10)
		cat = item.Categories
		day = ""
		genre = ""
		if item.SeriesName <> invalid
			if cat.count() > 1 then day = cat[1] + " on " + cat[0]
		else if cat.count() > 0
			genre = cat[0]
			if cat.count() > 1 then genre = genre + " / " + cat[1]
		end if
		meth = FirstOf(regRead("prefPlayMethod"),"Auto")
		if left(meth,4) = "Auto" then
			tt = "Auto-Detection"
		else
			tt = "Force "+meth
		end if
		if i.TranscodingInfo <> invalid then
			pberr = GetGlobalVar("playbackerror", "0").toInt()
			fall = ""
			if pberr > 0
				fall = "Fallback "
			end if
			transcodingInfo = i.TranscodingInfo
			item.ReleaseDate = tag + item.OrigReleaseDate + chr(10)
			if day <> "" item.ReleaseDate = item.ReleaseDate + day + chr(10)
			if genre <> "" then item.ReleaseDate = item.ReleaseDate + genre + chr(10)
			item.ReleaseDate = item.ReleaseDate + chr(10) + " " + chr(10) + fall + "Transcode @ " + tt + chr(10)
			if transcodingInfo.Width <> invalid or transcodingInfo.Height <> invalid or transcodingInfo.AudioChannels <> invalid then
				item.ReleaseDate = item.ReleaseDate + "("
				if transcodingInfo.Width <> invalid and transcodingInfo.Height <> invalid then  item.ReleaseDate = item.ReleaseDate + tostr(transcodingInfo.Width) + "x" + tostr(transcodingInfo.Height)
				shown = false
				if item.StreamInfo <> invalid then
					serverStreamInfo = item.StreamInfo
	   				audioStream = serverStreamInfo.AudioStream
					if audioStream <> invalid and audiostream.channels <> invalid
						channels = audioStream.Channels
						' stream defined audio channels
          					if channels = 8 then
               						audioCh = "7.1"
           					else if channels = 6 then
               						audioCh = "5.1"
           					else
              						audioCh = tostr(channels)
           					end if
						item.ReleaseDate = item.ReleaseDate + " " + tostr(audioCh) + "ch"
						shown = true
       					end if
				end if
				' transcoded audio channels
       				if transcodingInfo.AudioChannels <> invalid then
          				if transcodingInfo.AudioChannels = 8 then
               					audioCh = "7.1"
           				else if transcodingInfo.AudioChannels = 6 then
               					audioCh = "5.1"
           				else
              					audioCh = tostr(transcodingInfo.AudioChannels)
           				end if

					if shown then
						item.ReleaseDate = item.ReleaseDate +"->" + tostr(audioCh) + "ch"
					else
						item.ReleaseDate = item.ReleaseDate +" " + tostr(audioCh)
					end if
       				end if
				item.ReleaseDate = item.ReleaseDate + ")"
			end if
			item.ReleaseDate = item.ReleaseDate + chr(10)
			item.length = tostr(item.Length)	
			vc = "?" : ac = "?"
			if m.Codecs <> invalid
				r = CreateObject("roRegex","(.*)/(.*)/(.*)","")
				match = r.match(m.Codecs)
				if match.count() > 0 then
					junk = match[1]
					vc = LCase(match[2])
					ac = LCase(match[3])
				end if
			end if
			if transcodingInfo.isVideoDirect = true
				VideoDirect = "(copy)"
			else
				VideoDirect = ""
			end if
			if transcodingInfo.VideoCodec <> invalid then item.ReleaseDate = item.ReleaseDate + "Video: " + vc + "->" + tostr(transcodingInfo.VideoCodec) + " " + VideoDirect
			if transcodingInfo.isAudioDirect = true
				AudioDirect = "(copy)"
			else
				AudioDirect = ""
			end if
			if transcodingInfo.AudioCodec <> invalid then item.ReleaseDate = item.ReleaseDate + chr(10) + "Audio: " + ac + "->" + tostr(transcodingInfo.AudioCodec) + " " + AudioDirect
			if NOT transcodingInfo.AudioCodec <> invalid AND NOT transcodingInfo.VideoCodec <> invalid
				item.ReleaseDate = item.ReleaseDate + " "
			end if
			if transcodingInfo.TranscodeReasons <> invalid
				if transcodingInfo.isAudioDirect = true and transcodingInfo.isVideoDirect = true
					Reasons = "(DirectStream): Why? "
				else
					Reasons = "Why? "
				end if
				for each reason in transcodingInfo.TranscodeReasons
					if mid(reason,10,7) = "Bitrate"
						Reasons = Reasons + "Bitrate, "
					else if left(reason,10) = "VideoCodec"
						if transcodingInfo.isVideoDirect = false
							Reasons = Reasons + "VideoCodec, "
						end if
					else if left(reason,10) = "AudioCodec"
						if transcodingInfo.isAudioDirect = false
							Reasons = Reasons + "AudioCodec, "
						end if
					else
						Reasons = Reasons + left(reason,len(reason)-12) + ", "
					end if
				end for
				Reasons = Left(Reasons,len(Reasons)-2)
				item.ReleaseDate = item.ReleaseDate + chr(10) + Reasons
			end if
			if screen.context <> invalid and screen.Context.count() > 1
				item.ReleaseDate = item.ReleaseDate + chr(10) + "Play Queue: "+tostr(screen.curIndex+1)+" of "+tostr(screen.Context.count())
			end if
			item.ReleaseDate = item.ReleaseDate + chr(10) + " " + chr(10) + " " + chr(10) + " " + chr(10)
			GetGlobalAA().AddReplace("itemHUD",item)
			GetGlobalAA().AddReplace("ChopHUD", "3")
			'screen.SetContent(item)
			exit for
		end if
	end for
End Sub

Sub videoPlayerOnTimerExpired(timer)
	if timer.Name = "timeline"
		m.UpdateNowPlaying(true)
	else if timer.Name = "progress"
		m.ReportPlayback("progress")
	end if
End Sub

Sub videoPlayerUpdateNowPlaying(force=false)
	' Avoid duplicates
	if m.playState = m.lastTimelineState AND NOT force then return
	m.lastTimelineState = m.playState
	m.timelineTimer.Mark()
	item = m.Context[m.CurIndex]
	NowPlayingManager().UpdatePlaybackState("video", item, m.playState, m.lastPosition)
End Sub

Function videoPlayerConstructVideoItem(item, options) as Object
	item = GetFullItemMetadata(item, true, options)
	'if mediaItem <> invalid then videoItem.Duration = mediaItem.duration ' set duration - used for EndTime/TimeLeft on HUD  - ljunkie
	if item.ReleaseDate = invalid then item.ReleaseDate = "" ' we never want to display invalid
	item.OrigReleaseDate = item.ReleaseDate
	releaseDate = item.ReleaseDate
	serverStreamInfo = item.StreamInfo
	tag = ""
	if item.TagLine <> invalid
		'tag = tag + item.TagLine + chr(10)
	end if
	if item.SeriesName <> invalid
		tag = tag + item.SeriesName
	end if
	if item.ParentIndexNumber <> invalid
		if tag <> "" then tag = tag + chr(10)
		tag = tag + "Season " + tostr(item.ParentIndexNumber)
	end if
	if item.IndexNumber <> invalid
		if tag <> "" then tag = tag + " / "
		tag = tag + "Episode " + tostr(item.IndexNumber)
		' Add Double Episode Number
		if item.IndexNumberEnd <> invalid
			tag = tag +  "-" + itostr(item.IndexNumberEnd)
		end if
	end if
	if tag <> "" then tag = tag + chr(10)
	cat = item.Categories
	day = ""
	genre = ""
	if item.SeriesName <> invalid
		if cat.count() > 1 then day = cat[1] + " on " + cat[0]
	else if cat.count() > 0
		genre = cat[0]
		if cat.count() > 1 then genre = genre + " / " + cat[1]
	end if
	meth = FirstOf(regRead("prefPlayMethod"),"Auto")
	if left(meth,4) = "Auto" then
		tt = "Auto-Detection"
	else
		tt = "Force "+meth
	end if
	if serverStreamInfo.PlayMethod <> "Transcode" then
		audioCh = ""
		audioStream = serverStreamInfo.AudioStream
		if audioStream <> invalid and audioStream.Channels <> invalid then
			if audioStream.Channels = 8 then
				audioCh = "7.1"
			else if audioStream.Channels = 6 then
				audioCh = "5.1"
			else
				audioCh = tostr(audioStream.Channels) + "ch"
			end if
		end if
		audioCodec = ""
		if audioStream <> invalid then
			if (tostr(audioStream.Codec) = "dca") then
				audioCodec = "DTS"
			else
				audioCodec = tostr(audioStream.Codec)
			end if
		end if
		resolution = ""
		' Change the VideoStream.Width to Height, shows 1920p instead of 1080p and 1280p instead of 720p in Direct Play Info
		if serverStreamInfo.VideoStream <> invalid and serverStreamInfo.VideoStream.Height <> invalid then resolution = tostr(serverStreamInfo.VideoStream.Height) + "p "
		item.ReleaseDate = tag + item.OrigReleaseDate + chr(10)
		if day <> "" item.ReleaseDate = item.ReleaseDate + day + chr(10)
		if genre <> "" then item.ReleaseDate = item.ReleaseDate + genre + chr(10)
		item.ReleaseDate = item.ReleaseDate + chr(10) + " " + chr(10) + "Direct @ " + tt + chr(10)+"(" + resolution + audioCh + " " + audioCodec + " " + tostr(item.StreamFormat) + ")"
	else
		item.ReleaseDate = tag + item.OrigReleaseDate + chr(10)
		if day <> "" item.ReleaseDate = item.ReleaseDate + day + chr(10)
		if genre <> "" then item.ReleaseDate = item.ReleaseDate + genre + chr(10)
		pberr = GetGlobalVar("playbackerror", "0").toInt()
		fall = ""
		if pberr > 0
			fall = "Fallback "
		end if
        	item.ReleaseDate = item.ReleaseDate + chr(10) + " " + chr(10) +  fall + "Transcode @ " + tt + chr(10)
	end if
	if m.context <> invalid and m.Context.count() > 1
		item.ReleaseDate = item.ReleaseDate + chr(10) + "Play Queue: "+tostr(m.curIndex+1)+" of "+tostr(m.Context.count())
	end if
	item.ReleaseDate = item.ReleaseDate + chr(10) + " " + chr(10) + " " + chr(10) + " " + chr(10)
	GetGlobalAA().AddReplace("itemHUD",item)
	GetGlobalAA().AddReplace("ChopHUD", "3")
	return item
End Function

Sub videoPlayerStopTranscoding()
	Debug ("Sending message to server to stop transcoding")
	' URL
	url = GetServerBaseUrl() + "/Videos/ActiveEncodings"
	' Prepare Request
	request = HttpRequest(url)
	request.AddAuthorization()
	request.AddParam("DeviceId", getGlobalVar("rokuUniqueId", "Unknown"))
	request.SetRequest("DELETE")
	' Execute Request
	response = request.PostFromStringWithTimeout("", 5)
	if response = invalid
		createDialog("Transcoding Error!", "Error stopping server transcoding.", "OK", true)
		Debug("Error stopping server transcoding")
	end if
End Sub
