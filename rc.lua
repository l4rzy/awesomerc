local gears     = require("gears")
local awful     = require("awful")
awful.rules     = require("awful.rules")
                  require("awful.autofocus")
local wibox     = require("wibox")
local beautiful = require("beautiful")
local uselessfair  = require("uselessfair")
local notify	= require("lgi").require("Notify")

-- {{{ Error handling
if awesome.startup_errors then
	notify.init("error")
	_err = notify.Notification.new("Oops, there were errors during startup!",
			awesome.startup_errors,"application-exit")
	_err:show()
end

do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        if in_error then return end
        in_error = true

		notify.init("Error")
		_err = notify.Notification.new("Oops, an error happened!",
			err,"application-exit")
		_err:show()

        in_error = false
    end)
end
-- }}}

autostart_cmd = {"urxvtd", "thunar --daemon", "ibus-daemon -drx", "xfce4-volumed-pulse", 
	"/usr/lib/polkit-gnome/gtkpolkit", "xfce4-power-manager", "/usr/lib/xfce4/notifyd/xfce4-notifyd"}
function autostart(cmd) 
	for i in ipairs(cmd) do
		awful.util.spawn_with_shell(cmd[i])
	end
end

autostart(autostart_cmd)
awful.util.spawn_with_shell("runonce redshift")

-- beautiful init
beautiful.init(os.getenv("HOME") .. "/.config/awesome/themes/multicolor/theme.lua")

-- common
modkey     = "Mod4"
altkey     = "Mod1"
terminal   = "urxvtc"
editor     = os.getenv("EDITOR") or "nano"
editor_cmd = terminal .. " -e " .. editor

-- user defined
browser    = "chromium"
browser2   = "firefox"
gui_editor = "textadept"
graphics   = "gimp"
mail       = terminal .. " -e mutt "

local layouts = {
	uselessfair,				--1
    awful.layout.suit.floating, --2
    awful.layout.suit.tile,     --3
    awful.layout.suit.max       --4
}
-- }}}

-- {{{ Tags
tags = {
   names = { "W", "T", "I", "M", "F", "O" },
   layout = { layouts[1], layouts[1], layouts[4], layouts[3], layouts[2], layouts[3] }
}
for s = 1, screen.count() do
-- Each screen has its own tag table.
   tags[s] = awful.tag(tags.names, s, tags.layout)
end
-- }}}

-- {{{ Wallpaper
if beautiful.wallpaper then
    for s = 1, screen.count() do
        gears.wallpaper.maximized(beautiful.wallpaper, s, true)
    end
end
-- }}}

-- Spacer
spacer = wibox.widget.textbox(" | ")

-- Create a wibox for each screen and add it
mywibox = {}
mybottomwibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(awful.tag.getscreen(t)) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(awful.tag.getscreen(t)) end)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  -- Without this, the following
                                                  -- :isvisible() makes no sense
                                                  c.minimized = false
                                                  if not c:isvisible() then
                                                      awful.tag.viewonly(c:tags()[1])
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({ width=250 })
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))

for s = 1, screen.count() do

    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt()


    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                            awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                            awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                            awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                            awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))

    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, mytasklist.buttons)
	
    -- Create the upper wibox
    mywibox[s] = awful.wibox({ position = "bottom", screen = s, height = 17 })
    --border_width = 0, height =  20 })

    -- Widgets that are aligned to the upper left
    local left_layout = wibox.layout.fixed.horizontal()
    left_layout:add(mytaglist[s])
	left_layout:add(spacer)
	left_layout:add(mypromptbox[s])
	local middle_layout = wibox.layout.fixed.horizontal()
	middle_layout:add(mytasklist[s])
    -- Widgets that are aligned to the upper right
    local right_layout = wibox.layout.fixed.horizontal()
    if s == 1 then right_layout:add(wibox.widget.systray()) end
	
    right_layout:add(mylayoutbox[s])
    -- Now bring it all together (with the tasklist in the middle)
    local layout = wibox.layout.align.horizontal()
    layout:set_left(left_layout)
    layout:set_middle(middle_layout)
    layout:set_right(right_layout)

    mywibox[s]:set_widget(layout)


end
-- }}}

-- {{{ Mouse Bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
    -- Tag browsing
    awful.key({ modkey }, "Left",   awful.tag.viewprev       ),
    awful.key({ modkey }, "Right",  awful.tag.viewnext       ),
    awful.key({ modkey }, "Escape", awful.tag.history.restore),
	
	-- resize tilling windows 
	-- awful.key({ modkey, "Shift" }, "h", function () awful.tag.incmwfact(1) end),	
	awful.key({ modkey, "Mod1"    }, "Right",     function () awful.tag.incmwfact( 0.01)    end),
	awful.key({ modkey, "Mod1"    }, "Left",     function () awful.tag.incmwfact(-0.01)    end),
	awful.key({ modkey, "Mod1"    }, "Down",     function () awful.client.incwfact( 0.01)    end),
	awful.key({ modkey, "Mod1"    }, "Up",     function () awful.client.incwfact(-0.01)    end),
    -- By direction client focus
    awful.key({ modkey }, "j",
        function()
            awful.client.focus.bydirection("down")
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey }, "k",
        function()
            awful.client.focus.bydirection("up")
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey }, "h",
        function()
            awful.client.focus.bydirection("left")
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey }, "l",
        function()
            awful.client.focus.bydirection("right")
            if client.focus then client.focus:raise() end
        end),

    -- Show/Hide Wibox
    awful.key({ modkey }, "b", function ()
        mywibox[mouse.screen].visible = not mywibox[mouse.screen].visible
        mybottomwibox[mouse.screen].visible = not mybottomwibox[mouse.screen].visible
    end),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
    --awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end),
    awful.key({ modkey, "Control" }, "r",      awesome.restart),
    awful.key({ modkey, "Shift"   }, "e",      awesome.quit),
	awful.key({ modkey, "Shift"   }, "p",	   function () awful.util.spawn("thunar") end),

    -- MPD
    awful.key({         }, "XF86AudioPlay", function () awful.util.spawn("mpc toggle")  end),
    awful.key({         }, "XF86AudioNext", function () awful.util.spawn("mpc next")	end),
	awful.key({			}, "XF86AudioPrev", function () awful.util.spawn("mpc prev")	end),

    -- Ibus control 
    awful.key({ modkey  }, "v",
        function ()
            awful.util.spawn("ibus engine 'Unikey'")
        end),
    awful.key({ modkey  }, "g",
        function ()
            awful.util.spawn("ibus engine 'anthy'")
        end),
    awful.key({ modkey  }, "space",
        function ()
            awful.util.spawn("ibus engine 'xkb:us::eng'")
        end),
    -- User programs
    awful.key({ modkey, "Shift" }, "f", function () awful.util.spawn("j4-dmenu-desktop --display-binary --dmenu='dmenu -b -i'") end),
	-- run in terminal prompt
	awful.key({ modkey, "Shift"   }, "r",
          function ()
              awful.prompt.run({ prompt = "Run in terminal: " },
                  mypromptbox[mouse.screen].widget,
                  function (...) awful.util.spawn(terminal .. " -e " .. ...) end,
                  awful.completion.shell,
                  awful.util.getdir("cache") .. "/history")
          end)	
)

clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey, "Shift"   }, "q",      function (c) c:kill()                         end),
    awful.key({ modkey, "Shift"   }, "space",  function (c) awful.client.floating.toggle(c)  end),
    awful.key({ modkey, "Shift"   }, "t",      function (c) c.ontop = not c.ontop            end),
    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end)
)

-- Bind all key numbers to tags.
-- be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = awful.util.table.join(globalkeys,
        -- View tag only.
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = mouse.screen
                        local tag = awful.tag.gettags(screen)[i]
                        if tag then
                           awful.tag.viewonly(tag)
                        end
                  end),
        -- Toggle tag.
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      local tag = awful.tag.gettags(screen)[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end),
        -- Move client to tag.
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = awful.tag.gettags(client.focus.screen)[i]
                          if tag then
                              awful.client.movetotag(tag)
                          end
                     end
                  end),
        -- Toggle tag.
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = awful.tag.gettags(client.focus.screen)[i]
                          if tag then
                              awful.client.toggletag(tag)
                          end
                      end
                  end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

local floating_w = {"Audacious","Smplayer2","feh","Thunar","Leafpad","Engrampa","XTerm","Termite","Textadept"}
-- {{{ Rules
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     keys = clientkeys,
                     buttons = clientbuttons,
	                 size_hints_honor = false } },

	{ rule = { class = "Xfce4-notifyd" },
		properties = {
			focusable = false,
			border_width = 0
		}

	},
}

--set up floating windows
for i in ipairs(floating_w) do
	table.insert(awful.rules.rules,{
		rule = {class = floating_w[i]},
		properties = { floating = true }
		})
end

-- }}}

-- {{{ Signals
-- signal function to execute when a new client appears.
client.connect_signal("manage", function (c, startup)
    if c.class == "Xfce4-notifyd" then
		--dont focus it 
		
	end
end)

client.connect_signal("focus",
    function(c)
        if c.maximized_horizontal == true and c.maximized_vertical == true then
            c.border_color = beautiful.border_normal
        else
            c.border_color = beautiful.border_focus
        end
    end
)

client.connect_signal("unfocus", 
	function(c) 
		c.border_color = beautiful.border_normal 
	end
)
-- }}}

-- {{{ Arrange signal handler
for s = 1, screen.count() do screen[s]:connect_signal("arrange", function ()
        local clients = awful.client.visible(s)
        local layout  = awful.layout.getname(awful.layout.get(s))

        if #clients > 0 then -- Fine grained borders and floaters control
            for _, c in pairs(clients) do -- Floaters always have borders
                -- No borders with only one humanly visible client
                if layout == "max" then
                    c.border_width = 0
                elseif awful.client.floating.get(c) or layout == "floating" then
                    c.border_width = beautiful.border_width
                elseif #clients == 1 then
                    clients[1].border_width = beautiful.border_width
                    if layout ~= "max" then
                        awful.client.moveresize(0, 0, 2, 0, clients[1])
                    end
                else
                    c.border_width = beautiful.border_width
                end
            end
        end
      end)
end
-- }}}
