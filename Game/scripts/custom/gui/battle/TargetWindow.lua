
--[[===========================================================================

TargetWindow
-------------------------------------------------------------------------------
Window that shows when the battle cursor is over a character.

=============================================================================]]

-- Imports
local Vector = require('core/math/Vector')
local Sprite = require('core/graphics/Sprite')
local Window = require('core/gui/Window')
local SimpleText = require('core/gui/SimpleText')

-- Constants
local battleConfig = Config.battle
local attConfig = Config.attributes
local font = Font.gui_small

local TargetWindow = Window:inherit()

-------------------------------------------------------------------------------
-- Initialization
-------------------------------------------------------------------------------

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
  local pos2 = Vector(x, y + 15, -1)
  local pos3 = Vector(x, y + 25, -1)
  local pos4 = Vector(x, y + 35, -1)
  
  local attHP = attConfig[battleConfig.attHPID + 1]
  local attSP = attConfig[battleConfig.attSPID + 1]
  
  self.textName = SimpleText('', pos1, w, 'center')
  self.textHP = SimpleText(attHP.shortName .. ':', pos2, w, 'left', font)
  self.textSP = SimpleText(attSP.shortName .. ':', pos3, w, 'left', font)
  self.textTC = SimpleText(Vocab.turnCount .. ':', pos4, w, 'left', font)
  
  self.textHPValue = SimpleText('', pos2, w, 'right', font)
  self.textSPValue = SimpleText('', pos3, w, 'right', font)
  self.textTCValue = SimpleText('', pos4, w, 'right', font)
  self.content:add(self.textName)
  self.content:add(self.textHP)
  self.content:add(self.textSP)
  self.content:add(self.textTC)
  self.content:add(self.textHPValue)
  self.content:add(self.textSPValue)
  self.content:add(self.textTCValue)
  collectgarbage('collect')
end

function TargetWindow:setBattler(battler)  
  local tc = (battler.turnCount / BattleManager.turnLimit * 100)
  self.textName:setText(battler.data.name)
  self.textHPValue:setText(battler.currentHP .. '/' .. battler:maxHP())
  self.textSPValue:setText(battler.currentSP .. '/' .. battler:maxSP())
  self.textTCValue:setText(string.format( '%3.0f', tc ) .. '%')
  collectgarbage('collect')
end

return TargetWindow
