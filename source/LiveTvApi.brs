'******************************************************
' getDefaultLiveTvTimer
'******************************************************

Function getDefaultLiveTvTimer(programId As String) As Object
    
	url = GetServerBaseUrl() + "/LiveTv/Timers/Defaults"

    query = {
        ProgramId: programId
    }

    request = HttpRequest(url)
    request.ContentType("json")
    request.AddAuthorization()
    request.BuildQuery(query)

    response = request.GetToStringWithTimeout(10)
	
    if response <> invalid
	
        return ParseJSON(response)
		
    end if

    return invalid
	
End Function



'**********************************************************
'** cancelLiveTvTimer
'**********************************************************

Function cancelLiveTvTimer(timerId As String) As Boolean
    
	url = GetServerBaseUrl() + "/LiveTv/Timers/" + HttpEncode(timerId)

    request = HttpRequest(url)
    request.AddAuthorization()
    request.SetRequest("DELETE")

    response = request.PostFromStringWithTimeout("", 5)
	
    return response <> invalid
	
End Function


'**********************************************************
'** deleteLiveTvRecording
'**********************************************************

Function OLDdeleteLiveTvRecording(recordingId As String) As Boolean

    url = GetServerBaseUrl() + "/LiveTv/Recordings/" + HttpEncode(recordingId)

    request = HttpRequest(url)
    request.AddAuthorization()
    request.SetRequest("DELETE")

    response = request.PostFromStringWithTimeout("", 5)
	
    return response <> invalid
	
End Function

'**********************************************************
'** createLiveTvTimer
'**********************************************************

Function createLiveTvTimer(timerObj As Object) As Boolean

    url = GetServerBaseUrl() + "/LiveTv/Timers"

    request = HttpRequest(url)
    request.AddAuthorization()
	request.ContentType("json")

	json = SimpleJSONBuilder(timerObj)
	
    response = request.PostFromStringWithTimeout(json, 5)
	
    return response <> invalid
	
End Function

'**********************************************************
'** deleteAnyItem
'**********************************************************

Function deleteLiveTvRecording(ContentType As String, ItemId As String) As Boolean

    loadingDialog = CreateObject("roOneLineDialog")
    loadingDialog.SetTitle("Deleting item...")
    loadingDialog.ShowBusyAnimation()
    loadingDialog.Show()

    if ContentType = "Recording" then
    	url = GetServerBaseUrl() + "/LiveTv/Recordings/" + HttpEncode(ItemId)
    else
    	url = GetServerBaseUrl() + "/Items/" + HttpEncode(ItemId)
    end if
    request = HttpRequest(url)
    request.AddAuthorization()
    request.SetRequest("DELETE")

    response = request.PostFromStringWithTimeout("", 5)
    loadingDialog.Close()
    if response <> invalid then
        createDialog("Success", "The item was successfully deleted.", "", true)
    else
        createDialog("Error", "Error occured. The item was not deleted. Sorry.", "", true)
    end if
    return response <> invalid
	
End Function
