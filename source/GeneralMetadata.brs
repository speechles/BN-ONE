'******************************************************
' getPublicUserProfiles
'******************************************************

Function getPublicUserProfiles(serverUrl as String) As Object

	Debug("getPublicUserProfiles url: " + serverUrl)
	
    ' URL

	url = serverurl + "/Users/Public"

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid

        contentList   = CreateObject("roArray", 25, true)
        jsonObj       = ParseJSON(response)

        if jsonObj = invalid
	    'createDialog("JSON Error!", "Error while parsing JSON response for All User Profiles", "OK", true)
            Debug("Error while parsing JSON response for All User Profiles")
            return invalid
        end if

        for each i in jsonObj
            metaData = parseUser(i, serverurl)

            contentList.push( metaData )
        end for

        return contentList
    else
	createDialog("User Profile Error!", "Failed To Get All User Profiles.", "OK", true)
        Debug("Failed To Get All User Profiles")
    end if

    return invalid
End Function


'******************************************************
' Get User Profile
'******************************************************

Function getUserProfile(userId As String) As Object

    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(userId)
	debug("userprofileurl: "+url)
    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid

        i = ParseJSON(response)

        if i = invalid
	    'createDialog("JSON Error!", "Error Parsing User Profile", "OK", true)
            Debug("Error Parsing User Profile")
            return invalid
        end if
        metaData = parseUser(i)

        return metaData
    else
	createDialog("User Profile Error!", "Failed To Get User Profile.", "OK", true)
        Debug("Failed To Get User Profile")
    end if

    return invalid
End Function

Function parseUser(i as Object, serverUrl = "") as Object

    metaData = {}
    ' Set the Id
    metaData.Id = i.Id

    ' Set the Content Type
    metaData.ContentType = "user"
    metaData.isAdmin = firstOf(i.Policy.isAdministrator, "false")
    ' Set the Username
    metaData.Title = firstOf(i.Name, "Unknown")
    metaData.ShortDescriptionLine1 = firstOf(i.Name, "Unknown")

    ' Set the Has Password Flag
    metaData.HasPassword = firstOf(i.HasPassword, false)

    ' Get Image Sizes
    sizes = GetImageSizes("arced-square")

    ' Check if Item has Image, otherwise use default
    if i.PrimaryImageTag <> "" And i.PrimaryImageTag <> invalid
        imageUrl = GetServerBaseUrl(serverUrl) + "/Users/" + HttpEncode(i.Id) + "/Images/Primary/0"

        metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.PrimaryImageTag, false, 0)
        metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.PrimaryImageTag, false, 0)

    else 
        metaData.HDPosterUrl = GetViewController().getThemeImageUrl("hd-default-user.png")
        metaData.SDPosterUrl = GetViewController().getThemeImageUrl("hd-default-user.png")

    end if
	return metadata

End Function


'**********************************************************
'** Get Alphabetical List
'**********************************************************

Function getAlphabetList(contentType As String, parentId = invalid) As Object

    ' Set the buttons
    buttons = []
    letters = ["#","a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"]

    for each cLetter in letters
	if cLetter = "#"
		title = "Begins with Numbers"
		description = "Show content beginning with Numbers"
	else
		title = "Begins with "+UCase(cLetter)
		description = "Show content beginning with the letter "+UCase(cLetter)
	end if
        letterButton = {
            Id: cLetter
            ContentType: contentType
            Title: title
            ShortDescriptionLine1: " "
	    Description: description
            HDPosterUrl: GetViewController().getThemeImageUrl("letter_" + cLetter + ".jpg")
            SDPosterUrl: GetViewController().getThemeImageUrl("letter_" + cLetter + ".jpg")
        }
		
		if parentId <> invalid then
			letterButton.ParentId = parentId
		end if

        buttons.Push( letterButton )
    end for

    return {
        Items: buttons
        TotalCount: 27
    }
End Function

'**********************************************************
'** parseItemsResponse
'**********************************************************

Function parseItemsResponse(response as String, imageType as Integer, primaryImageStyle as String, mode ="" as String) As Object

    if response <> invalid

        fixedResponse = normalizeJson(response)

        contentList = CreateObject("roArray", 25, true)
        jsonObj     = ParseJSON(fixedResponse)

        if jsonObj = invalid  
	    'createDialog("JSON Error!", "Error while parsing JSON response", "OK", true)
            Debug("Error while parsing JSON response")
            return invalid
        end if
	if type(jsonObj) = "roAssociativeArray"
		totalRecordCount = jsonObj.TotalRecordCount
		if totalRecordCount <> invalid
			'debug("1 RoAssociateiveArray - TotalRecordCount "+tostr(totalRecordCount))
			for each i in jsonObj.Items
				metaData = getMetadataFromServerItem(i, imageType, primaryImageStyle, mode)
				contentList.push( metaData )
        		end for
		else
			totalRecordCount = 1
			'debug("2 " + type(jsonObj) + " - TotalRecordCount "+tostr(totalRecordCount))
			metaData = getMetadataFromServerItem(jsonObj, imageType, primaryImageStyle, mode)
			contentList.push( metaData )
		end if
	else
		totalRecordCount = jsonObj.count()
		'debug("3 " + type(jsonObj) + " - TotalRecordCount "+tostr(totalRecordCount))
        	for each i in jsonObj
			metaData = getMetadataFromServerItem(i, imageType, primaryImageStyle, mode)
			contentList.push( metaData )
        	end for
		
	end if

        return {
            Items: contentList
            TotalCount: totalRecordCount
        }

    else	
	createDialog("Parse Response Error!", "Error getting folder items.", "OK", true)
	Debug("Error getting folder items.")
    end if

	return invalid
End Function

Function getMetadataFromServerItem(i as Object, imageType as Integer, primaryImageStyle as String, mode ="" as String) As Object

    style = primaryImageStyle

    metaData = {}

    metaData.ContentType = getContentType(i, mode)

    metaData.Id = i.Id
	metaData.ServerId = i.ServerId

	metaData.Title = getTitle(i)
	metaData.CanDelete = i.CanDelete
	metaData.IsFolder = i.IsFolder
	metaData.MediaType = i.MediaType
	metaData.PrimaryImageAspectRatio = i.PrimaryImageAspectRatio
	metaData.MediaSources = i.MediaSources
	metaData.People = i.People
	metaData.CollectionType = i.CollectionType
	metaData.ParentId = i.ParentId
	metaData.ParentIndexNumber = i.ParentIndexNumber
	metaData.SeriesId = i.SeriesId
	metaData.SeasonId = i.SeasonId
	metaData.SeriesName = i.SeriesName
	metaData.indexNumber = i.indexNumber
	if i.ArtistItems <> invalid
		if i.ArtistItems.count() > 0 then metaData.Artistname = i.artistItems[0].name
	else if i.Artists <> invalid
		if i.Artists.count() > 0 then metaData.Artistname = i.arists[0]
	end if
	metaData.IndexNumberEnd = i.IndexNumberEnd
	metaData.Studios = i.Studios
	metaData.SeriesStudio = i.SeriesStudio
	metaData.ChannelId = i.ChannelId
	if i.Taglines <> invalid and i.Taglines.count() > 0
		metaData.Tagline = i.Taglines[0]
	end if
	metaData.StartDate = i.StartDate
	metaData.EndDate = i.EndDate
	metaData.TimerId = i.TimerId
	metaData.SeriesTimerId = i.SeriesTimerId
	metaData.ProgramId = i.ProgramId
	metaData.SongCount = i.SongCount
	metaData.AlbumCount = i.AlbumCount
        if i.MediaSources <> invalid and i.MediaSources.Count() > 0 then
		m.Extension = i.MediaSources[0].Container
		audio = "" : video = ""
		for each stream in i.MediaSources[0].MediaStreams
			if stream.Type = "Audio" and audio = "" then audio = stream.Codec
			if stream.Type = "Video" and video = "" then
				video = stream.Codec
				height = stream.Height
			end if
			if audio <> "" and video <> "" then exit for
		end For
		codec = " "
		if video <> "" then codec = Ucase(tostr(height))+"P/"+Ucase(video)+"/"
		if audio <> "" then codec = codec +Ucase(audio)+"/"
		m.Codecs = left(codec,len(codec)-1)
	else
		m.Codecs = ""
	end if

        '   if MediaName.Name <> invalid and MediaName.Name <> "" then
	'	s = CreateObject("roRegex","/","i")
	'	if s.isMatch(MediaName.Name) then
        '        	m.Codecs = mediaName.Name
	'	else
	'		m.Codecs = ""
	'	end if
	'        if MediaName.Container <> invalid then
	'	    m.Extension = mediaName.Container
	'        end if
	'    end if
	'end if

	'if i.Type <> invalid then
	'	m.itemType = i.itemType
	'else
	'	m.itemType = ""
	'end if

	if i.LocationType<> invalid then
		if i.LocationType = "Virtual" then
			m.VirtualType = MissOrUp(i)
		end if
	end if

	line1 = getShortDescriptionLine1(i, mode)

	if line1 <> "" then
		metaData.ShortDescriptionLine1 = line1
	end If
	
	more = FirstOf(RegUserRead("prefTwoDesc"), "1").ToInt()
	
	if more = 1 then
		line2 = getShortDescriptionLine2(i, mode)

		if line2 <> "" then
			metaData.ShortDescriptionLine2 = line2
		end If
	end if

    if i.RunTimeTicks <> "" And i.RunTimeTicks <> invalid
        metaData.Length = Int(((i.RunTimeTicks).ToFloat() / 10000) / 1000)
    end if

    with = FirstOf(RegUserRead("prefDetailStats"), "1").ToInt()
    if with = 1 then
	description = ""
        if i.MediaSources <> invalid and i.MediaSources.Count() > 0 then
	    mediaName = i.MediaSources[0]
            if mediaName <> invalid and MediaName.Name <> invalid and MediaName.Name <> "" then
		for count = 0 to i.MediaSources[0].count()-1
	    		MediaVideo = MediaName.MediaStreams[count]
			if MediaVideo <> invalid and (MediaVideo.AverageFrameRate <> invalid or MediaVideo.RealFrameRate <> invalid)
				exit for
			end if
		end for
		if MediaVideo <> invalid then
			fr = ""
			if MediaVideo.AverageFrameRate <> invalid
				fr = tostr(MediaVideo.AverageFrameRate)
			else if MediaVideo.RealFrameRate <> invalid
				fr = tostr(MediaVideo.RealFrameRate)
			end if
			if fr <> "" then
				if left(fr,1) = " " then fr = right(fr, fr.len() -1)
				if fr.len() > 6 then
					fr = left(fr,6)
				end if
				description = fr + "/"
			end if
		end if
	    end if
            if m.Codecs <> invalid and i.LocationType <> invalid and i.LocationType <> "Remote" then
		if description = "" then
			description = "* No Media Sources *"
		end if
                description = description + m.Codecs
	        if MediaName.Container <> invalid then
		    	description =  description + " (" + mediaName.Container + ") "
		end if
		description = WatchedLast(i,description) + chr(10) + getDescription(i, mode)
            else
                description = getDescription(i, mode)
            end if
        else
	    description = getDescription(i, mode)
        end if
    else
      description = getDescription(i, mode)
    end if
    if description <> ""
	metaData.FullDescription = getDescription(i, mode)
        metaData.Description = description
	metaData.Overview = description
    end if



    if i.OfficialRating <> invalid
        metaData.Rating = i.OfficialRating
    end if

    if i.CommunityRating <> invalid
        metaData.StarRating = Int(i.CommunityRating) * 10
    end if
	
	metaData.Director = getDirector(i, mode)

    ' Set the Play Access
    metaData.PlayAccess = firstOf(i.PlayAccess, "Full")

    ' Set the Place Holder (default to is not a placeholder)
    metaData.IsPlaceHolder = firstOf(i.IsPlaceHolder, false)

    ' Set the Local Trailer Count
    metaData.LocalTrailerCount = firstOf(i.LocalTrailerCount, 0)

    ' Set the Special Feature Count
    metaData.SpecialFeatureCount = firstOf(i.SpecialFeatureCount, 0)

    ' Set the Playback Position
	FillUserDataFromItem(metaData, i)

	releaseDate = i.PremiereDate
	if releaseDate = invalid then releaseDate = i.StartDate
	
	' Most people won't care about the exact release date of some types
	if i.Type = "Episode" then
		if releaseDate<> invalid
			metaData.ReleaseDate = formatDateStamp(releaseDate)
		end if
	else
		if releaseDate <> invalid
			metaData.ReleaseDate = left(releaseDate, 10)
		end if
	end If

    if i.RecursiveItemCount <> invalid
        metaData.NumEpisodes = i.RecursiveItemCount
    end if

    ' Set HD Flags
    if i.IsHD <> invalid
        metaData.HDBranded = i.IsHD
        metaData.IsHD = i.IsHD
    end if

    ' Set the Artist Name
    if i.Artists <> invalid And i.Artists[0] <> "" And i.Artists[0] <> invalid
        metaData.Artist = i.Artists[0]
	if i.AlbumArtist <> invalid and i.AlbumArtist <> ""
		metaData.Actors = i.AlbumArtist
	else
		metaData.Actors = i.Artists[0]
	end if
	if metaData.Actors <> ""
		metaData.Actors = metaData.Actors + " / "
	end if
    	if i.ProductionYear <> invalid and i.ProductionYear <> 0 and type(i.Productionyear) = "Integer"
		metaData.Actors = metaData.Actors + itostr(i.ProductionYear)
    	end if
	if metaData.Actors <> ""
		metaData.Actors = metaData.Actors + " / "
	end if
   	'if i.RecursiveItemCount <> invalid and metaData.Artist <> ""
	' 	metaData.Actors = metaData.Actors + Pluralize(i.RecursiveItemCount, "Track")
    	'end if
    else if i.AlbumArtist <> "" And i.AlbumArtist <> invalid
        metaData.Artist = i.AlbumArtist
	metaData.Actors = i.AlbumArtist
	metaData.AlbumArtist = i.AlbumArtist
    	if i.ProductionYear <> invalid and i.ProductionYear <> 0 and type(i.Productionyear) = "Integer"
		metaData.Actors = metaData.Actors + " / " + itostr(i.ProductionYear)
    	end if
   	'if i.RecursiveItemCount <> invalid and metaData.Artist <> ""
	'	metaData.Actors = metaData.Actors +" / " + Pluralize(i.RecursiveItemCount, "Track")
    	'end if
    else
        metaData.Artist = ""
    end if

    if i.PlayedPercentage <> invalid
			
        PlayedPercentage = i.PlayedPercentage
				
    else if i.UserData.PlaybackPositionTicks <> invalid and i.UserData.PlaybackPositionTicks <> ""
			
        if i.RunTimeTicks <> "" And i.RunTimeTicks <> invalid
            currentPosition = Int(((i.UserData.PlaybackPositionTicks).ToFloat() / 10000) / 1000)
            totalLength     = Int(((i.RunTimeTicks).ToFloat() / 10000) / 1000)
            if totalLength <> 0
                PlayedPercentage = Int((currentPosition / totalLength) * 100)
            else
                PlayedPercentage = 0
            end if
        else
            PlayedPercentage = 0
        end If
    else
        PlayedPercentage = 0
    end if

    if PlayedPercentage = 100
        PlayedPercentage = 0
    end if

    ' Set Unplayed Count
    UnplayedCount = i.UserData.UnplayedItemCount
	
	if UnplayedCount = invalid then UnplayedCount = 0

	isPlayed = i.UserData.Played

	if UnplayedCount > 0 then
		PlayedPercentage = 0
	end if

	' Don't show progress bars for these
	if i.Type = "MusicAlbum" or i.Type = "MusicArtist" then
		PlayedPercentage = 0
		isPlayed = false
	end if
	
	if i.type = "MusicAlbum"
		if i.AlbumArtist <> invalid and i.AlbumArtist <> ""
			album = i.AlbumArtist
		else
			album = i.Artists[0]
		end if
		albumLine = ""
		'if i.ProductionYear <> invalid and i.ProductionYear <> 0 then albumLine = albumLine + tostr(i.ProductionYear) + " / "
		'if i.RecursiveItemCount <> invalid then albumLine = albumLine + Pluralize(i.RecursiveItemCount, "Track")
		'if i.Artists <> invalid and i.Artists[0] <> invalid then albumLine = albumLine + " / " + Pluralize(i.Artists.Count(), "Artist")
		metadata.actors = album
	else if i.type = "MusicArtist" or i.Type = "MusicGenre" or i.Type = "Studio" and mode = "musicstudio" or i.type = "MusicStudio" Then
		text = ""
		'if i.SongCount <> invalid then text = text + Pluralize(i.SongCount, "Track")
		'if i.AlbumCount <> invalid then
		'	if text <> "" then text = text + " / "
		'	text = text + Pluralize(i.AlbumCount, "Album")
		'end if
		metadata.actors = text
	end if

	' Only display for these types
	if i.Type <> "Season" and i.Type <> "Series" and i.Type <> "BoxSet" then
		UnplayedCount = 0
	end if

	' Primary Image
    if imageType = 0 then

		if mode = "autosize" then
		
			if i.PrimaryImageAspectRatio <> invalid and i.PrimaryImageAspectRatio >= 1.35 then
				sizes = GetImageSizes("two-row-flat-landscape-custom")
			else if i.PrimaryImageAspectRatio <> invalid and i.PrimaryImageAspectRatio >= .95 then
				sizes = GetImageSizes("arced-square")
			else
				sizes = GetImageSizes("mixed-aspect-ratio-portrait")
			end if
			
		else
			sizes = GetImageSizes(style)
		end if
        

		if (mode = "seriesimageasprimary" or mode = "latestrow") And i.SeriesPrimaryImageTag <> "" And i.SeriesPrimaryImageTag <> invalid

            imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(i.SeriesId) + "/Images/Primary/0"

            metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.SeriesPrimaryImageTag, isPlayed, PlayedPercentage, UnplayedCount)
            metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.SeriesPrimaryImageTag, isPlayed, PlayedPercentage, UnplayedCount)
					
        else if i.ImageTags <> invalid And i.ImageTags.Primary <> "" And i.ImageTags.Primary <> invalid
				
            imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(i.Id) + "/Images/Primary/0"

            metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.ImageTags.Primary, isPlayed, PlayedPercentage, UnplayedCount)
            metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.ImageTags.Primary, isPlayed, PlayedPercentage, UnplayedCount)

        else if i.BackdropImageTags <> invalid and i.BackdropImageTags[0] <> "" And i.BackdropImageTags[0] <> invalid
				
            imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(i.Id) + "/Images/Backdrop/0"

            metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.BackdropImageTags[0], isPlayed, PlayedPercentage, UnplayedCount)
            metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.BackdropImageTags[0], isPlayed, PlayedPercentage, UnplayedCount)

        else if style = "two-row-flat-landscape-custom" or style = "flat-episodic-16x9"

            metaData.HDPosterUrl = GetViewController().getThemeImageUrl("hd-landscape.jpg")
            metaData.SDPosterUrl = GetViewController().getThemeImageUrl("sd-landscape.jpg")

        else if style = "mixed-aspect-ratio-square" or style = "arced-square" or style = "list" or style = "rounded-square-generic"

            metaData.HDPosterUrl = GetViewController().getThemeImageUrl("hd-square.jpg")
            metaData.SDPosterUrl = GetViewController().getThemeImageUrl("sd-square.jpg")

        else

            metaData.HDPosterUrl = GetViewController().getThemeImageUrl("hd-poster.jpg")
            metaData.SDPosterUrl = GetViewController().getThemeImageUrl("sd-poster.jpg")

        end if

    ' Thumb Image
    else if imageType = 1 then

        sizes = GetImageSizes("two-row-flat-landscape-custom")

        if i.ImageTags.Thumb <> "" And i.ImageTags.Thumb <> invalid
				
            imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(i.Id) + "/Images/Thumb/0"

            metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.ImageTags.Thumb, isPlayed, PlayedPercentage, UnplayedCount)
            metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.ImageTags.Thumb, isPlayed, PlayedPercentage, UnplayedCount)

        else if i.SeriesThumbImageTag <> "" And i.SeriesThumbImageTag <> invalid

            imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(i.SeriesId) + "/Images/Thumb/0"

            metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.SeriesThumbImageTag, isPlayed, PlayedPercentage, UnplayedCount)
            metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.SeriesThumbImageTag, isPlayed, PlayedPercentage, UnplayedCount)

        else if i.BackdropImageTags[0] <> "" And i.BackdropImageTags[0] <> invalid
				
            imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(i.Id) + "/Images/Backdrop/0"

            metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.BackdropImageTags[0], isPlayed, PlayedPercentage, UnplayedCount)
            metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.BackdropImageTags[0], isPlayed, PlayedPercentage, UnplayedCount)

        else if i.ImageTags.Primary <> "" And i.ImageTags.Primary <> invalid
				
            imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(i.Id) + "/Images/Primary/0"

            metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.ImageTags.Primary, isPlayed, PlayedPercentage, UnplayedCount)
            metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.ImageTags.Primary, isPlayed, PlayedPercentage, UnplayedCount)

        else 
            metaData.HDPosterUrl = GetViewController().getThemeImageUrl("hd-landscape.jpg")
            metaData.SDPosterUrl = GetViewController().getThemeImageUrl("sd-landscape.jpg")

        end if

    ' Backdrop Image
    else

        sizes = GetImageSizes("two-row-flat-landscape-custom")

        if i.BackdropImageTags[0] <> "" And i.BackdropImageTags[0] <> invalid
				
            imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(i.Id) + "/Images/Backdrop/0"

            metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.BackdropImageTags[0], isPlayed, PlayedPercentage, UnplayedCount)
            metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.BackdropImageTags[0], isPlayed, PlayedPercentage, UnplayedCount)

        else if i.ImageTags.Primary <> "" And i.ImageTags.Primary <> invalid
				
            imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(i.Id) + "/Images/Primary/0"

            metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.ImageTags.Primary, isPlayed, PlayedPercentage, UnplayedCount)
            metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.ImageTags.Primary, isPlayed, PlayedPercentage, UnplayedCount)

        else 
				
            metaData.HDPosterUrl = GetViewController().getThemeImageUrl("hd-landscape.jpg")
            metaData.SDPosterUrl = GetViewController().getThemeImageUrl("sd-landscape.jpg")

        end if

    end if

	if i.Type = "Episode" then
	
        ' Build Episode Information
        episodeInfo = ""

	if i.LocationType<> invalid then
        	if i.LocationType = "Virtual" then
	        	episodeInfo = m.VirtualType
        	end if
	end if

        ' Add Series Name
        if i.SeriesName <> invalid
            episodeInfo = episodeInfo + i.SeriesName
        end if

        ' Add Season Number
        if i.ParentIndexNumber <> invalid
            if episodeInfo <> ""
                episodeInfo = episodeInfo + " / "
            end if

            episodeInfo = episodeInfo + "Season " + itostr(i.ParentIndexNumber)
        end if

        ' Add Episode Number
        if i.IndexNumber <> invalid
            if episodeInfo <> ""
                episodeInfo = episodeInfo + " / "
            end if
                
            episodeInfo = episodeInfo + "Episode " + itostr(i.IndexNumber)

            ' Add Double Episode Number
            if i.IndexNumberEnd <> invalid
                episodeInfo = episodeInfo + "-" + itostr(i.IndexNumberEnd)
            end if
        end if

        ' Use Actors Area for Series / Season / Episode
        metaData.Actors = episodeInfo
	metaData.Categories = CreateObject("roArray", 3, true)
	if i.SeriesStudio <> invalid then metadata.Categories.Push(i.SeriesStudio)
	local = CreateObject("roDateTime")
	    if metaData.ReleaseDate <> Invalid and metaData.ReleaseDate <> "" then
		stamp = metaData.ReleaseDate + " 00:00:00"
		local.FromISO8601String(stamp)
	    	out = local.GetWeekday()
	    	if metaData.AirTime <> invalid and metaData.AirTime <> "" then out = out + " @ " + metaData.AirTime
	    	metadata.Categories.Push(out)
	    end if

	else
		FillActorsFromItem(metaData, i)
		FillCategoriesFromGenres(metaData, i)
	end if

	FillChaptersFromItem(metaData, i)

	if i.Type = "TvChannel"
		if i.CurrentProgram <> invalid
			if i.CurrentProgram.Name <> invalid
				metadata.Actors = i.CurrentProgram.Name
			end if
		end if
	else if i.MediaType = "Photo" then
		FillPhotoInfo(metaData, i)
	end if

    metaData.LocationType = firstOf(i.LocationType, "FileSystem")

    ' Setup Chapters
	
	addVideoDisplayInfo(metaData, i)

	if i.MediaType = "Audio" then SetAudioStreamProperties(metaData)

	if i.SeriesTimerId <> invalid And i.SeriesTimerId <> ""
        metaData.HDSmallIconUrl = GetViewController().getThemeImageUrl("SeriesRecording.png")
        metaData.SDSmallIconUrl = GetViewController().getThemeImageUrl("SeriesRecording.png")
    else if i.TimerId <> invalid And i.TimerId <> ""
        metaData.HDSmallIconUrl = GetViewController().getThemeImageUrl("Recording.png")
        metaData.SDSmallIconUrl = GetViewController().getThemeImageUrl("Recording.png")
    end if
	return metaData
	
End Function

Function WatchedLast(i as Object,description as String) as String
	if i.userData <> invalid
	  if i.UserData.PlayCount <> invalid then
		if description <> ""
			description = description + " / "
		end if
		description = description + "Played " + tostr(i.UserData.PlayCount) +"x"
	  end if
	  if i.UserData.LastPlayedDate <> invalid then
		if description <> ""
			description = description + " / "
 		end if

 		' fix timestamps GMT to local
		local = CreateObject("roDateTime")
		last = left(i.UserData.LastPlayedDate, 10) + " " + mid(i.UserData.LastPlayedDate,12,8)
		local.FromISO8601String(last)
		local.ToLocalTime()
		out = local.ToISOString()
		t = GetTimeString(local,0)
		description = description + "Last " + left(out, 10) + " at " + t
	  end if
	end if
	return description
End Function

Sub FillPhotoInfo(metaData as Object, item as Object)

	if item.ImageTags <> invalid And item.ImageTags.Primary <> "" And item.ImageTags.Primary <> invalid
				
		imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(item.Id) + "/Images/Primary/0"

		metaData.Url = BuildImage(imageUrl, invalid, invalid, item.ImageTags.Primary, false, 0, 0)
		
		metaData.Url = imageUrl
		
	end if
	
	metaData.TextOverlayUL = firstOf(item.Album, "")
	
	' Handled in PhotoPlayer
	'metaData.TextOverlayUR = "3 of 20"
	
	metaData.TextOverlayBody = metaData.Title

End Sub

Sub FillActorsFromItem(metaData as Object, item as Object)

		' Check For People, Grab First 3 If Exists
		if item.People <> invalid And item.People.Count() > 0
			metaData.Actors = CreateObject("roArray", 3, true)

			' Set Max People to grab Size of people array
			maxPeople = item.People.Count()-1

			' Check To Max sure there are 3 people
			if maxPeople > 2
				maxPeople = 2
			end if

			for actorCount = 0 to maxPeople
				if item.People[actorCount].Name <> "" And item.People[actorCount].Name <> invalid
					metaData.Actors.Push(item.People[actorCount].Name)
				end if
			end for
		end if

	
End Sub

Sub FillChaptersFromItem(metaData as Object, item as Object)

    if item.Chapters <> invalid

        metaData.Chapters = CreateObject("roArray", 5, true)
        chapterCount = 0

        for each c in item.Chapters
            chapterData = {}

            ' Set the chapter display title
            chapterData.Title = firstOf(c.Name, "Unknown")
            chapterData.ShortDescriptionLine1 = firstOf(c.Name, "Unknown")

            ' Set chapter time
            if c.StartPositionTicks <> invalid
                chapterPositionSeconds = Int(((c.StartPositionTicks).ToFloat() / 10000) / 1000)

                chapterData.StartPosition = chapterPositionSeconds
                chapterData.ShortDescriptionLine2 = formatTime(chapterPositionSeconds)
            end if

            ' Get Image Sizes
            sizes = GetImageSizes("flat-episodic-16x9")

            ' Check if Chapter has Image, otherwise use default
            if c.ImageTag <> "" And c.ImageTag <> invalid
			
                imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(item.Id) + "/Images/Chapter/" + itostr(chapterCount)

                chapterData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, c.ImageTag, false, 0)
                chapterData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, c.ImageTag, false, 0)

            else 
                chapterData.HDPosterUrl = GetViewController().getThemeImageUrl("hd-landscape.jpg")
                chapterData.SDPosterUrl = GetViewController().getThemeImageUrl("sd-landscape.jpg")

            end if

            ' Increment Count
            chapterCount = chapterCount + 1

            metaData.Chapters.push( chapterData )
        end for

    end if
	
End Sub

Sub FillUserDataFromItem(metaData as Object, item as Object)

	if item.UserData = invalid then return
	
    if item.UserData.PlaybackPositionTicks <> invalid and item.UserData.PlaybackPositionTicks <> ""
        positionSeconds = Int(((item.UserData.PlaybackPositionTicks).ToFloat() / 10000) / 1000)
        metaData.BookmarkPosition = positionSeconds
    else
        metaData.BookmarkPosition = 0
    end if

    if item.UserData.Played <> invalid And item.UserData.Played = true
        metaData.Watched = true
    else
        metaData.Watched = false
    end if

    if item.UserData.IsFavorite <> invalid And item.UserData.IsFavorite = true
        metaData.IsFavorite = true
    else
        metaData.IsFavorite = false
    end if
	
End Sub

Sub FillCategoriesFromGenres(metaData as Object, item as Object)

	metaData.Categories = CreateObject("roArray", 3, true)
	
    if item.Genres <> invalid And item.Genres.Count() > 0

        maxCategories = item.Genres.Count()-1

        if maxCategories > 2
            maxCategories = 2
        end if

        for categoryCount = 0 to maxCategories
            if item.Genres[categoryCount] <> "" And item.Genres[categoryCount] <> invalid
                metaData.Categories.Push(item.Genres[categoryCount])
            end if
        end for
    end if

End Sub

Function getTitle(i as Object) as String

	name = firstOf(i.Name, "Unknown")

	if i.Type = "Audio" Then

		if i.IndexNumber <> invalid then 
			name = tostr(i.IndexNumber) + ". " + name
		end if

		if i.ParentIndexNumber <> Invalid
			name = tostr(i.ParentIndexNumber) + "-" + name
		end if

	else if i.Type = "TvChannel" Then

		return firstOf(i.Number, "") + " " + firstOf(i.Name, "")

	else if i.Type = "Program" Then

		programTitle = ""
		if i.StartDate <> invalid And i.StartDate <> ""
			programTitle = getProgramDisplayTime(i.StartDate) + " - "
		end if

		' Add the Program Name
		programTitle = programTitle + firstOf(i.Name, "")

		return firstOf(programTitle, "")

	end If

	return name

End Function

'**********************************************************
'** getProgramDisplayTime
'**********************************************************

Function getProgramDisplayTime(dateString As String) As String

    dateTime = CreateObject("roDateTime")
    dateTime.FromISO8601String(dateString)
    return GetTimeString(dateTime, true)
	
End Function

Function getContentType(i as Object, mode as String) as String
	if i.Type = "CollectionFolder" Then
		return "MediaFolder"
	else if i.Type = "Genre" and mode = "moviegenre"
		return "MovieGenre"
	else if i.Type = "Genre" and mode = "tvgenre"
		return "TvGenre"
	else if i.Type = "Genre" and mode = "musicgenre"
		return "MusicGenre"
	else if i.Type = "Studio" and mode = "tvstudio"
		return "TvStudio"
	else if i.Type = "Studio" and mode = "moviestudio"
		return "MovieStudio"
	else if i.Type = "Studio" and mode = "musicstudio"
		return "MusicStudio"
	else if i.Type = "Audio" and mode = "musicfavorite"
		return "MusicFavorite"
	else if i.type = "Audio" and mode = "RecentlyPlayed"
		return "RecentlyPlayed"
	else if i.type = "Audio" and mode = "MostPlayed"
		return "MostPlayed"
	else if i.type = "Audio" and mode = "audiosearch"
		return "AudioSearch"
	else if i.type = "AudioPodcast" and mode = "podcastsearch"
		return "AudioPodcastSearch"
	else if mode = "localtrailers"
		return "LocalTrailers"
	end If
	return i.Type

End Function

function getShortDescriptionLine1(i as Object, mode as String) as String

	if i.Type = "Episode" Then

		if mode = "episodedetails" then return firstOf(i.Name, "Unknown")

		return firstOf(i.SeriesName, "Unknown")

	else if i.Type = "Recording" and mode = "recordinggroup" Then

		if i.EpisodeTitle <> invalid And i.EpisodeTitle <> ""
			return firstOf(i.EpisodeTitle, "Unknown")
		end if

	else if i.Type = "TvChannel" Then

		return firstOf(i.Number, "") + " " + firstOf(i.Name, "")
		
	end If

	return firstOf(i.Name, "Unknown")

End Function

Function getShortDescriptionLine2(i as Object, mode as String) as String
	'PrintAnyAA(4,i)
	if i.Type = "MusicAlbum" Then

		albumLine = ""
		'if i.ProductionYear <> invalid and i.ProductionYear <> 0 then albumLine = albumLine + tostr(i.ProductionYear) + " / "
		'if i.RecursiveItemCount <> invalid then albumLine = albumLine + Pluralize(i.RecursiveItemCount, "Track")
		'if i.Artists <> invalid and i.Artists[0] <> invalid then albumLine = albumLine + " / " + Pluralize(i.Artists.Count(), "Artist")
		'if albumLine <> "" then return albumLine
		if i.ArtistItems <> invalid
			if i.ArtistItems.count() > 0 then return i.artistItems[0].name
		end if
		if i.Artists <> invalid
			if i.Artists.count() > 0 then return i.arists[0]
		end if
		return "Unknown Artist"

	else if i.Type = "MusicArtist"  Then
		text = ""
		'if i.SongCount <> invalid then text = text + Pluralize(i.SongCount, "Track")
		'if i.AlbumCount <> invalid and i.AlbumCount <> 0  then
		'	if text <> "" then text = text + " / "
		'	text = text + Pluralize(i.AlbumCount, "Album")
		'end if
		return text

	else if (i.Type = "MusicGenre" or i.Type = "Studio") and (mode = "musicstudio" or i.type = "MusicStudio")
		text = ""
		'if i.SongCount <> invalid then text = text + Pluralize(i.SongCount, "Track")
		'if i.AlbumCount <> invalid then
			'if text <> "" then text = text + " / "
			'text = text + Pluralize(i.AlbumCount, "Album")
		'end if
		return text

	else if i.Type = "Genre" or i.Type = "Studio"

		'if (mode = "moviegenre" or mode = "moviestudio") and i.MovieCount <> invalid and type(i.MovieCount) = "Integer" then return Pluralize(i.MovieCount, "Movie")
		'if (mode = "tvgenre" or mode = "tvstudio") and i.SeriesCount <> invalid and type(i.SeriesCount) = "Integer" then return Pluralize(i.SeriesCount, "Show")
		'if i.RecursiveItemCount <> invalid then return Pluralize(i.RecursiveItemCount,"Item")
		return ""

	else if i.Type = "BoxSet" Then

		if i.ChildCount <> invalid then return Pluralize(i.ChildCount, "Movie")

	else if i.Type = "Episode" and mode = "episodedetails" Then

		episodeInfo = ""

		if i.LocationType<> invalid then
        		if i.LocationType = "Virtual" then
				episodeInfo = m.VirtualType
        		end if
		end if

		if i.ParentIndexNumber <> invalid then episodeInfo = episodeInfo + "Season " + itostr(i.ParentIndexNumber)

		' Add Episode Number
		if i.IndexNumber <> invalid

			if episodeInfo <> ""
				episodeInfo = episodeInfo + " / "
			end if
                
			episodeInfo = episodeInfo + "Episode " + itostr(i.IndexNumber)

			' Add Double Episode Number
			if i.IndexNumberEnd <> invalid
				episodeInfo = episodeInfo + "-" + itostr(i.IndexNumberEnd)
			end if
		end if

		' Set the Episode rating
		if i.OfficialRating <> "" And i.OfficialRating <> invalid
			if episodeInfo <> ""
				episodeInfo = episodeInfo + " / "
			end if
			episodeInfo = episodeInfo + firstOf(i.OfficialRating, "")
		end if

		' Set HD Video Flag
		if i.IsHD <> invalid
			if i.IsHD then 
				if episodeInfo <> ""
					episodeInfo = episodeInfo + " / "
				end if
				episodeInfo = episodeInfo + "HD" 
			end if
		end if

		if i.UserData.PlayCount <> invalid then
			if episodeInfo <> ""
				episodeInfo = episodeInfo + " / "
			end if
			episodeInfo = episodeInfo + "Played " + tostr(i.UserData.PlayCount) +"x"
		end if

		if i.UserData.LastPlayedDate <> invalid then
			if episodeInfo <> ""
				episodeInfo = episodeInfo + " / "
			end if

			' fix timestamps GMT to local
			local = CreateObject("roDateTime")
			last = left(i.UserData.LastPlayedDate, 10) + " " + mid(i.UserData.LastPlayedDate,12,8)
			local.FromISO8601String(last)
			local.ToLocalTime()
			out = local.ToISOString()
			t = GetTimeString(local,0)
			episodeInfo = episodeInfo + "Last on " + left(out, 10) + " at " + t
		end if
		return episodeInfo

	else if i.Type = "Episode" Then

		text = ""
		sea = ""
		if i.RunTimeTicks <> invalid and i.RunTimeTicks <> ""
            		textTime = formatTime(Int(((i.RunTimeTicks).ToFloat() / 10000) / 1000))
			shortrun = FirstOf(RegRead("prefAbbreviate"), "no")
			if shortrun = "yes" then
				r = CreateObject("roRegex","(\d+):(\d+):(\d+)","")
				match = r.match(textTime)
				if match.count() > 0 then
					hour = match[1]
					mi = match[2]
					se = 0
				else
					r = CreateObject("roRegex","(\d+):(\d+)","")
					match = r.match(textTime)
					if match.count() > 0 then
						hour = 0
						mi = match[1]
						se = match[2]
					else
						hour = 0
						mi = 0
						se = 0
					end if
				end if
				textTime = ""
				if tostr(hour) <> "0" then textTime = textTime + tostr(hour)+"h"
				if tostr(mi) <> "0" then textTime = textTime + tostr(mi)+"m"
				if tostr(se) <> "0" and tostr(mi) = "0" and tostr(hour) = "0" then textTime = textTime + tostr(se)+"s"
			end if
			text = text + textTime + " / "
		else if i.LocationType <> invalid then
			if i.LocationType = "Virtual" then
				text = text + m.VirtualType
			end if
		end if
		if i.ParentIndexNumber <> invalid then sea = sea + tostr(i.ParentIndexNumber)

		if i.IndexNumber <> invalid then
			sea = sea + "x" + tostr(i.IndexNumber)
			' Add Double Episode Number
			if i.IndexNumberEnd <> invalid
				sea = sea + "-" + tostr(i.IndexNumberEnd)
            		end if
		end if
		if sea <> "" then
			text = text + sea
			if i.Name <> invalid and i.Name <> "" then text = text + " - " + i.Name
		else
			if i.Name <> invalid and i.Name <> "" then text = text + i.Name
		end if
		return text

	else if i.Type = "Series" Then
		text = ""
		if i.ProductionYear <> invalid then text = text + tostr(i.ProductionYear)
            	if text <> ""
                	text = text + " / "
            	end if
		if mode <> "latestrow" and mode <> "latestrow2"
			if i.ChildCount <> invalid then text = text + Pluralize((i.ChildCount)," Season")
            		if text <> ""
                		text = text + " / "
            		end if
			if i.RecursiveItemCount <> invalid then text = text + Pluralize((i.RecursiveItemCount)," Episode")
		else
			if i.ChildCount <> invalid then text = text + Pluralize((i.ChildCount)," New Episode")
		end if
		return text

	else if i.Type = "Recording" and mode = "recordinggroup" Then

		if i.StartDate <> invalid And i.StartDate <> ""
			return mid(i.StartDate, 6, 5)
		end if

	else if i.Type = "Recording" Then

		episodeInfo = ""
		if i.StartDate <> invalid And i.StartDate <> ""
			episodeInfo = mid(i.StartDate, 6, 5) + ": "
		end if
            
		return episodeInfo + firstOf(i.EpisodeTitle, "")

	else if i.Type = "TvChannel" Then

		if i.CurrentProgram <> invalid and i.CurrentProgram.Name <> invalid
			return i.CurrentProgram.Name
		end if
			
	else if i.Type = "Program" Then

		programTime = ""
		
		if i.StartDate <> invalid And i.StartDate <> "" and i.EndDate <> invalid And i.EndDate <> ""
			programTime = getProgramDisplayTime(i.StartDate) + " - " + getProgramDisplayTime(i.EndDate)
		end if

		return programTime

	else if i.Type = "CollectionFolder" or i.Type = "PlaylistsFolder" or i.Type = "Playlist" Then

		collectionLine = ""
		if i.Type = "CollectionFolder" Then
			if i.CollectionType <> invalid And i.CollectionType <> "" then collectionLine = collectionLine + Ucase(left(tostr(i.CollectionType),1)) + right(tostr(i.CollectionType),len(tostr(i.CollectionType))-1)
			return collectionLine
		else collectionLine = "Playlist"
		end if
		if i.ChildCount <> invalid then collectionLine = collectionLine + " / " + Pluralize(i.ChildCount, "Item")
		return collectionLine

	else if i.MediaType = "Video" Then

		videoLine = ""
		if i.RunTimeTicks <> invalid and i.RunTimeTicks <> ""
            		textTime = formatTime(Int(((i.RunTimeTicks).ToFloat() / 10000) / 1000))
			shortrun = FirstOf(RegRead("prefAbbreviate"), "no")
			if shortrun = "yes" then
				r = CreateObject("roRegex","(\d+):(\d+):(\d+)","")
				match = r.match(textTime)
				if match.count() > 0 then
					hour = match[1]
					mi = match[2]
					se = 0
				else
					r = CreateObject("roRegex","(\d+):(\d+)","")
					match = r.match(textTime)
					if match.count() > 0 then
						hour = 0
						mi = match[1]
						se = match[2]
					else
						hour = 0
						mi = 0
						se = 0
					end if
				end if
				textTime = ""
				if tostr(hour) <> "0" then textTime = textTime + tostr(hour)+"h"
				if tostr(mi) <> "0" then textTime = textTime + tostr(mi)+"m"
				if tostr(se) <> "0" and tostr(mi) = "0" and tostr(hour) = "0" then textTime = textTime + tostr(se)+"s"
			end if
			videoLine = videoLine + textTime
		end if
		if i.ProductionYear <> invalid and i.ProductionYear <> 0
			if videoLine <> "" then videoLine = videoLine + " / "
			videoLine = videoLine + tostr(i.ProductionYear)
		end if
		if i.OfficialRating <> invalid
			if videoLine <> "" then videoLine = videoLine + " / " 
			videoLine = videoLine + tostr(i.OfficialRating)
		end if
        	if i.IsHD <> invalid
			if videoLine <> "" then videoLine = videoLine + " / " 
            		if i.IsHD then videoLine = videoLine + "HD" 
        	end if

        	if i.contentType = "LocalTrailers" or i.isTrailer = true
			if i.locationtype = "FileSystem" then 
				trInfo = "Local"
			else
				trInfo = "Remote"
			end if
			if videoLine <> ""
				videoLine = videoLine + " / "
			end if
			videoLine = videoLine + trInfo
		end if
		if i.userData <> invalid AND i.UserData.PlayCount <> invalid then
			if videoline <> "" then videoLine = videoLine + " / "
			videoLine = videoLine + tostr(i.UserData.PlayCount) + "x"
		end if
		return videoLine

	else if i.Type = "Audio" Then

		if i.Artists <> invalid AND i.Artists[0] <> invalid
			return tostr(i.Artists[0])
		else
			return "UNKNOWN ARTIST"
		end if

	else if i.type = "Video" or i.type = "MusicVideo" Then

		videoLine = ""
		if i.Duration <> invalid then
            		textTime = formatTime(Int(((i.RunTimeTicks).ToFloat() / 10000) / 1000))
			shortrun = FirstOf(RegRead("prefAbbreviate"), "no")
			if shortrun = "yes" then
				r = CreateObject("roRegex","(\d+):(\d+):(\d+)","")
				match = r.match(i.Duration)
				if match.count() > 0 then
					hour = match[1]
					mi = match[2]
					se = 0
				else
					r = CreateObject("roRegex","(\d+):(\d+)","")
					match = r.match(textTime)
					if match.count() > 0 then
						hour = 0
						mi = match[1]
						se = match[2]
					else
						hour = 0
						mi = 0
						se = 0
					end if
				end if
				textTime = ""
				if tostr(hour) <> "0" then textTime = textTime + tostr(hour)+"h"
				if tostr(mi) <> "0" then textTime = textTime + tostr(mi)+"m"
				if tostr(se) <> "0" and tostr(mi) = "0" and tostr(hour) = "0" then textTime = textTime + tostr(se)+"s"
			end if
			videoLine = VideoLine + textTime
		end if
        	if i.IsHD <> invalid
            		if i.IsHD then videoLine = videoLine + " / HD" 
        	end if
		if i.StreamFormat <> invalid then videoLine = videoLine + " / " + tostr(i.StreamFormat)
		return videoLine
	else if i.type = "Folder" then

		collectionLine = "Folder"
		if i.CollectionType <> invalid And i.CollectionType <> "" then collectionLine = collectionLine + " / " + Ucase(left(tostr(i.CollectionType),1)) + right(tostr(i.CollectionType),len(tostr(i.CollectionType))-1)
		if i.ChildCount <> invalid then collectionLine = collectionLine + " / " + Pluralize(i.ChildCount, "Item")
		return collectionLine
	else
		t = i.type
		s = CreateObject("roRegex","folder","i")
		if s.isMatch(t) then 'if i.type = "Folder" then
			collectionLine = "Folder"
			if i.CollectionType <> invalid And i.CollectionType <> "" then collectionLine = collectionLine + " / " + Ucase(left(tostr(i.CollectionType),1)) + right(tostr(i.CollectionType),len(tostr(i.CollectionType))-1)
			'if i.RecursiveItemCount <> invalid then collectionLine = collectionLine + " / " + Pluralize(i.RecursiveItemCount, "Item")
			return collectionLine
		end if
	end If
	if i.channelName <> invalid then return i.channelName
	return i.Type
End Function

function MissOrUp(i as Object) as String
	tr = CreateObject("roDateTime")
	if i.PremiereDate <> invalid
        	r = CreateObject("roRegex", "T", "")
		dt = r.Split(i.PremiereDate)
		releaseDate = dt[0]
	else
		releaseDate = i.StartDate
	end if

	' missorup is always episodes
        if releaseDate <> invalid
            rd = formatDateStamp(releaseDate)
	else
	    rd = "0"
        end if

	if i.AirTime <> Invalid and i.AirTime <> "" then
		hours = "00" : mins = "00"
		r = CreateObject("roRegex","(\d+):(\d+)","")
		match = r.match(i.AirTime)
		if match.count() > 0 then
			hour = match[1]
			mi = match[2]
			r = CreateObject("roRegex","pm","i")
			hour = hour.toInt()
			mi = mi.toInt()
			if r.IsMatch(i.AirTime) then hour = hour + 12
			hours = ZeroPad(itostr(hour))
			mins = ZeroPad(itostr(mi))
		end if
		stamp = rd + " " + hours + ":" + mins + ":00"
	else
		stamp = rd + " 00:00:00"
	end if
	tr.FromISO8601String(stamp)
	tr.ToLocalTime()
	t = tr.asSeconds()
	local = CreateObject("roDateTime")
	local.ToLocalTime()
	l = local.asSeconds()
	if l > t then
		tp = "[Missing] "
	else
		tp = "[Upcoming] "
	end if
	return tp
End function

Function getDescription(i as Object, mode as String) as String

	if i.Type = "Genre" or i.Type = "Studio" Then

		'if ( mode = "moviegenre" or mode = "moviestudio" ) and i.MovieCount <> invalid and type(i.MovieCount) = "Integer" then return Pluralize(i.MovieCount, "Movie")
		'if ( mode = "tvgenre" or mode = "tvstudio" ) and i.SeriesCount <> invalid and type(i.SeriesCount) = "Integer" then return Pluralize(i.SeriesCount, "Show")

	else if i.Type = "TvChannel" Then

        	if i.CurrentProgram <> invalid and i.CurrentProgram.Overview <> invalid
        		return i.CurrentProgram.Overview
        	end if
			
	else if i.Overview <> invalid Then
		reg = CreateObject("roRegex", chr(13), "")
		overview = reg.ReplaceAll(i.Overview,"")
		reg = CreateObject("roRegex", chr(10), "")
		overview = reg.ReplaceAll(overview," ")
		return overview
	end If

	return ""

End Function

function getDirector(i as Object, mode as String) as String

	if i.People <> invalid then
		for each person in i.People
			if person.Type = "Director" or person.Role = "Director" then
				
				return person.Name
			end if
		end for
	end if
	
	directorValue = ""
	
	return directorValue

End Function

Sub SetAudioStreamProperties(item as Object)

    ' Get Extension
	if item.MediaSources = invalid or item.MediaSources.Count() = 0 then return

	mediaSource = item.MediaSources[0]

    container = mediaSource.Container

	stream = CreateObject("roAssociativeArray")

	itemId = item.Id
	
	item.MediaSourceId = mediaSource.Id

	' Get the version number for checkminimumversion
	versionArr = getGlobalVar("rokuVersion")

	device = CreateObject("roDeviceInfo")
	audio = device.GetAudioDecodeInfo()
	
    ' Direct Playback mp3 and wma(plus flac for firmware 5.3 and above)
    If (container = "mp2") and audio.lookup("MP2") <> invalid
        item.Url = GetServerBaseUrl() + "/Audio/" + itemId + "/stream.mp2?static=true"
        item.StreamFormat = "mp2"
	item.playMethod = "DirectStream"
	item.canSeek = true

    Else If (container = "mp3") and audio.lookup("MP3") <> invalid
        item.Url = GetServerBaseUrl() + "/Audio/" + itemId + "/stream.mp3?static=true"
        item.StreamFormat = "mp3"
	item.playMethod = "DirectStream"
	item.canSeek = true

    Else If (container = "wav") and audio.lookup("LPCM") <> invalid
        item.Url = GetServerBaseUrl() + "/Audio/" + itemId + "/stream.wav?static=true"
        item.StreamFormat = "pcm"
	item.playMethod = "DirectStream"
	item.canSeek = true

    Else If (container = "wma") and audio.lookup("WMA") <> invalid
        item.Url = GetServerBaseUrl() + "/Audio/" + itemId + "/stream.wma?static=true"
        item.StreamFormat = "wma"
	item.playMethod = "DirectStream"
	item.canSeek = true

    Else If (container = "m4a" or container = "mka") and audio.lookup("AAC") <> invalid
        item.Url = GetServerBaseUrl() + "/Audio/" + itemId + "/stream.mp4?static=true"
        item.StreamFormat = "mp4"
	item.playMethod = "DirectStream"
	item.canSeek = true

    Else If (container = "mka") and audio.lookup("VORBIS") <> invalid
        item.Url = GetServerBaseUrl() + "/Audio/" + itemId + "/stream.mka?static=true"
        item.StreamFormat = "vorbis"
	item.playMethod = "DirectStream"
	item.canSeek = true
		
    Else If (container = "flac") And CheckMinimumVersion(versionArr, [5, 3]) and audio.lookup("FLAC") <> invalid
        item.Url = GetServerBaseUrl() + "/Audio/" + itemId + "/stream.flac?static=true"
        item.StreamFormat = "flac"
	item.playMethod = "DirectStream"
	item.canSeek = true

    'Else If (container = "aiff") or (container = "aif") And CheckMinimumVersion(versionArr, [5, 3]) and audio.lookup("ALAC") <> invalid
	'item.Url = GetServerBaseUrl() + "/Audio/" + itemId + "/stream.alac?static=true"
   	'item.StreamFormat = "alac"
	'item.playMethod = "DirectStream"
	'item.canSeek = true
    Else
        ' Transcode Play
        item.Url = GetServerBaseUrl() + "/Audio/" + itemId + "/stream.mp3?audioBitrate=320000&deviceId=" + getGlobalVar("rokuUniqueId", "Unknown")
        item.StreamFormat = "mp3"
	item.playMethod = "Transcode"
	item.canSeek = item.Length <> invalid
    End If
	
	accessToken = ConnectionManager().GetServerData(item.ServerId, "AccessToken")
		
	if firstOf(accessToken, "") <> "" then
		item.Url = item.Url + "&api_key=" + accessToken
	end if	

End Sub


'**********************************************************
'** getThemeMusic
'**********************************************************

Function getThemeMusic(itemId As String) As Object

    ' Validate Parameter
    if validateParam(itemId, "roString", "getThemeMusic") = false return invalid

    ' URL
    url = GetServerBaseUrl() + "/Items/" + HttpEncode(itemId) + "/ThemeSongs"

    ' Query
    query = {
        userid: getGlobalVar("user").Id
		InheritFromParent: "true"
    }

    ' Prepare Request
    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()
    request.BuildQuery(query)

    ' Execute Request
    response = request.GetToStringWithTimeout(10)
    if response <> invalid
		return parseItemsResponse(response, 0, "list")
    end if
    return invalid
End Function

Function convertItemPeopleToMetadata(people as Object) as Object

    contentList = CreateObject("roArray", 25, true)

    for each i in people
            
		metaData = {}

		metadata.ContentType = "ItemPerson"

		metadata.Title = firstOf(i.Name, "Unknown")
		metadata.Id = i.Id

        	metaData.Description = i.description
		metaData.Overview = i.description

		metaData.ShortDescriptionLine1 = metaData.Title

		sizes = GetImageSizes("arced-portrait")

		if i.PrimaryImageTag <> "" And i.PrimaryImageTag <> invalid
				
            imageUrl = GetServerBaseUrl() + "/Items/" + HttpEncode(i.Id) + "/Images/Primary/0"

            metaData.HDPosterUrl = BuildImage(imageUrl, sizes.hdWidth, sizes.hdHeight, i.PrimaryImageTag, false, 0, 0)
            metaData.SDPosterUrl = BuildImage(imageUrl, sizes.sdWidth, sizes.sdHeight, i.PrimaryImageTag, false, 0, 0)

        else
            metaData.HDPosterUrl = GetViewController().getThemeImageUrl("hd-poster.jpg")
            metaData.SDPosterUrl = GetViewController().getThemeImageUrl("sd-poster.jpg")
		end If

		if i.Role <> invalid and i.Role <> "" then
			metaData.ShortDescriptionLine2 = i.Role
		else if i.Type <> invalid then
			metaData.ShortDescriptionLine2 = i.Type
		end if

        contentList.push( metaData )
    end for

    return contentList
End Function


'**************************************************************
'** videoGetMediaDetails
'**************************************************************

Function GetFullItemMetadata(item, isForPlayback as Boolean, options as Object) as Object

	itemId = item.Id
	itemType = item.ContentType
	if itemid = invalid then return item

	Debug("Getting metadata for Id " + itemId)

    if itemType = "Program" then
	
		item = getLiveTvProgramMetadata(itemId)		
		
		if isForPlayback = true then
			item = getLiveTvChannel(item.ChannelId)
		end if
        
    else if itemType = "Recording" 
        item = getLiveTvRecording(itemId)
	else
		item = getVideoMetadata(itemId)
    end if

	if item <> invalid then
		if item.MediaType = "Video" or item.MediaType = "Audio" then
	
			if item.MediaSources <> invalid then
				item.StreamInfo = getStreamInfo(item.MediaSources[0], options) 
			end if
		end if

		if item.MediaType = "Video" and isForPlayback = true then
			addPlaybackInfo(item, options)
		end if
	end if
	
	return item

End Function

Sub addPlaybackInfo(item, options as Object)

	Debug("addPlaybackInfo item.Id: " + item.Id)
	
	' Seeing an extra space here when coming from remote control
	' We really should figure out why rather than fixing it here
	startPositionTicks = strTrim(tostr(firstOf(options.PlayStart, 0)) + "0000000")
	
	deviceProfile = getDeviceProfile(item)
	
	playbackInfo = getDynamicPlaybackInfo(item, deviceProfile, startPositionTicks, options.MediaSourceId, options.AudioStreamIndex, options.SubtitleStreamIndex)

	if validatePlaybackInfoResult(playbackInfo) = true then
		
		dynamicMediaSource = getOptimalMediaSource(item.MediaType, playbackInfo.MediaSources)
		
		if dynamicMediaSource <> invalid then
		
			if dynamicMediaSource.RequiresOpening = true then
			
				facade = CreateObject("roOneLineDialog")
				facade.SetTitle("Please wait...")
				facade.ShowBusyAnimation()
				facade.Show()
								
				liveStreamResult = getLiveStream(item.Id, playbackInfo.PlaySessionId, deviceProfile, startPositionTicks, dynamicMediaSource, options.AudioStreamIndex, options.SubtitleStreamIndex)
				
				facade.Close()

				liveStreamResult.MediaSource.enableDirectPlay = supportsDirectPlay(liveStreamResult.MediaSource)
				dynamicMediaSource = liveStreamResult.MediaSource
				
			end if
			
			addPlaybackInfoFromMediaSource(item, dynamicMediaSource, playbackInfo.PlaySessionId, options)
			
		else
			showPlaybackInfoErrorMessage("NoCompatibleStream")
		end if
		
	end if
End Sub

Sub addPlaybackInfoFromMediaSource(item, mediaSource, playSessionId, options as Object)

	streamInfo = getStreamInfo(mediaSource, options) 

	if streamInfo = invalid then return

	streamInfo.playSessionId = playSessionId 
	
	item.StreamInfo = streamInfo
	
	accessToken = firstOf(ConnectionManager().GetServerData(item.ServerId, "AccessToken"), "")

	' Setup Roku Stream
	' http://sdkdocs.roku.com/display/sdkdoc/Content+Meta-Data

	mediaSourceId = mediaSource.Id
	
	enableSelectableSubtitleTracks = true

	if streamInfo.PlayMethod = "DirectPlay" Then

		item.Stream = {
			url: mediaSource.Path
			contentid: "x-directstream"
			quality: false
		}

		' http://sdkdocs.roku.com/display/sdkdoc/Content+Meta-Data
		if mediaSource.Container = "mov" or mediaSource.Container = "m4v" then
			item.StreamFormat = "mp4"
		else
			item.StreamFormat = mediaSource.Container
		end if
		
	else if streamInfo.PlayMethod = "DirectStream" Then

		item.Stream = {
			url: GetServerBaseUrl() + "/Videos/" + item.Id + "/stream?static=true&mediaSourceId=" + mediaSourceId + "&api_key=" + accessToken,
			contentid: "x-directstream"
			quality: false
		}

		' http://sdkdocs.roku.com/display/sdkdoc/Content+Meta-Data
		if mediaSource.Container = "mov" or mediaSource.Container = "m4v" then
			item.StreamFormat = "mp4"
		else
			item.StreamFormat = mediaSource.Container
		end if
		
	else
	
		url = GetServerBaseUrl() + mediaSource.TranscodingUrl

		if streamInfo.SubtitleStream <> invalid then
		
			if firstOf(streamInfo.SubtitleStream.DeliveryMethod, "") <> "External" then
			
				enableSelectableSubtitleTracks = false
				
			else
				if streamInfo.SubtitleStream.IsExternalUrl = true then
					item.SubtitleUrl = streamInfo.SubtitleStream.DeliveryUrl
				else
					item.SubtitleUrl = GetServerBaseUrl() + streamInfo.SubtitleStream.DeliveryUrl
				end if
								
				item.SubtitleConfig = {
					ShowSubtitle: 1
					TrackName: item.SubtitleUrl
				}
			end if
			
		end if

		item.Stream = {
			url: url
			contentid: "x-hls"
			quality: false
		}

        item.StreamFormat = "hls"
        item.SwitchingStrategy = "full-adaptation"

	end if
	
	if streamInfo.Bitrate <> invalid then
		item.Stream.Bitrate = streamInfo.Bitrate / 1000
	end if

	isDisplayHd = getGlobalVar("displayType") = "HDTV"
	
	if item.IsHD = true And isDisplayHd then item.Stream.quality = true
	
	item.SubtitleTracks = []
	
	for each stream in mediaSource.MediaStreams
		if enableSelectableSubtitleTracks AND stream.Type = "Subtitle" and firstOf(stream.DeliveryMethod, "") = "External" then
		
			subtitleInfo = {
				Language: stream.Language
				TrackName: stream.DeliveryUrl
				Description: stream.Codec
			}
			
			if stream.IsExternalUrl <> true then
				subtitleInfo.TrackName = GetServerBaseUrl() + subtitleInfo.TrackName
			end if
								
			if subtitleInfo.Language = invalid then subtitleInfo.Language = "und"
			
			item.SubtitleTracks.push(subtitleInfo)
			
		end if
	end for
	
End Sub

Function getOptimalMediaSource(mediaType, mediaSources) 
	Force = FirstOf(regRead("prefPlayMethod"),"Auto")
	if Force = "Auto" or Force = "DirectPlay" then
		for each mediaSource in mediaSources
			mediaSource.enableDirectPlay = supportsDirectPlay(mediaSource)
			if mediaSource.enableDirectPlay = true or Force = "DirectPlay" then
				return mediaSource
			end if
		end for
	end if

	if Force = "Auto" or Force = "Direct" then	
		for each mediaSource in mediaSources
			if mediaSource.SupportsDirectStream = true or Force = "Direct" then
				return mediaSource
			end if
		end for
	end if

	if Force = "Auto" or left(Force,5) = "Trans"
		for each mediaSource in mediaSources
			if mediaSource.SupportsTranscoding = true or left(Force,5) = "Trans" then
				return mediaSource
			end if
		end for
	end if
	createDialog("Media Source Error!", "No Optimal Media Source Found. (invalid)", "OK", true)
	return invalid

End Function

Function supportsDirectPlay(mediaSource)

	if mediaSource.SupportsDirectPlay = true and mediaSource.Protocol = "Http" then

		' TODO: Need to verify the host is going to be reachable
		return true
	end if

	return false
			
End Function

Function validatePlaybackInfoResult(playbackInfo)

	if firstOf(playbackInfo.ErrorCode, "") <> "" then
		showPlaybackInfoErrorMessage(errorCode)
		return false
	end if
	
	return true
	
End Function

function showPlaybackInfoErrorMessage(errorCode)

	message = ""
	
	if errorCode = "NotAllowed" then
		message = "You're currently not authorized to play this content. Please contact your system administrator for details."
	else if errorCode = "NoCompatibleStream" then
		message = "No compatible streams are currently available. Please try again later or contact your system administrator for details."
	else if errorCode = "RateLimitExceeded" then
		message = "Your playback rate limit has been exceeded. Please contact your system administrator for details."
	else
		message = "There was an error processing the request. Please try again later."
	end if
	
	createDialog("Playback Error!", message, "OK", true)
	
End Function

function getDynamicPlaybackInfo(item, deviceProfile, startPositionTicks, mediaSourceId, audioStreamIndex, subtitleStreamIndex) 

	Debug("getDynamicPlaybackInfo itemId: " + item.Id)
	
	maxVideoBitrate = firstOf(RegRead("prefVideoQuality"), "3200")
	maxVideoBitrate = maxVideoBitrate.ToInt() * 1000
	force = firstOf(regRead("prefPlayMethod"),"Auto")
	if item <> invalid
        	if item.LocationType = "Remote"
			maxVideoBitrate = firstOf(RegRead("prefremoteVideoQuality"), "3200")
			maxVideoBitrate = maxVideoBitrate.ToInt() * 1000
		else if item.ContentType = "Program"
			maxVideoBitrate = firstOf(RegRead("preflivetvVideoQuality"), "3200")
			maxVideoBitrate = maxVideoBitrate.ToInt() * 1000
		end if

		if item.mediasources <> invalid and force = "Trans-DS"
			for each mediasource in item.mediasources[0].MediaStreams
				if mediasource.Type = "Video"
					if lcase(mediasource.codec) = "h264"
						if mediasource.bitrate <> invalid
							maxVideoBitrate = mediasource.bitrate - 1
						end if
					end if
				end if
			end for
		end if
	end if
	
	postData = {
		DeviceProfile: deviceProfile
	}

	query = {
		StartTimeTicks: startPositionTicks
		MaxStreamingBitrate: maxVideoBitrate
	}

	if audioStreamIndex <> invalid then 
		query.AudioStreamIndex = audioStreamIndex
	end if
	
	if subtitleStreamIndex <> invalid then 
		query.SubtitleStreamIndex = subtitleStreamIndex
	end if
	
	if mediaSourceId <> invalid then
		query.MediaSourceId = mediaSourceId
	end if

    url = GetServerBaseUrl() + "/Items/" + item.Id + "/PlaybackInfo?UserId=" + getGlobalVar("user").Id

	for each key in query
		url = url + "&" + key +"=" + tostr(query[key])
	end for

	Debug("getDynamicPlaybackInfo url: " + url)
	
    ' Prepare Request
    request = HttpRequest(url)
    request.AddAuthorization()
	request.ContentType("json")

	json = SimpleJSONBuilder(postData)
    response = request.PostFromStringWithTimeout(json, 10)

	if response = invalid
	createDialog("Response Error!", "No Dyanmic Playback info Found. (invalid)", "OK", true)
        return invalid
    else
	
		fixedResponse = normalizeJson(response)
        jsonObj     = ParseJSON(fixedResponse)	
        
		return jsonObj
		
    end if
	
End Function

function getLiveStream(itemId, playSessionId, deviceProfile, startPositionTicks, mediaSource, audioStreamIndex, subtitleStreamIndex)

	maxVideoBitrate = firstOf(RegRead("preflivetvVideoQuality"), "3200")
	maxVideoBitrate = maxVideoBitrate.ToInt() * 1000

	postData = {
		DeviceProfile: deviceProfile
		OpenToken: mediaSource.OpenToken
	}

	query = {
		StartTimeTicks: startPositionTicks
		ItemId: itemId
		MaxStreamingBitrate: maxVideoBitrate
		PlaySessionId: playSessionId
	}

	if audioStreamIndex <> invalid then 
		query.AudioStreamIndex = audioStreamIndex
	end if
	
	if subtitleStreamIndex <> invalid then 
		query.SubtitleStreamIndex = subtitleStreamIndex
	end if

    url = GetServerBaseUrl() + "/LiveStreams/Open?UserId=" + getGlobalVar("user").Id

	for each key in query
		url = url + "&" + key +"=" + tostr(query[key])
	end for

	' Prepare Request
    request = HttpRequest(url)
    request.AddAuthorization()
	request.ContentType("json")

	json = SimpleJSONBuilder(postData)
    response = request.PostFromStringWithTimeout(json, 30)

	if response = invalid
		createDialog("Response Error!", "No Live Stream Found. (invalid)", "OK", true)
        return invalid
    else
	
		fixedResponse = normalizeJson(response)
        jsonObj     = ParseJSON(fixedResponse)	
        
		return jsonObj
		
    end if
	
End Function

'**********************************************************
'** Format Time From Seconds
'**********************************************************

Function formatTime(seconds As Integer) As String
    if validateParam(seconds, "roInt", "formatTime") = false return -1

    textTime = ""
    hasHours = false

    ' Special Check For Zero
    if seconds < 60
        return "0:" + ZeroPad(itostr(seconds))
    end if
    
    ' Hours
    if seconds >= 3600
        textTime = textTime + itostr(seconds / 3600) + ":"
        hasHours = true
        seconds = seconds Mod 3600
    end if
    
    ' Minutes
    if seconds >= 60
        if hasHours
            textTime = textTime + ZeroPad(itostr(seconds / 60)) + ":"
        else
            textTime = textTime + itostr(seconds / 60) + ":"
        end if
        
        seconds = seconds Mod 60
    else
        if hasHours
            textTime = textTime + "00:"
        end if
    end if

    ' Seconds
    textTime = textTime + ZeroPad(itostr(seconds))

    return textTime
End Function