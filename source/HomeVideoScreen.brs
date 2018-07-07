'**********************************************************
'** createHomeMovieLibraryScreen
'**********************************************************

Function createHomeMovieLibraryScreen(viewController as Object, parentId as String) As Object

	RegUserWrite("hvImageType","1")
    	imageType      = (firstOf(RegUserRead("hvImageType"), "1")).ToInt()

	names = ["Videos", "Jump In", "Favorite Videos"]
	keys = ["0", "1", "2"]

	loader = CreateObject("roAssociativeArray")
	loader.getUrl = getHomeMovieLibraryRowScreenUrl
	loader.parsePagedResult = parseHomeMovieLibraryScreenResult
	loader.getLocalData = getHomeMovieLibraryScreenLocalData
	loader.parentId = parentId
    if imageType = 0 then
        screen = createPaginatedGridScreen(viewController, names, keys, loader, "mixed-aspect-ratio")
    Else
        screen = createPaginatedGridScreen(viewController, names, keys, loader, "two-row-flat-landscape-custom")
    End If

	screen.baseActivate = screen.Activate
	screen.Activate = homemovieScreenActivate

    screen.displayDescription = (firstOf(RegUserRead("hvDescription"), "1")).ToInt()

	screen.createContextMenu = homemovieScreenCreateContextMenu

    return screen

End Function

Sub homemovieScreenActivate(priorScreen)

    imageType      = (firstOf(RegUserRead("hvImageType"), "1")).ToInt()
	displayDescription = (firstOf(RegUserRead("hvDescription"), "1")).ToInt()
	
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

Function getHomeMovieLibraryScreenLocalData(row as Integer, id as String, startItem as Integer, count as Integer) as Object

	if row = 1 then
		return getAlphabetList("HomeVideoAlphabet", m.parentId)
	end If

    return invalid

End Function

Function getHomeMovieLibraryRowScreenUrl(row as Integer, id as String) as String

	filterBy       = (firstOf(RegUserRead("hvFilterBy"), "0")).ToInt()
	sortBy         = (firstOf(RegUserRead("hvSortBy"), "0")).ToInt()
	sortOrder      = (firstOf(RegUserRead("hvSortOrder"), "0")).ToInt()

	url = GetServerBaseUrl()

	query = {}

	if row = 0
		url = url  + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?recursive=true"
		if filterBy = 1
			query.AddReplace("Filters", "IsUnPlayed")
		else if filterBy = 2
			query.AddReplace("Filters", "IsPlayed")
		else if filterBy = 3
			query.AddReplace("Filters", "IsResumable")
		end if
		if sortBy = 1
			query.AddReplace("SortBy", "DateCreated,SortName")
		else if sortBy = 2
			query.AddReplace("SortBy", "DatePlayed,SortName")
		else if sortBy = 3
			query.AddReplace("SortBy", "PremiereDate,SortName")
		else if sortBy = 4
			query.AddReplace("SortBy", "Random,SortName")
		else if sortBy = 5
			query.AddReplace("SortBy", "PlayCount,SortName")
		else if sortBy = 6
			query.AddReplace("SortBy", "CriticRating,SortName")
		else if sortBy = 7
			query.AddReplace("SortBy", "CommunityRating,SortName")
		else if sortBy = 8
			query.AddReplace("SortBy", "Budget,SortName")
		else if sortBy = 9
			query.AddReplace("SortBy", "Revenue,SortName")
		else
			query.AddReplace("SortBy", "SortName")
		end if
		if sortOrder = 1
			query.AddReplace("SortOrder", "Descending")
		end if
		query.AddReplace("IncludeItemTypes", "MusicVideo,Video")
		query.AddReplace("fields", "PrimaryImageAspectRatio,Overview,ParentId")
		query.AddReplace("ParentId", m.parentId)
	else if row = 1
		' Alphabet - should never get in here
	else if row = 2
		' Favorite Movies
		url = url + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?recursive=true"
		query.AddReplace("Filters", "IsFavorite")
		query.AddReplace("SortBy", "SortName")
		query.AddReplace("SortOrder", "Ascending")
		query.AddReplace("fields", "PrimaryImageAspectRatio,Overview,ParentId")
		'query.AddReplace("ImageTypeLimit", "1")
		query.AddReplace("IncludeItemTypes", "MusicVideo,Video")
		query.AddReplace("ParentId", m.parentId)
	end If
	for each key in query
		url = url + "&" + key +"=" + HttpEncode(query[key])
	end for
    return url

End Function

Function parseHomeMovieLibraryScreenResult(row as Integer, id as string, startIndex as Integer, json as String) as Object
	imageType      = (firstOf(RegUserRead("hvImageType"), "1")).ToInt()
	primaryImageStyle = "mixed-aspect-ratio-portrait"
	mode = ""
    return parseItemsResponse(json, imageType, primaryImageStyle, mode)
End Function

Function HomemovieScreenCreateContextMenu()
	
	options = {
		settingsPrefix: "hv"
		sortOptions: ["Name", "Date Added", "Date Played", "Release Date", "Random", "Play Count", "Critic Rating", "Community Rating", "Budget", "Revenue"]
		filterOptions: ["None", "Unplayed", "Played", "Resumable"]
		showSortOrder: true
	}
	createContextMenuDialog(options)
	return true

End Function

'**********************************************************
'** createHomeMovieAlphabetScreen
'**********************************************************

Function createHomeMovieAlphabetScreen(viewController as Object, letter As String, parentId = invalid) As Object

    imageType      = (firstOf(RegUserRead("hvImageType"), "1")).ToInt()

	names = ["Videos","Favorite Videos"]
	keys = [letter,letter]

	loader = CreateObject("roAssociativeArray")
	loader.getUrl = getHomeMovieAlphabetScreenUrl
	loader.parsePagedResult = parseHomeMovieAlphabetScreenResult
	loader.parentId = parentId

    if imageType = 0 then
        screen = createPaginatedGridScreen(viewController, names, keys, loader, "mixed-aspect-ratio")
    Else
        screen = createPaginatedGridScreen(viewController, names, keys, loader, "two-row-flat-landscape-custom")
    End If

	screen.displayDescription = (firstOf(RegUserRead("movieDescription"), "1")).ToInt()

    if screen.displayDescription = 0 then
        screen.SetDescriptionVisible(false)
    end if

    return screen

End Function

Function getHomeMovieAlphabetScreenUrl(row as Integer, id as String) as String

	letter = id

    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?recursive=true"

    ' Query
    query = {
        IncludeItemTypes: "MusicVideo,Video"
        fields: "PrimaryImageAspectRatio,Overview,ParentId"
        sortby: "SortName"
        sortorder: "Ascending",
		ImageTypeLimit: "1"
    }
	
	if m.parentId <> invalid then query.parentId = m.parentId

    if row = 0 then
	if letter = "#" then
		filters = {
			NameLessThan: "a"
		}
    	else
        	filters = {
            		NameStartsWith: letter
        	}
	end if
    else
	if letter = "#" then
		filters = {
			NameLessThan: "a"
			isFavorite: "true"
		}
    	else
        	filters = {
            		NameStartsWith: letter
			isFavorite: "true"
        	}
	end if
    end if

    if filters <> invalid
        query = AddToQuery(query, filters)
    end if

	for each key in query
		url = url + "&" + key +"=" + HttpEncode(query[key])
	end for

    return url

End Function

Function parseHomeMovieAlphabetScreenResult(row as Integer, id as string, startIndex as Integer, json as String) as Object

	imageType      = (firstOf(RegUserRead("hvImageType"), "1")).ToInt()

    return parseItemsResponse(json, imageType, "mixed-aspect-ratio-portrait")

End Function