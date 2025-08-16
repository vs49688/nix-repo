function iterm_new()
    if hs.application.find("iTerm") then
        hs.applescript.applescript([[
            tell application "iTerm2"
                create window with default profile
            end tell
        ]])
    else
        hs.application.open("iTerm")
    end
end

hs.hotkey.bind({"ctrl", "alt"}, "t", iterm_new);
hs.hotkey.bind({"ctrl", "cmd"}, "t", iterm_new);
hs.hotkey.bind({"ctrl", "alt"}, "l", hs.caffeinate.lockScreen)
hs.hotkey.bind({"ctrl", "cmd"}, "l", hs.caffeinate.lockScreen)

function open_finder()
    hs.execute("open $HOME")
end
hs.hotkey.bind({"cmd"}, "e", open_finder)