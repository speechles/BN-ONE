'**********************************************************
'**  FilmographyScreen 
'**  For display of titles associated with a given person
'**  This is a modification of MovieLibraryScreen
'**********************************************************

'**********************************************************
'** createFilmographyScreen
'**********************************************************

Function createFilmographyScreen(viewController as Object, item as Object) As Object

    imageType      = (firstOf(RegUserRead("filmImageType"), "0")).ToInt()

	names = ["Movies", "Shows", "Episodes", "Trailers", "Favorite Movies", "Favorite Shows", "Favorite Episodes", "Favorite Trailers"]
	keys = ["0", "1", "2", "3", "4", "5", "6", "7"]

	loader = CreateObject("roAssociativeArray")
	loader.getUrl = getFilmographyRowScreenUrl
	loader.parsePagedResult = parseFilmographyScreenResult
	loader.personId = item.Id
	
    if imageType = 0 then
        screen = createPaginatedGridScreen(viewController, names, keys, loader, "mixed-aspect-ratio")
    Else
        screen = createPaginatedGridScreen(viewController, names, keys, loader, "two-row-flat-landscape-custom")
    End If

	screen.baseActivate = screen.Activate
	screen.Activate = filmographyScreenActivate

    screen.displayDescription = (firstOf(RegUserRead("filmDescription"), "1")).ToInt()

	screen.createContextMenu = filmographyScreenCreateContextMenu

    return screen

End Function

Sub filmographyScreenActivate(priorScreen)

    imageType      = (firstOf(RegUserRead("filmImageType"), "0")).ToInt()
	displayDescription = (firstOf(RegUserRead("filmDescription"), "1")).ToInt()
	
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

Function getFilmographyRowScreenUrl(row as Integer, id as String) as String

    filterBy       = (firstOf(RegUserRead("filmFilterBy"), "0")).ToInt()
    sortBy         = (firstOf(RegUserRead("filmSortBy"), "0")).ToInt()
    sortOrder      = (firstOf(RegUserRead("filmSortOrder"), "0")).ToInt()

    url = GetServerBaseUrl()

    query = {}

	url = url  + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?recursive=true"

	if filterBy = 1
		query.AddReplace("Filters", "IsUnPlayed")
	else if filterBy = 2
		query.AddReplace("Filters", "IsPlayed")
	end if

	if sortBy = 1
		query.AddReplace("SortBy", "DateCreated,SortName")
	else if sortBy = 2
		query.AddReplace("SortBy", "DatePlayed,SortName")
	else if sortBy = 3
		query.AddReplace("SortBy", "PremiereDate,SortName")
	else
		query.AddReplace("SortBy", "SortName")
	end if

	if sortOrder = 1
		query.AddReplace("SortOrder", "Descending")
	end if

	if row = 0 or row = 4
		query.AddReplace("IncludeItemTypes", "Movie")
	else if row = 1 or row = 5
		query.AddReplace("IncludeItemTypes", "Series")
	else if row = 2 or row = 6
		query.AddReplace("IncludeItemTypes", "Episode")
	else if row = 3 or row = 7
		query.AddReplace("IncludeItemTypes", "Trailer,ChannelVideoItem")
	end if

	if row > 3
		query.AddReplace("Filters", "IsFavorite")
	end if
	
	query.AddReplace("Fields", "Overview,ParentId")
	query.AddReplace("PersonIds", m.personId)

	for each key in query
		url = url + "&" + key +"=" + HttpEncode(query[key])
	end for

    return url

End Function

Function parseFilmographyScreenResult(row as Integer, id as string, startIndex as Integer, json as String) as Object

	imageType      = (firstOf(RegUserRead("filmImageType"), "0")).ToInt()
	primaryImageStyle = "mixed-aspect-ratio-portrait"
	mode = ""
	if row > 1 then mode = "seriesimageasprimary"

    return parseItemsResponse(json, imageType, primaryImageStyle, mode)

End Function

Function filmographyScreenCreateContextMenu()
	
	options = {
		settingsPrefix: "film"
		sortOptions: ["Name", "Date Added", "Date Played", "Release Date", "Random", "Play Count", "Critic Rating", "Community Rating", "Budget", "Revenue"]
		filterOptions: ["None", "Unplayed", "Played", "Resumable"]
		showSortOrder: true
	}
	createContextMenuDialog(options)

	return true

End Function
