
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
local stateValues = Config.battle.stateValues
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
  
  local pos1 = Vector(x, y, -1)
  local pos2 = Vector(x, y + 15 + #stateValues * 10, -1)

  -- Name text
  self.textName = SimpleText('', pos1, w, 'center')
  self.content:add(self.textName)
  
  -- State values texts
  self.textState = {}
  self.textStateValues = {}
  for i = 1, #stateValues do
    local value = stateValues[i]
    local pos = Vector(x, y + 5 +  i * 10, -1)
    local textName = SimpleText(value.shortName .. ':', pos, w, 'left', font)
    local textValue = SimpleText('', pos, w, 'right', font)
    self.textState[value.shortName] = textName
    self.textStateValues[value.shortName] = textValue
    self.content:add(textName)
    self.content:add(textValue)
  end
  
  -- Turn count text
  self.textTC = SimpleText(Vocab.turnCount .. ':', pos2, w, 'left', font)
  self.textTCValue = SimpleText('', pos2, w, 'right', font)
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
  for i = 1, #stateValues do
    local v = stateValues[i]
    local currentValue = battler.state[v.shortName]
    local maxValue = battler.stateMax[v.shortName](battler.att)
    local text = currentValue .. ''
    if maxValue then
      text = text .. '/' .. maxValue
    end
    self.textStateValues[v.shortName]:setText(text)
  end

  -- Turn count text
  local tc = (battler.state.turnCount / BattleManager.turnLimit * 100)
  self.textTCValue:setText(string.format( '%3.0f', tc ) .. '%')
  
  collectgarbage('collect')
end

return TargetWindow
