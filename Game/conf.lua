
--[[===========================================================================

File run before main.

=============================================================================]]

PROFI = require('ProFi')
love.filesystem.setRequirePath('scripts/?.lua;/?.lua')
require('core/requireoverride')
require('core/coroutineerr')

function love.conf(t)
  JSON = require('core/save/JsonParser')
  Config = JSON.decode(love.filesystem.read('data/config.json'))
  Database = {}
	local db = {'items', 'skills', 'skillDags', 'battlers', 'status', 'tilesets', 
    'animCharacter', 'animBattle', 'animOther', 'terrains', 'obstacles', 'ramps',
    'charBattle', 'charField', 'charOther'}
	for i = #db, 1, -1 do
    local file = db[i]
		Database[file] = JSON.decode(love.filesystem.read('data/' .. file .. '.json'))
	end
  t.window.title = Config.name
  t.window.width = Config.screen.nativeWidth * Config.screen.widthScale
  t.window.height = Config.screen.nativeHeight * Config.screen.heightScale
  t.window.fullscreentype = 'desktop'
  t.window.vsync = true 
  t.modules.joystick = false
  t.modules.physics = false
end
