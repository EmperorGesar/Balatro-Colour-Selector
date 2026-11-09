--[[
  Main Menu Theme Selector 2.0  (formerly "Colour Selector")
  -----------------------------------------------------
  Original idea / v1 by EmperorGesar.  v2 changes:
   * Lives in the Game settings tab as ONE compact row ("Main Menu Theme") under the Game Speed options.
     It opens a panel (inside the normal settings box) with every control, so nothing runs off screen.
   * A colour you pick yourself ALWAYS wins over the main menu theme of any other mod (Lost Edition, ArtBox, Grab Bag ...).
     "Auto" on a colour means "use the theme".
   * Background Theme cycler: every mod that paints the main menu background is detected automatically
     (no hard-coded mod list) and can be cycled through.
   * Title Logo cycler: every mod that ships its own Balatro title logo (balatro.png / Logo.png / darkBalatro.png ...)
     is detected automatically and can be cycled through.
]]

local mod = SMODS.current_mod
local cfg = mod.config
if type(cfg) ~= 'table' then cfg = {}; mod.config = cfg end
local DEFAULTS = { c1 = 'auto', c2 = 'auto', theme = 'auto', logo = 'auto' }
for k, v in pairs(DEFAULTS) do if cfg[k] == nil then cfg[k] = v end end

local function save_cfg()
  if SMODS.save_mod_config then pcall(SMODS.save_mod_config, mod) end
end

----------------------------------------------------------------------
-- Colours
----------------------------------------------------------------------
local RAND1 = { 1, 0, 0, 1 }
local RAND2 = { 0, 0, 1, 1 }
local C_PINK = HEX('fe55a5')
local C_CYAN = HEX('00eaff')

local PALETTE = {
  { key = 'RED',        label = 'Red',       get = function() return G.C.RED end },
  { key = 'BLUE',       label = 'Blue',      get = function() return G.C.BLUE end },
  { key = 'GREEN',      label = 'Green',     get = function() return G.C.GREEN end },
  { key = 'PURPLE',     label = 'Purple',    get = function() return G.C.PURPLE end },
  { key = 'ORANGE',     label = 'Orange',    get = function() return G.C.ORANGE end },
  { key = 'CYAN',       label = 'Cyan',      get = function() return C_CYAN end },
  { key = 'PINK',       label = 'Pink',      get = function() return C_PINK end },
  { key = 'YELLOW',     label = 'Yellow',    get = function() return G.C.YELLOW end },
  { key = 'JOKER_GREY', label = 'Grey',      get = function() return G.C.JOKER_GREY end },
  { key = 'L_BLACK',    label = 'Charcoal',  get = function() return G.C.L_BLACK end },
  { key = 'RAND1',      label = 'Rainbow A', get = function() return RAND1 end },
  { key = 'RAND2',      label = 'Rainbow B', get = function() return RAND2 end },
}
local PALETTE_BY_KEY = {}
for _, p in ipairs(PALETTE) do PALETTE_BY_KEY[p.key] = p end

local function colour_label(slot)
  local k = cfg['c' .. slot]
  local p = PALETTE_BY_KEY[k]
  return p and p.label or 'Auto'
end
local status = { n1 = colour_label(1), n2 = colour_label(2) }

----------------------------------------------------------------------
-- Theme detection: remember every colour set that any mod gives the main menu background
----------------------------------------------------------------------
local T = { list = {}, by_id = {}, last_foreign = nil, dirty = false, applied_sb = nil, forced = false }
local applying = false

local function caller_mod_id()
  for lvl = 3, 8 do
    local info = debug.getinfo(lvl, 'S')
    if not info then break end
    local src = info.source or ''
    local id = src:match('%[SMODS (%S+) "')
    if id then return id end
    if src:find('game%.lua') then return 'balatro' end
  end
  return nil
end

local function id_to_name(id)
  if id == 'balatro' then return 'Balatro (default)' end
  local m = SMODS.Mods and SMODS.Mods[id]
  return (m and (m.display_name or m.name)) or id
end

local define_ref = Sprite.define_draw_steps
function Sprite:define_draw_steps(defs)
  if not applying and self == G.SPLASH_BACK and type(defs) == 'table' then
    for _, d in ipairs(defs) do
      if d.shader == 'splash' and type(d.send) == 'table' then
        local id = caller_mod_id()
        local rec
        if id and id ~= mod.id then
          rec = T.by_id[id]
          if not rec then
            rec = { id = id, name = id_to_name(id) }
            T.by_id[id] = rec
            T.list[#T.list + 1] = rec
          end
          rec.send = d.send
        end
        T.last_foreign = { id = id, send = d.send }
        T.dirty = true
      end
    end
  end
  return define_ref(self, defs)
end

local function manual_colour(slot)
  local p = PALETTE_BY_KEY[cfg['c' .. slot]]
  return p and p.get() or nil
end

local function wants_override()
  if manual_colour(1) or manual_colour(2) then return true end
  if cfg.theme ~= 'auto' and T.by_id[cfg.theme] then return true end
  return false
end

local function apply_background()
  local sb = G.SPLASH_BACK
  T.dirty = false
  if not sb or not sb.draw_steps then return end
  T.applied_sb = sb
  local c1, c2 = manual_colour(1), manual_colour(2)
  local theme = (cfg.theme ~= 'auto') and T.by_id[cfg.theme] or nil
  if not (c1 or c2 or theme) then
    -- nothing is forced any more: give the background back to whatever the mods set up
    if T.forced and T.last_foreign and T.last_foreign.send then
      applying = true
      pcall(define_ref, sb, { { shader = 'splash', send = T.last_foreign.send } })
      applying = false
    end
    T.forced = false
    return
  end
  local base = (theme and theme.send) or (T.last_foreign and T.last_foreign.send)
  if not base then return end
  local send = {}
  for _, s in ipairs(base) do
    if s.name == 'colour_1' and c1 then
      send[#send + 1] = { name = 'colour_1', val = c1 }
    elseif s.name == 'colour_2' and c2 then
      send[#send + 1] = { name = 'colour_2', val = c2 }
    else
      send[#send + 1] = s
    end
  end
  applying = true
  pcall(define_ref, sb, { { shader = 'splash', send = send } })
  applying = false
  T.forced = true
end

----------------------------------------------------------------------
-- Logo detection: any mod that ships a title-logo-shaped png
----------------------------------------------------------------------
local LOGO = { list = nil, cache = {}, current = nil }

local function png_size(path)
  if not (NFS and NFS.read) then return end
  local ok, hdr = pcall(NFS.read, path, 24)
  if not ok or type(hdr) ~= 'string' or #hdr < 24 or hdr:sub(2, 4) ~= 'PNG' then return end
  local function be(i) local a, b, c, d = hdr:byte(i, i + 3); return ((a * 256 + b) * 256 + c) * 256 + d end
  return be(17), be(21)
end

local function scan_logos()
  if LOGO.list then return LOGO.list end
  local found, per_mod = {}, {}
  local seen = {}
  if SMODS.Mods and NFS and NFS.getDirectoryItems then
    for id, m in pairs(SMODS.Mods) do
      if type(m) == 'table' and m.path and m.can_load ~= false and not m.disabled and id ~= mod.id then
        for _, scale in ipairs({ 2, 1 }) do
          local dir = m.path .. 'assets/' .. scale .. 'x'
          local ok, items = pcall(NFS.getDirectoryItems, dir)
          if ok and type(items) == 'table' then
            for _, f in ipairs(items) do
              local lf = f:lower()
              if lf:sub(-4) == '.png' and not lf:find('icon') and (lf:find('balatro') or lf:find('logo') or lf:find('title')) then
                local key = id .. '/' .. lf
                if not seen[key] then
                  local w, h = png_size(dir .. '/' .. f)
                  if w and h and h > 0 and math.abs(w / h - 333 / 216) < 0.05 then
                    seen[key] = true
                    found[#found + 1] = { id = key, file = f, modpath = m.path, mod_id = id, mod_name = m.display_name or m.name or id }
                    per_mod[id] = (per_mod[id] or 0) + 1
                  end
                end
              end
            end
          end
        end
      end
    end
  end
  table.sort(found, function(a, b) return (a.mod_name .. a.file):lower() < (b.mod_name .. b.file):lower() end)
  for _, e in ipairs(found) do
    e.label = e.mod_name
    if per_mod[e.mod_id] > 1 then e.label = e.mod_name .. ' - ' .. e.file:gsub('%.[pP][nN][gG]$', '') end
  end
  local list = { { id = 'auto', label = 'Auto (as loaded)' }, { id = 'vanilla', label = 'Balatro (default)', vanilla = true } }
  for _, e in ipairs(found) do list[#list + 1] = e end
  LOGO.list = list
  return list
end

local function atlas_for(entry)
  if LOGO.cache[entry.id] then return LOGO.cache[entry.id] end
  local a
  if entry.vanilla then
    local scale = (G.SETTINGS.GRAPHICS and G.SETTINGS.GRAPHICS.texture_scaling) or 2
    local ok, data = pcall(love.image.newImageData, 'resources/textures/' .. scale .. 'x/balatro.png')
    if ok and data then
      local ok2, img = pcall(love.graphics.newImage, data, { mipmaps = true, dpiscale = scale })
      if ok2 then a = { name = 'balatro', px = 333, py = 216, image_data = data, image = img, columns = 1, rows = 1, atlas_table = 'ASSET_ATLAS' } end
    end
  else
    local o = setmetatable({ key = 'balatro', name = 'balatro', path = entry.file, px = 333, py = 216,
      mod = { path = entry.modpath }, atlas_table = 'ASSET_ATLAS', registered = true }, SMODS.Atlas)
    local prev = G.ASSET_ATLAS.balatro
    local ok = pcall(o.inject, o)
    G.ASSET_ATLAS.balatro = prev
    if ok and o.image then a = o end
  end
  LOGO.cache[entry.id] = a
  return a
end

local function apply_logo()
  if not G.ASSET_ATLAS then return end
  if not LOGO.original then LOGO.original = G.ASSET_ATLAS.balatro end
  local want
  if cfg.logo == 'auto' then
    want = LOGO.original
  else
    for _, e in ipairs(scan_logos()) do
      if e.id == cfg.logo then want = atlas_for(e); break end
    end
    if not want then want = LOGO.original end
  end
  if want and G.ASSET_ATLAS.balatro ~= want then
    G.ASSET_ATLAS.balatro = want
    if G.I and G.I.SPRITE then
      for _, v in pairs(G.I.SPRITE) do
        if v.atlas and v.atlas.name == 'balatro' then pcall(v.reset, v) end
      end
    end
  end
end

----------------------------------------------------------------------
-- Hooks
----------------------------------------------------------------------
local update_ref = Game.update
function Game:update(dt)
  update_ref(self, dt)
  local t = self.TIMERS.REAL
  RAND1[1] = 0.5 + 0.5 * math.cos(t)
  RAND1[2] = 2 / 3 + 1 / 3 * math.cos(t + 0.6 * math.pi)
  RAND1[3] = 2 / 3 + 1 / 3 * math.cos(t + math.pi)
  RAND2[1] = 2 / 3 + 1 / 3 * math.cos(t + math.pi)
  RAND2[2] = 2 / 3 + 1 / 3 * math.cos(t - 0.6 * math.pi)
  RAND2[3] = 0.5 + 0.5 * math.cos(t)
  -- Re-assert our choice whenever another mod (or the game) repainted the background.
  if (T.dirty or G.SPLASH_BACK ~= T.applied_sb) and (wants_override() or T.forced) then
    apply_background()
  elseif G.SPLASH_BACK ~= T.applied_sb then
    T.applied_sb = G.SPLASH_BACK
    T.dirty = false
  else
    T.dirty = false
  end
end

local main_menu_ref = Game.main_menu
function Game:main_menu(change_context)
  main_menu_ref(self, change_context)
  T.dirty = true
  if wants_override() or T.forced then pcall(apply_background) end
  if cfg.logo ~= 'auto' or LOGO.original then pcall(apply_logo) end
end

----------------------------------------------------------------------
-- UI
----------------------------------------------------------------------
local function rebuild_status()
  status.n1 = colour_label(1)
  status.n2 = colour_label(2)
end

G.FUNCS.csel_pick = function(e)
  local d = e.config.ref_table
  if not d then return end
  cfg['c' .. d.slot] = d.key
  rebuild_status()
  save_cfg()
  apply_background()
  if play_sound then play_sound('button', 1, 0.3) end
end

G.FUNCS.csel_swatch_hl = function(e)
  local d = e.config.ref_table
  if not d then return end
  local on = cfg['c' .. d.slot] == d.key
  e.config.outline = on and 1.6 or nil
  e.config.outline_colour = G.C.WHITE
end

local function swatch_row(slot)
  local nodes = {}
  nodes[#nodes + 1] = { n = G.UIT.C, config = { align = 'cm', padding = 0.04 }, nodes = {
    { n = G.UIT.C, config = { align = 'cm', minw = 0.95, minh = 0.5, r = 0.1, hover = true, shadow = true, colour = G.C.GREY,
      button = 'csel_pick', func = 'csel_swatch_hl', ref_table = { slot = slot, key = 'auto' } }, nodes = {
      { n = G.UIT.T, config = { text = 'Auto', scale = 0.32, colour = G.C.UI.TEXT_LIGHT, shadow = true } } } } } }
  for _, p in ipairs(PALETTE) do
    nodes[#nodes + 1] = { n = G.UIT.C, config = { align = 'cm', padding = 0.04 }, nodes = {
      { n = G.UIT.C, config = { align = 'cm', minw = 0.5, minh = 0.5, r = 0.1, hover = true, shadow = true, colour = p.get(),
        button = 'csel_pick', func = 'csel_swatch_hl', ref_table = { slot = slot, key = p.key } }, nodes = {} } } }
  end
  return { n = G.UIT.R, config = { align = 'cm', padding = 0 }, nodes = nodes }
end

local function section(title_prefix, slot)
  return { n = G.UIT.R, config = { align = 'cm', padding = 0.03 }, nodes = {
    { n = G.UIT.R, config = { align = 'cm', padding = 0.02 }, nodes = {
      { n = G.UIT.T, config = { text = title_prefix .. ': ', scale = 0.38, colour = G.C.UI.TEXT_LIGHT, shadow = true } },
      { n = G.UIT.T, config = { ref_table = status, ref_value = 'n' .. slot, scale = 0.38, colour = G.C.ORANGE, shadow = true } },
    } },
    swatch_row(slot),
  } }
end

local function theme_lists()
  local ids, labels = { 'auto' }, { 'Auto (as loaded)' }
  for _, rec in ipairs(T.list) do ids[#ids + 1] = rec.id; labels[#labels + 1] = rec.name end
  return ids, labels
end

G.FUNCS.csel_theme_cycle = function(args)
  local ids = theme_lists()
  cfg.theme = ids[args.to_key] or 'auto'
  save_cfg()
  apply_background()
end

G.FUNCS.csel_logo_cycle = function(args)
  local list = scan_logos()
  local pick = list[args.to_key]
  cfg.logo = pick and pick.id or 'auto'
  save_cfg()
  apply_logo()
end

local function panel_nodes()
  rebuild_status()
  local t_ids, t_labels = theme_lists()
  local t_cur = 1
  for i, id in ipairs(t_ids) do if id == cfg.theme then t_cur = i end end
  local logos = scan_logos()
  local l_labels, l_cur = {}, 1
  for i, e in ipairs(logos) do l_labels[i] = e.label; if e.id == cfg.logo then l_cur = i end end
  return {
    { n = G.UIT.R, config = { align = 'cm', padding = 0.04 }, nodes = {
      { n = G.UIT.T, config = { text = 'Main Menu Theme', scale = 0.55, colour = G.C.UI.TEXT_LIGHT, shadow = true } } } },
    section('Outer Colour', 1),
    section('Inner Colour', 2),
    { n = G.UIT.R, config = { align = 'cm', padding = 0.02 }, nodes = {
      create_option_cycle({ w = 7, scale = 0.62, label = 'Background Theme (from mods)', options = t_labels,
        opt_callback = 'csel_theme_cycle', current_option = t_cur, colour = G.C.RED }) } },
    { n = G.UIT.R, config = { align = 'cm', padding = 0.02 }, nodes = {
      create_option_cycle({ w = 7, scale = 0.62, label = 'Title Logo (from mods)', options = l_labels,
        opt_callback = 'csel_logo_cycle', current_option = l_cur, colour = G.C.RED }) } },
    { n = G.UIT.R, config = { align = 'cm', padding = 0.02 }, nodes = {
      { n = G.UIT.T, config = { text = 'A colour you pick always wins over a mod theme. Auto = use the theme.', scale = 0.25, colour = G.C.UI.TEXT_INACTIVE } } } },
  }
end

function G.UIDEF.csel_menu()
  return create_UIBox_generic_options({ back_func = 'settings', contents = panel_nodes() })
end

G.FUNCS.csel_open = function(e)
  G.SETTINGS.paused = true
  G.FUNCS.overlay_menu({ definition = G.UIDEF.csel_menu() })
end

-- Also show the same controls in this mod's page of the Mods menu.
mod.config_tab = function()
  return { n = G.UIT.ROOT, config = { align = 'cm', padding = 0.1, r = 0.1, colour = G.C.BLACK, minw = 8, minh = 5 }, nodes = panel_nodes() }
end

-- One compact row in the Game settings tab (directly under the Game Speed options).
local settings_tab_ref = G.UIDEF.settings_tab
function G.UIDEF.settings_tab(tab)
  local setting_tab = settings_tab_ref(tab)
  if tab == 'Game' and type(setting_tab) == 'table' and setting_tab.nodes then
    -- The Game tab is almost full already: tighten the toggle rows a little to make room for our row.
    for i = 2, #setting_tab.nodes do
      local n = setting_tab.nodes[i]
      if type(n) == 'table' and n.config and n.config.padding == 0.1 and n.config.r == 0.1
         and n.config.focus_args and n.config.focus_args.funnel_from then
        n.config.padding = 0.03
      end
    end
    local row = { n = G.UIT.R, config = { align = 'cm', padding = 0.02 }, nodes = {
      UIBox_button({ button = 'csel_open', label = { 'Main Menu Theme' }, minw = 4.2, minh = 0.5, scale = 0.38, colour = G.C.BLUE,
        focus_args = { nav = 'wide' } }) } }
    table.insert(setting_tab.nodes, 2, row)
  end
  return setting_tab
end
