
--[[===============================================================================================

Conf
---------------------------------------------------------------------------------------------------
File run before main. Prepares window.

=================================================================================================]]

love.filesystem.setRequirePath('scripts/?.lua;/?.lua')

require('override')
require('mathlib')
require('class')

local Serializer = require('core/save/Serializer')

function love.conf(t)
  local projectName = 'project'
  for k, v in pairs(arg) do
    if v == '-p' then
      projectName = arg[k + 1]
      break
    end
  end
  print("Loading project '" .. projectName .. "'")
  Project = Serializer.load(projectName .. '.json')
  Config = Serializer.load(Project.dataPath .. '/system/config.json')
  t.identity = Config.name 
  t.window.title = Config.name
  t.window.icon = Project.imagePath .. '/icon.png'
  t.window.width = Config.screen.nativeWidth * Config.screen.widthScale / 100
  t.window.height = Config.screen.nativeHeight * Config.screen.heightScale / 100
  t.window.fullscreentype = 'desktop'
  t.window.usedpiscale = false
  t.window.vsync = false
  t.modules.joystick = false
  t.modules.physics = false
end
