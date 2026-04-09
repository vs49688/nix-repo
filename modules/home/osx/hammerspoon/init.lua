GHOSTTY = "com.mitchellh.ghostty"

hs.application.enableSpotlightForNameSearches(false)

hs.hotkey.bind({"ctrl", "alt"}, "l", hs.caffeinate.lockScreen)
hs.hotkey.bind({"ctrl", "cmd"}, "l", hs.caffeinate.lockScreen)

local function openNewGhostty()
    local ghostty = hs.application.find(GHOSTTY)
    if ghostty then
        -- NB: if this doesn't work, check accessibility options
        ghostty:selectMenuItem({"File", "New Window"})
    else
        hs.application.open(GHOSTTY)
    end
end

hs.hotkey.bind({"ctrl", "alt"}, "T", openNewGhostty)
hs.hotkey.bind({"ctrl", "cmd"}, "T", openNewGhostty)

function open_finder()
    hs.execute("open $HOME")
end
hs.hotkey.bind({"cmd"}, "e", open_finder)
