'**********************************************************
'** createHomeScreen
'**********************************************************

Function createHomeScreen(viewController as Object) as Object

	names = []
	keys = []

	QuickJumpRow = FirstOf(RegRead("prefQuickJumpRow"),"0")

	OptionsRow = FirstOf(RegRead("prefOptionsRow"),"0")

	ImageType = FirstOf(RegUserRead("homeImageType"),"0")

	if QuickJumpRow = "1"
		keys.push("quickjump")
		names.push("Quick Launch")
	end if

	if OptionsRow = "0" or OptionsRow = "2"
		keys.push("options")
		names.push("Options and QuickViews")
		shown = 1
	else
		shown = 0
	end if
	pre = keys.count()
	views = getUserViews()
	
	for each view in views
	
		names.push(view.Title)
		
		key = view.CollectionType + "|" + view.Id + "|" + firstOf(view.HDPosterUrl, "")
		
		keys.push(key)
		
	end for
	if (pre = keys.count() and shown <> 1) or OptionsRow = "1" or OptionsRow = "2"
		keys.push("options")
		names.push("Options and QuickViews")
	end if

	loader = CreateObject("roAssociativeArray")
	loader.getUrl = getHomeScreenRowUrl
	loader.parsePagedResult = parseHomeScreenResult
	loader.getLocalData = getHomeScreenLocalData
	if ImageType = "0"
		screen = createPaginatedGridScreen(viewController, names, keys, loader, "mixed-aspect-ratio", 10, 100)
		screen.SetDescriptionVisible(true)
		screen.displayDescription = 1
	else
		screen = createPaginatedGridScreen(viewController, names, keys, loader, "two-row-flat-landscape-custom", 10, 100)
		screen.SetDescriptionVisible(false)
		screen.displayDescription = 0
	end if
	screen.baseHandleMessage = screen.HandleMessage
	screen.HandleMessage = handleHomeScreenMessage
	screen.OnTimerExpired = homeScreenOnTimerExpired
	screen.SuperActivate = screen.Activate
	screen.Activate = homeScreenActivate
	screen.refreshBreadcrumb = homeRefreshBreadcrumb
	screen.clockTimer = createTimer()
	screen.clockTimer.Name = "clock"
	screen.clockTimer.SetDuration(20000, true) ' A little lag is fine here
	viewController.AddTimer(screen.clockTimer, screen)

	ConnectionManager().sendWolToAllServers(m)
	screen.createContextMenu = HomeScreenCreateContextMenu
	' only the audio contextmenu exists on the homescreen
	' so allow it to show up as no conflict
	GetGlobalAA().AddReplace("AudioConflict","0")
	return screen
End Function

Function getUserViews() as Object

	views = []
	
	if getGlobalVar("user") = invalid then return views
	url = GetServerBaseUrl() + "/Users/" + getGlobalVar("user").Id + "/Views?fields=PrimaryImageAspectRatio"
	
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()
	ImageType = FirstOf(RegUserRead("homeImageType"),"0")
	if type(ImageType) = "roString" or type(ImageType) = "String" then
		ImageType = ImageType.toInt()
	end if
	if ImageType = 0
		imageStyle = "mixed-aspect-ratio-portrait"
	else
		imageStyle = "two-row-flat-landscape-custom"
	end if
    response = request.GetToStringWithTimeout(10)
    if response <> invalid
	result = parseItemsResponse(response, ImageType, imageStyle)
		for each i in result.Items
		
			viewType = firstOf(i.CollectionType, "")
			
			' Filter out unsupported views
			if viewType = "movies" or viewType = "music" or viewType = "tvshows" or viewType = "livetv" or viewType = "channels" or viewType = "folders" or viewType = "playlists" or viewType = "musicvideos" or viewType = "homevideos" or viewType = "boxsets" or viewType = "photos" then
				views.push(i)
			' Mixed content has no contentType
			else if viewType = "" and i.contenttype = "MediaFolder"
				viewType = "folders2"
				views.push(i)
			' Treat all other types as folders for now
			else
				viewType = "folders"
				views.push(i)
			end if
		
			' Normalize this
			i.CollectionType = viewType
			
		end for
    else
	createDialog("User Views Error!", "Failed To Get User Views (invalid).", "OK", true)
    end if	
	
	return views

End Function

Function getHomeScreenLocalData(row as Integer, id as String, startItem as Integer, count as Integer) as Object

	viewController = GetViewController()
	
	parts = id.tokenize("|")
	id = parts[0]
	parentId = firstOf(parts[1], "")
	viewTileImageUrl = parts[2]
	if id = "options" then
		return GetOptionButtons(viewController)

	else if id = "quickjump" then
		return GetQuickJumpButtons(viewController)

	else if id = "folders2" 
	
		folderToggle  = (firstOf(RegUserRead("folderToggle"), "2")).ToInt()
		
		' Jump list
		if folderToggle = 2 then
		
			return GetFolderButtons(viewController, folderToggle, parentId, viewTileImageUrl)
		end if
		
	else if id = "movies" 
	
		movieToggle  = (firstOf(RegUserRead("movieToggle"), "2")).ToInt()
		
		' Jump list
		if movieToggle = 3 then
		
			return GetMovieButtons(viewController, movieToggle, parentId, viewTileImageUrl)
		end if
		
	else if id = "tvshows" 
	
		tvToggle  = (firstOf(RegUserRead("tvToggle"), "1")).ToInt()
		
		' Jump list
		if tvToggle = 3 then
		
			return GetTVButtons(viewController, tvToggle, parentId, viewTileImageUrl)
		end if

	else if id = "music" 
	
		musicToggle  = (firstOf(RegUserRead("musicToggle"), "1")).ToInt()
		
		' Jump list
		if musicToggle = 2 or musicToggle = 3 then
		
			return GetMusicButtons(viewController, musicToggle, parentId, viewTileImageUrl)
		end if

	else if id = "homevideos" or id = "musicvideos"
	
		hvToggle  = (firstOf(RegUserRead("hvToggle"), "1")).ToInt()
		
		' Jump list
		if hvToggle = 2 then
		
			return GetHomeVideoButtons(viewController, hvToggle, parentId, viewTileImageUrl)
		end if

	else if id = "photos"
	
		photoToggle  = (firstOf(RegUserRead("photoToggle"), "1")).ToInt()
		
		' Jump list
		if photoToggle = 2 then
		
			return GetPhotoButtons(viewController, photoToggle, parentId, viewTileImageUrl)
		end if

	end If
	
	return invalid

End Function

Function getHomeScreenRowUrl(row as Integer, id as String) as String

	parts = id.tokenize("|")
	id = parts[0]
	parentId = firstOf(parts[1], "")
	url = GetServerBaseUrl()
	latest = FirstOf(regUserRead("preflatest"), "0").toInt()
	remwatch = FirstOf(RegUserRead("prefRemWatch"),"yes")
	remwatchsug = FirstOf(RegUserRead("prefRemWatchSug"),"yes")
	query = {}
	ImageType = FirstOf(RegUserRead("homeImageType"),"0")
	if type(ImageType) = "roString" or type(ImageType) = "String" then
		ImageType = ImageType.toInt()
	end if
	eble = "Primary,Backdrop,Thumb"

	if id = "folders"
	
		url = url  + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?sortby=sortname"
		query.AddReplace("Fields", "ItemCounts,PrimaryImageAspectRatio,Overview,ParentId")
		
	else if id = "playlists"
	
		url = url  + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?sortby=sortname&fields=PrimaryImageAspectRatio,Overview,ParentId&CollapseBoxSetItems=false"

	else if id = "boxsets"

		url = url  + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?sortby=sortname&fields=PrimaryImageAspectRatio"
		
	else if id = "channels"
	
		url = url  + "/Channels?userid=" + HttpEncode(getGlobalVar("user").Id)
		query.AddReplace("Fields", "ItemCounts,PrimaryImageAspectRatio,Overview")

	else if id = "folders2"

		folderToggle  = (firstOf(RegUserRead("folderToggle"), "1")).ToInt()

		if folderToggle = 1 then
			if latest = 0 then
				url = url + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?"
				query = {
					recursive: "true"
					ExcludeLocationTypes: "Virtual"
					fields: "PrimaryImageAspectRatio,Overview,ParentId"
					sortby: "DateCreated"
					sortorder: "Descending"
					ImageTypeLimit: "1"
				}
				if remwatch = "yes" then query.AddReplace("filters", "IsUnplayed")
			else
				url = url + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items/Latest?"
				query = {
					fields: "DateCreated,ItemCounts,PrimaryImageAspectRatio,Overview,ParentId"
					ImageTypeLimit: "1"
					EnableImageTypes: "Primary,Thumb,Backdrop"
					GroupItems: "false"
					EnableTotalRecordCount: "true"
				}	
				if latest = 2
					query.AddReplace("GroupItems", "True")
					query.AddReplace("EnableImageTypes", eble)
				end if
				'if remwatch = "yes" then query.AddReplace("filters", "IsUnplayed")
			end if
			
		' Resume
		else if folderToggle = 3 then
			
			url = url + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?"
			query = {
				recursive: "true"
				fields: "PrimaryImageAspectRatio,Overview,ParentId"
				sortby: "DatePlayed"
				sortorder: "Descending"
				filters: "IsResumable",
				ImageTypeLimit: "1"
			}
			
		' Favorites
		else if folderToggle = 4 then
			
			url = url + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?"
			query = {
				recursive: "true"
				fields: "PrimaryImageAspectRatio,Overview,ParentId"
				sortby: "SortName"
				sortorder: "Ascending"
				filters: "IsFavorite",
				ImageTypeLimit: "1"
			}
		end if	

	else if id = "movies"
	
		movieToggle  = (firstOf(RegUserRead("movieToggle"), "1")).ToInt()

		' Next Up
		if movieToggle = 1 then
			
			url = url + "/Movies/Recommendations?userId=" + HttpEncode(getGlobalVar("user").Id)
			
			query = {
				ItemLimit: "20"
				CategoryLimit: "6"
				fields: "PrimaryImageAspectRatio,Overview,ParentId",
				ImageTypeLimit: "1"
			}
			if remwatchsug = "yes" then query.AddReplace("filters", "IsUnplayed")
			
		' Latest
		else if movieToggle = 2 then
			if latest = 0 then
				url = url + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?IncludeItemTypes=Movie"
				query = {
					recursive: "true"
					ExcludeLocationTypes: "Virtual"
					fields: "PrimaryImageAspectRatio,Overview,ParentId"
					sortby: "DateCreated"
					sortorder: "Descending"
					ImageTypeLimit: "1"
				}
				if remwatch = "yes" then query.AddReplace("filters", "IsUnplayed")
			else
				url = url + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items/Latest?IncludeItemTypes=Movie"
				query = {
					fields: "DateCreated,ItemCounts,PrimaryImageAspectRatio,Overview,ParentId"
					ImageTypeLimit: "1"
					EnableImageTypes: "Primary,Backdrop,Thumb"
					EnableTotalRecordCount: "true"
				}
				'if remwatch = "yes" then query.AddReplace("filters", "IsUnplayed")
			end if

		' Resume
		else if movieToggle = 4 then
			
			url = url + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?includeitemtypes=Movie"
			query = {
				recursive: "true"
				fields: "PrimaryImageAspectRatio,Overview,ParentId"
				sortby: "DatePlayed"
				sortorder: "Descending"
				filters: "IsResumable",
				ImageTypeLimit: "1"
			}
			
		' Favorites
		else if movieToggle = 5 then
			
			url = url + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?includeitemtypes=Movie"
			query = {
				recursive: "true"
				fields: "PrimaryImageAspectRatio,Overview,ParentId"
				sortby: "SortName"
				sortorder: "Ascending"
				filters: "IsFavorite",
				ImageTypeLimit: "1"
			}
			
		' Genres
		else if movieToggle = 6 then
			
			url = url + "/Genres?Recursive=true&EnableTotalRecordCount=true"
			query = {
				userid: getGlobalVar("user").Id
				includeitemtypes: "Movie"
				fields: "ItemCounts,PrimaryImageAspectRatio,Overview,ParentId"
				sortby: "SortName"
				sortorder: "Ascending"
			}
			
		end if		
		
	else if id = "tvshows"
	
		tvToggle  = (firstOf(RegUserRead("tvToggle"), "1")).ToInt()

		' Next Up
		if tvToggle = 1 then
			
			url = url + "/Shows/NextUp?userId=" + HttpEncode(getGlobalVar("user").Id)
			
			query = {
				fields: "PrimaryImageAspectRatio,Overview,AirTime,ParentId",
				ImageTypeLimit: "1"
			}
			
		' Latest
		else if tvToggle = 2 then
			if latest = 0 then
				url = url + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?IncludeItemTypes=Episode"
				query = {
					recursive: "true"
					ExcludeLocationTypes: "Virtual"
					fields: "PrimaryImageAspectRatio,Overview,AirTime,ParentId"
					sortby: "DateCreated"
					sortorder: "Descending"
					ImageTypeLimit: "1"
				}
				if remwatch = "yes" then query.AddReplace("filters", "IsUnplayed")
			else
				url = url + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items/Latest?IncludeItemTypes=Episode"
				query = {
					fields: "DateCreated,ItemCounts,PrimaryImageAspectRatio,Overview,AirTime,ParentId"
					ImageTypeLimit: "1"
					EnableImageTypes: "Primary,Thumb,Backdrop"
					GroupItems: "false"
					EnableTotalRecordCount: "true"
				}	
				if latest = 2
					query.AddReplace("GroupItems", "True")
					query.AddReplace("EnableImageTypes", eble)
				end if
				'if remwatch = "yes" then query.AddReplace("filters", "IsUnplayed")
			end if
			
		' Resume
		else if tvToggle = 4 then
			
			url = url + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?includeitemtypes=Episode"
			query = {
				recursive: "true"
				fields: "PrimaryImageAspectRatio,Overview,AirTime,ParentId"
				sortby: "DatePlayed"
				sortorder: "Descending"
				filters: "IsResumable",
				ImageTypeLimit: "1"
			}
			
		' Favorites
		else if tvToggle = 5 then
			
			url = url + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?includeitemtypes=Series"
			query = {
				recursive: "true"
				fields: "PrimaryImageAspectRatio,Overview,AirTime,ParentId"
				sortby: "SortName"
				sortorder: "Ascending"
				filters: "IsFavorite",
				ImageTypeLimit: "1"
			}
			
		' Genres
		else if tvToggle = 6 then
			
			url = url + "/Genres?SortBy=SortName"
			query = {
				sortorder: "Ascending",
				includeitemtypes: "Series",
				recursive: "true"
				userid: getGlobalVar("user").Id	
			}
				'fields: "ItemCounts,PrimaryImageAspectRatio,Overview,AirTime,ParentId"
				'ImageTypeLimit: "1"
		end if		
		
	else if id = "livetv"
	
		liveTvToggle = (firstOf(RegUserRead("liveTvToggle"), "1")).ToInt()

		' Suggested
		if liveTvToggle = 1 then
			
			url = url + "/LiveTv/Programs/Recommended?userId=" + HttpEncode(getGlobalVar("user").Id)
			query = {
				IsAiring: "true"
			}
			
		' Favorites
		else if liveTvToggle = 2 then
			
			url = url + "/LiveTv/Channels?userId=" + HttpEncode(getGlobalVar("user").Id)
			query = {
				IsFavorite: "true"
			}
			
		' Resume
		else if liveTvToggle = 3 then
			
			url = url + "/LiveTv/Recordings?userId=" + HttpEncode(getGlobalVar("user").Id)
			query = {
				IsInProgress: "false"
			}
			
		end if		
		
	else if id = "music"
	
		musicToggle  = (firstOf(RegUserRead("musicToggle"), "1")).ToInt()
		
		' Latest
		if musicToggle = 1 then
			if latest = 1 then
				url = url + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?includeitemtypes=MusicAlbum"	
				query = {
					recursive: "true"
					fields: "PrimaryImageAspectRatio,Overview,ParentId"
					sortby: "DateCreated"
					sortorder: "Descending",
					ImageTypeLimit: "1"
				}
				if remwatch = "yes" then query.AddReplace("filters", "IsUnplayed")
			else
				url = url + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items/Latest?IncludeItemTypes=MusicAlbum"
				query = {
					fields: "DateCreated,ItemCounts,PrimaryImageAspectRatio,Overview,ParentId"
					ImageTypeLimit: "1"
					EnableImageTypes: "Primary,Backdrop,Thumb"
					TotalRecordCount: "100"
					EnableTotalRecordCount: "true"
				}
			end if
			'if remwatch = "yes" then query.AddReplace("filters", "IsUnplayed")

		' Favorite
		else if musicToggle = 4 then
			
			url = url + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?includeitemtypes=MusicAlbum"		
			query = {
				recursive: "true"
				fields: "PrimaryImageAspectRatio,AudioInfo,ParentId,SyncInfo,Overview,Genres"
                    		SortBy: "AlbumArtist,SortName"
		    		filters: "IsFavorite",
				ImageTypeLimit: "1"
			}

		' Recent
		else if musicToggle = 5 then
			
			url = url + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?includeitemtypes=Audio"		
			query = {
				recursive: "true"
				fields: "PrimaryImageAspectRatio,AudioInfo,ParentId,SyncInfo,Overview,Genres"
				sortby: "DatePlayed"
				filters: "isPlayed"
				sortorder: "Descending",
				ImageTypeLimit: "1"
			}

		' Most Played
		else if musicToggle = 6 then
			
			url = url + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?includeitemtypes=Audio"		
			query = {
				recursive: "true"
				fields: "PrimaryImageAspectRatio,AudioInfo,ParentId,SyncInfo,Overview,Genres"
				sortby: "PlayCount"
				filters: "isPlayed"
				sortorder: "Descending",
				ImageTypeLimit: "1"
			}

		' Genre
		else if musicToggle = 7 then
			
			url = url + "/Genres?Recursive=true"
			query = {
				userid: getGlobalVar("user").Id
				includeitemtypes: "MusicAlbum,Audio"
				fields: "ItemCounts,PrimaryImageAspectRatio,AudioInfo,ParentId,SyncInfo,Overview,Genres"
				sortby: "SortName"
				sortorder: "Ascending",
				ImageTypeLimit: "1"
			}
		
		else
		
			' Not going to use the output, just checking to see if the user has music in their library
			url = url + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?includeitemtypes=Audio"		
			query = {
				recursive: "true"
				fields: "PrimaryImageAspectRatio,Overview"
				sortby: "DateCreated"
				sortorder: "Descending",
				ImageTypeLimit: "1"
			}
		
			
		end if
	else if id = "homevideos" or id = "musicvideos"
		hvToggle  = (firstOf(RegUserRead("hvToggle"), "1")).ToInt()
		if hvToggle = 1 then
			if latest = 0 then
				url = url + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?IncludeItemTypes=MusicVideo,Video"
				query = {
					recursive: "true"
					ExcludeLocationTypes: "Virtual"
					fields: "PrimaryImageAspectRatio,Overview,ParentId"
					sortby: "DateCreated"
					sortorder: "Descending"
					ImageTypeLimit: "1"
				}
				if remwatch = "yes" then query.AddReplace("filters", "IsUnplayed")
			else
				url = url + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items/Latest?IncludeItemTypes=MusicVideo,Video"
				query = {
					fields: "DateCreated,ItemCounts,PrimaryImageAspectRatio,Overview,ParentId"
					ImageTypeLimit: "1"
					EnableImageTypes: "Primary,Thumb,Backdrop"
					GroupItems: "false"
					EnableTotalRecordCount: "true"
				}	
				if latest = 2
					query.AddReplace("GroupItems", "True")
					query.AddReplace("EnableImageTypes", eble)
				end if
				'if remwatch = "yes" then query.AddReplace("filters", "IsUnplayed")
			end if
			
		' Resume
		else if hvToggle = 3 then
			
			url = url + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?includeitemtypes=MusicVideo,Video"
			query = {
				recursive: "true"
				fields: "PrimaryImageAspectRatio,Overview,ParentId"
				sortby: "DatePlayed"
				sortorder: "Descending"
				filters: "IsResumable",
				ImageTypeLimit: "1"
			}
			
		' Favorites
		else if hvToggle = 4 then
			
			url = url + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?includeitemtypes=MusicVideo,Video"
			query = {
				recursive: "true"
				fields: "PrimaryImageAspectRatio,Overview,ParentId"
				sortby: "SortName"
				sortorder: "Ascending"
				filters: "IsFavorite",
				ImageTypeLimit: "1"
			}
		end if	
	else if id = "photos"
		photoToggle  = (firstOf(RegUserRead("photoToggle"), "1")).ToInt()
		if photoToggle = 1 then
			if latest = 0 then
				url = url + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?"
				query = {
					recursive: "true"
					ExcludeLocationTypes: "Virtual"
					fields: "PrimaryImageAspectRatio,Overview,ParentId"
					sortby: "DateCreated"
					sortorder: "Descending"
					ImageTypeLimit: "1"
				}
				if remwatch = "yes" then query.AddReplace("filters", "IsUnplayed")
			else
				url = url + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items/Latest?"
				query = {
					fields: "DateCreated,ItemCounts,PrimaryImageAspectRatio,Overview,ParentId"
					ImageTypeLimit: "1"
					EnableImageTypes: "Primary,Thumb,Backdrop"
					GroupItems: "false"
					EnableTotalRecordCount: "true"
				}	
				if latest = 2
					query.AddReplace("GroupItems", "True")
					query.AddReplace("EnableImageTypes", eble)
				end if
				'if remwatch = "yes" then query.AddReplace("filters", "IsUnplayed")
			end if
			
		' Resume
		else if photoToggle = 3 then
			
			url = url + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?"
			query = {
				recursive: "true"
				fields: "PrimaryImageAspectRatio,Overview,ParentId"
				sortby: "DatePlayed"
				sortorder: "Descending"
				filters: "IsResumable",
				ImageTypeLimit: "1"
			}
			
		' Favorites
		else if photoToggle = 4 then
			
			url = url + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?"
			query = {
				recursive: "true"
				fields: "PrimaryImageAspectRatio,Overview,ParentId"
				sortby: "SortName"
				sortorder: "Ascending"
				filters: "IsFavorite",
				ImageTypeLimit: "1"
			}
		end if	
		
	end If
	
	if id <> "channels" and id <> "livetv" and parentId <> "" then
		
		query.AddReplace("ParentId", parentId)

	end if

	for each key in query
		url = url + "&" + key +"=" + HttpEncode(query[key])
	end for
    return url

End Function

Function parseHomeScreenResult(row as Integer, id as string, startIndex as Integer, json as String) as Object

	viewController = GetViewController()
	maxListSize = 100
	
	parts = id.tokenize("|")
	id = parts[0]
	parentId = firstOf(parts[1], "")
	viewTileImageUrl = parts[2]
	ImageType = FirstOf(RegUserRead("homeImageType"),"0")
	if type(ImageType) = "roString" or type(ImageType) = "String" then
		ImageType = ImageType.toInt()
	end if
	if ImageType = 0
		imageStyle = "mixed-aspect-ratio-portrait"
	else
		imageStyle = "two-row-flat-landscape-custom"
	end if
	
	if id = "folders" then
		return parseItemsResponse(json, imageType, imageStyle)
	else if id = "playlists" then
		return parseItemsResponse(json, imageType, imageStyle)
	else if id = "boxsets" then
		return parseItemsResponse(json, imageType, imageStyle)
	else if id = "channels" then
		return parseItemsResponse(json, imageType, imageStyle)
		
	else if id = "movies" then
	
		movieToggle  = (firstOf(RegUserRead("movieToggle"), "1")).ToInt()		
		
		if movieToggle = 1 then
			response = parseSuggestedMoviesResponse(json)
		else if movieToggle = 6 then
			response = parseItemsResponse(json, imageType, imageStyle, "moviegenre")
			response.Items = AddParentID(response.Items, parentId)
		else
			response = parseItemsResponse(json, imageType, imageStyle)
		end if
		
		buttons = GetBaseMovieButtons(viewController, movieToggle, parentId, viewTileImageUrl, response)
		buttonCount = buttons.Count()
		minTotalRecordCount = buttonCount + response.Items.Count()
		
		' Only insert buttons if startIndex = 0
		if startIndex = 0 then						
			buttons.Append(response.Items)		
			response.Items = buttons
		end if

		if response.TotalCount > maxListSize then response.TotalCount = maxListSize	
		if response.TotalCount < minTotalRecordCount then response.TotalCount = minTotalRecordCount	
		return response
		
	else if id = "tvshows" then
	
		tvToggle  = (firstOf(RegUserRead("tvToggle"), "1")).ToInt()
		latest = FirstOf(regUserRead("preflatest"), "0").toInt()		

		if ImageType = 0
			seriesimage = "seriesimageasprimary"
		else
			seriesimage = ""
		end if

		if tvToggle = 2 then
			if latest = 2
				if ImageType = 0
					response = parseItemsResponse(json, imageType, imageStyle, "latestrow")
				else
					response = parseItemsResponse(json, imageType, imageStyle, "latestrow2")
				end if
			else
				response = parseItemsResponse(json, imageType, imageStyle, seriesimage)
			end if
		else if tvToggle = 5 then
			response = parseItemsResponse(json, imageType, imageStyle)
		else if tvToggle = 6 then
			response = parseItemsResponse(json, imageType, imageStyle, "tvgenre")
			response.Items = AddParentID(response.Items, parentId)
		else
			response = parseItemsResponse(json, imageType, imageStyle, seriesimage)
		end if
		
		buttons = GetBaseTVButtons(viewController, tvToggle, parentId, viewTileImageUrl)
		buttonCount = buttons.Count()
		minTotalRecordCount = buttonCount + response.Items.Count()
		
		' Only insert buttons if startIndex = 0
		if startIndex = 0 then						
			buttons.Append(response.Items)		
			response.Items = buttons
		end if

		if response.TotalCount > maxListSize then response.TotalCount = maxListSize	
		if response.TotalCount < minTotalRecordCount then response.TotalCount = minTotalRecordCount
		return response
		
	else if id = "livetv" then
	
		liveTvToggle = (firstOf(RegUserRead("liveTvToggle"), "1")).ToInt()
		
		if liveTvToggle = 1 then
			response = parseLiveTvProgramsResponse(json)
		else if liveTvToggle = 2 then
			response = parseLiveTvChannelsResult(json)
		else
			response = parseLiveTvRecordingsResponse(json)
		end if
		
		buttons = GetBaseLiveTVButtons(viewController, liveTvToggle)
		buttonCount = buttons.Count()
		minTotalRecordCount = buttonCount + response.Items.Count()
		
		' Only insert buttons if startIndex = 0
		if startIndex = 0 then						
			buttons.Append(response.Items)		
			response.Items = buttons
		end if
		
		if response.TotalCount > maxListSize then response.TotalCount = maxListSize	
		if response.TotalCount < minTotalRecordCount then response.TotalCount = minTotalRecordCount	
		return response
		
	else if id = "music" then
		musicToggle  = (firstOf(RegUserRead("musicToggle"), "1")).ToInt()

		if MusicToggle = 5
			response = parseItemsResponse(json, 0, "mixed-aspect-ratio-square", "RecentlyPlayed")
		else if MusicToggle = 6
			response = parseItemsResponse(json, 0, "mixed-aspect-ratio-square", "MostPlayed")
		else if MusicToggle = 7
			response = parseItemsResponse(json, imageType, imageStyle)
		else
			response = parseItemsResponse(json, 0, "mixed-aspect-ratio-square")
		end if

		if musicToggle = 2 or MusicToggle = 3 then
			return GetMusicButtons(viewController, musicToggle, parentId, viewTileImageUrl)
		end if
		buttons = GetBaseMusicButtons(viewController, musicToggle, parentId, viewTileImageUrl)
		buttonCount = buttons.Count()
		minTotalRecordCount = buttonCount + response.Items.Count()
		' Only insert buttons if startIndex = 0
		if startIndex = 0 then
			buttons.Append(response.Items)		
			response.Items = buttons
		end if
		if musicToggle = 5 or musicToggle = 6 then maxListSize = 102
		if musicToggle <> 7 then
			if response.TotalCount > maxListSize then response.TotalCount = maxListSize
		end if
		if response.TotalCount < minTotalRecordCount then response.TotalCount = minTotalRecordCount
		return response

	else if id = "homevideos" or id = "musicvideos"
	
		hvToggle  = (firstOf(RegUserRead("hvToggle"), "1")).ToInt()
		latest = FirstOf(regUserRead("preflatest"), "0").toInt()		

		if hvToggle = 1 then
			if latest = 2
				if ImageType = 0
					response = parseItemsResponse(json, imageType, imageStyle, "latestrow")
				else
					response = parseItemsResponse(json, imageType, imageStyle, "latestrow2")
				end if
			else
				response = parseItemsResponse(json, imageType, imageStyle)
			end if
		else
			response = parseItemsResponse(json, 0, "mixed-aspect-ratio")
		end if

		'if hvToggle = 2
			'return GetHomeVideoButtons(viewController, hvToggle, parentId, viewTileImageUrl)
		'end if
		buttons = GetBaseHomeVideoButtons(viewController, hvToggle, parentId, viewTileImageUrl)
		buttonCount = buttons.Count()
		minTotalRecordCount = buttonCount + response.Items.Count()
		
		' Only insert buttons if startIndex = 0
		if startIndex = 0 then						
			buttons.Append(response.Items)		
			response.Items = buttons
		end if

		if response.TotalCount > maxListSize then response.TotalCount = maxListSize	
		if response.TotalCount < minTotalRecordCount then response.TotalCount = minTotalRecordCount
		return response

	else if id = "folders2"
	
		folderToggle  = (firstOf(RegUserRead("folderToggle"), "1")).ToInt()
		latest = FirstOf(regUserRead("preflatest"), "0").toInt()		

		if folderToggle = 1 then
			if latest = 2
				if ImageType = 0
					response = parseItemsResponse(json, imageType, imageStyle, "latestrow")
				else
					response = parseItemsResponse(json, imageType, imageStyle, "latestrow2")
				end if
			else
				response = parseItemsResponse(json, imageType, imageStyle)
			end if
		else
			response = parseItemsResponse(json, imageType, imageStyle)
		end if

		buttons = GetBaseFolderButtons(viewController, folderToggle, parentId, viewTileImageUrl)
		buttonCount = buttons.Count()
		minTotalRecordCount = buttonCount + response.Items.Count()
		
		' Only insert buttons if startIndex = 0
		if startIndex = 0 then						
			buttons.Append(response.Items)		
			response.Items = buttons
		end if

		if response.TotalCount > maxListSize then response.TotalCount = maxListSize	
		if response.TotalCount < minTotalRecordCount then response.TotalCount = minTotalRecordCount
		return response

	else if id = "photos"
	
		photoToggle  = (firstOf(RegUserRead("photoToggle"), "1")).ToInt()
		latest = FirstOf(regUserRead("preflatest"), "0").toInt()		

		if photoToggle = 1 then
			if latest = 2
				if ImageType = 0
					response = parseItemsResponse(json, imageType, imageStyle, "latestrow")
				else
					response = parseItemsResponse(json, imageType, imageStyle, "latestrow2")
				end if
			else
				response = parseItemsResponse(json, imageType, imageStyle)
			end if
		else
			response = parseItemsResponse(json, imageType, imageStyle)
		end if

		buttons = GetBasePhotoButtons(viewController, photoToggle, parentId, viewTileImageUrl)
		buttonCount = buttons.Count()
		minTotalRecordCount = buttonCount + response.Items.Count()
		
		' Only insert buttons if startIndex = 0
		if startIndex = 0 then						
			buttons.Append(response.Items)		
			response.Items = buttons
		end if

		if response.TotalCount > maxListSize then response.TotalCount = maxListSize	
		if response.TotalCount < minTotalRecordCount then response.TotalCount = minTotalRecordCount
		return response
		
	end if
	'return parseItemsResponse(json, imageType, imageStyle)

	
End Function

Function AddParentID(items as Object, parentId as String) as Object
	for each item in items
		item.parentId = parentId
	end for
	return items
End Function

Function handleHomeScreenMessage(msg) as Boolean

	handled = false

	viewController = m.ViewController

	if type(msg) = "roGridScreenEvent" Then

        if msg.isListItemSelected() Then
			
		rowIndex = msg.GetIndex()
		context = m.contentArray[rowIndex]           
		index = msg.GetData()
		item = context[index]

            if item = invalid then

            Else If item.ContentType = "MovieToggle" Then

		handled = true
                GetNextMovieToggle()
                m.loader.RefreshRow(rowIndex)

            Else If item.ContentType = "MovieRefreshSuggested" Then
				
                handled = true
                m.loader.RefreshRow(rowIndex)

            Else If item.ContentType = "TVToggle" Then
				
                handled = true
                GetNextTVToggle()
                m.loader.RefreshRow(rowIndex)

            Else If item.ContentType = "LiveTVToggle" Then
				
                handled = true
                GetNextLiveTVToggle()
                m.loader.RefreshRow(rowIndex)

            Else If item.ContentType = "MusicToggle" Then
				
                handled = true
                GetNextMusicToggle()
                m.loader.RefreshRow(rowIndex)

            Else If item.ContentType = "HomeVideoToggle" Then
				
                handled = true
                GetNextHomeVideoToggle()
                m.loader.RefreshRow(rowIndex)

            Else If item.ContentType = "FolderToggle" Then
				
                handled = true
                GetNextFolderToggle()
                m.loader.RefreshRow(rowIndex)

            Else If item.ContentType = "PhotoToggle" Then
				
                handled = true
                GetNextPhotoToggle()
                m.loader.RefreshRow(rowIndex)

            End If
				
        End If
			
    End If

	return handled or m.baseHandleMessage(msg)

End Function

'**********************************************************
'** GetNextMovieToggle
'**********************************************************

Function GetNextMovieToggle()

	movieToggle  = (firstOf(RegUserRead("movieToggle"), "1")).ToInt()
	
    movieToggle = movieToggle + 1

    if movieToggle = 7 then
        movieToggle = 1
    end if

    RegUserWrite("movieToggle", movieToggle)
	
End Function

'**********************************************************
'** Get GetMovieButtons
'**********************************************************

Function GetBaseMovieButtons(viewController as Object, movieToggle as Integer, parentId as String, allTileImageUrl = invalid, movieResponse = invalid) As Object

	if firstOf(allTileImageUrl, "") = "" then
		allTileImageUrl = viewController.getThemeImageUrl("hd-movies.jpg")
	end if
	
	buttons = [
        {
            Title: "Movie Library"
            ContentType: "MovieLibrary"
            ShortDescriptionLine1: "Library"
            HDPosterUrl: allTileImageUrl
            SDPosterUrl: allTileImageUrl,
			Id: parentId
        }
    ]

    switchButton = [
        {
            ContentType: "MovieToggle"
	    Description: "Click the tile to toggle the highlight to the next one down."
        }
    ]

    if movieToggle = 1 then
	
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-1.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-1.jpg")
        buttons.Append( switchButton )
	
	rec = movieResponse.recommendationtype

        if rec = "SimilarToRecentlyPlayed"
		rectype = "Watched the Movie"
        else if rec = "SimilarToLikedItem"
		rectype = "Like the Movie"
	else if rec = "HasDirectorFromRecentlyPlayed"
		rectype = "Watched the Director"
	else if rec = "HasLikedDirector"
		rectype = "Like the Director"
	else if rec = "HasActorFromRecentlyPlayed"
		rectype = "Watched the Actor"
	else if rec = "HasLikedActor"
		rectype = "Like the Actor"
	else
		rectype = "Not enough known"
	end if

	if movieResponse <> invalid
		if movieResponse.BaselineItemName <> invalid
			bn = movieResponse.BaselineItemName
		else
			bn = "to make suggestions"
		end if
	else
		bn = "to make suggestions"
	end if

        suggestedButton = [
                {
                    Title: rectype + chr(10) + bn
                    ContentType: "MovieRefreshSuggested"
                    ShortDescriptionLine1: rectype
                    ShortDescriptionLine2: bn
		    Description: "Click this tile to suggest different media."
                    HDPosterUrl: viewController.getThemeImageUrl("hd-similar-to.jpg")
                    SDPosterUrl: viewController.getThemeImageUrl("hd-similar-to.jpg")
                }
            ]

        buttons.Append( suggestedButton )

    else if movieToggle = 2 then
	
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-2.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-2.jpg")
		buttons.Append( switchButton )

    else if movieToggle = 3 then
	
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-3.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-3.jpg")
		buttons.Append( switchButton )

    else if movieToggle = 4 then
	
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-4.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-4.jpg")
		buttons.Append( switchButton )

    else if movieToggle = 5 then
	
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-5.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-5.jpg")
		buttons.Append( switchButton )

    else if movieToggle = 6 then
	
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-6.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-6.jpg")
		buttons.Append( switchButton )

    end if

	return buttons
    
End Function

Function GetMovieButtons(viewController as Object, movieToggle as Integer, parentId as String, allTileImageUrl = invalid) As Object

    buttons = GetBaseMovieButtons(viewController, movieToggle, parentId, allTileImageUrl)

    if movieToggle = 3 then
	
        alphaMovies = getAlphabetList("MovieAlphabet", parentId)
        if alphaMovies <> invalid
            buttons.Append( alphaMovies.Items )
        end if

    end if

    Return {
		Items: buttons
		TotalCount: buttons.Count()
	}
	
End Function

'**********************************************************
'** Get TV Buttons Row
'**********************************************************

Function GetBaseTVButtons(viewController as Object, tvToggle as Integer, parentId as String, allTileImageUrl = invalid) As Object

    if firstOf(allTileImageUrl, "") = "" then
		allTileImageUrl = viewController.getThemeImageUrl("hd-tv.jpg")
	end if
	
	buttons = [
        {
            Title: "TV Library"
            ContentType: "TVLibrary"
            ShortDescriptionLine1: "Library"
            HDPosterUrl: allTileImageUrl
            SDPosterUrl: allTileImageUrl,
			Id: parentId
        }
    ]

	switchButton = [
        {
            ContentType: "TVToggle"
	    Description: "Click the tile to toggle the highlight to the next one down."
        }
    ]

    if tvToggle = 1 then
	
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-1.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-1.jpg")

    else if tvToggle = 2 then
	
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-2.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-2.jpg")

    else if tvToggle = 3 then
	
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-3.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-3.jpg")

    else if tvToggle = 4 then
	
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-4.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-4.jpg")

    else if tvToggle = 5 then
	
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-5.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-5.jpg")

    else if tvToggle = 6 then
	
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-6.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-6.jpg")

    end if

    buttons.Append( switchButton )

	return buttons
	
End Function


'**********************************************************
'** Get Next TV Toggle
'**********************************************************

Function GetNextTVToggle()

	tvToggle     = (firstOf(RegUserRead("tvToggle"), "1")).ToInt()
	
    tvToggle = tvToggle + 1

    if tvToggle = 7 then
        tvToggle = 1
    end if

    RegUserWrite("tvToggle", tvToggle)
	
End Function

'**********************************************************
'** Get TV Buttons Row
'**********************************************************

Function GetTVButtons(viewController as Object, tvToggle as Integer, parentId as String, allTileImageUrl = invalid) As Object

    buttons = GetBaseTVButtons(viewController, tvToggle, parentId, allTileImageUrl)

    if tvToggle = 3 then
	
        alphaTV = getAlphabetList("TvAlphabet", parentId)
        if alphaTV <> invalid
            buttons.Append( alphaTV.Items )
        end if

    end if

    Return {
		Items: buttons
		TotalCount: buttons.Count()
	}
	
End Function

'**********************************************************
'** Get Home Videos Buttons Row
'**********************************************************

Function GetBaseHomeVideoButtons(viewController as Object, hvToggle as Integer, parentId as String, allTileImageUrl = invalid) As Object

	themeType = FirstOf(RegRead("prefTheme"),"1")

    if firstOf(allTileImageUrl, "") = "" then
		allTileImageUrl = viewController.getThemeImageUrl("hd-tv.jpg")
	end if
	
	buttons = [
        {
            Title: "Video Library"
            ContentType: "HomeMovieLibrary"
            ShortDescriptionLine1: "Library"
            HDPosterUrl: allTileImageUrl
            SDPosterUrl: allTileImageUrl,
			Id: parentId
        }
    ]

	switchButton = [
        {
            ContentType: "HomeVideoToggle"
	    Description: "Click the tile to toggle the highlight to the next one down."
        }
    ]

    if themeType = "1"

    	if hvToggle = 1 then
	
       		switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-17.jpg")
		switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-17.jpg")

    	else if hvToggle = 2 then
	
		switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-3.jpg")
		switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-3.jpg")

	else if hvToggle = 3 then
	
		switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-4.jpg")
		switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-4.jpg")

	else if hvToggle = 4 then
	
		switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-18.jpg")
		switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-18.jpg")

	end if

     else

    	if hvToggle = 1 then
	
       		switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-20.jpg")
		switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-20.jpg")

    	else if hvToggle = 2 then
	
		switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-21.jpg")
		switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-21.jpg")

	else if hvToggle = 3 then
	
		switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-22.jpg")
		switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-22.jpg")

	else if hvToggle = 4 then
	
		switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-23.jpg")
		switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-23.jpg")

	end if

    end if
    buttons.Append( switchButton )

	return buttons
	
End Function

'**********************************************************
'** Get Folder Buttons Row
'**********************************************************

Function GetBaseFolderButtons(viewController as Object, hvToggle as Integer, parentId as String, allTileImageUrl = invalid) As Object

	themeType = FirstOf(RegRead("prefTheme"),"1")
	folderToggle  = (firstOf(RegUserRead("folderToggle"), "2")).ToInt()

    if firstOf(allTileImageUrl, "") = "" then
		allTileImageUrl = viewController.getThemeImageUrl("hd-tv.jpg")
	end if
	
	buttons = [
        {
            Title: "Library"
            ContentType: "Folder"
            ShortDescriptionLine1: "Library"
            HDPosterUrl: allTileImageUrl
            SDPosterUrl: allTileImageUrl,
			Id: parentId
        }
    ]

	switchButton = [
        {
            ContentType: "FolderToggle"
	    Description: "Click the tile to toggle the highlight to the next one down."
        }
    ]

        if themeType = "1"

    	if folderToggle = 1 then
	
       		switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-17.jpg")
		switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-17.jpg")

    	else if folderToggle = 2 then
	
		switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-3.jpg")
		switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-3.jpg")

	else if folderToggle = 3 then
	
		switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-4.jpg")
		switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-4.jpg")

	else if folderToggle = 4 then
	
		switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-18.jpg")
		switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-18.jpg")

	end if

     else

    	if folderToggle = 1 then
	
       		switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-20.jpg")
		switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-20.jpg")

    	else if folderToggle = 2 then
	
		switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-21.jpg")
		switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-21.jpg")

	else if folderToggle = 3 then
	
		switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-22.jpg")
		switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-22.jpg")

	else if folderToggle = 4 then
	
		switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-23.jpg")
		switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-23.jpg")

	end if

    end if

    buttons.Append( switchButton )

	return buttons
	
End Function


'**********************************************************
'** Get Photo Buttons Row
'**********************************************************

Function GetBasePhotoButtons(viewController as Object, photoToggle as Integer, parentId as String, allTileImageUrl = invalid) As Object

	themeType = FirstOf(RegRead("prefTheme"),"1")
	photoToggle  = (firstOf(RegUserRead("photoToggle"), "2")).ToInt()

    if firstOf(allTileImageUrl, "") = "" then
		allTileImageUrl = viewController.getThemeImageUrl("hd-tv.jpg")
	end if
	
	buttons = [
        {
            Title: "Photo Library"
            ContentType: "PhotoFolder"
            ShortDescriptionLine1: "Library"
            HDPosterUrl: allTileImageUrl
            SDPosterUrl: allTileImageUrl,
			Id: parentId
        }
    ]

	switchButton = [
        {
            ContentType: "PhotoToggle"
	    Description: "Click the tile to toggle the highlight to the next one down."
        }
    ]

        if themeType = "1"

    	if photoToggle = 1 then
	
       		switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-17.jpg")
		switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-17.jpg")

    	else if photoToggle = 2 then
	
		switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-3.jpg")
		switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-3.jpg")

	else if photoToggle = 3 then
	
		switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-4.jpg")
		switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-4.jpg")

	else if photoToggle = 4 then
	
		switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-18.jpg")
		switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-18.jpg")

	end if

     else

    	if photoToggle = 1 then
	
       		switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-20.jpg")
		switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-20.jpg")

    	else if photoToggle = 2 then
	
		switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-21.jpg")
		switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-21.jpg")

	else if photoToggle = 3 then
	
		switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-22.jpg")
		switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-22.jpg")

	else if photoToggle = 4 then
	
		switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-23.jpg")
		switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-23.jpg")

	end if

    end if

    buttons.Append( switchButton )

	return buttons
	
End Function

'**********************************************************
'** Get Next Home Video Toggle
'**********************************************************

Function GetNextHomeVideoToggle()

	hvToggle     = (firstOf(RegUserRead("hvToggle"), "1")).ToInt()
	
    hvToggle = hvToggle + 1

    if hvToggle > 4 then
        hvToggle = 1
    end if

    RegUserWrite("hvToggle", hvToggle)
	
End Function

'**********************************************************
'** Get Next Folder Toggle
'**********************************************************

Function GetNextFolderToggle()

	folderToggle     = (firstOf(RegUserRead("folderToggle"), "1")).ToInt()
	
    folderToggle = folderToggle + 1

    if folderToggle > 4 then
        folderToggle = 1
    end if

    RegUserWrite("folderToggle", folderToggle)
	
End Function

'**********************************************************
'** Get Next Photo Toggle
'**********************************************************

Function GetNextPhotoToggle()

	photoToggle     = (firstOf(RegUserRead("photoToggle"), "1")).ToInt()
	
    photoToggle = photoToggle + 1

    if photoToggle > 4 then
        photoToggle = 1
    end if

    RegUserWrite("photoToggle", photoToggle)
	
End Function

'**********************************************************
'** Get Home Video Buttons Row
'**********************************************************

Function GetHomeVideoButtons(viewController as Object, hvToggle as Integer, parentId as String, allTileImageUrl = invalid) As Object

    buttons = GetBaseHomeVideoButtons(viewController, hvToggle, parentId, allTileImageUrl)

    if hvToggle = 2 then
	
        alpha = getAlphabetList("HomeVideoAlphabet", parentId)
        if alpha <> invalid
            buttons.Append( alpha.Items )
        end if

    end if

    Return {
		Items: buttons
		TotalCount: buttons.Count()
	}
	
End Function

'**********************************************************
'** Get Folder Buttons Row
'**********************************************************

Function GetFolderButtons(viewController as Object, folderToggle as Integer, parentId as String, allTileImageUrl = invalid) As Object

    buttons = GetBaseFolderButtons(viewController, folderToggle, parentId, allTileImageUrl)

    if folderToggle = 2 then
	
        alpha = getAlphabetList("FolderAlphabet", parentId)
        if alpha <> invalid
            buttons.Append( alpha.Items )
        end if

    end if

    Return {
		Items: buttons
		TotalCount: buttons.Count()
	}
	
End Function

'**********************************************************
'** Get Photo Buttons Row
'**********************************************************

Function GetPhotoButtons(viewController as Object, photoToggle as Integer, parentId as String, allTileImageUrl = invalid) As Object

    buttons = GetBasePhotoButtons(viewController, photoToggle, parentId, allTileImageUrl)

    if photoToggle = 2 then
	
        alpha = getAlphabetList("PhotoAlphabet", parentId)
        if alpha <> invalid
            buttons.Append( alpha.Items )
        end if

    end if

    Return {
		Items: buttons
		TotalCount: buttons.Count()
	}
	
End Function


'**********************************************************
'** Get Next Live TV Toggle
'**********************************************************

Function GetNextLiveTVToggle()

	liveTvToggle = (firstOf(RegUserRead("liveTvToggle"), "1")).ToInt()
    liveTvToggle = liveTvToggle + 1

    if liveTvToggle = 4 then
        liveTvToggle = 1
    end if

    RegUserWrite("liveTvToggle", liveTvToggle)
	
End Function

'**********************************************************
'** Get Live TV Buttons Row
'**********************************************************

Function GetBaseLiveTVButtons(viewController as Object, liveTvToggle as Integer) As Object

	buttons = [
        {
            Title: "Channels"
            ContentType: "LiveTVChannels"
            ShortDescriptionLine1: "Channels"
	    Description: "Show the live TV Channels available."
            HDPosterUrl: viewController.getThemeImageUrl("hd-tv.jpg")
            SDPosterUrl: viewController.getThemeImageUrl("hd-tv.jpg")
        },
        {
            Title: "Guide"
            ContentType: "LiveTVFavoriteGuide"
            ShortDescriptionLine1: "Guide"
	    Description: "Show the live TV Guide."
            HDPosterUrl: viewController.getThemeImageUrl("hd-tv.jpg")
            SDPosterUrl: viewController.getThemeImageUrl("hd-tv.jpg")
        },
        {
            Title: "Recordings"
            ContentType: "LiveTVRecordings"
            ShortDescriptionLine1: "Recordings"
	    Description: "Show the live TV Recordings."
            HDPosterUrl: viewController.getThemeImageUrl("hd-tv.jpg")
            SDPosterUrl: viewController.getThemeImageUrl("hd-tv.jpg")
        }
    ]

    switchButton = [
        {
            ContentType: "LiveTVToggle"
	    Description: "Click the tile to toggle the highlight to the next one down."
        }
    ]

    if liveTvToggle = 1 then
	
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-10.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-10.jpg")

        buttons.Append( switchButton )

    else if liveTvToggle = 2 then
	
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-11.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-11.jpg")

        buttons.Append( switchButton )

    else if liveTvToggle = 3 then
	
        switchButton[0].HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-12.jpg")
        switchButton[0].SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-12.jpg")
		
        buttons.Append( switchButton )

    end if
	return buttons
	
End Function

'**********************************************************
'** GetNextMusicToggle
'**********************************************************

Function GetNextMusicToggle()

	musicToggle  = (firstOf(RegUserRead("musicToggle"), "1")).ToInt()
	musicToggle = musicToggle + 1
	themeType = FirstOf(RegRead("prefTheme"),"1")
	if (musicToggle > 7 and themeType = "1") or (musicToggle > 3 and themeType = "0")
		musicToggle = 1
	end if

	' Update Registry
	RegUserWrite("musicToggle", musicToggle)
	
End Function

'**********************************************************
'** GetMusicButtons
'**********************************************************

Function GetBaseMusicButtons(viewController as Object, musicToggle as Integer, parentId as String, allTileImageUrl = invalid) As Object

    if firstOf(allTileImageUrl, "") = "" then
		allTileImageUrl = viewController.getThemeImageUrl("hd-music.jpg")
	end if
	
	buttons = [
        {
            Title: "Music Library"
            ContentType: "MusicLibrary"
            ShortDescriptionLine1: "Library"
            HDPosterUrl: allTileImageUrl
            SDPosterUrl: allTileImageUrl,
			Id: parentId
        }
    ]

	switchButton = {
            ContentType: "MusicToggle"
	    Description: "Click the tile to toggle the highlight to the next one down."
        }

    ' Latest
    if musicToggle = 1 then
        switchButton.HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-7.jpg")
        switchButton.SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-7.jpg")

    ' Jump In Album
    else if musicToggle = 2 then
        switchButton.HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-8.jpg")
        switchButton.SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-8.jpg")

    ' Jump In Artist
    else if musicToggle = 3 then
        switchButton.HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-9.jpg")
        switchButton.SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-9.jpg")

    ' Favorite Albums
    else if musicToggle = 4 then
        switchButton.HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-13.jpg")
        switchButton.SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-13.jpg")

    ' Recently played Albums
    else if musicToggle = 5 then
        switchButton.HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-14.jpg")
        switchButton.SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-14.jpg")

    ' Most Played Albums
    else if musicToggle = 6 then
        switchButton.HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-15.jpg")
        switchButton.SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-15.jpg")

    ' Genre
    else if musicToggle = 7 then
        switchButton.HDPosterUrl = viewController.getThemeImageUrl("hd-toggle-16.jpg")
        switchButton.SDPosterUrl = viewController.getThemeImageUrl("hd-toggle-16.jpg")

    end if

    buttons.Push( switchButton )

	return buttons
End Function

Function GetMusicButtons(viewController as Object, musicToggle as Integer, parentId as String, allTileImageUrl = invalid) As Object

	buttons = GetBaseMusicButtons(viewController, musicToggle, parentId, allTileImageUrl)

    ' Jump In Album
    if musicToggle = 2 then
	alphaMusicAlbum = getAlphabetList("MusicAlbumAlphabet", parentId)
        if alphaMusicAlbum <> invalid
            buttons.Append( alphaMusicAlbum.Items )
        end if

    ' Jump In Artist
    else if musicToggle = 3 then
	alphaMusicArtist = getAlphabetList("MusicArtistAlphabet", parentId)
        if alphaMusicArtist <> invalid
            buttons.Append( alphaMusicArtist.Items )
        end if

    end if

    Return {
		Items: buttons
		TotalCount: buttons.Count()
	}
	
End Function

'**********************************************************
'** GetQuickJumpButtons
'**********************************************************

Function GetQuickJumpButtons(viewController as Object) As Object
    
	buttons = []
	
	Quote = chr(34)
	Apps = QueryApps()

	versionArr = getGlobalVar("rokuVersion")
	If CheckMinimumVersion(versionArr, [6, 1]) then
		if AppExists(Apps, "44191")
			buttons.push({
            			Title: "Emby Official"
            			ContentType: "emby"
            			ShortDescriptionLine1: "Emby Official"
				ShortDescriptionLine2: "Launch App"
				HDPosterUrl: "pkg:/images/quicklaunch/hd-emby.png"
				SDPosterUrl: "pkg:/images/quicklaunch/hd-emby.png"
			})
		else
			buttons.push({
            			Title: "Emby Official"
            			ContentType: "emby"
            			ShortDescriptionLine1: "Emby Official"
				ShortDescriptionLine2: "Install App"
				HDPosterUrl: "pkg:/images/quicklaunch/hd-emby.png"
				SDPosterUrl: "pkg:/images/quicklaunch/hd-emby.png"
			})
		end if

		if AppExists(Apps, "43157")
			buttons.push({
            			Title: "Emby BETA"
            			ContentType: "embybeta"
            			ShortDescriptionLine1: "Emby BETA"
				ShortDescriptionLine2: "Launch App"
				HDPosterUrl: "pkg:/images/quicklaunch/hd-emby.png"
				SDPosterUrl: "pkg:/images/quicklaunch/hd-emby.png"
			})
		else
			buttons.push({
            			Title: "Emby BETA"
            			ContentType: "embybeta"
            			ShortDescriptionLine1: "Emby BETA"
				ShortDescriptionLine2: "Install App"
				HDPosterUrl: "pkg:/images/quicklaunch/hd-emby.png"
				SDPosterUrl: "pkg:/images/quicklaunch/hd-emby.png"
			})
		end if
	end if

	device = CreateObject("roDeviceInfo")
	rokuTV = device.GetDisplayProperties()
	isRokuTV = rokuTV.internal

	if isRokuTV
		buttons.push({
            		Title: "TV Tuner"
            		ContentType: "tvtuner"
            		ShortDescriptionLine1: "TV Tuner"
			ShortDescriptionLine2: "Launch OTA"
			HDPosterUrl: "pkg:/images/quicklaunch/hd-antenna.jpg"
			SDPosterUrl: "pkg:/images/quicklaunch/hd-antenna.jpg"
		})
	end if

	if AppExists(Apps, "81444")
		buttons.push({
			Title: "XTV"
			ContentType: "xtv"
			ShortDescriptionLine1: "XTV IPTV"
			ShortDescriptionLine2: "Launch App"
			HDPosterUrl: "pkg:/images/quicklaunch/hd-xtv.png"
			SDPosterUrl: "pkg:/images/quicklaunch/hd-xtv.png"
		})
	end if

	if AppExists(Apps, "12")
		buttons.push({
			Title: "Netflix"
			ContentType: "netflix"
			ShortDescriptionLine1: "Netflix"
			ShortDescriptionLine2: "Launch App"
			HDPosterUrl: "pkg:/images/quicklaunch/hd-netflix.jpg"
			SDPosterUrl: "pkg:/images/quicklaunch/hd-netflix.jpg"
		})
	end if

	if AppExists(Apps, "13")
		buttons.push({
			Title: "Amazon Video"
			ContentType: "amazoninstant"
			ShortDescriptionLine1: "Amazon Video"
			ShortDescriptionLine2: "Launch App"
			HDPosterUrl: "pkg:/images/quicklaunch/hd-amazon.jpg"
			SDPosterUrl: "pkg:/images/quicklaunch/hd-amazon.jpg"
		})
	end if

	if AppExists(Apps, "2285")
		buttons.push({
			Title: "Hulu"
			ContentType: "hulu"
			ShortDescriptionLine1: "Hulu"
			ShortDescriptionLine2: "Launch App"
 			HDPosterUrl: "pkg:/images/quicklaunch/hd-hulu.jpg"
			SDPosterUrl: "pkg:/images/quicklaunch/hd-hulu.jpg"
		})
	end if

	if AppExists(Apps, "837")
		buttons.push({
			Title: "YouTube"
			ContentType: "youtube"
			ShortDescriptionLine1: "YouTube"
			ShortDescriptionLine2: "Launch App"
			HDPosterUrl: "pkg:/images/quicklaunch/hd-youtube.jpg"
			SDPosterUrl: "pkg:/images/quicklaunch/hd-youtube.jpg"
		})
	end if

	if AppExists(Apps, "50025")
		buttons.push({
			Title: "Google Play Movies & TV"
			ContentType: "googleplay"
			ShortDescriptionLine1: "Google Play Movies"
			ShortDescriptionLine2: "Launch App"
			HDPosterUrl: "pkg:/images/quicklaunch/hd-googleplay.png"
			SDPosterUrl: "pkg:/images/quicklaunch/hd-googleplay.png"
		})
	end if

	if AppExists(Apps, "46041")
		buttons.push({
			Title: "Sling TV"
			ContentType: "slingtv"
			ShortDescriptionLine1: "Sling TV"
			ShortDescriptionLine2: "Launch App"
			HDPosterUrl: "pkg:/images/quicklaunch/hd-sling.jpg"
			SDPosterUrl: "pkg:/images/quicklaunch/hd-sling.jpg"
		})
	end if

	if AppExists(Apps, "61322")
		buttons.push({
			Title: "HBO NOW"
			ContentType: "hbonow"
			ShortDescriptionLine1: "HBO NOW"
			ShortDescriptionLine2: "Launch App"
			HDPosterUrl: "pkg:/images/quicklaunch/hd-hbonow.jpg"
			SDPosterUrl: "pkg:/images/quicklaunch/hd-hbonow.jpg"
		})
	end if

	if AppExists(Apps, "8838")
		buttons.push({
			Title: "Showtime"
			ContentType: "showtime"
			ShortDescriptionLine1: "Showtime"
			ShortDescriptionLine2: "Launch App"
			HDPosterUrl: "pkg:/images/quicklaunch/hd-showtime.jpg"
			SDPosterUrl: "pkg:/images/quicklaunch/hd-showtime.jpg"
		})
	end if

	if AppExists(Apps, "13842")
		buttons.push({
			Title: "VUDU"
			ContentType: "vudu"
			ShortDescriptionLine1: "VUDU"
			ShortDescriptionLine2: "Launch App"
			HDPosterUrl: "pkg:/images/quicklaunch/hd-vudu.jpg"
			SDPosterUrl: "pkg:/images/quicklaunch/hd-vudu.jpg"
		})
	end if

	if AppExists(Apps, "23353")
		buttons.push({
			Title: "PBS"
			ContentType: "pbs"
			ShortDescriptionLine1: "PBS"
			ShortDescriptionLine2: "Launch App"
			HDPosterUrl: "pkg:/images/quicklaunch/hd-pbs.jpg"
			SDPosterUrl: "pkg:/images/quicklaunch/hd-pbs.jpg"
		})
	end if

	if AppExists(Apps, "14295")
		buttons.push({
			Title: "Acorn TV"
			ContentType: "acorntv"
			ShortDescriptionLine1: "Acorn TV"
			ShortDescriptionLine2: "Launch App"
			HDPosterUrl: "pkg:/images/quicklaunch/hd-acorntv.png"
			SDPosterUrl: "pkg:/images/quicklaunch/hd-acorntv.png"
		})
	end if

	if AppExists(Apps, "74519")
		buttons.push({
			Title: "PLuto TV"
			ContentType: "plutotv"
			ShortDescriptionLine1: "Pluto TV"
			ShortDescriptionLine2: "Launch App"
			HDPosterUrl: "pkg:/images/quicklaunch/hd-pluto.png"
			SDPosterUrl: "pkg:/images/quicklaunch/hd-pluto.png"
		})
	end if

	if AppExists(Apps, "28")
		buttons.push({
			Title: "Pandora"
			ContentType: "pandora"
			ShortDescriptionLine1: "Pandora"
			ShortDescriptionLine2: "Launch App"
			HDPosterUrl: "pkg:/images/quicklaunch/hd-pandora.jpg"
			SDPosterUrl: "pkg:/images/quicklaunch/hd-pandora.jpg"
		})
	end if

	if AppExists(Apps, "1453")
		buttons.push({
			Title: "TuneIn Radio"
			ContentType: "tunein"
			ShortDescriptionLine1: "TuneIn Radio"
			ShortDescriptionLine2: "Launch App"
			HDPosterUrl: "pkg:/images/quicklaunch/hd-tunein.jpg"
			SDPosterUrl: "pkg:/images/quicklaunch/hd-tunein.jpg"
		})
	end if

	Return {
		Items: buttons
		TotalCount: buttons.Count()
	}
End Function

'**********************************************************
'** GetOptionButtons
'**********************************************************

Function GetOptionButtons(viewController as Object) As Object
    
	buttons = []
	
	buttons.push({
            Title: "Search"
            ContentType: "Search"
            ShortDescriptionLine1: "Search"
	    ShortDescriptionLine2: "ALL LIBRARIES"
	    Description: "Search all libraries for media."
            HDPosterUrl: viewController.getThemeImageUrl("hd-search.jpg")
            SDPosterUrl: viewController.getThemeImageUrl("hd-search.jpg")
        })

	device = CreateObject("roDeviceInfo")
	friendlyName = device.GetFriendlyName()
	BlingPlace = FirstOf(RegRead("prefBlingPlace"),"0")

	if blingPlace = "1"

	buttons.push({
            Title: "Favorites"
            ContentType: "ViewFavorites"
            ShortDescriptionLine1: "Favorites"
	    ShortDescriptionLine2: "VIEW ALL"
	    Description: "See all your favorites in one place."+chr(10)+"(Sorted By: Alphabetical)"
            HDPosterUrl: viewController.getThemeImageUrl("hd-favorites.jpg")
            SDPosterUrl: viewController.getThemeImageUrl("hd-favorites.jpg")
        })
	buttons.push({
            Title: "Latest"
            ContentType: "ViewLatest"
            ShortDescriptionLine1: "Latest"
	    ShortDescriptionLine2: "BY DATE ADDED"
	    Description: "See your latest media."+chr(10)+"(Sorted By: Date Added)"
            HDPosterUrl: viewController.getThemeImageUrl("hd-latest.jpg")
            SDPosterUrl: viewController.getThemeImageUrl("hd-latest.jpg")
        })
	buttons.push({
            Title: "Latest"
            ContentType: "ViewNewest"
            ShortDescriptionLine1: "Latest"
	    ShortDescriptionLine2: "BY PREMIERE DATE"
	    Description: "See your latest media."+chr(10)+"(Sorted By: Premiere Date)"
            HDPosterUrl: viewController.getThemeImageUrl("hd-latest.jpg")
            SDPosterUrl: viewController.getThemeImageUrl("hd-latest.jpg")
        })
	buttons.push({
            Title: "Continue Playing"
            ContentType: "ContinueWatching"
            ShortDescriptionLine1: "Continue Playing"
	    ShortDescriptionLine2: "VIEW ALL"
	    Description: "See all your media that you've never finished playing."+chr(10)+"(Sorted By: Date Last Played)."
            HDPosterUrl: viewController.getThemeImageUrl("hd-resumes.jpg")
            SDPosterUrl: viewController.getThemeImageUrl("hd-resumes.jpg")
        })
	buttons.push({
            Title: "Recently Played"
            ContentType: "ViewRecent"
            ShortDescriptionLine1: "Recently Played"
	    ShortDescriptionLine2: "VIEW 100 ITEMS"
	    Description: "See your media that was recently played."+chr(10)+"(Sorted By: Date Last Played)."
            HDPosterUrl: viewController.getThemeImageUrl("hd-recent.jpg")
            SDPosterUrl: viewController.getThemeImageUrl("hd-recent.jpg")
        })
	buttons.push({
            Title: "Frequently Played"
            ContentType: "ViewFrequent"
            ShortDescriptionLine1: "Frequently Played"
	    ShortDescriptionLine2: "VIEW 100 ITEMS"
	    Description: "See your media that is frequently played."+chr(10)+"(Sorted By: Play Count)."
            HDPosterUrl: viewController.getThemeImageUrl("hd-frequent.jpg")
            SDPosterUrl: viewController.getThemeImageUrl("hd-frequent.jpg")
        })
	buttons.push({
            Title: "I Feel Lucky!"
            ContentType: "ViewRandom"
            ShortDescriptionLine1: "I Feel Lucky!"
	    ShortDescriptionLine2: "RANDOM 100 ITEMS"
	    Description: "See random selections from your libraries. This is the best way to discover new content."+chr(10)+"(Filtered By: Unwatched)"
            HDPosterUrl: viewController.getThemeImageUrl("hd-random.jpg")
            SDPosterUrl: viewController.getThemeImageUrl("hd-random.jpg")
        })

	end if

	buttons.push({
            Title: "Preferences"+chr(10)+friendlyName + " [" + "v" + getGlobalVar("channelVersion", "Unknown") + "]"
            ContentType: "Preferences"
            ShortDescriptionLine1: "Preferences"
            ShortDescriptionLine2: friendlyName + " [" + "v" + getGlobalVar("channelVersion", "Unknown") + "]"
	    Description: "Change settings to customize the application for your tastes."
            HDPosterUrl: viewController.getThemeImageUrl("hd-preferences.jpg")
            SDPosterUrl: viewController.getThemeImageUrl("hd-preferences.jpg")
        })

	name = right(GetServerBaseUrl(),GetServerBaseUrl().len()-7)
	part = name.Instr("/")
	name = left(name,part)

    	buttons.push({
            Title: "Change Server"+chr(10)+name
            ContentType: "ChangeServer"
            ShortDescriptionLine1: "Change Server"
	    ShortDescriptionLine2: name
	    Description: "Change to a new server, or a new emby connect user."
            HDPosterUrl: viewController.getThemeImageUrl("hd-landscape.jpg")
            SDPosterUrl: viewController.getThemeImageUrl("hd-landscape.jpg")
        })

	username = ""
	user = getGlobalVar("user")
	if user <> invalid then
		username = user.Title
		if user.IsAdmin then username = username + " *ADMIN*"
	end if

	buttons.push({
            Title: "Sign Out"+chr(10)+username
            ContentType: "UserLogout"
            ShortDescriptionLine1: "Sign Out"
	    ShortDescriptionLine2: username
	    Description: "Use this to switch users on the server. DO NOT use with emby connect!"
            HDPosterUrl: viewController.getThemeImageUrl("hd-switch-user.jpg")
            SDPosterUrl: viewController.getThemeImageUrl("hd-switch-user.jpg")
        })

	peepsnames = GetAlsoWatching()
	if peepsnames <> ""
		r = CreateObject("roRegex", ",", "")
		if r.split(peepsnames).count() <> 0
			peep = tostr(Pluralize(r.split(peepsnames).count()," Other"))+" Watching"
		end if
	else
		peep = "No Others Watching"
	end if

	buttons.push({
            Title: "Also Watching"+chr(10)+peep
            ContentType: "AlsoWatching"
            ShortDescriptionLine1: "Also Watching"
	    ShortDescriptionLine2: peep
	    Description: "Multiple users can have their watched, resume, and play count statuses update in sync."
            HDPosterUrl: viewController.getThemeImageUrl("hd-also-user.jpg")
            SDPosterUrl: viewController.getThemeImageUrl("hd-also-user.jpg")
        })

	if blingPlace = "0"

	buttons.push({
            Title: "Favorites"
            ContentType: "ViewFavorites"
            ShortDescriptionLine1: "Favorites"
	    ShortDescriptionLine2: "VIEW ALL"
	    Description: "See all your favorites in one place."+chr(10)+"(Sorted By: Alphabetical)"
            HDPosterUrl: viewController.getThemeImageUrl("hd-favorites.jpg")
            SDPosterUrl: viewController.getThemeImageUrl("hd-favorites.jpg")
        })
	buttons.push({
            Title: "Latest"
            ContentType: "ViewLatest"
            ShortDescriptionLine1: "Latest"
	    ShortDescriptionLine2: "BY DATE ADDED"
	    Description: "See your latest media."+chr(10)+"(Sorted By: Date Added)"
            HDPosterUrl: viewController.getThemeImageUrl("hd-latest.jpg")
            SDPosterUrl: viewController.getThemeImageUrl("hd-latest.jpg")
        })
	buttons.push({
            Title: "Latest"
            ContentType: "ViewNewest"
            ShortDescriptionLine1: "Latest"
	    ShortDescriptionLine2: "BY PREMIERE DATE"
	    Description: "See your latest media."+chr(10)+"(Sorted By: Premiere Date)"
            HDPosterUrl: viewController.getThemeImageUrl("hd-latest.jpg")
            SDPosterUrl: viewController.getThemeImageUrl("hd-latest.jpg")
        })
	buttons.push({
            Title: "Continue Playing"
            ContentType: "ContinueWatching"
            ShortDescriptionLine1: "Continue Playing"
	    ShortDescriptionLine2: "VIEW ALL"
	    Description: "See all your media that you've never finished playing."+chr(10)+"(Sorted By: Date Last Played)."
            HDPosterUrl: viewController.getThemeImageUrl("hd-resumes.jpg")
            SDPosterUrl: viewController.getThemeImageUrl("hd-resumes.jpg")
        })
	buttons.push({
            Title: "Recently Played"
            ContentType: "ViewRecent"
            ShortDescriptionLine1: "Recently Played"
	    ShortDescriptionLine2: "VIEW 100 ITEMS"
	    Description: "See your media that was recently played."+chr(10)+"(Sorted By: Date Last Played)."
            HDPosterUrl: viewController.getThemeImageUrl("hd-recent.jpg")
            SDPosterUrl: viewController.getThemeImageUrl("hd-recent.jpg")
        })
	buttons.push({
            Title: "Frequently Played"
            ContentType: "ViewFrequent"
            ShortDescriptionLine1: "Frequently Played"
	    ShortDescriptionLine2: "VIEW 100 ITEMS"
	    Description: "See your media that is frequently played."+chr(10)+"(Sorted By: Play Count)."
            HDPosterUrl: viewController.getThemeImageUrl("hd-frequent.jpg")
            SDPosterUrl: viewController.getThemeImageUrl("hd-frequent.jpg")
        })
	buttons.push({
            Title: "I Feel Lucky!"
            ContentType: "ViewRandom"
            ShortDescriptionLine1: "I Feel Lucky!"
	    ShortDescriptionLine2: "RANDOM 100 ITEMS"
	    Description: "See random selections from your libraries. This is the best way to discover new content."+chr(10)+"(Filtered By: Unwatched)"
            HDPosterUrl: viewController.getThemeImageUrl("hd-random.jpg")
            SDPosterUrl: viewController.getThemeImageUrl("hd-random.jpg")
        })

	end if

	buttons.push({
            Title: "Device Info"
            ContentType: "DeviceInfo"
            ShortDescriptionLine1: "Device Info"
	    ShortDescriptionLine2: "ABOUT YOUR DEVICE"
	    Description: "See interesting nerdy information about your specific device. Some of it can be helpful for bug reporting."
            HDPosterUrl: viewController.getThemeImageUrl("hd-device.jpg")
            SDPosterUrl: viewController.getThemeImageUrl("hd-device.jpg")
        })

	if FirstOf(RegRead("prefenabledebug"),"false") = "true"
		buttons.push({
            		Title: "Debug Logs"
            		ContentType: "DebugLogs"
            		ShortDescriptionLine1: "Debug Logs"
	    		ShortDescriptionLine2: "VIEW THE LOGS"
	    		Description: "See the debug logs from your device. This is very useful when reporting bugs."
            		HDPosterUrl: viewController.getThemeImageUrl("hd-tv.jpg")
            		SDPosterUrl: viewController.getThemeImageUrl("hd-tv.jpg")
        	})
	end if

	musicstop = FirstOf(GetGlobalVar("musicstop"),"0")
	if AudioPlayer().Context <> invalid and musicstop = "0"
		text = Pluralize(AudioPlayer().Context.count(),"Track")
		buttons.push({
				Title: "Now Playing"
				ContentType: "NowPlaying"
				ShortDescriptionLine1: "Now Playing"
				ShortDescriptionLine2: text
				Description: "See the details of the presently playing track."
				HDPosterUrl: viewController.getThemeImageUrl("hd-music.jpg")
				SDPosterUrl: viewController.getThemeImageUrl("hd-music.jpg")
			})
		buttons.push({
				Title: "Track List"
				ContentType: "MusicList"
				ShortDescriptionLine1: "Track List"
				ShortDescriptionLine2: text
				Description: "See the track list of presently playing audio."
				HDPosterUrl: viewController.getThemeImageUrl("hd-music.jpg")
				SDPosterUrl: viewController.getThemeImageUrl("hd-music.jpg")
			})
	end if
	
	Return {
		Items: buttons
		TotalCount: buttons.Count()
	}
	
End Function

Function HomeScreenCreateContextMenu()
	
	options = {
		settingsPrefix: "home"
		showSortOrder: false
	}
	createContextMenuDialog(options)
	returned = getGlobalVar("ContextReturn")
	if returned <> "preferences" and returned <> "homescreen" and returned <> "nowplaying" and returned <> "search" and returned <> "also"
		while m.ViewController.screens.Count() > 0
			m.ViewController.PopScreen(m.ViewController.screens[m.ViewController.screens.Count() - 1])
		end while
		m.ViewController.CreateHomeScreen()
	end if
	return true

End Function

Sub homeScreenOnTimerExpired(timer)

    ' if WOL packets were sent, we should reload the homescreen ( send the request again )
    if timer.Name = "WOLsent" then

        if timer.keepAlive = invalid then 
            Debug("WOL packets were sent -- create request to refresh/load data ( only for servers with WOL macs )")
        end if
     
        if timer.keepAlive = true then 
            if GetViewController().genIdleTime <> invalid and GetViewController().genIdleTime.RemainingSeconds() = 0 then 
                Debug("roku is idle: NOT sending keepalive WOL packets")
            else 
                Debug("keepalive WOL packets being sent.")
                ConnectionManager().sendWolToAllServers(m)
            end if
        'else if server.online and timer.keepAlive = invalid then 
            'Debug("WOL " + tostr(server.name) + " is already online")
        else 
			' Refresh home page data
        end if 

        ' recurring or not, we will make it active until we complete X requests
        timer.active = true
        if timer.count = invalid then timer.count = 0
        timer.count = timer.count+1
        timer.mark()

        ' deactivate after third attempt ( 3 x 3 = 9 seconds after all inital WOL requests )
        if timer.count > 2 then 
            ' convert wolTimer to a keepAlive timer ( 5 minutes )
            timer.keepalive = true
            timer.SetDuration(5*60*1000, false) ' reset timer to 5 minutes - send a WOL request
            timer.mark()
        end if

    end if

    if timer.Name = "clock" AND m.ViewController.IsActiveScreen(m) then
        m.refreshBreadcrumb()
    end if
End Sub

Sub homeScreenActivate(priorScreen)
    m.refreshBreadcrumb()
    m.SuperActivate(priorScreen)
End Sub

Sub homeRefreshBreadcrumb()

	username = ""
	user = getGlobalVar("user")
	peepsnames = GetAlsoWatching()
	r = CreateObject("roRegex", ",", "")
	if r.split(peepsnames).count() <> 0
		peep = "+"+toStr(r.split(peepsnames).count())
	else
		peep = ""
	end if
	if user <> invalid then username = user.Title + peep

	showClock = firstOf(RegRead("prefShowClock"), "yes")
	if showClock = "yes" then
		m.Screen.SetBreadcrumbText(username, CurrentTimeAsString())
	else
		m.Screen.SetBreadcrumbText(username, "")
	end if

End Sub