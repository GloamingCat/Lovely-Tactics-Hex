
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
local BattlePortrait = require('custom/gui/battle/BattlePortrait')

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
  local w = 180
  local h = 80
  local m = 12
  old_init(self, GUI, w, h, Vector(ScreenManager.width / 2 - w / 2 - m, 
      -ScreenManager.height / 2 + h / 2 + m), skin)
  
  local hpw = self.paddingw / 2
  w = w / 2
  h = - h / 2 + self.paddingh
  
  local pos1 = Vector(-hpw, h, -1)
  local pos2 = Vector(-hpw, h + 10, -1)
  local pos3 = Vector(-hpw, h + 20, -1)
  local pos4 = Vector(-hpw, h + 30, -1)
  
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
  if self.portrait then
    self.portrait:destroy()
  end
  local w = self.width / 2 - 3 * self.paddingw / 2
  local h = self.height - self.paddingh * 2
  self.portrait = BattlePortrait(battler, 'Small', 
    self.paddingw, self.paddingh, w, h)
  
  local tc = (battler.turnCount / BattleManager.turnLimit * 100)
  
  self.textName:setText(battler.data.name)
  self.textHPValue:setText(battler.currentHP .. '/' .. battler:maxHP())
  self.textSPValue:setText(battler.currentSP .. '/' .. battler:maxSP())
  self.textTCValue:setText(string.format( '%3.0f', tc ) .. '%')
  
  collectgarbage('collect')
end

return TargetWindow
