
-- ================================================================================================

--- Font configuration.
---------------------------------------------------------------------------------------------------
-- @conf Fonts

-- ================================================================================================

--- Format of the font info table. It's an array with 3 to 5 elements.
-- @table Info
-- @tfield string 1 The name of the font style.
-- @tfield string 2 The name of the font's file type.
-- @tfield number 3 The size of the font.
-- @tfield boolean 4 Make the text italic.
-- @tfield boolean 5 Make the text bold.

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
	menu_title = huge_font,
	menu_default = default_font,
	menu_button = default_font,
	menu_dialogue = medium_font,
	menu_tiny = tiny_font,
	menu_small = small_font,
	menu_medium = medium_font,
	menu_big = big_font,
	menu_huge = huge_font,
	menu_tooltip = medium_font,

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
	popup_exp = medium_font,

	log = log_font,
	pause = medium_font

}
