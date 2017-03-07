
local GUI = require('core/gui/GUI')
local TurnWindow = require('custom/gui/battle/TurnWindow')
local SkillWindow = require('custom/gui/battle/SkillWindow')
local ItemWindow = require('custom/gui/battle/ItemWindow')
local Vector = require('core/math/Vector')

--[[===========================================================================

The GUI that is openned in the start of a character turn.

=============================================================================]]

local BattleGUI = GUI:inherit()

function BattleGUI:createWindows()
  self.name = 'Battle GUI'
  
  local skillList = BattleManager.currentCharacter.battler.skillList
  if not skillList:isEmpty() then
    self.skillWindow = SkillWindow(self)
  end
  
  local itemList = BattleManager.currentCharacter.battler.inventory
  if not itemList:isEmpty() then
    self.itemWindow = ItemWindow(self)
  end
  
  self.turnWindow = TurnWindow(self)
  self.turnWindow:setPosition(Vector(-ScreenManager.width / 2 + self.turnWindow.width / 2 + 8, 
      -ScreenManager.height / 2 + self.turnWindow.height / 2 + 8))
  
  self.activeWindow = self.turnWindow
  self.windowList:add(self.turnWindow)
end

-- Overrides GUI:show.
local old_show = BattleGUI.show
function BattleGUI:show(...)
  FieldManager.renderer:moveToObject(BattleManager.currentCharacter)
  old_show(self, ...)
end

return BattleGUI
