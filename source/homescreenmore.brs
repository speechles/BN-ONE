'******************************************************
' createHomeVideoAlphabetScreen
'******************************************************

Function createHomeVideoAlphabetScreen(viewController as Object, letter As String, parentId = invalid) As Object

    'imageType      = (firstOf(RegUserRead("hvImageType"), "0")).ToInt()
	imageType = 1

	names = ["Videos","Favorite Videos"]
	keys = [letter,letter]

	loader = CreateObject("roAssociativeArray")
	loader.getUrl = getHomeVideoAlphabetScreenUrl
	loader.parsePagedResult = parseHomeVideoAlphabetScreenResult
	loader.parentId = parentId

    if imageType = 0 then
        screen = createPaginatedGridScreen(viewController, names, keys, loader, "mixed-aspect-ratio")
    Else
        screen = createPaginatedGridScreen(viewController, names, keys, loader, "two-row-flat-landscape-custom")
    End If

	screen.displayDescription = (firstOf(RegUserRead("hvDescription"), "1")).ToInt()

    return screen

End Function

Function getHomeVideoAlphabetScreenUrl(row as Integer, id as String) as String

	letter = id

    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?recursive=true"

    ' Query
    query = {
        IncludeItemTypes: "MusicVideo,Video"
        fields: "Overview"
        sortby: "SortName"
        sortorder: "Ascending",

    }

		'ImageTypeLimit: "1"
	
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

Function parseHomeVideoAlphabetScreenResult(row as Integer, id as string, startIndex as Integer, json as String) as Object

	imageType      = (firstOf(RegUserRead("hvImageType"), "0")).ToInt()

    return parseItemsResponse(json, 1, "mixed-aspect-ratio-portrait")

End Function

'******************************************************
' createFolderAlphabetScreen
'******************************************************

Function createFolderAlphabetScreen(viewController as Object, letter As String, parentId = invalid) As Object

    'imageType      = (firstOf(RegUserRead("folderImageType"), "0")).ToInt()
	imageType = 1

	names = ["Library","Favorite Library"]
	keys = [letter,letter]

	loader = CreateObject("roAssociativeArray")
	loader.getUrl = getFolderAlphabetScreenUrl
	loader.parsePagedResult = parseFolderAlphabetScreenResult
	loader.parentId = parentId

    if imageType = 0 then
        screen = createPaginatedGridScreen(viewController, names, keys, loader, "mixed-aspect-ratio")
    Else
        screen = createPaginatedGridScreen(viewController, names, keys, loader, "two-row-flat-landscape-custom")
    End If

	screen.displayDescription = (firstOf(RegUserRead("folderDescription"), "1")).ToInt()

    return screen

End Function

Function getFolderAlphabetScreenUrl(row as Integer, id as String) as String

	letter = id

    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?recursive=true"

    ' Query
    query = {
        fields: "Overview"
        sortby: "SortName"
        sortorder: "Ascending",

    }

		'ImageTypeLimit: "1"
	
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

Function parseFolderAlphabetScreenResult(row as Integer, id as string, startIndex as Integer, json as String) as Object

	imageType      = (firstOf(RegUserRead("folderImageType"), "0")).ToInt()

    return parseItemsResponse(json, 1, "mixed-aspect-ratio-portrait")

End Function

'******************************************************
' createPhotoAlphabetScreen
'******************************************************

Function createPhotoAlphabetScreen(viewController as Object, letter As String, parentId = invalid) As Object

    'imageType      = (firstOf(RegUserRead("photoImageType"), "0")).ToInt()
	imageType = 1

	names = ["Library","Favorite Library"]
	keys = [letter,letter]

	loader = CreateObject("roAssociativeArray")
	loader.getUrl = getPhotoAlphabetScreenUrl
	loader.parsePagedResult = parsePhotoAlphabetScreenResult
	loader.parentId = parentId

    if imageType = 0 then
        screen = createPaginatedGridScreen(viewController, names, keys, loader, "mixed-aspect-ratio")
    Else
        screen = createPaginatedGridScreen(viewController, names, keys, loader, "two-row-flat-landscape-custom")
    End If

	screen.displayDescription = (firstOf(RegUserRead("photoDescription"), "1")).ToInt()

    return screen

End Function

Function getPhotoAlphabetScreenUrl(row as Integer, id as String) as String

	letter = id

    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?recursive=true"

    ' Query
    query = {
        fields: "Overview"
        sortby: "SortName"
        sortorder: "Ascending",

    }

		'ImageTypeLimit: "1"
	
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

Function parsePhotoAlphabetScreenResult(row as Integer, id as string, startIndex as Integer, json as String) as Object

	imageType      = (firstOf(RegUserRead("photoImageType"), "0")).ToInt()

    return parseItemsResponse(json, 1, "mixed-aspect-ratio-portrait")

End Function