
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
  print("OS: " .. love._os)
  local projectName = nil
  for k, v in pairs(arg) do
    if v == '-p' then
      projectName = arg[k + 1] .. '.json'
      break
    end
  end
  if not projectName then
    local files = love.filesystem.getDirectoryItems('/')
    for i = 1, #files do
      if files[i]:find('%w*' .. '%.json') then
        projectName = files[i]
        break
      end
    end
  end
  print("Loading project '" .. projectName .. "'")
  Project = Serializer.load(projectName)
  Config = Serializer.load(Project.dataPath .. '/system/config.json')
  if love._os == 'Android' or love._os == 'iOS' then
    if Config.platform % 2 == 0 then
      Config.platform = Config.platform + 1 -- Make mobile
    end
  elseif love._os == 'Web' then
    if Config.platform < 2 then
      Config.platform = Config.platform + 2 -- Make web
    end
  end
  t.identity = Config.name 
  t.window.title = Config.name
  t.window.icon = Project.imagePath .. '/icon.png'
  t.window.fullscreentype = 'desktop'
  t.window.resizable = true
  t.window.usedpiscale = false
  t.window.vsync = false
  t.modules.joystick = true
  t.modules.physics = false
  t.window.minwidth = Config.screen.nativeWidth
  t.window.minheight = Config.screen.nativeHeight
  t.window.width = Config.screen.nativeWidth * Config.screen.widthScale / 100
  t.window.height = Config.screen.nativeHeight * Config.screen.heightScale / 100
  t.window.fullscreen = Config.platform == 1
end
