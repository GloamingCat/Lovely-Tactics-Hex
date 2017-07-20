
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
local stateVariables = Config.stateVariables
local battleConfig = Config.battle
local attConfig = Config.attributes
local font = Font.gui_small

local TargetWindow = class(Window)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Overrides Window:init.
function TargetWindow:init(GUI)
  local vars = {}
  for i = 1, #stateVariables do
    local var = stateVariables[i]
    if var.targetGUI then
      vars[#vars + 1] = var
    end
  end
  self.vars = vars
  local w = 100
  local h = self:vpadding() * 2 + 25 + #vars * 10
  local margin = 12
  Window.init(self, GUI, w, h, Vector(ScreenManager.width / 2 - w / 2 - margin, 
      -ScreenManager.height / 2 + h / 2 + margin))
end
-- Initializes name and status texts.
function TargetWindow:createContent()
  Window.createContent(self)
  -- Top-left position
  local x = -self.width / 2 + self:hpadding()
  local y = -self.height / 2 + self:vpadding()
  local w = self.width - self:hpadding() * 2
  -- Name text
  local posName = Vector(x, y)
  self.textName = SimpleText('', posName, w, 'center')
  self.content:add(self.textName)
  -- State values texts
  self.textState = {}
  self.textStateValues = {}
  for i = 1, #self.vars do
    local var = self.vars[i]
    local pos = Vector(x, y + 5 + i * 10)
    local textName = SimpleText(var.shortName .. ':', pos, w, 'left', font)
    local textValue = SimpleText('', pos, w, 'right', font)
    self.textState[var.shortName] = textName
    self.textStateValues[var.shortName] = textValue
    self.content:add(textName)
    self.content:add(textValue)
  end
  -- Turn count text
  local posTC = Vector(x, y + 15 + #self.vars * 10)
  self.textTC = SimpleText(Vocab.turnCount .. ':', posTC, w, 'left', font)
  self.textTCValue = SimpleText('', posTC, w, 'right', font)
  self.content:add(self.textTC)
  self.content:add(self.textTCValue)
  collectgarbage('collect')
end

---------------------------------------------------------------------------------------------------
-- Content
---------------------------------------------------------------------------------------------------

function TargetWindow:setBattler(battler)  
  -- Name text
  self.textName:setText(battler.data.name)
  self.textName:redraw()
  -- State values text
  for i = 1, #self.vars do
    local v = self.vars[i]
    local currentValue = battler.state[v.shortName]
    local maxValue = battler.stateMax[v.shortName](battler.att)
    local text = currentValue .. ''
    if maxValue then
      text = text .. '/' .. maxValue
    end
    local stateText = self.textStateValues[v.shortName]
    stateText:setText(text)
    stateText:redraw()
  end
  -- Turn count text
  local tc = (battler.state.turnCount / Battle.turnLimit * 100)
  self.textTCValue:setText(string.format( '%3.0f', tc ) .. '%')
  self.textTCValue:redraw()
  collectgarbage('collect')
end

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- String representation.
function TargetWindow:__tostring()
  return 'TargetWindow'
end

return TargetWindow
