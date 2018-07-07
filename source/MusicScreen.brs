'**********************************************************
'** createMusicLibraryScreen
'**********************************************************

Function createMusicLibraryScreen(viewController as Object, parentId as String) As Object

	names = ["Albums", "Artists", "Jump Into Albums", "Jump Into Artists", "Favorite Tracks", "Favorite Albums", "Favorite Artists", "Genres", "Studios", "Playlists"]
	keys = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]

	loader = CreateObject("roAssociativeArray")
	loader.getUrl = getMusicLibraryRowScreenUrl
	loader.parsePagedResult = parseMusicLibraryScreenResult
	loader.getLocalData = getMusicLibraryScreenLocalData
	loader.parentId = parentId

    screen = createPaginatedGridScreen(viewController, names, keys, loader, "two-row-flat-landscape-custom")

    return screen
End Function

Function getMusicLibraryScreenLocalData(row as Integer, id as String, startItem as Integer, count as Integer) as Object

	if row = 2 then
		return getAlphabetList("MusicAlbumAlphabet", m.parentId)
	else if row = 3 then
		return getAlphabetList("MusicArtistAlphabet", m.parentId)
	end If

    return invalid

End Function

Function getMusicLibraryRowScreenUrl(row as Integer, id as String) as String

    ' URL
    url = GetServerBaseUrl()

    ' Query
    query = {}

	if row = 0
		url = url  + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?recursive=true"

		query = {
			sortby: "AlbumArtist,SortName",
			sortorder: "Ascending",
			IncludeItemTypes: "MusicAlbum",
			fields: "ItemCounts,AudioInfo,ParentId,PrimaryImageAspectRatio,Overview,Genres",
			parentId: m.parentId,
			ImageTypeLimit: "1"
		}
	else if row = 1
		url = url  + "/Artists/AlbumArtists?recursive=true"

		query = {
			fields: "ItemCounts,ParentId,AudioInfo,PrimaryImageAspectRatio,Overview,Genres",
			sortby: "SortName",
			sortorder: "Ascending",
			IncludeItemTypes: "MusicAlbum",
			parentId: m.parentId,
			UserId: getGlobalVar("user").Id,
			ImageTypeLimit: "1"
		}
	else if row = 2
		' Music album alphabet - should never get in here
	else if row = 3
		' Music artist alphabet - should never get in here
	else if row = 4
		url = url  + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?recursive=true"
	
		query = {
                    filters: "IsFavorite",
		    SortBy: "AlbumArtist,SortName",
                    SortOrder: "Ascending",
                    IncludeItemTypes: "Audio",
                    Fields: "ItemCounts,ParentId,PrimaryImageAspectRatio,Overview,Genres",
		    parentId: m.parentId,
                    ImageTypeLimit: "1"
		}

	else if row = 5
		url = url  + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?recursive=true"

		query = {
			filters: "IsFavorite",
			sortby: "AlbumArtist,SortName",
			sortorder: "Ascending",
			IncludeItemTypes: "MusicAlbum",
			fields: "ItemCounts,ParentId,PrimaryImageAspectRatio,Overview,Genres",
			parentId: m.parentId,
			ImageTypeLimit: "1"
		}
	else if row = 6
		url = url  + "/Artists/AlbumArtists?recursive=true"

		query = {
			filters: "IsFavorite",
			sortby: "SortName",
			sortorder: "Ascending",
			IncludeItemTypes: "MusicAlbum",
			fields: "ItemCounts,ParentId,PrimaryImageAspectRatio,Overview,Genres",
			parentId: m.parentId,
			UserId: getGlobalVar("user").Id,
			ImageTypeLimit: "1"
		}
	else if row = 7
		url = url  + "/Genres?recursive=true"

		query = {
			userid: getGlobalVar("user").Id,
			recursive: "true",
			IncludeItemTypes: "MusicAlbum",
			fields: "ItemCounts,ParentId,PrimaryImageAspectRatio,Overview,Genres",
			sortby: "SortName",
			sortorder: "Ascending",
			parentId: m.parentId
		}
	else if row = 8
		url = url  + "/Studios?recursive=true"
		query.AddReplace("SortBy", "SortName")
		query.AddReplace("sortorder", "Ascending")
		query.AddReplace("fields", "ItemCounts,ParentId,PrimaryImageAspectRatio,Overview,Genres,Studios")
		query.AddReplace("userid", getGlobalVar("user").Id)
		query.AddReplace("IncludeItemTypes", "MusicAlbum")
		query.AddReplace("ParentId", m.parentId)
		'query.AddReplace("ImageTypeLimit", "1")
	else if row = 9
		url = url  + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?recursive=true"
		query.AddReplace("SortBy", "SortName")
		query.AddReplace("sortorder", "Ascending")
		query.AddReplace("fields", "ItemCounts,ParentId,PrimaryImageAspectRatio,Overview,Genres")
		query.AddReplace("IncludeItemTypes", "Playlist")
		'query.AddReplace("ParentId", m.parentId)
		query.AddReplace("ImageTypeLimit", "1")
	end If

	for each key in query
		url = url + "&" + key +"=" + HttpEncode(query[key])
	end for

    return url

End Function

Function parseMusicLibraryScreenResult(row as Integer, id as string, startIndex as Integer, json as String) as Object

	imageType      = 1
	primaryImageStyle = "two-row-flat-landscape-custom"
	mode = ""
	if row = 8 then mode = "musicstudio"
	if row = 4 then mode = "musicfavorite"
	if row = 0 or row = 4 or row = 5 then
		primaryImageStyle = "arced-square"
		imageType = 0
	end if
	return parseItemsResponse(json, imageType, primaryImageStyle, mode)

End Function

'**********************************************************
'** createMusicAlbumsScreen
'**********************************************************

Function createMusicAlbumsScreen(viewController as Object, artistInfo As Object) As Object

    screen = CreatePosterScreen(viewController, artistInfo, "arced-square")

	screen.GetDataContainer = getMusicAlbumsDataContainer

    return screen

End Function

Function getMusicAlbumsDataContainer(viewController as Object, item as Object) as Object

    MusicMetadata = InitMusicMetadata()

    musicData = MusicMetadata.GetArtistAlbums(item.Title)

    if musicData = invalid
        return invalid
    end if

	obj = CreateObject("roAssociativeArray")
	obj.names = []
	obj.keys = []
	obj.items = musicData.Items

	return obj

End Function

'**********************************************************
'** createMusicArtistsAlphabetScreen
'**********************************************************

Function createMusicArtistsAlphabetScreen(viewController as Object, letter As String, parentId = invalid) As Object

	' Dummy up an item
	item = CreateObject("roAssociativeArray")
	item.Title = letter

    screen = CreatePosterScreen(viewController, item, "arced-square")

	screen.ParentId = parentId
	screen.GetDataContainer = getMusicArtistsAlphabetDataContainer

    return screen
End Function

Function getMusicArtistsAlphabetDataContainer(viewController as Object, item as Object) as Object

    letter = item.Title

    if letter = "#" then
        filters = {
            NameLessThan: "a"
        }
    else
        filters = {
            NameStartsWith: letter
        }
    end if
	
	if m.ParentId <> invalid then filters.ParentId = m.ParentId

    musicData = getMusicArtists(invalid, invalid, filters)
    if musicData = invalid
        return invalid
    end if
	obj = CreateObject("roAssociativeArray")
	obj.names = []
	obj.keys = []
	obj.items = musicData.Items

	return obj

End Function


'**********************************************************
'** createMusicAlbumsAlphabetScreen
'**********************************************************

Function createMusicAlbumsAlphabetScreen(viewController as Object, letter As String, parentId = invalid) As Object

	' Dummy up an item
	item = CreateObject("roAssociativeArray")
	item.Title = letter

    screen = CreatePosterScreen(viewController, item, "arced-square")

	screen.ParentId = parentId
	screen.GetDataContainer = getMusicAlbumsAlphabetDataContainer

    return screen

End Function

Function getMusicAlbumsAlphabetDataContainer(viewController as Object, item as Object) as Object

    letter = item.Title

    if letter = "#" then
        filters = {
            NameLessThan: "a"
        }
    else
        filters = {
            NameStartsWith: letter
        }
    end if
	
	if m.ParentId <> invalid then filters.ParentId = m.ParentId

    musicData = getMusicAlbums(invalid, invalid, filters)
    if musicData = invalid
        return invalid
    end if

	obj = CreateObject("roAssociativeArray")
	obj.names = []
	obj.keys = []
	obj.items = musicData.Items

	return obj

End Function

'**********************************************************
'** createMusicGenresScreen
'**********************************************************

Function createMusicGenresScreen(viewController as Object, genre As String) As Object

    if validateParam(genre, "roString", "createMusicGenresScreen") = false return -1

	' Dummy up an item
	item = CreateObject("roAssociativeArray")
	item.Title = genre

    screen = CreatePosterScreen(viewController, item, "arced-square")

 	screen.GetDataContainer = getMusicGenreDataContainer

    return screen

End Function

Function getMusicGenreDataContainer(viewController as Object, item as Object) as Object

    genre = item.Title

    MusicMetadata = InitMusicMetadata()

    musicData = MusicMetadata.GetGenreAlbums(genre)
    if musicData = invalid
        return invalid
    end if

	obj = CreateObject("roAssociativeArray")
	obj.names = []
	obj.keys = []
	obj.items = musicData.Items

	return obj

End Function

'**********************************************************
'** createMusicStudiosScreen
'**********************************************************

Function createMusicStudiosScreen(viewController as Object, studio As String) As Object

    if validateParam(studio, "roString", "createMusicStudiosScreen") = false return -1

	' Dummy up an item
	item = CreateObject("roAssociativeArray")
	item.Title = studio

    screen = CreatePosterScreen(viewController, item, "arced-square")

 	screen.GetDataContainer = getMusicStudioDataContainer

    return screen

End Function

Function getMusicStudioDataContainer(viewController as Object, item as Object) as Object

    genre = item.Title

    MusicMetadata = InitMusicMetadata()

    musicData = MusicMetadata.GetStudioAlbums(genre)
    if musicData = invalid
        return invalid
    end if
	obj = CreateObject("roAssociativeArray")
	obj.names = []
	obj.keys = []
	obj.items = musicData.Items

	return obj

End Function

'**********************************************************
'** createMusicItemSpringboardScreen
'**********************************************************

Function createMusicItemSpringboardScreen(context, index, viewController) As Dynamic

	obj = createBaseSpringboardScreen(context, index, viewController)

	obj.SetupButtons = musicItemSpringboardSetupButtons
	
	obj.superHandleMessage = obj.HandleMessage
	obj.HandleMessage = musicItemSpringboardHandleMessage
	obj.GetMediaDetails = audioGetMediaDetails
	obj.Activate = MusicItemActivate
	obj.item = GetFullItemMetadata(context[index], false, {})
	if obj.item.ContentType = "MusicArtist"
		obj.screen.SetPosterStyle("rounded-square-generic")
	else if (obj.item.ContentType <> "MusicAlbum") then
		obj.screen.SetPosterStyle("rounded-rect-16x9-generic")
	end if
	
    return obj
End Function

Sub musicItemSpringboardSetupButtons()
	m.ClearButtons()
	m.item = GetFullItemMetadata(m.item, false, {})
	if m.item.ContentType = "MediaFolder"
		m.AddButton("Open", "open")
	else
		if m.item.ContentType = "MusicAlbum" 
			m.AddButton("Track List", "tracklist")
			m.AddButton("Shuffle Tracks", "shuffle")
			if m.item.fulldescription <> invalid and m.item.fulldescription <> ""
				m.AddButton("Show Overview","showoverview")
			end if
			artistname = ""
			if m.item.artist <> invalid 
				artistname = m.item.artist
			end if
			if artistname <> "" then m.AddButton("-> Go To "+artistname, "goto")
		else
			m.AddButton("Discography", "albumlist")
			if m.item.ContentType = "MusicArtist"
				m.AddButton("Artist Tracks ...", "artisttracklist")
				m.AddButton("Shuffle Artist Tracks", "shuffle")
				if m.item.fulldescription <> invalid and m.item.fulldescription <> ""
					m.AddButton("Show Overview","showoverview")
				end if
			else if m.item.ContentType = "MusicGenre"
				m.AddButton("Genre Tracks", "genretracklist")
				m.AddButton("Genre Artists","allgenreartist")
				m.AddButton("Shuffle Genre Tracks", "shuffle")
			else if m.item.ContentType = "MusicStudio" or m.item.ContentType = "Studio"
				m.AddButton("Studio Tracks", "studiotracklist")
				m.AddButton("Studio Artists","allstudioartist")
				m.AddButton("Shuffle Studio Tracks", "shuffle")
			else
				m.AddButton("Shuffle Tracks", "shuffle")
			end if
		end if
		m.AddButton("Instant Mix", "instantmix")

	end if
	if m.item <> invalid
		if m.item.IsFavorite <> invalid
			if m.item.IsFavorite
				m.AddButton("Remove as Favorite", "removefavorite")
			else
				m.AddButton("Mark as Favorite", "markfavorite")
			end if
		end if
	end if
End Sub

'**************************************************************
'** MusicItemActivate
'**************************************************************

Sub MusicItemActivate(priorScreen)
    	if m.refreshOnActivate <> invalid
		if m.refreshOnActivate
			m.refreshOnActivate = false
			m.Refresh(true)
		end if
	end if
End Sub

'**********************************************************
'** musicGetSongsForItem
'**********************************************************

Function musicGetSongsForItem(item) As Object
	busyDialog = CreateObject("roMessageDialog")
	busyDialog.SetTitle("Creating Track list...")
	busyDialog.UpdateText("Album 1 of...")
	busyDialog.ShowBusyAnimation()
	busyDialog.Show()

	songs = []
	albums = []
	
	MusicMetadata = InitMusicMetadata()
	
	if (item.ContentType = "MusicArtist")
		albumData = MusicMetadata.GetArtistAlbums(item.Title)
		albums = albumData.Items
	else if (item.ContentType = "MusicGenre")
		albumData = MusicMetadata.GetGenreAlbums(item.Title)
		albums = albumData.Items
	else if (item.ContentType = "MusicStudio")
		albumData = MusicMetadata.GetStudioAlbums(item.Title)
		albums = albumData.Items
	else if (item.ContentType = "MusicAlbum")
		albums = [item]
	end if

	'if (item.ContentType = "Audio") then
		'return item
	'else
	songtotals = 0
	albumscount = 0
	  for each a in albums
		albumscount = albumscount + 1
		aData = MusicMetadata.GetAlbumSongs(a.Id)
		if aData <> invalid
			if aData.Items <> invalid
				songtotals = songtotals + aData.Items.count()
				Title = a.title
				If Title <> invalid
					if Title.len() > 30
						Title = left(Title,30)+"..."
					end if
				else
					Title = "Unknown Album Title"
				end if
				busyDialog.UpdateText("Album "+tostr(albumscount)+" of "+tostr(albums.count())+": "+Title+chr(10)+"Total Tracks Acquired: "+tostr(songtotals))
				songs.Append(aData.Items)
			end if
		end if
	  end for
	'end if	
		
	return songs	
		
End Function

'**********************************************************
'** musicGetInstantMixForItem
'**********************************************************

Function musicGetInstantMixForItem(item) As Object

	mixItems = []
		
	url = GetServerBaseUrl()
	userId = HttpEncode(getGlobalVar("user").Id)
	fieldsString = "&fields=" + HttpEncode("AudioInfo,PrimaryImageAspectRatio,MediaSources,Overview,Genres")
	
	if (item.ContentType = "MusicAlbum")
		url = url + "/Albums/" + HttpEncode(item.id)
	else if (item.ContentType = "MusicArtist")
		url = url + "/Artists/" + HttpEncode(item.Title)
	else if (item.ContentType = "MusicGenre")
		url = url + "/MusicGenres/" + HttpEncode(item.Title)
	else if (item.ContentType = "MusicStudio")
		url = url + "/Studios/" + HttpEncode(item.Title)
	end if
	
	limit = FirstOf(RegRead("prefinstantmix"),"100")
	url = url + "/InstantMix?UserId=" + userId + fieldsString
	'if limit <> "0" then url = url + "&Limit="+limit
	debug(url)
    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()
	
    ' Execute Request
    response = request.GetToStringWithTimeout(10)
	
	if response <> invalid	
		container = parseItemsResponse(response, 0, "list")
		mixItems = container.items
	end if	
	
	return mixItems
End Function

'**********************************************************
'** createMusicListScreen
'**********************************************************

Function createMusicListScreen(viewController as Object, pending As Object) As Object
	screen = CreateListScreen(viewController)

	screen.baseHandleMessage = screen.HandleMessage
	screen.HandleMessage = musicSongsHandleMessage

	player = AudioPlayer()

	tracks = []
	for each item in pending
		if item.mediatype <> invalid then tracks.push(item)
	end for 
				
	totalDuration = GetTotalDuration(tracks)
	if tracks.count() > 0 and tracks[0].shortdescriptionline2 = "TuneIn"
		screen.SetHeader(pluralize(tracks.count(),"Station"))
	else
		screen.SetHeader(pluralize(tracks.count(),"Track") + " / " + totalDuration)
	end if

	if getGlobalVar("legacyDevice")
		backButton = {
			Title: ">> Back <<",
			ContentType: "exit",
		}

		musicData.Items.Unshift( backButton )
	end if

	screen.SetContent(tracks)

	player.SetRepeat(0)

	screen.prevIconIndex = invalid
	screen.focusedItemIndex = 0
	screen.audioItems = tracks

	screen.IsShuffled = false
	
	screen.playFromIndex = musicSongsPlayFromIndex

	' reset context menu conflict to use Audio
	GetGlobalAA().AddReplace("AudioConflict", "0")
	GetGlobalAA().AddReplace("musicstop", "0")

	return screen

End Function

'**********************************************************
'** createMusicSongsScreen
'**********************************************************

Function createMusicSongsScreen(viewController as Object, artistInfo As Object, contextIndex as Integer) As Object
    MusicMetadata = InitMusicMetadata()
    if artistInfo.contentType = "MusicFavorite"
    	musicData = MusicMetadata.GetSong(artistInfo.Id)
	screen = createMusicListScreen(viewController, musicData.Items)
	screen.SetFocusedItem(contextIndex)
	return screen
    else if artistInfo.contentType = "RecentlyPlayed"
    	musicData = MusicMetadata.GetRecent(artistInfo.Id)
	screen = createMusicListScreen(viewController, musicData.Items)
	screen.SetFocusedItem(contextIndex)
	return screen
    else if artistInfo.contentType = "MostPlayed"
    	musicData = MusicMetadata.GetMost(artistInfo.Id)
	screen =  createMusicListScreen(viewController, musicData.Items)
	screen.SetFocusedItem(contextIndex)
	return screen
    else
    	musicData = MusicMetadata.GetAlbumSongs(artistInfo.Id)
	screen = createMusicListScreen(viewController, musicData.Items)
	screen.SetFocusedItem(contextIndex)
	return screen
    end if
End Function

Function createAudioSearchScreen(viewController as Object, Songs As Object, contextIndex as Integer) As Object
	MusicMetadata = InitMusicMetadata()
	musicData = MusicMetadata.SongRefill(Songs)
	screen = createMusicListScreen(viewController, musicData)
	screen.SetFocusedItem(contextIndex)
	return screen
End Function

Sub musicSongsPlayFromIndex(index)

	player = AudioPlayer()
	
	player.SetContextFromItems(m.audioItems, index, m, true)
	player.Play()
				
End Sub

Function musicSongsHandleMessage(msg) As Boolean
    handled = false

	viewController = m.ViewController

    player = AudioPlayer()
    remoteKeyLeft   = 4
    remoteKeyRight  = 5
    remoteKeyOK     = 6
    remoteKeyRev    = 8
    remoteKeyFwd    = 9
    remoteKeyStar   = 10
    remoteKeyPause  = 13

    If type(msg) = "roAudioPlayerEvent" Then

        If msg.isListItemSelected() Then

            If m.prevIconIndex<>invalid then HideSpeakerIcon(m, m.prevIconIndex)
            m.prevIconIndex = ShowSpeakerIcon(m, player.CurIndex)

            m.SetFocusedItem(m.focusedItemIndex)

        Else If msg.isPaused()

            ShowPauseIcon(m, player.CurIndex)

            m.SetFocusedItem(m.focusedItemIndex)

        Else If msg.isFullResult() Then

		if m.prevIconIndex <> invalid then HideSpeakerIcon(m, m.prevIconIndex)

        Else If msg.isResumed()

            ShowSpeakerIcon(m, player.CurIndex)

            m.SetFocusedItem(m.focusedItemIndex)

        End If

    Else If type(msg) = "roListScreenEvent" Then

        If msg.isListItemFocused() Then

            handled = true

            m.focusedItemIndex = msg.GetIndex()

        Else If msg.isListItemSelected() Then

            handled = true

            if m.audioItems[msg.GetIndex()].ContentType = "exit"

                Debug("Close Music Album Screen")
                If player.IsPlaying Then
		    sm = FirstOf(RegRead("prefStopMusic"),"false")
		    if sm = "true" then
                    	player.Stop()
		    end if
                End If

				m.Screen.Close()

            else

				player.SetContextFromItems(m.audioItems, msg.GetIndex(), m, true)
				player.Play()
            end if

        Else If msg.isScreenClosed() Then

            Debug("Close Music Album Screen")
            If player.IsPlaying Then
		    sm = FirstOf(RegRead("prefStopMusic"),"false")
		    if sm = "true" then
                    	player.Stop()
		    end if
            End If

        Else If msg.isRemoteKeyPressed()

            handled = true
            index = msg.GetIndex()
	    if player.context <> invalid and player.CurIndex <> invalid
		if player.Context[player.CurIndex] <> invalid
			item = player.Context[player.CurIndex]
			If index = remoteKeyPause Then
				If player.IsPaused player.Resume() Else player.Pause()
			Else If index = remoteKeyRev Then
				Debug("Previous Song")
                		If player.IsPlaying player.Prev()
			Else If index = remoteKeyFwd Then
				Debug("Next Song")
				If player.IsPlaying player.Next()
			Else If index = remoteKeyLeft and item.canSeek then
				if player.IsPlaying player.Seek(-5000, true)
			Else If index = remoteKeyRight and item.canSeek then
				if player.IsPlaying player.Seek(5000, true)
			End If
		end if
	    end if
        End If
    End If

	if handled = false then
		handled = m.baseHandleMessage(msg)
	end if

    return handled
End Function

'**********************************************************
'** musicItemSpringboardHandleMessage
'**********************************************************
	
Function musicItemSpringboardHandleMessage(msg) As Boolean
	handled = false
	screen = m
	item = m.item

	if type(msg) = "roSpringboardScreenEvent" then
	   if msg.isButtonPressed() then
		method = "0"
		handled = true
		buttonCommand = m.buttonCommands[str(msg.getIndex())]
		Debug("Button command: " + tostr(buttonCommand))
			
		breadcrumbText = m.item.Title
		screenName = tostr(buttonCommand) + " " + tostr(m.item.id)
		startPlaying = true
		busyDialog = invalid
		if buttonCommand = "open" then
			GetViewController().CreateScreenForItem(Item, 0, [item.Title])
			return true
		else if (buttonCommand = "albumlist") then
			if (m.item.ContentType = "MusicArtist")
				listScreen = createMusicAlbumsScreen(m.ViewController, m.item)
			else if (m.item.ContentType = "MusicGenre")
				listScreen = createMusicGenresScreen(m.ViewController, m.item.Title)
			else if (m.item.ContentType = "MusicStudio") or (m.item.ContentType = "Studio")
				listScreen = createMusicStudiosScreen(m.ViewController, m.item.Title)
			end if
			startPlaying = false
		else if buttonCommand = "goto"
			artistname = ""
			if item.artist <> invalid 
				artistname = item.artist
			end if
			if artistName <> ""
   				loadingDialog = CreateObject("roOneLineDialog")
    				loadingDialog.SetTitle("Getting "+artistName)
    				loadingDialog.ShowBusyAnimation()
    				loadingDialog.Show()
        			newscreen = getMusicArtistByName(artistName)
				newScreen.ScreenName = "ArtistByName" + item.Id
        			GetViewController().CreateScreenForItem(newscreen.items, 0, ["",artistName])
    				'loadingDialog.close()
			end if
        		return true
		else if buttonCommand = "removefavorite" then
			screen.refreshOnActivate = true
			result = postFavoriteStatus(m.item.Id, false)
			if result then
        			createDialog("Favorites Changed", m.item.Title + " has been removed from your favorites.", "OK", true)
			else
				createDialog("Favorites Error!", m.item.Title + " has NOT been removed from your favorites.", "OK", true)
			end if
			return true
    		else if buttonCommand = "markfavorite" then
			screen.refreshOnActivate = true
			result = postFavoriteStatus(m.item.Id, true)
			if result then
        			createDialog("Favorites Changed", m.item.Title + " has been added to your favorites.", "OK", true)
			else
				createDialog("Favorites Error!", m.item.Title + " has NOT been added to your favorites.", "OK", true)
			end if
			return true
		else
	    		if buttonCommand = "showoverview" then
        			newScreen = createTextDescriptionScreen(m.ViewController, item)
				newScreen.ScreenName = "Text" + item.Id
        			m.ViewController.InitializeOtherScreen(newScreen, [item.Title,"Overview"])
				newScreen.Show()
        			return true
    	    		else if buttonCommand = "allgenreartist" then
        			newScreen = createArtistGenreScreen(m.ViewController, item)
				newScreen.ScreenName = "ArtistGenre" + item.Id
        			m.ViewController.InitializeOtherScreen(newScreen, [item.Title, "Artists"])
				newScreen.Show()
        			return true
    	    		else if buttonCommand = "allstudioartist" then
        			newScreen = createArtistStudioScreen(m.ViewController, item)
				newScreen.ScreenName = "ArtistStudio" + item.Id
        			m.ViewController.InitializeOtherScreen(newScreen, [item.Title, "Artists"])
				newScreen.Show()
        			return true
			else if (buttonCommand = "instantmix")
				busyDialog = CreateObject("roMessageDialog")
				busyDialog.SetTitle("Creating Instant Mix Track list...")
				busyDialog.ShowBusyAnimation()
				busyDialog.Show()
				tracks = musicGetInstantMixForItem(m.item)
				breadcrumbText = "Instant Mix For " + breadcrumbText
				screenName = "instantmix " + screenName
			else
				if buttonCommand = "genretracklist"
					busyDialog = CreateObject("roMessageDialog")
					busyDialog.SetTitle("Creating Track list...")
					busyDialog.ShowBusyAnimation()
					busyDialog.Show()
					data = musicGetSongsByGenre(m.item.Title)
    					MusicMetadata = InitMusicMetadata()
    					tracks = MusicMetadata.SongRefill(data.items)
				else if buttonCommand = "studiotracklist"
					busyDialog = CreateObject("roMessageDialog")
					busyDialog.SetTitle("Creating Track list...")
					busyDialog.ShowBusyAnimation()
					busyDialog.Show()
					data = musicGetSongsByStudio(m.item.Title)
    					MusicMetadata = InitMusicMetadata()
    					tracks = MusicMetadata.SongRefill(data.items)
				else if (buttonCommand = "artisttracklist")
					method = showTrackMethodDialog()
					if method <> "3"
						busyDialog = CreateObject("roMessageDialog")
						busyDialog.SetTitle("Creating Track list...")
						busyDialog.ShowBusyAnimation()
						busyDialog.Show()

						if method <> "0"
							data = musicGetSongsByArtist(m.item.Title)
    							MusicMetadata = InitMusicMetadata()
    							tracks = MusicMetadata.SongRefill(data.items)
						else
							tracks = musicGetSongsForItem(m.item)
						end if
						if method <> "2"
							total = tracks.count()
							busyDialog = CreateObject("roMessageDialog")
							busyDialog.SetTitle("Reducing Track list...")
							busyDialog.UpdateText("Song 1 of...")
							busyDialog.ShowBusyAnimation()
							busyDialog.Show()
							if tracks <> invalid
								indexer = 0
								counter = 0
	  							for each song in tracks
									if song <> invalid
										if UCase(song.Artist) <> UCase(item.Title)
											tracks.Delete(counter)
										else
											counter = counter + 1
										end if
									end if
									indexer = indexer + 1
									busyDialog.UpdateText("Song "+tostr(indexer)+" of "+tostr(total)+", Total Tracks by Artist: "+tostr(tracks.count()))
	  							end for
							end if
							busyDialog.Close()
						end if
					end if
				else
					busyDialog = CreateObject("roMessageDialog")
					busyDialog.SetTitle("Creating Track list...")
					busyDialog.ShowBusyAnimation()
					busyDialog.Show()
					if (m.item.ContentType = "MusicArtist")
						data = musicGetSongsByArtist(m.item.Title)
    						MusicMetadata = InitMusicMetadata()
    						tracks = MusicMetadata.SongRefill(data.items)
					else if (m.item.ContentType = "MusicGenre")
						data = musicGetSongsByGenre(m.item.Title)
    						MusicMetadata = InitMusicMetadata()
    						tracks = MusicMetadata.SongRefill(data.items)
					else if (m.item.ContentType = "MusicStudio") or (m.item.ContentType = "Studio")
						data = musicGetSongsByStudio(m.item.Title)
    						MusicMetadata = InitMusicMetadata()
    						tracks = MusicMetadata.SongRefill(data.items)
					else
						tracks = musicGetSongsForItem(m.item)
					end if
				end if

				if (buttonCommand = "shuffle") AND (tracks.Count() > 1) then 
					startIndex = rnd(tracks.Count()) - 1
					ShuffleArray(tracks, startIndex)
				end if
				
				if (buttonCommand = "tracklist") then startPlaying = false
				
				if (m.item.ContentType = "MusicAlbum") AND (m.item.Artist <> invalid) AND (m.item.Artist <> "") then
						'breadcrumbText = m.item.AlbumArtist + " - " + breadcrumbText
				end if
	
			end if	
			if method <> "3"			
				if tracks <> invalid
					if tracks.count() > 0
						listScreen = createMusicListScreen(m.ViewController, tracks)
					else
						createDialog("Track List Error", "There are 0 tracks to play.  Sorry.", "OK", true)
						return handled OR m.superHandleMessage(msg)
					end if
				else
					createDialog("Track List Error", "The tracks are invalid and cannot be played.  Sorry.", "OK", true)
					return handled OR m.superHandleMessage(msg)
				end if
			end if
		end if
		if method <> "3"
			m.ViewController.AddBreadcrumbs(listScreen, [breadcrumbText])
			m.ViewController.UpdateScreenProperties(listScreen)
			m.ViewController.PushScreen(listScreen)
			if (busyDialog <> invalid) then busyDialog.Close()
			listScreen.Show()
		
			'if (startPlaying) then listScreen.PlayFromIndex(0)
		end if				            
	    end if
	end if

	return handled OR m.superHandleMessage(msg)
end Function	

'**********************************************************
'** Music Get Songs by Artist
'**********************************************************

Function musicGetSongsByArtist(artistName As String) As Object
    ' Validate Parameter
    if validateParam(artistName, "roString", "musicmetadata_artist_albums") = false return invalid

    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items"

    limit = FirstOf(RegRead("prefgenrestudio"),"200")
    ' Query
    query = {
        artists: artistName
        recursive: "true"
        includeitemtypes: "Audio"
        fields: "AudioInfo,ParentId,PrimaryImageAspectRatio,DateCreated,Overview,Genres"
        sortby: "SortName"
        sortorder: "Ascending",
	ImageTypeLimit: "1"
    }
	if limit <> "0"
		query.addreplace("Limit", limit)
		query.addreplace("StartIndex", "0")
	end if

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()
    request.BuildQuery(query)

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid
        return parseItemsResponse(response, 0, "arced-square")
    else
	createDialog("Response Error!", "No Tracks by Artist were Found. (invalid)", "OK", true)
    end if

    return invalid
End Function

'**********************************************************
'** Music Get Songs by Genre
'**********************************************************

Function musicGetSongsByGenre(genre As String) As Object

    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items"


    limit = FirstOf(RegRead("prefgenrestudio"),"200")
    ' Query
    query = {
        genres: genre
        recursive: "true"
        includeitemtypes: "Audio"
        fields: "AudioInfo,ParentId,PrimaryImageAspectRatio,DateCreated,Overview,Genres"
        sortby: "SortName"
        sortorder: "Ascending",
	ImageTypeLimit: "1"
    }
	if limit <> "0"
		query.addreplace("Limit", limit)
		query.addreplace("StartIndex", "0")
	end if

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()
    request.BuildQuery(query)

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid
        return parseItemsResponse(response, 0, "arced-square")
    else
	createDialog("Response Error!", "No Tracks by Genre were Found. (invalid)", "OK", true)
    end if

    return invalid
End Function

'**********************************************************
'** Music Get Artists by Genre
'**********************************************************

Function musicGetArtistsByGenre(genre As String) As Object

    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items"

    ' Query
    query = {
        sortby: "SortName"
        sortorder: "Ascending"
        includeitemtypes: "MusicArtist"
        recursive: "true"
        fields: "ItemCounts,AudioInfo,ParentId,PrimaryImageAspectRatio,DateCreated,Overview,Genres"
	CollapseBoxSetItems: "false"
        genres: genre
	ImageTypeLimit: "1"
    }

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()
    request.BuildQuery(query)

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid
        return parseItemsResponse(response, 0, "arced-square")
    else
	createDialog("Response Error!", "No Artists by Genre were Found. (invalid)", "OK", true)
    end if

    return invalid
End Function

'**********************************************************
'** Music Get Artists by Studio
'**********************************************************

Function musicGetArtistsByStudio(studio As String) As Object

    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items"

    ' Query
     query = {
        studios: studio
        recursive: "true"
        includeitemtypes: "MusicArtist"
        fields: "ItemCounts,AudioInfo,ParentId,PrimaryImageAspectRatio,DateCreated,Overview,Genres"
        sortby: "SortName"
        sortorder: "Ascending",
	ImageTypeLimit: "1"
    }

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()
    request.BuildQuery(query)

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid
        return parseItemsResponse(response, 0, "arced-square")
    else
	createDialog("Response Error!", "No Artists by Studio were Found. (invalid)", "OK", true)
    end if

    return invalid
End Function

'**********************************************************
'** Music Get Songs by Studio
'**********************************************************

Function musicGetSongsByStudio(studio As String) As Object

    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items"


    limit = FirstOf(RegRead("prefgenrestudio"),"200")
    ' Query
    query = {
        studios: studio
        recursive: "true"
        includeitemtypes: "Audio"
        fields: "AudioInfo,ParentId,PrimaryImageAspectRatio,DateCreated,Overview,Genres"
        sortby: "SortName"
        sortorder: "Ascending",
	ImageTypeLimit: "1"
    }
	if limit <> "0"
		query.addreplace("Limit", limit)
		query.addreplace("StartIndex", "0")
	end if

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()
    request.BuildQuery(query)

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid
        return parseItemsResponse(response, 0, "arced-square")
    else
	createDialog("Response Error!", "No Tracks by Studio were Found. (invalid)", "OK", true)
    end if

    return invalid
End Function

Function createTrackMethodDialog()
	dlg = createBaseDialog()
	dlg.Title = "Artists Tracks"
	dlg.Text = "How do you want to obtain the artist tracks?"+chr(10)
	dlg.SetButton("2", "(normal) Artist Tracks & no Fflter")
	dlg.SetButton("1", "(slow) Artist Tracks & filter by Artist")
	dlg.SetButton("0", "(slowest) Album Tracks & filter by Artist")
	dlg.SetButton("3", "Cancel")
	return dlg
End Function

Function showTrackMethodDialog()
	dlg = createTrackMethodDialog()
	dlg.Show(true)
	return dlg.Result
End Function

'**********************************************************
'** createArtistGenreScreen
'**********************************************************

function createArtistGenreScreen(viewController as Object, item as Object) as Object

    obj = CreatePosterScreen(viewController, item, "arced-square")

	obj.GetDataContainer = getArtistGenreDataContainer

    return obj
end function

Function getArtistGenreDataContainer(viewController as Object, item as Object) as Object

    items = musicGetArtistsByGenre(item.Title)

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
'** createArtistStudioScreen
'**********************************************************

function createArtistStudioScreen(viewController as Object, item as Object) as Object

    obj = CreatePosterScreen(viewController, item, "arced-square")

	obj.GetDataContainer = getArtistStudioDataContainer

    return obj
end function

Function getArtistStudioDataContainer(viewController as Object, item as Object) as Object

    items = musicGetArtistsByStudio(item.Title)

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
'** GetTotalDuration
'**********************************************************

Function GetTotalDuration(songs As Object) As String
    total = 0
    For each songData in songs
	songLength = songData.Length
        total = total + firstOf(songLength, 0)
    End For

    Return FormatTime(total)
End Function

'**********************************************************
'** ShowSpeakerIcon
'**********************************************************

Function ShowSpeakerIcon(screen As Object, index As Integer) As Integer
	items = screen.audioItems
	if items <> invalid and items.count() > 0 and index < items.count() and AudioPlayer().context <> invalid
		if items[index].artist = AudioPlayer().context[index].artist and items[index].Title = AudioPlayer().context[index].Title
    			items[index].HDSmallIconUrl = GetViewController().getThemeImageUrl("SpeakerIcon.png")
    			items[index].SDSmallIconUrl = GetViewController().getThemeImageUrl("SpeakerIcon.png")
    			screen.SetContent(items)
    			screen.Show()
			return index
		end if
	end if
	return 0
End Function

'**********************************************************
'** ShowPauseIcon
'**********************************************************

Function ShowPauseIcon(screen As Object, index As Integer)
	items = screen.audioItems
	if items <> invalid and items.count() > 0 and index < items.count() and AudioPlayer().context <> invalid and AudioPlayer().context[index] <> invalid
		if items[index].artist = AudioPlayer().context[index].artist and items[index].Title = AudioPlayer().context[index].Title
			items[index].HDSmallIconUrl = GetViewController().getThemeImageUrl("PauseIcon.png")
			items[index].SDSmallIconUrl = GetViewController().getThemeImageUrl("PauseIcon.png")
			screen.SetContent(items)
		end if
	end if
End Function

'**********************************************************
'** HideSpeakerIcon
'**********************************************************

Function HideSpeakerIcon(screen As Object, index As Integer, refreshScreen=invalid)
	items = screen.audioItems
	if items <> invalid and items.count() > 0 and index < items.count() and AudioPlayer().context <> invalid
		items[index].HDSmallIconUrl = false
		items[index].SDSmallIconUrl = false
		If refreshScreen<>invalid Then
			screen.SetContent(items)
		end if
	end if
End Function