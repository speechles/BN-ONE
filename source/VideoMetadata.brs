'*****************************************************************
'**  Emby Roku Client - Video Metadata
'*****************************************************************


'**********************************************************
'** Get Video Details
'**********************************************************

Function getVideoMetadata(videoId As String) As Object
    
	' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items/" + HttpEncode(videoId)

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid

        fixedResponse = normalizeJson(response)

        i = ParseJSON(fixedResponse)

        ' Get Image Sizes
        if i.Type = "Episode"
            imageStyle = "rounded-rect-16x9-generic"
        else
            imageStyle = "movie"
        end if

		return getMetadataFromServerItem(i, 0, imageStyle, "springboard")
    else
	createDialog("MetaData Error!", "Failed to Get Video Metadata.", "OK", true)
        Debug("Failed to Get Video Metadata")
    end if

    return invalid
End Function

'**********************************************************
'** addVideoDisplayInfo
'**********************************************************

Sub addVideoDisplayInfo(metaData as Object, item as Object)

	mediaStreams = invalid

	if item.MediaSources <> invalid and item.MediaSources.Count() > 0 then
		mediaStreams = item.MediaSources[0].MediaStreams
	end if

	if mediaStreams = invalid then mediaStreams = item.MediaStreams

	' Can't continue at this point
	if mediaStreams = invalid then
		'createDialog("DisplayInfo Error!", "Failed to Get Display Info.", "OK", true)
		return
	end if

    foundVideo             = false

    for each stream in mediaStreams

        if stream.Type = "Video" And foundVideo = false
            foundVideo = true

            ' Determine Full 1080p
            if firstOf(stream.Height, 0) >= 1080
                metaData.FullHD = true
            end if

            ' Determine Frame Rate
            if stream.RealFrameRate <> invalid
                if stream.RealFrameRate >= 29
                    metaData.FrameRate = 30
                else
                    metaData.FrameRate = 24
                end if

            else if stream.AverageFrameRate <> invalid
                if stream.RealFrameRate >= 29
                    metaData.FrameRate = 30
                else
                    metaData.FrameRate = 24
                end if

            end if

        else if stream.Type = "Audio" 

            channels = firstOf(stream.Channels, 2)
            if channels > 5
                metaData.AudioFormat = "dolby-digital"
            end if

        end if

    end for

End Sub

Function getStreamInfo(mediaSource as Object, options as Object) as Object

	audioStream = getMediaStream(mediaSource.MediaStreams, "Audio", options.AudioStreamIndex, mediaSource.DefaultAudioStreamIndex)
	videoStream = getMediaStream(mediaSource.MediaStreams, "Video", invalid, invalid)
	subtitleStream = getMediaStream(mediaSource.MediaStreams, "Subtitle", options.SubtitleStreamIndex, mediaSource.DefaultSubtitleStreamIndex)

	streamInfo = {
		MediaSource: mediaSource,
		VideoStream: videoStream,
		AudioStream: audioStream,
		SubtitleStream: subtitleStream,
		LiveStreamId: mediaSource.LiveStreamId,
		CanSeek: mediaSource.RunTimeTicks <> "" And mediaSource.RunTimeTicks <> invalid
	}

	if audioStream <> invalid then 
		streamInfo.AudioStreamIndex = audioStream.Index
	else
		streamInfo.AudioStreamIndex = mediaSource.DefaultAudioStreamIndex
	end if
	
	if subtitleStream <> invalid then 
		streamInfo.SubtitleStreamIndex = subtitleStream.Index
	else
		streamInfo.SubtitleStreamIndex = mediaSource.DefaultSubtitleStreamIndex
	end if

	' Use the force luke..
	Force = FirstOf(regRead("prefPlayMethod"), "Auto")
	if Force <> "Auto" then
		if Force = "DirectPlay" then
	
			streamInfo.PlayMethod = "DirectPlay"
			streamInfo.Bitrate = mediaSource.Bitrate
		
		else if Force = "Direct" then

			streamInfo.PlayMethod = "DirectStream"
			streamInfo.Bitrate = mediaSource.Bitrate

		else
			streamInfo.PlayMethod = "Transcode"
			maxVideoBitrate = firstOf(RegRead("prefVideoQuality"), "3200")
                        if mediaSource.LocationType = "Remote"
				maxVideoBitrate = firstOf(RegRead("prefremoteVideoQuality"), "3200")
			else if mediasource.ContentType = "Program"
				maxVideoBitrate = firstOf(RegRead("preflivetvVideoQuality"), "3200")
			end if
			maxVideoBitrate = maxVideoBitrate.ToInt()
	
			streamInfo.Bitrate = maxVideoBitrate * 1000

		end if
	else
		if mediaSource.enableDirectPlay = true then
	
			streamInfo.PlayMethod = "DirectPlay"
			streamInfo.Bitrate = mediaSource.Bitrate
		
		else if mediaSource.SupportsDirectStream = true then

			streamInfo.PlayMethod = "DirectStream"
			streamInfo.Bitrate = mediaSource.Bitrate

		else
			streamInfo.PlayMethod = "Transcode"
			maxVideoBitrate = firstOf(RegRead("prefVideoQuality"), "3200")
                        if mediaSource.LocationType = "Remote"
				maxVideoBitrate = firstOf(RegRead("prefremoteVideoQuality"), "3200")
			else if mediasource.ContentType = "Program"
				maxVideoBitrate = firstOf(RegRead("preflivetvVideoQuality"), "3200")
			end if
			maxVideoBitrate = maxVideoBitrate.ToInt()
	
			streamInfo.Bitrate = maxVideoBitrate * 1000

		end if
	end if

	return streamInfo

End Function

Function StartTranscodingSession(videoUrl)
    cookiesRequest = CreateObject("roUrlTransfer")
    cookiesRequest.SetUrl(videoUrl)
    cookiesHead = cookiesRequest.Head()
    m.Cookie = cookiesHead.GetResponseHeaders()["set-cookie"]

    if m.Cookie <> invalid then
        arr = strTokenize(m.Cookie, ";")
        m.Cookie = arr[0]
    end if

    return m.Cookie
End Function

Function getMediaStream(mediaStreams, streamType, optionIndex, defaultIndex) as Object

	if optionIndex <> invalid then
		for each stream in mediaStreams
			if stream.Index = optionIndex and stream.Type = streamType then return stream
		end for
	end if

	if defaultIndex <> invalid then
		for each stream in mediaStreams
			if stream.Index = defaultIndex and stream.Type = streamType then return stream
		end for
	end if

	' We have to return something
	if streamType = "Video" or streamType = "Audio" then
		for each stream in mediaStreams
			if stream.Type = streamType then return stream
		end for
	end if
	return invalid

End Function

'**********************************************************
'** reportPlayback
'**********************************************************

Sub reportPlayback(id As String, mediaType as String, action As String, playMethod as String, isPaused as Boolean, canSeek as Boolean, position as Integer, mediaSourceId as String, playSessionId = invalid, liveStreamId = invalid, audioStreamIndex = invalid, subtitleStreamIndex = invalid)

    ' Format Position Seconds into Ticks
	positionTicks = invalid
	
    if position <> invalid
        positionTicks =  itostr(position) + "0000000"
    end if

	url = ""
	
    if action = "start"
        ' URL
        url = GetServerBaseUrl() + "/Sessions/Playing"
		
    else if action = "progress"
	
        ' URL
        url = GetServerBaseUrl() + "/Sessions/Playing/Progress"
		
    else if action = "stop"
	
        ' URL
        url = GetServerBaseUrl() + "/Sessions/Playing/Stopped"
		
    end if

	url = url + "?itemId=" + id

    if positionTicks <> invalid
		url = url + "&PositionTicks=" + tostr(positionTicks)
    end if

	url = url + "&isPaused=" + tostr(isPaused)
	url = url + "&canSeek=" + tostr(canSeek)
	url = url + "&PlayMethod=" + playMethod
	url = url + "&QueueableMediaTypes=" + mediaType
	url = url + "&MediaSourceId=" + tostr(mediaSourceId)
	
    if playSessionId <> invalid
		url = url + "&PlaySessionId=" + tostr(playSessionId)
    end if
	
    if liveStreamId <> invalid
		url = url + "&LiveStreamId=" + tostr(liveStreamId)
    end if
	
    if audioStreamIndex <> invalid
		url = url + "&AudioStreamIndex=" + tostr(audioStreamIndex)
    end if

    if subtitleStreamIndex <> invalid
		url = url + "&SubtitleStreamIndex=" + tostr(subtitleStreamIndex)
    end if

	'Debug("Reporting playback to " + url)
	
	' Prepare Request
    request = HttpRequest(url)
    request.AddAuthorization()

	context = CreateObject("roAssociativeArray")
	GetViewController().StartRequest(request.Http, invalid, context, "", "post")

End Sub


'**********************************************************
'** Post Manual Watched Status
'**********************************************************

Function postWatchedStatus(videoId As String, markWatched As Boolean) As Boolean
    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/PlayedItems/" + HttpEncode(videoId)

    ' Prepare Request
    request = HttpRequest(url)
    request.AddAuthorization()

    ' If marking as unwatched
    if Not markWatched
        request.SetRequest("DELETE")
    end if

    ' Execute Request
    response = request.PostFromStringWithTimeout("", 5)
    if response <> invalid
        Debug("Mark Played/Unplayed")
        return true
    else
	createDialog("Watched Error!", "The watch status for " + m.metadata.Title + "  cannot be changed.", "OK", true)
        Debug("Failed to Post Manual Watched Status")
    end if

    return false
End Function

'**********************************************************
'** Get All Episodes of a series
'**********************************************************

Function getAllEpisodes(seriesId As String) As Object
	' URL
	url = GetServerBaseUrl() + "/Shows/" + HttpEncode(seriesId) + "/Episodes.json?"
	userId = getGlobalVar("user").Id
	url = url + "userId=" + HttpEncode(userId) + "&fields=PrimaryImageAspectRatio,Overview&Id=" + HttpEncode(seriesId)
	debug("** Getting All episodes of "+seriesId)

    	' Prepare Request
    	request = HttpRequest(url)
    	request.AddAuthorization()

    	' Execute Request
	response = request.GetToStringWithTimeout(20)
    	if response <> invalid
		return response
    	else
		debug("getAllEpisodes - invalid response!")
		createDialog("Response Error!", "getAllEpisodes is taking too long to respond.", "OK", true)
		return invalid
    	end if
End Function


'**********************************************************
'** Post Favorite Status
'**********************************************************

Function postFavoriteStatus(videoId As String, markFavorite As Boolean) As Boolean
    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/FavoriteItems/" + HttpEncode(videoId)

    ' Prepare Request
    request = HttpRequest(url)
    request.AddAuthorization()

    ' If marking as un-favorite
    if Not markFavorite
        request.SetRequest("DELETE")
    end if

    ' Execute Request
    response = request.PostFromStringWithTimeout("", 5)
    if response <> invalid
        Debug("Add/Remove Favorite")
        return true
    else
	createDialog("Favorites Error!", "Failed to Post Favorite Status", "OK", true)
        Debug("Failed to Post Favorite Status")
    end if

    return false
End Function

'**********************************************************
'** Post Also Watching Status
'**********************************************************

Function postAlsoWatchingStatus(UserId As String, markAlso As Boolean, sessionId as String) As Boolean
    ' URL
	base = GetServerBaseUrl()
	reg = CreateObject("roRegex", "/emby", "i")
	baseurl = reg.ReplaceAll(base,"")
     url = baseurl + "/emby/Sessions/" + HttpEncode(sessionId) + "/Users/" + HttpEncode(UserId)

    ' Prepare Request
    request = HttpRequest(url)
    request.AddAuthorization()

    ' If removing as also watched
    if Not markAlso
        request.SetRequest("DELETE")
    end if

    ' Execute Request
    response = request.PostFromStringWithTimeout("", 5)
    if response <> invalid
        Debug("Sessions Also Watching")
        return true
    else
	createDialog("Also Watching Error!", "This user cannot be added to your session.", "OK", true)
        Debug("Failed to Post Manual Watched Status")
    end if

    return false
End Function

'**********************************************************
'** Get Local Trailers
'**********************************************************

Function getLocalTrailers(videoId As String) As Object
    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items/" + HttpEncode(videoId) + "/LocalTrailers"

    return getSpecialFeaturesFromUrl(url)
End Function


'**********************************************************
'** Get Special Features
'**********************************************************

Function getSpecialFeatures(videoId As String) As Object
    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items/" + HttpEncode(videoId) + "/SpecialFeatures"

    return getSpecialFeaturesFromUrl(url)
End Function

Function getSpecialFeaturesFromUrl(url As String) As Object
    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid

        fixedResponse = normalizeJson(response)

        contentList = CreateObject("roArray", 25, true)
        jsonObj     = ParseJSON(fixedResponse)

        if jsonObj = invalid
            Debug("Error while parsing JSON response")
            return invalid
        end if

        for each i in jsonObj
		metaData = getMetadataFromServerItem(i, 0, "flat-episodic-16x9")
		metaData.Overview = m.Viewcontroller.TrailerOverview
		if metaData.overview <> invalid
			if metaData.description <> invalid
				if NOT metaData.description = metaData.overview
					metaData.description = metaData.description + metaData.overview
				end if
			else
				metaData.description = metaData.overview
			end if
		end if
		trLoc=""
		if right(url,8)="Trailers"
			if metaData.LocationType = "FileSystem"
				trLoc = "Local / "
			else
				trLoc = "Internet / "
			end if
		end if
		if metaData.Shortdescriptionline2 <> invalid
			MetaData.shortdescriptionline2 = trLoc + metaData.shortdescriptionline2
		end if
		contentList.push( metaData )
	end for
        return contentList
    else
	createDialog("Response Error!", "Failed to Get Special Features", "OK", true)
    end if

    return invalid
End Function


'**********************************************************
'** Get Video Intros
'**********************************************************

Function getVideoIntros(videoId As String) As Object
    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items/" + HttpEncode(videoId) + "/Intros"

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid

		return parseItemsResponse(response, 0, "flat-episodic-16x9")
    else
	createDialog("Response Error!", "Failed to Get Video Intros", "OK", true)
    end if

    return invalid
End Function

'**********************************************************
'** Get Additional Parts
'**********************************************************

Function getAdditionalParts(videoId As String) As Object
    ' URL
    url = GetServerBaseUrl() + "/Videos/" + HttpEncode(videoId) + "/AdditionalParts?UserId=" + HttpEncode(getGlobalVar("user").Id)

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid
	return parseItemsResponse(response, 0, "flat-episodic-16x9")
    end if

    return invalid
End Function

'**********************************************************
'** Get Playlist Parts
'**********************************************************

Function getPlaylistParts(videoId As String) As Object
    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?ParentId=" + HttpEncode(videoId) + "&fields=PrimaryImageAspectRatio,Overview,ParentId&CollapseBoxSetItems=false&ImageTypeLimit=1"

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid
	return parseItemsResponse(response, 0, "flat-episodic-16x9")
    end if

    return invalid
End Function

'**********************************************************
'** Credit: RarFlix - everything below
'**********************************************************

sub updateVideoHUD(m,curProgress,releaseDate = invalid)
    'Debug("---- timeline sent :: HUD updated " + tostr(curProgress))

    endString = invalid
    watchedString = invalid
    item = GetGlobalVar("itemHUD")
    chop = GetGlobalVar("ChopHUD").toInt()

    if item.releaseDate <> invalid
	releaseDate = item.releaseDate
	list = releaseDate.Tokenize(chr(10))
	'if type(item.length) = "String"
	'	chop = 2
	'else
	'	chop = 3
	'end if
	total = list.count() - chop
	if total > 0
		text = ""
		count = 0
		for each i in list
			count = count + 1
			text = text + i + chr(10)
			if count >= total then exit for
		end for
		Item.OrigHUDreleaseDate = text
	end if
    end if

    date = CreateObject("roDateTime")
    length = item.length
    if type(item.length) = "roString" or type(item.length) = "String"
	length = item.length.toInt()
    else
	length = item.length
    end if
    if length <> invalid and length > 0
        duration = int(length)
        timeLeft = int(Duration - curProgress)
        endString = "Time: " + RRmktime(date.AsSeconds()) + chr(10) + "End Time: " + RRmktime(date.AsSeconds()+timeLeft) + "  (" + GetDurationString(timeLeft,0,1,1) + ")" + chr(10) + "Watched: " + GetDurationString(int(curProgress),0,0,1)+chr(10)
    else
         ' include current time and watched time when video duration is unavailable (HLS & web videos)
         watchedString = " " + chr(10)+ "Time: " + RRmktime(date.AsSeconds()) + chr(10) + "Watched: " + GetDurationString(int(curProgress),0,0,1)+chr(10)
    end if

    ' set the HUD
    content = CreateObject("roAssociativeArray")
    content = item ' assign Video item and reset other keys
    'content.length = Int(((item.mediaSource.RunTimeTicks).ToFloat() / 10000) / 1000)
    'content.title = item.title

    ' set the Orig Release date before we start appending. We can then reuse the OrigHUDreleaseDate for future calls
    if item.OrigHUDreleaseDate = invalid then
        if content.releasedate <> invalid then
            item.OrigHUDreleaseDate = content.releasedate
       else
            item.OrigHUDreleaseDate = ""
        end if
    end if

     ' overwrite release date now
    content.releasedate = item.OrigHUDreleasedate

    content.releasedate = content.releasedate + chr(10)
    if endString <> invalid then content.releasedate = content.releasedate +  endString
    if watchedString <> invalid then content.releasedate = content.releasedate + watchedString
 
    if GetGlobalAA().Lookup("bandwidth") <> invalid then
	GetGlobalAA().AddReplace("ChopHUD","4")
        rawBW = GetGlobalAA().Lookup("bandwidth")
	if rawBW > 1024
		rawBW = rawBW / 1024
		format = " Mbps"
	else
		format = " Kbps"
	end if
	content.releasedate = content.releasedate + chr(10) + "Measured: " + tostr(rawBW) + format
    end if
   ' update HUD
    m.Screen.SetContent(content)
end sub

Function RRbitrate( bitrate As Float) As String
    speed = bitrate/1000/1000
    ' brightscript doesn't have sprintf ( only include on decimal place )
    speed = speed * 10
    speed = speed + 0.5
    speed = fix(speed)
    speed = speed / 10
    format = " mbps"
    if speed < 1 then
      speed = speed*1000
      format = " kbps"
    end if
    return tostr(speed) + format
End Function

Function RRmktime( epoch As Integer, localize = 1 as Integer) As String
    ' we will use home screen clock type to make the time ( if disabled, we will just use 12 hour )
    ' -- another toggle could be useful if someone wants 24hour time and NO clock on the homescreen ( too many toggles though )
    timePref = FirstOf(RegRead("prefTimeFormat"), "12h")

    datetime = CreateObject("roDateTime")
    datetime.FromSeconds(epoch)
    if localize = 1 then datetime.ToLocalTime()

    hours = datetime.GetHours()
    minutes = datetime.GetMinutes()
    seconds = datetime.GetSeconds()
  

    ' this works for 12/24 hour formats
    minute = tostr(minutes)
    if minutes < 10 then minute = "0" + tostr(minutes)

    hour = hours
    if timePref <> "24h" then 
        ' 12 hour format
        if hours = 0 then
           hour = 12
        end If

        if hours > 12 then
            hour = hours-12
        end If

        if hours >= 0 and hours < 12 then
            AMPM = "am"
        else
            AMPM = "pm"
        end if

        result = tostr(hour) + ":" + minute + AMPM
    else 
        ' 24 hour format
        if hours < 10 then hour = "0" + tostr(hours)
        result = tostr(hour) + ":" + minute
    end if

    return result
End Function

Function GetDurationString( Seconds As Dynamic, emptyHr = 0 As Integer, emptyMin = 0 As Integer, emptySec = 0 As Integer  ) As String
   datetime = CreateObject( "roDateTime" )

   if (type(Seconds) = "roString") then
       TotalSeconds% = Seconds.toint()
   else if (type(Seconds) = "roInteger") or (type(Seconds) = "Integer") then
       TotalSeconds% = Seconds
   else
       return "Unknown"
   end if

   datetime.FromSeconds( TotalSeconds% )
      
   hours = datetime.GetHours().ToStr()
   minutes = datetime.GetMinutes().ToStr()
   seconds = datetime.GetSeconds().ToStr()
   
   duration = ""
   If hours <> "0" or emptyHr = 1 Then
      duration = duration + hours + "h "
   End If

   If minutes <> "0" or emptyMin = 1 Then
      duration = duration + minutes + "m "
   End If
   If seconds <> "0" or emptySec = 1 Then
      duration = duration + seconds + "s"
   End If
   
   Return duration
End Function
