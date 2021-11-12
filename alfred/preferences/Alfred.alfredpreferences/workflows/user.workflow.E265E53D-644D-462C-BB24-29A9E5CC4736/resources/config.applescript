-- core configuration --

-- configurable options --

-- limit number of songs to improve efficiency
property resultLimit : 15
-- whether or not to retrieve/display album artwork for each result
property albumArtEnabled : true

-- workflow parameters --

-- workflow folders
property libraryFolder : (path to library folder from user domain as text)
property cacheFolder : (libraryFolder & "Caches:")
property alfredWorkflowDataFolder : (cacheFolder & "com.runningwithcrayons.Alfred:Workflow Data:")
property bundleId : "com.calebevans.playsong"
property workflowCacheFolder : (alfredWorkflowDataFolder & bundleId & ":") as text

-- album artwork folders
property artworkDocsFolder : ((get path to library folder from user domain as text) & "Containers:com.apple.AMPArtworkAgent:Data:Documents")
property artworkImageFolder : (artworkDocsFolder & ":artwork:")

-- the default icon used for search results without album artwork
property defaultIconName : "resources/icon-noartwork.png"
-- the name of the playlist used by the workflow for playing songs
property workflowPlaylistName : "Alfred Play Song"
-- list of Alfred results
property resultList : {}

-- replaces substring in string with another substring
on replace(replaceThis, replaceWith, theString)

	set oldDelims to AppleScript's text item delimiters
	set AppleScript's text item delimiters to replaceThis
	set strItems to text items of theString
	set AppleScript's text item delimiters to replaceWith
	set newString to strItems as text
	set AppleScript's text item delimiters to oldDelims
	return newString

end replace

-- retrieve the plural/singular form of a quantity based on the given number
on quantifyNumber(theNumber, quantityName, pluralQuantityName)

	if theNumber is 1 then

		set theString to (theNumber as text) & space & quantityName

	else

		set theString to (theNumber as text) & space & pluralQuantityName

	end if

	return theString

end quantifyNumber

-- encodes JSON reserved characters in the given string
on encodeFeedbackChars(theString)

	set theString to replace("\\", "\\\\", theString)
	set theString to replace("\"", "\\\"", theString)
	return theString

end encodeFeedbackChars

-- decodes JSON reserved characters in the given string
on decodeFeedbackChars(theString)

	set theString to replace("\\\\", "\\", theString)
	set theString to replace("\\\"", "\"", theString)
	return theString

end decodeFeedbackChars

-- adds Alfred result to result list
on addResult(theResult)

	copy theResult to the end of resultList

end addResult

-- adds item for "No Results" message
on addNoResultsItem(query, queryType)

	addResult({uid:"no-results", valid:"no", title:"No Results Found", subtitle:("No " & queryType & "s matching '" & query & "'"), icon:defaultIconName})

end addNoResultsItem

on resultListIsFull()

	return (length of resultList is resultLimit)

end resultListIsFull

on resultListIsEmpty()

	return (length of resultList is 0)

end resultListIsFull

-- builds Alfred result item as JSON
on getResultFeedback(theResult)

	-- encode reserved JSON characters
	set resultUid to encodeFeedbackChars(uid of theResult)
	set resultValid to (valid of theResult) as text
	set resultTitle to encodeFeedbackChars(title of theResult)
	set resultSubtitle to encodeFeedbackChars(subtitle of theResult)

	if (icon of theResult) contains ":" then

		set resultIcon to encodeFeedbackChars(POSIX path of icon of theResult)

	else

		set resultIcon to icon of theResult

	end if

	set json to "{"
	set json to json & "\"uid\":\"" & resultUid & "\","
	set json to json & "\"arg\":\"" & resultUid & "\","
	set json to json & "\"valid\":\"" & resultValid & "\","
	set json to json & "\"title\":\"" & resultTitle & "\","
	set json to json & "\"subtitle\":\"" & resultSubtitle & "\","
	set json to json & "\"icon\":{\"path\":\"" & resultIcon & "\"}"
	set json to json & "}"
	return json

end getResultFeedback

-- retrieves JSON document for Alfred results
on getResultListFeedback()

	set json to "{\"items\": ["

	repeat with theResult in resultList

		set json to json & getResultFeedback(theResult)
		set json to json & ","

	end repeat

	-- remove trailing comma after last item
	set json to text 1 thru (length of json - 1) of json
	set json to json & "]}"
	return json

end getResultListFeedback

-- writes the given content to the given file
on fileWrite(theFile, theContent)

	set fileRef to open for access theFile with write permission
	try
		set eof of fileRef to 0
		write theContent to fileRef starting at eof
		close access fileRef
	on error
		close access fileRef
	end try

end fileWrite

-- query path to artwork image file cached natively by Music.app in Catalina
on getSongArtworkPath(theSong)

	try

		if albumArtEnabled is false then return defaultIconName

		tell application "Music"

			-- get persistent ID of song and convert from hexadecimal to decimal (base-10)
			set hexSongId to persistent ID of theSong
			set decSongId to (do shell script "echo $((16#" & hexSongId & "))")

			-- retrieve filename of cached artwork
			set artworkName to (do shell script ("/usr/bin/sqlite3 " & (POSIX path of artworkDocsFolder) & "/artworkd.sqlite '" & ¬
			"select ZHASHSTRING, ZKIND from ZIMAGEINFO where Z_PK = (" & ¬
			"(select ZIMAGEINFO from ZSOURCEINFO where Z_PK = (" & ¬
			"select ZSOURCEINFO from ZDATABASEITEMINFO where ZPERSISTENTID = " & ¬
			decSongId & ")))' | " & ¬
			"awk '{split($0,a,\"|\"); print a[1] \"_sk_\" a[2] \"_cid_1.jpeg\"}'"))

			set artworkPath to (artworkImageFolder & artworkName)

		end tell

		return artworkPath

	on error errorMessage

		log errorMessage

	end try

end getNativeCachedArtworkPath

-- creates album artwork cache
on createWorkflowPlaylist()

	tell application "Music"

		if not (user playlist workflowPlaylistName exists) then

			make new user playlist with properties {name:workflowPlaylistName, shuffle:false}

		end if

	end tell

end createWorkflowPlaylist

on clearQueue()

	tell application "Music"

		if user playlist workflowPlaylistName exists then

			delete tracks of user playlist workflowPlaylistName

		end if

	end tell

end clearQueue

on queueSongs(theSongs)

	tell application "Music"

		repeat with theSong in theSongs

			duplicate theSong to user playlist workflowPlaylistName

		end repeat

	end tell

end queueSongs

on playQueue()

	tell application "Music"

		if number of tracks in user playlist workflowPlaylistName is not 0 then

			play user playlist workflowPlaylistName

		end if

	end tell

end playQueue

on getPlaylist(playlistId)

	tell application "Music"

		return (first playlist whose id is playlistId)

	end tell

end getPlaylist

on getPlaylistSongs(playlistId)

	tell application "Music"

		set thePlaylist to getPlaylist(playlistId) of me
		set playlistSongs to every track of thePlaylist

	end tell

	return playlistSongs

end getPlaylistSongs

-- retrieves list of artist names for the given genre
on getGenreArtists(genreName)

	tell application "Music"

		set genreSongs to every track of playlist 2 whose genre is genreName
		set artistNames to {}

		repeat with theSong in genreSongs

			if (artist of theSong) is not in artistNames then

				set artistNames to artistNames & (artist of theSong)

			end if

		end repeat

	end tell

	return artistNames

end getGenreArtists

-- retrieves list of songs within the given genre, sorted by artist
on getGenreSongs(genreName)

	set artistNames to getGenreArtists(genreName) of me
	set genreSongs to {}

	repeat with artistName in artistNames

		set genreSongs to genreSongs & getArtistSongs(artistName) of me

	end repeat

	return genreSongs

end getGenreSongs

-- retrieves list of album names for the given artist
on getArtistAlbums(artistName)

	tell application "Music"

		set artistSongs to every track of playlist 2 whose artist is artistName
		set albumNames to {}

		repeat with theSong in artistSongs

			if (album of theSong) is not in albumNames then

				set albumNames to albumNames & (album of theSong)

			end if

		end repeat

	end tell

	return albumNames

end getArtistAlbums

-- retrieves list of songs by the given artist, sorted by album
on getArtistSongs(artistName)

	tell application "Music"

		set albumNames to getArtistAlbums(artistName) of me
		set artistSongs to {}

		repeat with albumName in albumNames

			set albumSongs to (every track of playlist 2 whose artist is artistName and album is albumName)
			set artistSongs to artistSongs & albumSongs

		end repeat

	end tell

	return artistSongs

end getArtistSongs

-- retrieves list of songs in the given album
on getAlbumSongs(albumName)

	tell application "Music"

		set albumSongs to every track of playlist 2 whose album is albumName

	end tell

	return albumSongs

end getAlbumSongs

-- retrieves the song with the given ID
on getSong(songId)

	tell application "Music"

		set theSong to first track of playlist 2 whose database ID is songId

	end tell

	return theSong

end getSong

-- retrieves a list of objects or names matching the given query and type
on getResultsFromQuery(query, queryType)

	set evalScript to run script "
	script

		on findResults(query, queryType, resultLimit)

			tell application \"Music\"

				set theSongs to (get every track in playlist 2 whose " & queryType & " starts with query)

				if length of theSongs < resultLimit then

					set theSongs to theSongs & (get every track in playlist 2 whose " & queryType & " contains (space & query) and " & queryType & " does not start with query)

				end if

				if length of theSongs < resultLimit then

					set theSongs to theSongs & (get every track in playlist 2 whose " & queryType & " contains query and " & queryType & " does not start with query and " & queryType & " does not contain (space & query))

				end if

				if length of theSongs is 0 then

					if queryType is \"name\" then

						set theSongs to theSongs & (search playlist 2 for query only songs)

					else if queryType is not \"genre\" then

						set theSongs to theSongs & (search playlist 2 for query only " & queryType & "s)

					end if

				end if

				if queryType is \"name\" then

					if length of theSongs > resultLimit then

						set theSongs to items 1 thru resultLimit of theSongs

					end if

					set theResults to theSongs

				else

					set theResults to {}

					repeat with theSong in theSongs

						if length of theResults is resultLimit then exit repeat

						set theResult to " & queryType & " of theSong

						if theResult is not in theResults then

							set theResults to theResults & theResult

						end if

					end repeat

				end if

			end tell

			return theResults

		end findResults

	end script
	"

	evalScript's findResults(query, queryType, resultLimit)

end getResultsFromQuery

-- returns the given string with leading and trailing whitespace removed
on trimWhitespace(theString)

	-- trim leading whitespace
	repeat while theString begins with space

		if length of theString is 1 then return ""
		set theString to text 2 thru end of theString

	end repeat

	-- trim trailing whitespace
	repeat while theString ends with space

		set theString to text 1 thru ((length of theString) - 1) of theString

	end repeat

	return theString

end trimWhitespace

-- queues the song with the given ID
on queueSong(songId)

	set theSong to getSong(songId)
	queueSongs({theSong})

end queueSong

-- queues all songs belonging to the given album
on queueAlbum(albumName)

	set albumName to decodeFeedbackChars(albumName)
	set albumSongs to getAlbumSongs(albumName)
	queueSongs(albumSongs)

end queueAlbum

-- queues all songs by the given artist
on queueArtist(artistName)

	set artistName to decodeFeedbackChars(artistName)
	set artistSongs to getArtistSongs(artistName)
	queueSongs(artistSongs)

end queueArtist

-- queues all songs within the given genre
on queueGenre(genreName)

	set genreName to decodeFeedbackChars(genreName)
	set genreSongs to getGenreSongs(genreName)
	queueSongs(genreSongs)

end queueGenre

-- queues all songs in the given playlist
on queuePlaylist(playlistId)

	set playlistSongs to getPlaylistSongs(playlistId)
	queueSongs(playlistSongs)

end queuePlaylist

-- parses the given result query to retrieve type and id of item to queue
on parseResultQuery(query)

	set pos to offset of "-" in query
	set theType to text 1 thru (pos - 1) of query
	set theId to text (pos + 1) thru end of query
	return {type:theType, id:theId}

end parseResultQuery

on queue(query)

	set typeAndId to parseResultQuery(query)
	set theType to type of typeAndId
	set theId to id of typeAndId

	createWorkflowPlaylist()

	if theType is "song" then
		queueSong(theId)
	else if theType is "album" then
		queueAlbum(theId)
	else if theType is "artist" then
		queueArtist(theId)
	else if theType is "genre" then
		queueGenre(theId)
	else if theType is "playlist" then
		queuePlaylist(theId)
	else
		log "Unsupported type: " & theType
	end if

end queue

on play(query)

	clearQueue()
	queue(query)
	playQueue()

end play
