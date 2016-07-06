'**********************************************************
'** createFolderScreen
'**********************************************************

Function createFolderScreen(viewController as Object, item as Object) As Object

	parentId = item.Id
	
	title = item.Title

	if item.ContentType = "BoxSet" then
		settingsPrefix = "boxset"
		contextMenuType = Invalid
		RegUserWrite(settingsPrefix + "ImageType","0")
	else
		settingsPrefix = "folders"
		contextMenuType = "folders"
		title = item.Title + "  ( Press * for Options )"
	End if

    	imageType      = (firstOf(RegUserRead(settingsPrefix + "ImageType"), "0")).ToInt()

	names = [title,"Favorite "+tostr(title)]
	keys = ["0"+tostr(item.Id), "1"+tostr(item.Id)]
	'names = [title]
	'keys = [item.Id]

	loader = CreateObject("roAssociativeArray")
	loader.settingsPrefix = settingsPrefix
	loader.contentType = item.ContentType
	loader.getUrl = getFolderItemsUrl
	loader.parsePagedResult = parseFolderItemsResult

	if imageType = 0 then
		gridStyle = "mixed-aspect-ratio"
    Else
		gridStyle = "two-row-flat-landscape-custom"
    End If
	
    screen = createPaginatedGridScreen(viewController, names, keys, loader, gridStyle)

	screen.baseActivate = screen.Activate
	screen.Activate = folderScreenActivate

	screen.settingsPrefix = settingsPrefix

	screen.contextMenuType = contextMenuType
	
	if imageType = 0 then
		screen.displayDescription = 1
	else
		screen.displayDescription = (firstOf(RegUserRead(settingsPrefix + "Description"), "1")).ToInt()
	end if

	screen.createContextMenu = folderScreenCreateContextMenu

    return screen
End Function

Sub folderScreenActivate(priorScreen)

    imageType      = (firstOf(RegUserRead(m.settingsPrefix + "ImageType"), "0")).ToInt()
	
	if imageType = 0 then
		displayDescription = 1
	else
		displayDescription = (firstOf(RegUserRead(m.settingsPrefix + "Description"), "1")).ToInt()
	end if
	
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

Function getFolderItemsQuery(row as integer, settingsPrefix as String, contentType as String) as Object

    filterBy       = (firstOf(RegUserRead(settingsPrefix + "FilterBy"), "0")).ToInt()
    sortBy         = (firstOf(RegUserRead(settingsPrefix + "SortBy"), "0")).ToInt()
    sortOrder      = (firstOf(RegUserRead(settingsPrefix + "SortOrder"), "0")).ToInt()

    query = {}


	' Just take the default filter and sort order for collections
	if contentType <> "BoxSet" then

		if filterBy = 1
			if row = 1
				query.AddReplace("Filters", "IsUnPlayed,IsFavorite")
			else
				query.AddReplace("Filters", "IsUnPlayed")
			end if
		else if filterBy = 2
			if row = 1
				query.AddReplace("Filters", "IsPlayed,IsFavorite")
			else
				query.AddReplace("Filters", "IsPlayed")
			end if
		else if filterBy = 3
			if row = 1
				query.AddReplace("Filters", "IsResumable,IsFavorite")
			else
				query.AddReplace("Filters", "IsResumable")
			end if
		else
			if row = 1 then query.AddReplace("Filters", "IsFavorite")
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
	else
		query.AddReplace("SortBy", "PremiereDate,SortName")
		query.AddReplace("SortOrder", "Ascending")
		if row = 1 then query.AddReplace("Filters", "IsFavorite")
	end if

	return query

End Function

Function getFolderItemsUrl(row as Integer, id as String) as String

    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?parentid=" + right(id,id.len() - 1)

    query = {
        fields: "Overview,PrimaryImageAspectRatio"
    }

	filters = getFolderItemsQuery(row, m.settingsPrefix, m.contentType)

    if filters <> invalid
        query = AddToQuery(query, filters)
    end if

	for each key in query
		url = url + "&" + key +"=" + HttpEncode(query[key])
	end for

    return url

End Function

Function parseFolderItemsResult(row as Integer, id as string, startIndex as Integer, json as String) as Object

	imageType      = (firstOf(RegUserRead(m.settingsPrefix + "ImageType"), "0")).ToInt()
	
    return parseItemsResponse(json, imageType, "mixed-aspect-ratio-portrait")

End Function

Function folderScreenCreateContextMenu()
	
	if m.contextMenuType <> invalid then
	
		options = {
			settingsPrefix: m.contextMenuType
			sortOptions: ["Name", "Date Added", "Date Played", "Release Date", "Random", "Play Count", "Critic Rating", "Community Rating", "Budget", "Revenue"]
			filterOptions: ["None", "Unplayed", "Played", "Resumable"]
			showSortOrder: true
		}
		createContextMenuDialog(options)
	end if

	return true

End Function
