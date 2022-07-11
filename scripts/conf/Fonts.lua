
local huge_font = { 'Roboto', 'ttf', 20 }
local big_font = { 'Roboto', 'ttf', 15 }
local critical_font = { 'Roboto', 'ttf', 13 }
local default_font = { 'Roboto', 'ttf', 11 }
local medium_font = { 'Roboto', 'ttf', 9.5 }
local small_font = { 'Roboto', 'ttf', 8 }
local tiny_font = { 'Roboto', 'ttf', 6.5 }
local fps_font = { 'Roboto', 'ttf', 3 }

return  {

	-- Fonts
	gui_title = huge_font,
	gui_default = default_font,
	gui_button = medium_font,
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

	-- Settings
	scale = 4,
	outlineSize = 4

}
