
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

local TargetWindow = Window:inherit()

-------------------------------------------------------------------------------
-- Initialization
-------------------------------------------------------------------------------

-- Overrides Window:init.
local old_init = TargetWindow.init
function TargetWindow:init(GUI, skin)
  local w = 108
  local h = 48
  local p = 12
  old_init(self, GUI, w, h, Vector(ScreenManager.width / 2 - w / 2 - p, 
      -ScreenManager.height / 2 + h / 2 + p), skin)
  
  --[[local hpw = self.paddingw / 2
  local w = self.width / 2 - hpw * 3
  local h = self.height - self.paddingh * 2
  
  local pos1 = Vector(hpw, self.paddingh, -1)
  local pos2 = Vector(hpw, self.paddingh + 20, -1)
  local pos3 = Vector(hpw, self.paddingh + 40, -1)
  
  local attHP = attConfig[battleConfig.attHPID + 1]
  local attSP = attConfig[battleConfig.attSPID + 1]
  
  self.textHP = SimpleText(attHP.shortName, pos1, w)
  self.textSP = SimpleText(attSP.shortName, pos2, w)
  self.textTC = SimpleText(Vocab.turnCount, pos3, w)
  
  self.textHPValue = SimpleText('', pos1, w, 'right')
  self.textSPValue = SimpleText('', pos2, w, 'right')
  self.textTCValue = SimpleText('', pos3, w, 'right')]]
end

function TargetWindow:setBattler(battler)  
  --[[if self.portrait then
    self.portrait:destroy()
  end
  local w = self.width / 2 - 3 * self.paddingw / 2
  local h = self.height - self.paddingh * 2
  self.portrait = BattlePortrait(battler, 'Small', 
    self.paddingw, self.paddingh, w, h)
  
  self.textHPValue:setText(battler.currentHP)
  self.textSPValue:setText(battler.currentSP)
  self.textTCValue:setText(battler.turnCount)]]
end

return TargetWindow
