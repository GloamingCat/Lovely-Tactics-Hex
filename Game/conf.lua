
--[[===========================================================================

File run before main.

=============================================================================]]

love.filesystem.setRequirePath('scripts/?.lua;/?.lua')
require('core/requireoverride')
require('core/coroutineerr')

function love.conf(t)
  JSON = require('core/save/JsonParser')
  Config = JSON.decode(love.filesystem.read('data/config.json'))
  Database = {}
	local db = {'items', 'skills', 'skillDags', 'battlers', 'status', 'animCharacter', 
    'animBattle', 'animOther', 'terrains', 'obstacles', 'ramps', 'characters', 'tilesets'}
	for i,file in ipairs(db) do
		Database[file] = JSON.decode(love.filesystem.read('data/' .. file .. '.json'))
	end
  t.window.title = Config.name
  t.window.width = 400
  t.window.height = 225
  t.window.fullscreentype = 'desktop'
  t.modules.joystick = false
  t.modules.physics = false
end
