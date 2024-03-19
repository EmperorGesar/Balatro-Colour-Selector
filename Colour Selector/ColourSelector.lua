--- STEAMODDED HEADER
--- MOD_NAME: Colour Selector
--- MOD_ID: ColourSelector
--- MOD_AUTHOR: [EmperorGesar]
--- MOD_DESCRIPTION: Mod for selecting and changing the colours of the main menu background

----------------------------------------------
------------MOD CODE -------------------------

local filename = "colours.txt"
local c1 = ""
local c2 = ""

function SMODS.INIT.ColourSelector()
    G.C.RAND1 = {1, 0, 0, 1}
    G.C.RAND2 = {0, 0, 1, 1}
    G.C.PINK = HEX('fe55a5')
    G.C.CYAN = HEX('00eaff')

    local directory = "Mods/Colour Selector"
    local files = love.filesystem.getDirectoryItems(directory)
    local found = false

    for _, file in ipairs(files) do
        if string.sub(file, -4) == ".txt" then
            local filePath = directory .. "/" .. file
            local fileContent = love.filesystem.read(filePath)
            local func, err = loadstring("return " .. fileContent)

            if func then
                local colours = func()
                G.C.COLOUR1 = colours.colour1
                G.C.COLOUR2 = colours.colour2
                c1 = c1 .. colours.name1
                c2 = c2 .. colours.name2
                found = true
            end
        end
    end

    if found == false then
        G.C.COLOUR1 = G.C.RED
        G.C.COLOUR2 = G.C.BLUE
    end
end

local updateRef = Game.update
function Game:update(dt)
    updateRef(self, dt)

    self.C.RAND1[1] = 0.5+0.5*math.cos(self.TIMERS.REAL)
    self.C.RAND1[2] = 2/3+1/3*math.cos(self.TIMERS.REAL+0.6*math.pi)
    self.C.RAND1[3] = 2/3+1/3*math.cos(self.TIMERS.REAL+math.pi)

    self.C.RAND2[1] = 2/3+1/3*math.cos(self.TIMERS.REAL+math.pi)
    self.C.RAND2[2] = 2/3+1/3*math.cos(self.TIMERS.REAL-0.6*math.pi)
    self.C.RAND2[3] = 0.5+0.5*math.cos(self.TIMERS.REAL)
end

local main_menuRef = Game.main_menu
function Game:main_menu(change_context)
	main_menuRef(self, change_context)

    local splash_args = {mid_flash = change_context == 'splash' and 1.6 or 0.}
    ease_value(splash_args, 'mid_flash', -(change_context == 'splash' and 1.6 or 0), nil, nil, nil, 4)

    G.SPLASH_BACK:define_draw_steps({{
        shader = 'splash',
        send = {
            {name = 'time', ref_table = G.TIMERS, ref_value = 'REAL'},
            {name = 'vort_speed', val = 0.4},
            {name = 'colour_1', ref_table = G.C, ref_value = 'COLOUR1'},
            {name = 'colour_2', ref_table = G.C, ref_value = 'COLOUR2'},
            {name = 'mid_flash', ref_table = splash_args, ref_value = 'mid_flash'},
            {name = 'vort_offset', val = 0},
        }}})
end

local function save(colour, val)
    local directory = "Mods/Colour Selector"
    local filePath = directory .. "/" .. filename
    local content = ""
    if colour == 1 then
        c1 = val
        content = "{[\"colour1\"] = " .. val .. ", [\"colour2\"] = " .. c2 .. ", [\"name1\"] = " .. "\"" .. val .. "\"" .. ", [\"name2\"] = " .. "\"" .. c2 .. "\"" .. "}"
    end
    if colour == 2 then
        c2 = val
        content = "{[\"colour1\"] = " .. c1 .. ", [\"colour2\"] = " .. val .. ", [\"name1\"] = " .. "\"" .. c1 .. "\"" .. ", [\"name2\"] = " .. "\"" .. val .. "\"" .. "}"
    end
    love.filesystem.write(filePath, content)
end

function G.FUNCS.c1r()
    G.C.COLOUR1 = G.C.RED
    save(1, "G.C.RED")
end

function G.FUNCS.c1b()
    G.C.COLOUR1 = G.C.BLUE
    save(1, "G.C.BLUE")
end

function G.FUNCS.c1g()
    G.C.COLOUR1 = G.C.GREEN
    save(1, "G.C.GREEN")
end

function G.FUNCS.c1p()
    G.C.COLOUR1 = G.C.PURPLE
    save(1, "G.C.PURPLE")
end

function G.FUNCS.c1o()
    G.C.COLOUR1 = G.C.ORANGE
    save(1, "G.C.ORANGE")
end

function G.FUNCS.c1c()
    G.C.COLOUR1 = G.C.CYAN
    save(1, "G.C.CYAN")
end

function G.FUNCS.c1k()
    G.C.COLOUR1 = G.C.PINK
    save(1, "G.C.PINK")
end

function G.FUNCS.c1y()
    G.C.COLOUR1 = G.C.YELLOW
    save(1, "G.C.YELLOW")
end

function G.FUNCS.c1j()
    G.C.COLOUR1 = G.C.JOKER_GREY
    save(1, "G.C.JOKER_GREY")
end

function G.FUNCS.c1l()
    G.C.COLOUR1 = G.C.L_BLACK
    save(1, "G.C.L_BLACK")
end

function G.FUNCS.c1r1()
    G.C.COLOUR1 = G.C.RAND1
    save(1, "G.C.RAND1")
end

function G.FUNCS.c1r2()
    G.C.COLOUR1 = G.C.RAND2
    save(1, "G.C.RAND2")
end

function G.FUNCS.c2r()
    G.C.COLOUR2 = G.C.RED
    save(2, "G.C.RED")
end

function G.FUNCS.c2b()
    G.C.COLOUR2 = G.C.BLUE
    save(2, "G.C.BLUE")
end

function G.FUNCS.c2g()
    G.C.COLOUR2 = G.C.GREEN
    save(2, "G.C.GREEN")
end

function G.FUNCS.c2p()
    G.C.COLOUR2 = G.C.PURPLE
    save(2, "G.C.PURPLE")
end

function G.FUNCS.c2o()
    G.C.COLOUR2 = G.C.ORANGE
    save(2, "G.C.ORANGE")
end

function G.FUNCS.c2c()
    G.C.COLOUR2 = G.C.CYAN
    save(2, "G.C.CYAN")
end

function G.FUNCS.c2k()
    G.C.COLOUR2 = G.C.PINK
    save(2, "G.C.PINK")
end

function G.FUNCS.c2y()
    G.C.COLOUR2 = G.C.YELLOW
    save(2, "G.C.YELLOW")
end

function G.FUNCS.c2j()
    G.C.COLOUR2 = G.C.JOKER_GREY
    save(2, "G.C.JOKER_GREY")
end

function G.FUNCS.c2l()
    G.C.COLOUR2 = G.C.L_BLACK
    save(2, "G.C.L_BLACK")
end

function G.FUNCS.c2r1()
    G.C.COLOUR2 = G.C.RAND1
    save(2, "G.C.RAND1")
end

function G.FUNCS.c2r2()
    G.C.COLOUR2 = G.C.RAND2
    save(2, "G.C.RAND2")
end

setting_tabRef = G.UIDEF.settings_tab
function G.UIDEF.settings_tab(tab)
    local setting_tab = setting_tabRef(tab)

    if tab == 'Game' then
        local c1 = {n=G.UIT.R, config = {align = 'cm', r = 0}, nodes={
            {n=G.UIT.R, config = {align = 'cm', r = 0}, nodes={
                {n=G.UIT.T, config={text = "Outer Colour  ", scale = 0.35, colour = G.C.WHITE, shadow = true}},

                {n = G.UIT.C, config = {padding = 0.2,align = "cm"}, nodes = {
                    UIBox_button({minw = 0.5, minh = 0.5, button = "c1r", colour = G.C.RED, label = {" "}, scale = 0.35})
                }},
                {n = G.UIT.C, config = {padding = 0.2,align = "cm"}, nodes = {
                    UIBox_button({minw = 0.5, minh = 0.5, button = "c1b", colour = G.C.BLUE, label = {" "}, scale = 0.35})
                }},
                {n = G.UIT.C, config = {padding = 0.2,align = "cm"}, nodes = {
                    UIBox_button({minw = 0.5, minh = 0.5, button = "c1g", colour = G.C.GREEN, label = {" "}, scale = 0.35})
                }},
                {n = G.UIT.C, config = {padding = 0.2,align = "cm"}, nodes = {
                    UIBox_button({minw = 0.5, minh = 0.5, button = "c1p", colour = G.C.PURPLE, label = {" "}, scale = 0.35})
                }},
                {n = G.UIT.C, config = {padding = 0.2,align = "cm"}, nodes = {
                    UIBox_button({minw = 0.5, minh = 0.5, button = "c1o", colour = G.C.ORANGE, label = {" "}, scale = 0.35})
                }},
                {n = G.UIT.C, config = {padding = 0.2,align = "cm"}, nodes = {
                    UIBox_button({minw = 0.5, minh = 0.5, button = "c1c", colour = G.C.CYAN, label = {" "}, scale = 0.35})
                }},
                {n = G.UIT.C, config = {padding = 0.2,align = "cm"}, nodes = {
                    UIBox_button({minw = 0.5, minh = 0.5, button = "c1k", colour = G.C.PINK, label = {" "}, scale = 0.35})
                }},
                {n = G.UIT.C, config = {padding = 0.2,align = "cm"}, nodes = {
                    UIBox_button({minw = 0.5, minh = 0.5, button = "c1y", colour = G.C.YELLOW, label = {" "}, scale = 0.35})
                }},
                {n = G.UIT.C, config = {padding = 0.2,align = "cm"}, nodes = {
                    UIBox_button({minw = 0.5, minh = 0.5, button = "c1j", colour = G.C.JOKER_GREY, label = {" "}, scale = 0.35})
                }},
                {n = G.UIT.C, config = {padding = 0.2,align = "cm"}, nodes = {
                    UIBox_button({minw = 0.5, minh = 0.5, button = "c1l", colour = G.C.BLACK, label = {" "}, scale = 0.35})
                }},
                {n = G.UIT.C, config = {padding = 0.2,align = "cm"}, nodes = {
                    UIBox_button({minw = 0.5, minh = 0.5, button = "c1r1", colour = G.C.RAND1, label = {" "}, scale = 0.35})
                }},
                {n = G.UIT.C, config = {padding = 0.2,align = "cm"}, nodes = {
                    UIBox_button({minw = 0.5, minh = 0.5, button = "c1r2", colour = G.C.RAND2, label = {" "}, scale = 0.35})
                }}
            }},

            {n=G.UIT.R, config = {align = 'cm', r = 0}, nodes={
                {n=G.UIT.T, config={text = "Inner Colour  ", scale = 0.35, colour = G.C.WHITE, shadow = true}},

                {n = G.UIT.C, config = {padding = 0.2,align = "cm"}, nodes = {
                    UIBox_button({minw = 0.5, minh = 0.5, button = "c2r", colour = G.C.RED, label = {" "}, scale = 0.35})
                }},
                {n = G.UIT.C, config = {padding = 0.2,align = "cm"}, nodes = {
                    UIBox_button({minw = 0.5, minh = 0.5, button = "c2b", colour = G.C.BLUE, label = {" "}, scale = 0.35})
                }},
                {n = G.UIT.C, config = {padding = 0.2,align = "cm"}, nodes = {
                    UIBox_button({minw = 0.5, minh = 0.5, button = "c2g", colour = G.C.GREEN, label = {" "}, scale = 0.35})
                }},
                {n = G.UIT.C, config = {padding = 0.2,align = "cm"}, nodes = {
                    UIBox_button({minw = 0.5, minh = 0.5, button = "c2p", colour = G.C.PURPLE, label = {" "}, scale = 0.35})
                }},
                {n = G.UIT.C, config = {padding = 0.2,align = "cm"}, nodes = {
                    UIBox_button({minw = 0.5, minh = 0.5, button = "c2o", colour = G.C.ORANGE, label = {" "}, scale = 0.35})
                }},
                {n = G.UIT.C, config = {padding = 0.2,align = "cm"}, nodes = {
                    UIBox_button({minw = 0.5, minh = 0.5, button = "c2c", colour = G.C.CYAN, label = {" "}, scale = 0.35})
                }},
                {n = G.UIT.C, config = {padding = 0.2,align = "cm"}, nodes = {
                    UIBox_button({minw = 0.5, minh = 0.5, button = "c2k", colour = G.C.PINK, label = {" "}, scale = 0.35})
                }},
                {n = G.UIT.C, config = {padding = 0.2,align = "cm"}, nodes = {
                    UIBox_button({minw = 0.5, minh = 0.5, button = "c2y", colour = G.C.YELLOW, label = {" "}, scale = 0.35})
                }},
                {n = G.UIT.C, config = {padding = 0.2,align = "cm"}, nodes = {
                    UIBox_button({minw = 0.5, minh = 0.5, button = "c2j", colour = G.C.JOKER_GREY, label = {" "}, scale = 0.35})
                }},
                {n = G.UIT.C, config = {padding = 0.2,align = "cm"}, nodes = {
                    UIBox_button({minw = 0.5, minh = 0.5, button = "c2l", colour = G.C.BLACK, label = {" "}, scale = 0.35})
                }},
                {n = G.UIT.C, config = {padding = 0.2,align = "cm"}, nodes = {
                    UIBox_button({minw = 0.5, minh = 0.5, button = "c2r1", colour = G.C.RAND1, label = {" "}, scale = 0.35})
                }},
                {n = G.UIT.C, config = {padding = 0.2,align = "cm"}, nodes = {
                    UIBox_button({minw = 0.5, minh = 0.5, button = "c2r2", colour = G.C.RAND2, label = {" "}, scale = 0.35})
                }}
            }}
        }}
        

        table.insert(setting_tab.nodes[1].nodes, #setting_tab.nodes[1].nodes + 1, c1)
    end
    return setting_tab
end

----------------------------------------------
------------MOD CODE END----------------------
