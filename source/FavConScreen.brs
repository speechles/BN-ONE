'******************************************************
' createFavConLibraryScreen
'******************************************************
'* favorites, continue playing, latest, random, recently, frequently

Function createFavConLibraryScreen(viewController as Object, parentId as String, Ty as String) As Object

    imageType      = (firstOf(RegUserRead("FavConImageType"), "0")).ToInt()
	GetGlobalAA().AddReplace("Ty", Ty)
	if Ty = "6"
		names = ["Movies", "Shows", "Episodes", "Trailers"]
		keys = ["0", "1", "2", "3"]
	else if Ty <> "4" and Ty <> "5"
		names = ["Movies", "Shows", "Episodes", "Trailers", "Videos", "Artists", "Albums", "Tracks", "Podcasts", "LiveTV", "Collection Folders", "Photos"]
		keys = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11"]
	else
		names = ["Movies", "Episodes", "Trailers", "Videos", "Tracks", "Podcasts", "LiveTV", "Photos"]
		keys = ["0", "1", "2", "3", "4", "5", "6", "7"]
	end if

	loader = CreateObject("roAssociativeArray")
	loader.getUrl = getFavConLibraryRowScreenUrl
	loader.parsePagedResult = parseFavConLibraryScreenResult
	loader.parentId = parentId
    if imageType = 0 then
	if Ty="2"
		screen = createPaginatedGridScreen(viewController, names, keys, loader, "mixed-aspect-ratio")
	else
		screen = createPaginatedGridScreen(viewController, names, keys, loader, "mixed-aspect-ratio")
	end if
    Else
	if Ty = "2" or Ty = "3"
		screen = createPaginatedGridScreen(viewController, names, keys, loader, "two-row-flat-landscape-custom")
	else
		screen = createPaginatedGridScreen(viewController, names, keys, loader, "two-row-flat-landscape-custom")
	end if
    End If

	screen.baseActivate = screen.Activate
	screen.Activate = FavConScreenActivate
	screen.displayDescription = (firstOf(RegUserRead("FavConDescription"), "1")).ToInt()
	screen.createContextMenu = FavConScreenCreateContextMenu

    return screen

End Function

Sub FavConScreenActivate(priorScreen)

    imageType      = (firstOf(RegUserRead("FavConImageType"), "0")).ToInt()
	displayDescription = (firstOf(RegUserRead("FavConDescription"), "1")).ToInt()
	
    if imageType = 0 then
		gridStyle = "mixed-aspect-ratio"
    Else
		gridStyle = "two-row-flat-landscape-custom"
    End If

	m.baseActivate(priorScreen)

	if gridStyle <> m.gridStyle or displayDescription <> m.displayDescription then
		
		m.displayDescription = displayDescription
		m.gridStyle = gridStyle
		m.DestroyAndRecreate()

	end if

End Sub

Function FavConScreenCreateContextMenu()
	
	options = {
		settingsPrefix: "FavCon"
	}
	'	sortOptions: ["Name", "Date Added", "Date Played", "Release Date", "Random", "Play Count", "Critic Rating", "Community Rating", "Budget", "Revenue"]
	'	filterOptions: ["None", "Continuing Series", "Ended Series", "Played", "Unplayed", "Resumable"]
	'	showSortOrder: true
	'}
	createContextMenuDialog(options)
	return true
End Function

Function getFavConLibraryRowScreenUrl(row as Integer, id as String) as String

	'filterBy       = (firstOf(RegUserRead("FavConFilterBy"), "0")).ToInt()
	'sortBy         = (firstOf(RegUserRead("FavConSortBy"), "0")).ToInt()
	'sortOrder      = (firstOf(RegUserRead("FavConSortOrder"), "0")).ToInt()

	' URL
	url = GetServerBaseUrl()

		Ty = FirstOf(GetGlobalVar("Ty"), "0").toInt()
    	query = {}

	if row = 0
		' Movies
		url = url  + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?recursive=true"

		query = {
			IncludeItemTypes: "Movie"
		}
	else if row = 1 and (Ty < 4 or Ty = 6)
		' Shows
		url = url  + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?recursive=true"

		query = {
			IncludeItemTypes: "Series"
		}
	else if (row = 2 and (Ty < 4 or Ty = 6)) or (Ty > 3 and row = 1)
		' Episodes
		url = url  + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?recursive=true"

		query = {
			IncludeItemTypes: "Episode"
		}
	else if (row = 3 and (Ty < 4 or Ty = 6)) or (Ty > 3 and row = 2)
		' Trailers
		url = url  + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?recursive=true"

		query = {
			IncludeItemTypes: "Trailer,ChannelVideoItem"
		}
	else if (row = 4 and Ty < 4) or (Ty > 3 and row = 3)
		' Videos
		url = url  + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?recursive=true"

		query = {
			IncludeItemTypes: "Video,AdultVideo,MusicVideo"
		}
	else if row = 5 and Ty < 4
		' Artists
		if Ty = 1
			url = url  + "/Artists/AlbumArtists?recursive=true"

			query = {
				IncludeItemTypes: "MusicAlbum"
				UserId: getGlobalVar("user").Id
			}
		else
			url = url  + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?recursive=true"

			query = {
				IncludeItemTypes: "MusicArtist"
			}
		end if
	else if row = 6 and Ty < 4
		' Albums
		url = url  + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?recursive=true"

		query = {
			IncludeItemTypes: "MusicAlbum"
		}
	else if (row = 7 and Ty < 4) or (Ty > 3 and row = 4 and ty <> 6)
		' Tracks
		url = url  + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?recursive=true"

		query = {
			IncludeItemTypes: "Audio"
		}
	else if (row = 8 and Ty < 4) or (Ty > 3 and row = 5 and ty <> 6)
		' Podcasts
		url = url  + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?recursive=true"

		query = {
			IncludeItemTypes: "VideoPodcast,AudioPodCast,Podcast"
		}
	else if (row = 9 and Ty < 4) or (Ty > 3 and row = 6 and ty <> 6)
		' LiveTV
		url = url  + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?recursive=true"

		query = {
			IncludeItemTypes: "LiveTvProgram,LiveTvChannel,LiveTvVideoRecording,LiveTvAudioRecording"
		}
	else if (row = 10 and Ty < 4) and (ty <> 6)
		' Collection Folders
		url = url  + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?recursive=true"

		query = {
			IncludeItemTypes: "CollectionFolder"
		}
	else if (row = 11 and Ty < 4) or (Ty > 3 and row = 7 and ty <> 6)
		' Photos
		url = url  + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?recursive=true"

		query = {
			IncludeItemTypes: "PhotoAlbum,Photo"
		}
	end If

	query.AddReplace("fields", "ItemCounts,Overview,AirTime,PrimaryImageAspectRatio")

    	if Ty = 1
		query.AddReplace("filters", "IsFavorite")
		query.AddReplace("sortby", "SortName")
		query.AddReplace("sortorder", "Ascending")
	else if Ty = 0
		query.AddReplace("filters", "IsResumable")
		query.AddReplace("sortby", "DatePlayed")
		query.AddReplace("sortorder", "Descending")
	else if Ty = 2
		query.AddReplace("ExcludeLocationTypes", "Virtual")
		query.AddReplace("sortby", "DateCreated")
		query.AddReplace("sortorder", "Descending")
	else if Ty = 3
		query.AddReplace("filters", "IsUnPlayed")
		query.AddReplace("ExcludeLocationTypes", "Virtual")
		query.AddReplace("SortBy", "Random")
	else if Ty = 4
		query.AddReplace("ExcludeLocationTypes", "Virtual")
		query.AddReplace("SortBy", "DatePlayed")
		query.AddReplace("sortorder", "Descending")
	else if Ty = 5
		query.AddReplace("ExcludeLocationTypes", "Virtual")
		query.AddReplace("SortBy", "PlayCount")
		query.AddReplace("sortorder", "Descending")
	else
		query.AddReplace("ExcludeLocationTypes", "Virtual")
		query.AddReplace("SortBy", "PremiereDate,SortName")
		query.AddReplace("sortorder", "Descending")
	end if

	for each key in query
		url = url + "&" + key +"=" + HttpEncode(query[key])
	end for
    return url

End Function

Function parseFavConLibraryScreenResult(row as Integer, id as string, startIndex as Integer, json as String) as Object

	imageType      = (firstOf(RegUserRead("FavConImageType"), "0")).ToInt()
	primaryImageStyle = "mixed-aspect-ratio-portrait"
	mode = ""
	Ty = FirstOf(GetGlobalVar("Ty"), "0").toInt()
	EpMax = (firstOf(RegUserRead("prefepisodesmax"), "100")).ToInt()

	if (row > 5 and row < 9 and Ty < 4) or (row > 3 and row < 6 and Ty > 3)
		primaryImageStyle = "mixed-aspect-ratio-square"
	else
		primaryImageStyle = "mixed-aspect-ratio-portrait"
	end if
	if (row = 2 and (Ty < 4 or Ty = 6)) or (row = 1 and Ty > 3)
		mode = "seriesimageasprimary" 
	else if (row = 7 and Ty < 4) or (Ty > 3 and row = 4)
		mode = "audiosearch"
	else if (row = 8 and Ty < 4) or (Ty > 3 and row = 5)
		mode = "podcastsearch"
	end if
    	response = parseItemsResponse(json, imageType, primaryImageStyle, mode)
	if (row = 2 and (Ty < 4 or Ty = 6)) or (row = 1 and Ty > 3  and Ty <> 6)
		if response.TotalCount > EpMax then response.TotalCount = EpMax
	else if Ty > 1 and response.TotalCount > 100
		response.TotalCount = 100
	end if
	return response

End Function