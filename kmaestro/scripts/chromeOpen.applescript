tell application "Keyboard Maestro Engine"
	set urlToFetch to getvariable "urlToFetch"
end tell

set _win to false

tell application "Google Chrome"
	set {idList, urlList} to {id, URL} of every tab of every window
end tell

set AppleScript's text item delimiters to linefeed

if (urlList as text) contains urlToFetch = true then
	set theWin to 1
	
	repeat with i in urlList
		set theTab to 1
		
		repeat with n in i
			if n starts with urlToFetch then
				set {_win, _tab} to {theWin, theTab}
			end if
			
			set theTab to theTab + 1
		end repeat
		
		set theWin to theWin + 1
	end repeat
end if

if _win ≠ false then
	tell application "System Events"
		if quit delay ≠ 0 then set quit delay to 0
		
		tell process "Google Chrome"
			perform action "AXRaise" of window _win
		end tell
	end tell
	
	tell application "Google Chrome"
		tell front window to set active tab index to _tab
	end tell
else
	tell application "Google Chrome"
		tell front window
			make new tab at end of tabs with properties {URL:urlToFetch}
		end tell
	end tell
end if