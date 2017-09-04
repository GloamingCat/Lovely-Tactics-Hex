
--[[===============================================================================================

TargetWindow
---------------------------------------------------------------------------------------------------
Window that shows when the battle cursor is over a character.

=================================================================================================]]

-- Imports
local Vector = require('core/math/Vector')
local Sprite = require('core/graphics/Sprite')
local Window = require('core/gui/Window')
local SimpleText = require('core/gui/SimpleText')

-- Constants
local hpName = Config.battle.attHP
local spName = Config.battle.attSP
local font = Font.gui_small

local TargetWindow = class(Window)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Overrides Window:init.
function TargetWindow:init(GUI)
  local w = 100
  local h = self:calculateHeight()
  local margin = 12
  Window.init(self, GUI, w, h, Vector(ScreenManager.width / 2 - w / 2 - margin, 
      -ScreenManager.height / 2 + h / 2 + margin))
end
-- Initializes name and status texts.
function TargetWindow:createContent(width, height)
  Window.createContent(self, width, height)
  -- Top-left position
  local x = -self.width / 2 + self:hPadding()
  local y = -self.height / 2 + self:vpadding()
  local w = self.width - self:hPadding() * 2
  -- Name text
  local posName = Vector(x, y)
  self.textName = SimpleText('', posName, w, 'center')
  self.content:add(self.textName)
  -- State values texts  
  local posHP = Vector(x, y + 15)
  self.textHP = self:addStateVariable(hpName, posHP, w)
  local posSP = Vector(x, y + 25)
  self.textSP = self:addStateVariable(spName, posSP, w)
  collectgarbage('collect')
end
-- Creates texts for the given state variable.
-- @param(name : string) the name of the variable
-- @param(pos : Vector) the position of the text
-- @param(w : width) the max width of the text
function TargetWindow:addStateVariable(name, pos, w)
  local textName = SimpleText(name .. ':', pos, w, 'left', font)
  local textValue = SimpleText('', pos, w, 'right', font)
  self.content:add(textName)
  self.content:add(textValue)
  return textValue
end

---------------------------------------------------------------------------------------------------
-- Content
---------------------------------------------------------------------------------------------------

-- Changes the window's content to show the given battler's stats.
-- @param(battler : Battler)
function TargetWindow:setBattler(battler)  
  -- Name text
  self.textName:setText(battler.data.name)
  self.textName:redraw()
  -- HP text
  local textHP = battler.state[hpName] .. '/' .. battler.att[hpName]()
  self.textHP:setText(textHP)
  self.textHP:redraw()
  -- SP text
  local textSP = battler.state[spName] .. '/' .. battler.att[spName]()
  self.textSP:setText(textSP)
  self.textSP:redraw()
  collectgarbage('collect')
end

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Calculates the height given the shown variables.
function TargetWindow:calculateHeight()
  return self:vpadding() * 2 + 35
end
-- String representation.
function TargetWindow:__tostring()
  return 'TargetWindow'
end

return TargetWindow
