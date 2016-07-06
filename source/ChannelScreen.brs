'**********************************************************
'** Show Channel List Page
'**********************************************************
Function createChannelScreen(viewController as Object, item As Object) As Object

    settingsPrefix = "channel"
    'm.settingsPrefix = settingsPrefix
    contextMenuType = "folders"
    'm.contextMenuType = contextMenuType

	names = [item.title,"Favorite "+tostr(item.title)]
	keys = ["0"+tostr(item.Id), "1"+tostr(item.Id)]
    	'names = [item.Title + " (* Options)"]
    	'keys = [item.Id]
  
    loader = CreateObject("roAssociativeArray")
    loader.settingsPrefix = settingsPrefix
    loader.contentType = item.contentType
    loader.getUrl = getChannelScreenUrl
    loader.parsePagedResult = parseChannelScreenResult
    loader.channel = item
    
    imageType      = (firstOf(RegUserRead("channelImageType"), "0")).ToInt()

    if imageType = 0 then
		gridStyle = "mixed-aspect-ratio"
    Else
		gridStyle = "two-row-flat-landscape-custom"
    End If

    screen = createPaginatedGridScreen(viewController, names, keys, loader, gridstyle)

    screen.displayDescription = 0

    screen.baseActivate = screen.Activate
    screen.Activate = ChannelScreenActivate

    screen.settingsPrefix = settingsPrefix

    screen.contextMenuType = contextMenuType
	
    if imageType = 0 then
        screen.displayDescription = 1
    else
        screen.displayDescription = (firstOf(RegUserRead("channelDescription"), "1")).ToInt()
    end if

    screen.createContextMenu = ChannelScreenCreateContextMenu

    return screen

End Function

Sub ChannelScreenActivate(priorScreen)

    imageType      = (firstOf(RegUserRead("channelImageType"), "0")).ToInt()
	
	if imageType = 0 then
		displayDescription = 1
	else
		displayDescription = (firstOf(RegUserRead("channelDescription"), "1")).ToInt()
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

Function getChannelItemsQuery(row as Integer, settingsPrefix as String, contentType as String) as Object

    filterBy       = (firstOf(RegUserRead("channelFilterBy"), "0")).ToInt()
    sortBy         = (firstOf(RegUserRead("channelSortBy"), "0")).ToInt()
    sortOrder      = (firstOf(RegUserRead("channelSortOrder"), "0")).ToInt()

    query = {}

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
    else
	if row = 1 then query.AddReplace("Filters", "IsFavorite")
    end if

	' Just take the default sort order for collections
	if contentType <> "BoxSet" then
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

Function getChannelScreenUrl(row as Integer, id as String) as String

    channel = m.channel

     ' URL
    url = GetServerBaseUrl()

    ' Query
    'query = getChannelItemsQuery(row, m.settingsPrefix, m.contentType)

    'if row = 0
        if channel.ChannelId <> invalid
            url = url  + "/Channels/" + HttpEncode(channel.ChannelId) + "/Items?userId=" + getGlobalVar("user").Id
        'else
            'url = url  + "/Channels/" + HttpEncode(channel.Id) + "/Items?userId=" + getGlobalVar("user").Id
        'end if
        
        ' Query
        query = {
            fields: "Overview,PrimaryImageAspectRatio"
        }

	filters = getChannelItemsQuery(row, m.settingsPrefix, m.contentType)

    	if filters <> invalid
        	query = AddToQuery(query, filters)
    	end if

        if channel.ChannelId <> invalid
            q = { folderid: channel.Id }
            query.Append(q)
        end if
    end If
    
    for each key in query
        url = url + "&" + key +"=" + HttpEncode(query[key])
    end for
    
    print "Channel url: " + url

    return url

End Function

Function parseChannelScreenResult(row as Integer, id as string, startIndex as Integer, json as String) as Object

    imageType      = (firstOf(RegUserRead("channelImageType"), "0")).ToInt()

    return parseItemsResponse(json, imagetype, "mixed-aspect-ratio-portrait", "autosize")

End Function

Function ChannelScreenCreateContextMenu()
	
	if m.contextMenuType <> invalid then
	
		options = {
			settingsPrefix: "channel"
			sortOptions: ["Name", "Date Added", "Date Played", "Release Date", "Random", "Play Count", "Critic Rating", "Community Rating", "Budget", "Revenue"]
			filterOptions: ["None", "Unplayed", "Played"]
			showSortOrder: true
		}
		createContextMenuDialog(options)
	end if

	return true

End Function
