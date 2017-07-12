
--[[===============================================================================================

File run before main.

=================================================================================================]]

function love.conf(t)
  love.filesystem.setRequirePath('scripts/?.lua;/?.lua')
  PROFI = require('ProFi')
  JSON = require('core/save/JsonParser')
  local configjson = love.filesystem.read('data/config.json')
  Config = JSON.decode(configjson)
  Database = {}
	local db = {'attributes', 'items', 'skills', 'skillDags', 'battlers', 'status', 
    'animCharacter', 'animBattle', 'animOther', 'terrains', 'obstacles', 'ramps', 'troops',
    'charBattle', 'charField', 'charOther'}
	for i = #db, 1, -1 do
    local file = db[i]
    local datajson = love.filesystem.read('data/' .. file .. '.json')
		Database[file] = JSON.decode(datajson)
	end
  t.identity = Config.name 
  t.window.title = Config.name
  t.window.icon = 'images/icon24.png'
  t.window.width = Config.screen.nativeWidth * Config.screen.widthScale
  t.window.height = Config.screen.nativeHeight * Config.screen.heightScale
  t.window.fullscreentype = 'desktop'
  t.window.vsync = true 
  t.modules.joystick = false
  t.modules.physics = false
end
