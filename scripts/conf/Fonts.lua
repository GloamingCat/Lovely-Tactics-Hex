
local multiplier = Config.platform == 1 and 1 or 0.9

local huge_font = { 'Roboto', 'ttf', 25 * multiplier }
local big_font = { 'Roboto', 'ttf', 20 * multiplier }
local critical_font = { 'Roboto', 'ttf', 17 * multiplier }
local default_font = { 'Roboto', 'ttf', 14 * multiplier }
local medium_font = { 'Roboto', 'ttf', 11 * multiplier }
local small_font = { 'Roboto', 'ttf', 9 * multiplier }
local tiny_font = { 'Roboto', 'ttf', 7.5 * multiplier }
local fps_font = { 'Roboto', 'ttf', 5 * multiplier }

return  {

	-- Fonts
	gui_title = huge_font,
	gui_default = default_font,
	gui_button = default_font,
	gui_dialogue = medium_font,
	gui_tiny = tiny_font,
	gui_small = small_font,
	gui_medium = medium_font,
	gui_big = big_font,
	gui_huge = huge_font,

	popup_dmghp = default_font,
	popup_dmgsp = default_font,
	popup_healhp = default_font,
	popup_healsp = default_font,
	popup_dmghp_crit = critical_font,
	popup_dmgsp_crit = critical_font,
	popup_healhp_crit = critical_font,
	popup_healsp_crit = critical_font,

	popup_miss = default_font,
	popup_status_add = default_font,
	popup_status_remove = default_font,
	popup_levelup = default_font,

	fps = fps_font,
  pause = medium_font,

	-- Settings
	scale = 4,
	outlineSize = 4

}
