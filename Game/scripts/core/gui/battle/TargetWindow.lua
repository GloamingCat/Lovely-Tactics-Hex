
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
local old_init = TargetWindow.init
function TargetWindow:init(GUI, skin)
  local w = 100
  local h = 70
  local m = 12
  old_init(self, GUI, w, h, Vector(ScreenManager.width / 2 - w / 2 - m, 
      -ScreenManager.height / 2 + h / 2 + m), skin)
  
  local x = - w / 2 + self.paddingw
  local y = - h / 2 + self.paddingh
  w = w - self.paddingw * 2

  -- Name text
  local posName = Vector(x, y, -1)
  self.textName = SimpleText('', posName, w, 'center')
  self.content:add(self.textName)
  
  -- State values texts
  self.textState = {}
  self.textStateValues = {}
  local varCount = 0
  for i = 1, #stateVariables do
    local var = stateVariables[i]
    if var.targetGUI then
      varCount = varCount + 1
      local pos = Vector(x, y + 5 + varCount * 10, -1)
      local textName = SimpleText(var.shortName .. ':', pos, w, 'left', font)
      local textValue = SimpleText('', pos, w, 'right', font)
      self.textState[var.shortName] = textName
      self.textStateValues[var.shortName] = textValue
      self.content:add(textName)
      self.content:add(textValue)
    end
  end
  
  -- Turn count text
  local posTC = Vector(x, y + 15 + varCount * 10, -1)
  self.textTC = SimpleText(Vocab.turnCount .. ':', posTC, w, 'left', font)
  self.textTCValue = SimpleText('', posTC, w, 'right', font)
  self.content:add(self.textTC)
  self.content:add(self.textTCValue)
  
  collectgarbage('collect')
end

---------------------------------------------------------------------------------------------------
-- Update
---------------------------------------------------------------------------------------------------

function TargetWindow:setBattler(battler)  
  -- Name text
  self.textName:setText(battler.data.name)
  
  -- State values text
  for i = 1, #stateVariables do
    local v = stateVariables[i]
    if v.targetGUI then
      local currentValue = battler.state[v.shortName]
      local maxValue = battler.stateMax[v.shortName](battler.att)
      local text = currentValue .. ''
      if maxValue then
        text = text .. '/' .. maxValue
      end
      self.textStateValues[v.shortName]:setText(text)
    end
  end

  -- Turn count text
  local tc = (battler.state.turnCount / BattleManager.turnLimit * 100)
  self.textTCValue:setText(string.format( '%3.0f', tc ) .. '%')
  
  collectgarbage('collect')
end

return TargetWindow
