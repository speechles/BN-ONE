'******************************************************
' Creates the capabilities object that is reported to Emby servers
'******************************************************

Function getDirectPlayProfiles()

	profiles = []

	versionArr = getGlobalVar("rokuVersion")
	' init audio profiles
	audioContainers = ""
	mp4Audio = ""
	mkvAudio = ""

	' firmware 6.1 and greater
        If CheckMinimumVersion(versionArr, [6, 1]) then
	    surroundSound = getGlobalVar("SurroundSound")
	    audioOutput51 = getGlobalVar("audioOutput51")
	    surroundSoundDCA = getGlobalVar("audioDTS")
	else
	' legacy
	    surroundSound = SupportsSurroundSound(false, false)

	    audioOutput51 = getGlobalVar("audioOutput51")
	    surroundSoundDCA = surroundSound AND audioOutput51 'AND (RegRead("fivepointoneDCA", "preferences", "1") = "1")
	    surroundSound = surroundSound AND audioOutput51 'AND (RegRead("fivepointone", "preferences", "1") = "1")
	end if

	device = CreateObject("roDeviceInfo")
	audio = device.GetAudioDecodeInfo()
	if FindMemberFunction(device, "CanDecodeVideo") <> invalid then
		supports4kcodec = (device.CanDecodeVideo({codec: "hevc"}).result = true or device.CanDecodeVideo({codec: "vp9"}).result = true)
	else
		supports4kcodec = false
	end if

	' if private mode enabled disable surround sound
	private = FirstOf(regRead("prefprivate"),"0")
	if private = "1" then
		surroundSound = false
	    	audioOutput51 = false
	    	surroundSoundDCA = false
	end if

	rokuTV = device.GetDisplayProperties()
	isRokuTV = rokuTV.internal
	if isRokuTV then debug("RokuTV Support: Enabled")

	autoDDplus = firstOf(RegRead("prefddplus"), "1")
	if autoDDplus = "1"
		audioDDPlus = FirstOf(getGlobalVar("audioDDPlus"), false)
	else
		audioDDPlus = false
	end if

	' preferences
        truehd = firstOf(RegRead("truehdtest"), "0")
	DTStoAC3 = firstOf(RegRead("prefDTStoAC3"), "0")
	directFlash = firstOf(RegRead("prefdirectFlash"), "0")


	force = firstOf(regRead("prefPlayMethod"),"Auto")
	if force <> "Auto" then
		debug("Forcing "+force+" no capabilities required!")
	else

	  if audio.lookup("LPCM") <> invalid
		audioContainers = audioContainers + ",raw"
		mkvAudio = mkvAudio + ",lpcm"
		mp4Audio = mp4Audio + ",lpcm"
	  end if

	  if audio.lookup("AAC") <> invalid
		audioContainers = audioContainers + ",mp4,mka,m4a"
		mkvAudio = mkvAudio + ",aac"
		mp4Audio = mp4Audio + ",aac"
	  end if

	  if audio.lookup("MP3") <> invalid
		audioContainers = audioContainers + ",mp3"
		mkvAudio = mkvAudio + ",mp3"
		mp4Audio = mp4Audio + ",mp3"
	  end if

	  if audio.lookup("MPEG2") <> invalid
		audioContainers = audioContainers + ",mp2"
		mkvAudio = mkvAudio + ",mp2"
		mp4Audio = mp4Audio + ",mp2"
	  end if

	  if audio.lookup("WMA") <> invalid
		audioContainers = audioContainers + ",wma,asf"
		mp4Audio = mp4audio + ",wma"
		mkvAudio = mkvAudio + ",wma"
	  end if

	  if audio.lookup("WMAPRO") <> invalid
		mp4Audio = mp4audio + ",wmapro"
		mkvAudio = mkvAudio + ",wmapro"
	  end if

	  ' flac and alac need version check
	  if CheckMinimumVersion(versionArr, [5, 3]) then
		audioContainers = audioContainers + ",wav"
		if audio.lookup("flac") <> invalid
			audioContainers = audioContainers + ",flac"
			mkvAudio = mkvAudio + ",flac"
		end if
		if audio.lookup("alac") <> invalid
			mp4Audio = mp4Audio + ",alac"
			mkvAudio = mkvAudio + ",alac"
		end if
	  end if

	  ' VORBIS is listed, but not supported yet or some weird shit
	  ' so we can list it, just cant uncomment this.. stupid roku
	  if audio.lookup("VORBIS") <> invalid
		mp4Audio = mp4audio + ",vorbis"
		mkvAudio = mkvAudio + ",vorbis"
	  end if

	  if audio.lookup("OPUS") <> invalid
		mp4Audio = mp4audio + ",opus"
		mkvAudio = mkvAudio + ",opus"
	  end if

	  ' strip comma off front
	  audioContainers = right(audioContainers,audioContainers.len()-1)

	  profiles.push({
		Type: "Audio"
		Container: audioContainers
	  })
	  debug("Supported Audio Containers: "+audioContainers)
	
	  if surroundSound then
		mp4Audio = mp4Audio + ",ac3"
	  end if
	  if audioDDPlus then
		mp4Audio = mp4Audio + ",eac3"
	  end if

	  mp4Video = "h264,mpeg4"
	  mp4Container = "mp4,mov,m4v"

	  ' force flash support directplay
	  if directFlash = "1" then
		mp4Container = mp4Container + ",flv,f4v"
	  end if

	  ' roku 4 has support for hevc and vp9
	  if supports4kcodec
		mp4Video = mp4Video + ",hevc,vp9"
	  end if

	  ' rokuTV allows mpeg2 support
	  if isRokuTV then
		mp4Video = mp4Video + ",mpeg2,mpeg2video,mpeg1,mpeg1video"
	  end if

	  ' strip comma off front
	  mp4Audio = right(mp4Audio,mp4Audio.len()-1)

	  profiles.push({
		Type: "Video"
		Container: mp4Container
		VideoCodec: mp4Video
		AudioCodec: mp4Audio
	  })
	  debug("Supported MP4 Containers: "+mp4Container)
	  debug("Supported MP4 V-Codecs: "+mp4Video)
	  debug("Supported MP4 A-Codecs: "+mp4Audio)

	  if CheckMinimumVersion(versionArr, [5, 1]) then
	
		if surroundSound then
            		mkvAudio = mkvAudio + ",ac3"
        	end if

        	if surroundSoundDCA and DTStoAC3 = "0" then
            		mkvAudio = mkvAudio + ",dca"
        	end if
	  	if audioDDPlus then
			mkvAudio = mkvAudio + ",eac3"
		end if

        	if truehd = "1" then
            		mkvAudio = mkvAudio + ",truehd"
        	end if
	  end if

	  mkvVideo = "h264,mpeg4"

	  ' roku 4 has support for hevc and vp9
	  if supports4kcodec
		mkvVideo = mkvVideo + ",hevc,vp9"
	  end if

	  ' rokuTV allows mpeg2 support
	  if isRokuTV then
		mkvVideo = mkvVideo + ",mpeg2,mpeg2video,mpeg1,mpeg1video"
	  end if

	  ' strip comma off front
	  mkvAudio = right(mkvAudio,mkvAudio.len()-1)

          profiles.push({
		Type: "Video"
		Container: "mkv"
		VideoCodec: mkvVideo
		AudioCodec: mkvAudio
	  })
	  debug("Supported MKV Containers: mkv")
	  debug("Supported MKV V-Codecs: "+mkvVideo)
	  debug("Supported MKV A-Codecs: "+mkvAudio)
	end if

	return profiles

End Function

Function getTranscodingProfiles()

	versionArr = getGlobalVar("rokuVersion")
    	device = CreateObject("roDeviceInfo")
	audio = device.GetAudioDecodeInfo()
	onlyh264 = firstOf(RegRead("prefonlyh264"), "1")
	onlyAAC = firstOf(RegRead("prefonlyAAC"), "1")
	Unknown = firstOf(RegRead("prefTransAC3"), "aac")
	forceSurround = firstOf(RegRead("prefforceSurround"),"0")
	AACconv = firstOf(RegRead("prefConvAAC"), "aac")
	DefAudio = firstOf(RegRead("prefDefAudio"), "aac")
	versionArr = getGlobalVar("rokuVersion")
	private = FirstOf(regRead("prefprivate"),"0")
	autoDDplus = firstOf(RegRead("prefddplus"), "1")
	if autoDDplus = "1"
		audioDDPlus = FirstOf(getGlobalVar("audioDDPlus"), false)
	else
		audioDDPlus = false
	end if

	' firmware 6.1 and greater
        If CheckMinimumVersion(versionArr, [6, 1]) then
	    surroundSound = getGlobalVar("SurroundSound")
	    audioOutput51 = getGlobalVar("audioOutput51")
	    surroundSoundDCA = getGlobalVar("audioDTS")
	else
	    surroundSound = SupportsSurroundSound(false, false)

	    audioOutput51 = getGlobalVar("audioOutput51")
	    surroundSoundDCA = surroundSound AND audioOutput51 'AND (RegRead("fivepointoneDCA", "preferences", "1") = "1")
	    surroundSound = surroundSound AND audioOutput51 'AND (RegRead("fivepointone", "preferences", "1") = "1")
	end if
	if FindMemberFunction(device, "CanDecodeVideo") <> invalid then
		supportshevc = (device.CanDecodeVideo({codec: "hevc"}).result = true)
	else
		supportshevc = false
	end if

	if private = "1" then
		surroundsound = false
		audioOutput51 = false
	    	surroundSoundDCA = false
	end if

	profiles = []
	
	profiles.push({
		Type: "Audio"
		Container: "mp3"
		AudioCodec: "mp3"
		Context: "Streaming"
		Protocol: "Http"
	})
	
	' pass in codecs
	t = m.Codecs
	' the default
	transAudio = DefAudio

	' unknown audio possibly pass ac3
	if t = invalid then transAudio = Unknown

	' force surround can happen if surroundsound is found
	if forceSurround = "1" and surroundSound then transAudio = "ac3"


	' 2.0 channel codecs
	if onlyAAC = "0" and t <> invalid then
	s = CreateObject("roRegex","mp3","i")
		if s.isMatch(t) then
			if audio.lookup("mp3") <> invalid
				transAudio = "mp3"
			end if
		else
			s = CreateObject("roRegex","mp2","i")
			if s.isMatch(t) then
				if audio.lookup("MPEG2") <> invalid
					transAudio = "mp2"
				end if
			end if
		end if
	end if

	' 2.0/5.1 codecs
	if t <> invalid then

		' aac direct-stream copies in case we are using ac3
		' respect the fourceSurround always with aac
		s = CreateObject("roRegex","aac","i")
		if s.isMatch(t) and forceSurround = "0" then
			if audio.lookup("AAC") <> invalid
				transAudio = AACconv
			end if
		end if

		' firmware check flac/alac
		if CheckMinimumVersion(versionArr, [5, 3]) then
			' flac direct-stream copies
			s = CreateObject("roRegex","flac","i")
			if s.isMatch(t) then
				if audio.lookup("FLAC") <> invalid
					transAudio = transAudio + ",flac"
				end if
			end if
			' alac direct-stream copies
			s = CreateObject("roRegex","alac","i")
			if s.isMatch(t) then
				if audio.lookup("ALAC") <> invalid
					transAudio = transAudio + ",alac"
				end if
			end if
		end if

		' lpcm direct-stream copies
		s = CreateObject("roRegex","lpcm","i")
		if s.isMatch(t) then
			transAudio = transAudio + ",lpcm"
		end if
	end if

	' surround sound codecs
	if surroundSound then
	    if t <> invalid then
		' dts/ac3/truehd direct stream as ac3
		s = CreateObject("roRegex","dts","i")
	        r = CreateObject("roRegex","ac3","i")
	        q = CreateObject("roRegex","truehd","i")
		p = CreateObject("roRegex","eac3","i")
	        if q.isMatch(t) or r.isMatch(t) 'or s.isMatch(t) or p.isMatch(t)
			transAudio = "ac3"
			if audioDDPlus AND p.isMatch(t)
				transAudio = transAudio + ",eac3"
	        	end if
		end if
	    end if
        end if

		' vorbis cant direct-stream copies
		'if audio.lookup("VORBIS") <> invalid and t <> invalid then
		'	s = CreateObject("roRegex","vorbis","i")
		'	if s.isMatch(t) then
		'		transAudio = transAudio + ",vorbis"
		'	end if
		'end if

	' pass in container
	u = m.Extension

	' the default
	transVideo = "h264"

	' h264 / mpeg4
	if u <> invalid then
		' mkv container with mpeg4 cannot be xvid/divx
		r = CreateObject("roRegex","mkv","i")
	        if r.isMatch(u) or onlyh264 = "1" then
			' do nothing mpeg4 in mkv should not pass
		else
			' mpeg4 is not in mkv
			p = CreateObject("roRegex","mpeg4","i")
			if p.isMatch(t) then
				transVideo = "mpeg4"
			end if
		end if
	end if

	force = firstOf(regRead("prefPlayMethod"),"Auto")
	' hevc
	if t <> invalid then
		v = CreateObject("roRegex","hevc","i")
	        if v.isMatch(t) and force <> "Trans-DS"
			if supportshevc then transVideo = "hevc"
		end if
	end if

	profiles.push({
		Type: "Video"
		Container: "ts"
		AudioCodec: transAudio
		VideoCodec: transVideo
		Context: "Streaming"
		Protocol: "Hls"
	})
	debug("Transcoding V-Codec: "+transVideo)
	debug("Transcoding A-Codec: "+transAudio)
	return profiles

End Function

Function getCodecProfiles()

	profiles = []
	' deprecated ... this is set by a preference now.
	'maxRefFrames = firstOf(getGlobalVar("maxRefFrames"), 12)
	playsAnamorphic = firstOf(getGlobalVar("playsAnamorphic"), false)
        truehd = firstOf(RegRead("truehdtest"), "0")
	device = CreateObject("roDeviceInfo")
	versionArr = getGlobalVar("rokuVersion")
	framerate = firstOf(regRead("prefmaxframe"), "30")
	Go4k = firstOf(RegRead("prefgo4k"), "0")
	FourkReady = CanPlay4k()
	Force = firstOf(RegRead("prefPlayMethod"), "Auto")
	directFlash = firstOf(RegRead("prefdirectFlash"), "0")
	if directFlash = "1" and framerate = "30" then
		framerate = "31"
	end if
	maxlevel = firstOf(RegRead("prefmaxlevel"), "51")
	rokuTV = device.GetDisplayProperties()
	isRokuTV = rokuTV.internal
	if FindMemberFunction(device, "CanDecodeVideo") <> invalid then
		supports4kcodec = (device.CanDecodeVideo({codec: "hevc"}).result = true or device.CanDecodeVideo({codec: "vp9"}).result = true)
	else
		supports4kcodec = false
	end if
	audio = device.GetAudioDecodeInfo()

	if left(Force,5) = "Trans" then
		framerate = 30
	end if

	if getGlobalVar("displayType") <> "HDTV" or firstOf(RegRead("prefreso"), "auto") = "720p"
		maxWidth = "1280"
		maxHeight = "720"
	else if firstOf(RegRead("prefreso"), "auto") = "1080p"
		maxWidth = "1920"
		maxHeight = "1080"
	else
		if Go4k = "0" then
			maxWidth = "1920"
			maxHeight = "1080"
		else
        		maxWidth = "3840"
        		maxHeight = "2160"
		end if
	end if

	if supports4kcodec
        	max4kWidth = "3840"
        	max4kHeight = "2160"
	end if

	' firmware 6.1 and greater
        If CheckMinimumVersion(versionArr, [6, 1]) then
	    surroundSound = getGlobalVar("SurroundSound")
	    audioOutput51 = getGlobalVar("audioOutput51")
	    surroundSoundDCA = getGlobalVar("AudioDTS")
	else
	    surroundSound = SupportsSurroundSound(false, false)

	    audioOutput51 = getGlobalVar("audioOutput51")
	    surroundSoundDCA = surroundSound AND audioOutput51 'AND (RegRead("fivepointoneDCA", "preferences", "1") = "1")
	    surroundSound = surroundSound AND audioOutput51 'AND (RegRead("fivepointone", "preferences", "1") = "1")
	end if
	autoDDplus = firstOf(RegRead("prefddplus"), "1")
	if autoDDplus = "1"
		audioDDPlus = FirstOf(getGlobalVar("audioDDPlus"), false)
	else
		audioDDPlus = false
	end if
	
	' private listening nuke all surround sound
	private = FirstOf(regRead("prefprivate"),"0")
	if private = "1" then
		surroundsound = false
		audioOutput51 = false
	    	surroundSoundDCA = false
		audioDDplus = false
	end if

        MaxRef = firstOf(RegRead("prefmaxrefs"), "12")

	h264Conditions = []
	h264Conditions.push({
		Condition: "LessThanEqual"
		Property: "RefFrames"
		Value: tostr(maxRef)
		IsRequired: false
	})
	h264Conditions.push({
		Condition: "LessThanEqual"
		Property: "VideoBitDepth"
		Value: "8"
		IsRequired: false
	})
	h264Conditions.push({
		Condition: "LessThanEqual"
		Property: "Width"
		Value: maxWidth
		IsRequired: true
	})
	h264Conditions.push({
		Condition: "LessThanEqual"
		Property: "Height"
		Value: maxHeight
		IsRequired: true
	})
	h264Conditions.push({
		Condition: "LessThanEqual"
		Property: "VideoFramerate"
		Value: framerate
		IsRequired: false
	})
	h264Conditions.push({
		Condition: "EqualsAny"
		Property: "VideoProfile"
		Value: "high|main|baseline|constrained baseline"
		IsRequired: false
	})
	h264Conditions.push({
		Condition: "LessThanEqual"
		Property: "VideoLevel"
		Value: maxlevel
		IsRequired: false
	})
	if playsAnamorphic = false Then
	h264Conditions.push({
		Condition: "Equals"
		Property: "IsAnamorphic"
		Value: "false"
		IsRequired: false
	})
	end if

	profiles.push({
		Type: "Video"
		Codec: "h264"
		Conditions: h264Conditions
	})

	' rokuTV has ability to direct play MPEG2
	if isRokuTV then

	mpeg2Conditions = []
	mpeg2Conditions.push({
		Condition: "LessThanEqual"
		Property: "Width"
		Value: maxWidth
		IsRequired: true
	})
	mpeg2Conditions.push({
		Condition: "LessThanEqual"
		Property: "Height"
		Value: maxHeight
		IsRequired: true
	})
	mpeg2Conditions.push({
		Condition: "LessThanEqual"
		Property: "VideoFramerate"
		Value: framerate
		IsRequired: false
	})

	profiles.push({
		Type: "Video"
		Codec: "mpeg2video"
		Conditions: mpeg2Conditions
	})
	profiles.push({
		Type: "Video"
		Codec: "mpeg2"
		Conditions: mpeg2Conditions
	})


	mpeg1Conditions = []
	mpeg1Conditions.push({
		Condition: "LessThanEqual"
		Property: "Width"
		Value: maxWidth
		IsRequired: true
	})
	mpeg1Conditions.push({
		Condition: "LessThanEqual"
		Property: "Height"
		Value: maxHeight
		IsRequired: true
	})
	mpeg1Conditions.push({
		Condition: "LessThanEqual"
		Property: "VideoFramerate"
		Value: framerate
		IsRequired: false
	})

	profiles.push({
		Type: "Video"
		Codec: "mpeg1video"
		Conditions: mpeg1Conditions
	})
	profiles.push({
		Type: "Video"
		Codec: "mpeg1"
		Conditions: mpeg1Conditions
	})
	end if 'rokuTV

	' roku4 has ability to direct play h265/hevc
	if supports4kcodec

	hevcConditions = []
	hevcConditions.push({
		Condition: "LessThanEqual"
		Property: "Width"
		Value: max4kWidth
		IsRequired: true
	})
	hevcConditions.push({
		Condition: "LessThanEqual"
		Property: "Height"
		Value: max4kHeight
		IsRequired: true
	})
	hevcConditions.push({
		Condition: "LessThanEqual"
		Property: "VideoFramerate"
		Value: "60"
		IsRequired: false
	})
	profiles.push({
		Type: "Video"
		Codec: "hevc"
		Conditions: hevcConditions
	})

	' roku4 has ability to direct play vp9 too
	vp9Conditions = []
	vp9Conditions.push({
		Condition: "LessThanEqual"
		Property: "Width"
		Value: max4kWidth
		IsRequired: true
	})
	vp9Conditions.push({
		Condition: "LessThanEqual"
		Property: "Height"
		Value: max4kHeight
		IsRequired: true
	})
	vp9Conditions.push({
		Condition: "LessThanEqual"
		Property: "VideoFramerate"
		Value: "30"
		IsRequired: false
	})

	profiles.push({
		Type: "Video"
		Codec: "vp9"
		Conditions: vp9Conditions
	})
	end if ' roku 4
	
	mpeg4Conditions = []
	mpeg4Conditions.push({
		Condition: "LessThanEqual"
		Property: "RefFrames"
		Value: tostr(maxRef)
		IsRequired: false
	})
	mpeg4Conditions.push({
		Condition: "LessThanEqual"
		Property: "VideoBitDepth"
		Value: "8"
		IsRequired: false
	})
	mpeg4Conditions.push({
		Condition: "LessThanEqual"
		Property: "Width"
		Value: maxWidth
		IsRequired: true
	})
	mpeg4Conditions.push({
		Condition: "LessThanEqual"
		Property: "Height"
		Value: maxHeight
		IsRequired: true
	})
	mpeg4Conditions.push({
		Condition: "LessThanEqual"
		Property: "VideoFramerate"
		Value: framerate
		IsRequired: false
	})
	if playsAnamorphic = false Then
	mpeg4Conditions.push({
		Condition: "Equals"
		Property: "IsAnamorphic"
		Value: "false"
		IsRequired: false
	})
	end if
	mpeg4Conditions.push({
		Condition: "NotEquals"
		Property: "CodecTag"
		Value: "DX50"
		IsRequired: true
	})
	t = m.Extension
	if t <> invalid then
		' mkv container with mpeg4 cannot be xvid/divx/mp4v
		r = CreateObject("roRegex","mkv","i")
	        if r.isMatch(t) then
			mpeg4Conditions.push({
				Condition: "NotEquals"
				Property: "CodecTag"
				Value: "DIVX"
				IsRequired: false
			})
			mpeg4Conditions.push({
				Condition: "NotEquals"
				Property: "CodecTag"
				Value: "XVID"
				IsRequired: false
			})
			mpeg4Conditions.push({
				Condition: "NotEquals"
				Property: "CodecTag"
				Value: "MP4V"
				IsRequired: false
			})
		end if
	end if
	
	profiles.push({
		Type: "Video"
		Codec: "mpeg4"
		Conditions: mpeg4Conditions
	})

	' support AAC if found
	AACchannels = audio.lookup("AAC")
	if AACchannels <> invalid
		AACchannels = left(AACchannels,1)
		if firstOf(RegRead("prefaac2"), "0") = "0" then AACchannels = "2"
		profiles.push({
			Type: "VideoAudio"
			Codec: "aac"
			Conditions: [{
				Condition: "Equals"
				Property: "IsSecondaryAudio"
				Value: "false"
				IsRequired: false
			},
			{
				Condition: "LessThanEqual"
				Property: "AudioChannels"
				Value: AACchannels
				IsRequired: true
			}]
		})
	end if

	' support 7.1 Channel Dolby Digital+ if found
	if audioDDPlus
		EAC3channels = left(audio.lookup("DD+"),1)
		profiles.push({
			Type: "VideoAudio"
			Codec: "eac3"
			Conditions: [{
				Condition: "Equals"
				Property: "IsSecondaryAudio"
				Value: "false"
				IsRequired: false
			},
			{
				Condition: "LessThanEqual"
				Property: "AudioChannels"
				Value: EAC3Channels
				IsRequired: true
			}]
		})
	end if

	' support dolby digital if surround is found
	if surroundSound
	    AC3channels = left(audio.lookup("AC3"),1)
	    profiles.push({
		Type: "VideoAudio"
		Codec: "ac3"
		Conditions: [{
			Condition: "Equals"
			Property: "IsSecondaryAudio"
			Value: "false"
			IsRequired: false
		},
		{
			Condition: "LessThanEqual"
			Property: "AudioChannels"
			Value: AC3Channels
			IsRequired: true
		}]
	    })
	end if

	' Support DTS pass-through
	if surroundSoundDCA
		if truehd = "1" then
			dcaChannels = "8"
		else
			dcaChannels = left(audio.lookup("DTS"),1)
		end if
		profiles.push({
		 Type: "VideoAudio"
		 Codec: "dca"
		 Conditions: [{
			Condition: "Equals"
			Property: "IsSecondaryAudio"
			Value: "false"
			IsRequired: false
		 },
		 {
			Condition: "LessThanEqual"
			Property: "AudioChannels"
			Value: dcaChannels
			IsRequired: true
		 }]
		})
	end if

	' FLAC and ALAC need firmware check!
	if CheckMinimumVersion(versionArr, [5, 3]) then

	  ' support FLAC if found
	  FLACchannels = audio.lookup("FLAC")
	  if FLACchannels <> invalid
		FLACchannels = left(FLACchannels,1)
	 	 profiles.push({
			Type: "VideoAudio"
			Codec: "flac"
			Conditions: [{
				Condition: "Equals"
				Property: "IsSecondaryAudio"
				Value: "false"
				IsRequired: false
			},
			{
				Condition: "LessThanEqual"
				Property: "AudioChannels"
				Value: FLACchannels
				IsRequired: true
			}]
	 	 })
	  end if

	  ' support ALAC if found
	  ALACchannels = audio.lookup("ALAC")
	  if ALACchannels <> invalid
		ALACchannels = left(ALACchannels,1)
		profiles.push({
			Type: "VideoAudio"
			Codec: "alac"
			Conditions: [{
				Condition: "Equals"
				Property: "IsSecondaryAudio"
				Value: "false"
				IsRequired: false
			},
			{
				Condition: "LessThanEqual"
				Property: "AudioChannels"
				Value: ALACchannels
				IsRequired: true
			}]
	 	})
	  end if
	end if

	' support LPCM if found
	LPCMchannels = audio.lookup("LPCM")
	if LPCMchannels <> invalid
		LPCMchannels = left(LPCMchannels,1)
		profiles.push({
			Type: "VideoAudio"
			Codec: "lpcm"
			Conditions: [{
				Condition: "Equals"
				Property: "IsSecondaryAudio"
				Value: "false"
				IsRequired: false
			},
			{
				Condition: "LessThanEqual"
				Property: "AudioChannels"
				Value: LPCMchannels
				IsRequired: true
			}]
		})
	end if

	' support WMA if found
	WMAchannels = audio.lookup("WMA")
	if WMAchannels <> invalid
		WMAchannels = left(WMAchannels,1)
		profiles.push({
			Type: "VideoAudio"
			Codec: "wma"
			Conditions: [{
				Condition: "Equals"
				Property: "IsSecondaryAudio"
				Value: "false"
				IsRequired: false
			},
			{
				Condition: "LessThanEqual"
				Property: "AudioChannels"
				Value: WMAchannels
				IsRequired: true
			}]
		})
	end if

	' support WMAPro if found
	WMAPchannels = audio.lookup("WMAP")
	if WMAPchannels <> invalid
		WMAPchannels = left(WMAPchannels,1)
		profiles.push({
			Type: "VideoAudio"
			Codec: "wmapro"
			Conditions: [{
				Condition: "Equals"
				Property: "IsSecondaryAudio"
				Value: "false"
				IsRequired: false
			},
			{
				Condition: "LessThanEqual"
				Property: "AudioChannels"
				Value: WMAPchannels
				IsRequired: true
			}]
		})
	end if

	' support MP3 if found
	MP3channels = audio.lookup("MP3")
	if MP3channels <> invalid
		MP3channels = left(MP3channels,1)
		profiles.push({
			Type: "VideoAudio"
			Codec: "mp3"
			Conditions: [{
				Condition: "Equals"
				Property: "IsSecondaryAudio"
				Value: "false"
				IsRequired: false
			},
			{
				Condition: "LessThanEqual"
				Property: "AudioChannels"
				Value: MP3channels
				IsRequired: true
			}]
		})
	end if

	' support MP3 if found
	MP2channels = audio.lookup("MPEG2")
	if MP2channels <> invalid
		MP2channels = left(MP2channels,1)
		profiles.push({
			Type: "VideoAudio"
			Codec: "mp2"
			Conditions: [{
				Condition: "Equals"
				Property: "IsSecondaryAudio"
				Value: "false"
				IsRequired: false
			},
			{
				Condition: "LessThanEqual"
				Property: "AudioChannels"
				Value: MP2channels
				IsRequired: true
			}]
		})
	end if

	' support VORBIS if found
	VORBISchannels = audio.lookup("VORBIS")
	if VORBISchannels <> invalid
		VORBISchannels = left(VORBISchannels,1)
		profiles.push({
			Type: "VideoAudio"
			Codec: "vorbis"
			Conditions: [{
				Condition: "Equals"
				Property: "IsSecondaryAudio"
				Value: "false"
				IsRequired: false
			},
			{
				Condition: "LessThanEqual"
				Property: "AudioChannels"
				Value: VORBISchannels
				IsRequired: true
			}]
		})
	end if

	' support OPUS if found
	OPUSchannels = audio.lookup("OPUS")
	if OPUSchannels <> invalid
		OPUSchannels = left(OPUSchannels,1)
		profiles.push({
			Type: "VideoAudio"
			Codec: "opus"
			Conditions: [{
				Condition: "Equals"
				Property: "IsSecondaryAudio"
				Value: "false"
				IsRequired: false
			},
			{
				Condition: "LessThanEqual"
				Property: "AudioChannels"
				Value: OPUSchannels
				IsRequired: true
			}]
		})
	end if

	' TRUEHD pass-through test
        if truehd = "1" then
	  profiles.push({
		Type: "VideoAudio"
		Codec: "TrueHD"
		Conditions: [{
			Condition: "Equals"
			Property: "IsSecondaryAudio"
			Value: "false"
			IsRequired: false
		},
		{
			Condition: "LessThanEqual"
			Property: "AudioChannels"
			Value: "8"
			IsRequired: true
		}]
	  })

	  profiles.push({
		Type: "VideoAudio"
		Codec: "DTS"
		Conditions: [{
			Condition: "Equals"
			Property: "IsSecondaryAudio"
			Value: "false"
			IsRequired: false
		},
		{
			Condition: "LessThanEqual"
			Property: "AudioChannels"
			Value: "8"
			IsRequired: true
		}]
	  })
	end if
	
	return profiles

End Function

Function getContainerProfiles()

	profiles = []

	videoContainerConditions = []
	
	versionArr = getGlobalVar("rokuVersion")
    major = versionArr[0]

    if major < 4 then
		' If everything else looks ok and there are no audio streams, that's
		' fine on Roku 2+.
		videoContainerConditions.push({
			Condition: "NotEquals"
			Property: "NumAudioStreams"
			Value: "0"
			IsRequired: false
		})
	end if
	
	' Multiple video streams aren't supported, regardless of type.
    videoContainerConditions.push({
		Condition: "Equals"
		Property: "NumVideoStreams"
		Value: "1"
		IsRequired: false
	})
		
	profiles.push({
		Type: "Video"
		Conditions: videoContainerConditions
	})
	
	return profiles

End Function

Function getSubtitleProfiles()

	profiles = []
	
	profiles.push({
		Format: "srt"
		Method: "External"
		
		' If Roku adds support for non-Latin characters, remove this
		Language: "und,afr,alb,baq,bre,cat,dan,eng,fao,glg,ger,ice,may,gle,ita,lat,ltz,nor,oci,por,roh,gla,spa,swa,swe,wln,est,fin,fre,dut"
	})
	
	profiles.push({
		Format: "srt"
		Method: "Embed"
		
		' If Roku adds support for non-Latin characters, remove this
		Language: "und,afr,alb,baq,bre,cat,dan,eng,fao,glg,ger,ice,may,gle,ita,lat,ltz,nor,oci,por,roh,gla,spa,swa,swe,wln,est,fin,fre,dut"
	})

	profiles.push({
		Format: "subrip"
		Method: "External"
		
		' If Roku adds support for non-Latin characters, remove this
		Language: "und,afr,alb,baq,bre,cat,dan,eng,fao,glg,ger,ice,may,gle,ita,lat,ltz,nor,oci,por,roh,gla,spa,swa,swe,wln,est,fin,fre,dut"
	})
	
	profiles.push({
		Format: "subrip"
		Method: "Embed"
		
		' If Roku adds support for non-Latin characters, remove this
		Language: "und,afr,alb,baq,bre,cat,dan,eng,fao,glg,ger,ice,may,gle,ita,lat,ltz,nor,oci,por,roh,gla,spa,swa,swe,wln,est,fin,fre,dut"
	})
			
	return profiles

End Function

Function getDeviceProfile(item = invalid) 

	maxVideoBitrate = firstOf(RegRead("prefVideoQuality"), "3200")
	maxVideoBitrate = maxVideoBitrate.ToInt() * 1000
	force = firstOf(regRead("prefPlayMethod"),"Auto")
	if item <> invalid
        	if item.LocationType = "Remote"
			text = "Remote @"
			maxVideoBitrate = firstOf(RegRead("prefremoteVideoQuality"), "3200")
			maxVideoBitrate = maxVideoBitrate.ToInt() * 1000
		else if item.ContentType = "Program"
			text = "LiveTV @"
			maxVideoBitrate = firstOf(RegRead("preflivetvVideoQuality"), "3200")
			maxVideoBitrate = maxVideoBitrate.ToInt() * 1000
		else
			text = "Local @"
		end if

		if item.mediasources <> invalid and force = "Trans-DS"
			for each mediasource in item.mediasources[0].MediaStreams
				if mediasource.Type = "Video"
					'if lcase(mediasource.codec) = "h264" or lcase(mediasource.codec) = "hevc"
						if mediasource.bitrate <> invalid
							maxVideoBitrate = mediasource.bitrate - 1
							text = left(text,text.len()-2) + " (disabled directstream) @"
						end if
					'end if
				end if
			end for
		end if
	else
		text = "Primary @"
	end if
	debug(text + " MaxVideoBitrate: "+tostr(MaxVideoBitrate/1000)+" Kb/s")

	
	profile = {
		MaxStaticBitrate: "60000000"
		MaxStreamingBitrate: tostr(maxVideoBitrate)
		MusicStreamingTranscodingBitrate: "320000"
		DirectPlayProfiles: getDirectPlayProfiles()
		TranscodingProfiles: getTranscodingProfiles()
		CodecProfiles: getCodecProfiles()
		ContainerProfiles: getContainerProfiles()
		SubtitleProfiles: getSubtitleProfiles()
		Name: "Roku BN"
	}
	
	return profile
	
End Function

Function getCapabilities() 

	caps = {
		PlayableMediaTypes: ["Audio","Video","Photo"]
		SupportsMediaControl: true
		SupportedCommands: ["MoveUp","MoveDown","MoveLeft","MoveRight","Select","Back","GoHome","SendString","GoToSearch","GoToSettings","DisplayContent","SetAudioStreamIndex","SetSubtitleStreamIndex","DisplayMessage"]
		MessageCallbackUrl: ":8324/emby/message"
		DeviceProfile: getDeviceProfile()
		SupportedLiveMediaTypes: ["Video"]
		AppStoreUrl: "https://my.roku.com/account/add?channel=EmbyBlueNeon"
		AppId: "dev"
		IconUrl: "http://ereader.kiczek.com/rokublue.png"
	}
	
	return caps
	
End Function
