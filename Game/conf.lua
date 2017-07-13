
--[[===============================================================================================

Conf
---------------------------------------------------------------------------------------------------
File run before main. Prepares window.

=================================================================================================]]

function love.conf(t)
  love.filesystem.setRequirePath('scripts/?.lua;/?.lua')
  JSON = require('core/save/JsonParser')
  local configjson = love.filesystem.read('data/config.json')
  Config = JSON.decode(configjson)
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
