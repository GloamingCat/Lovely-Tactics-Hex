
local huge_font = { 'Roboto', 'ttf', 25 }
local big_font = { 'Roboto', 'ttf', 20 }
local critical_font = { 'Roboto', 'ttf', 17 }
local default_font = { 'Roboto', 'ttf', 14 }
local medium_font = { 'Roboto', 'ttf', 11 }
local small_font = { 'Roboto', 'ttf', 9 }
local tiny_font = { 'Roboto', 'ttf', 7.5 }
local log_font = { 'Roboto', 'ttf', 5 }

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
  gui_tooltip = medium_font,

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

	log = log_font,
  pause = medium_font

}
