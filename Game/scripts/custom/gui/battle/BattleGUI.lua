
--[[===============================================================================================

BattleGUI
---------------------------------------------------------------------------------------------------
The GUI that is openned in the start of a character turn.
Its result is the action time that the character spent.

=================================================================================================]]

-- Imports
local GUI = require('core/gui/GUI')
local TurnWindow = require('core/gui/battle/TurnWindow')
local SkillWindow = require('core/gui/battle/SkillWindow')
local ItemWindow = require('core/gui/battle/ItemWindow')
local Vector = require('core/math/Vector')

local BattleGUI = class(GUI)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

function BattleGUI:createWindows()
  self.name = 'Battle GUI'
  -- Skill Window
  local skillList = BattleManager.currentCharacter.battler.skillList
  if not skillList:isEmpty() then
    self.skillWindow = SkillWindow(self, skillList)
  end
  -- Item Window
  local inventory = SaveManager.current.partyInventory
  if Battle.individualInventory then
    inventory = BattleManager.currentCharacter.battler.inventory
  end
  local itemList = inventory:getUsableItems(1)
  if #itemList > 0 then
    self.itemWindow = ItemWindow(self, inventory, itemList)
  end
  -- Main Window
  self.turnWindow = TurnWindow(self)
  self.turnWindow:setPosition(Vector(-ScreenManager.width / 2 + self.turnWindow.width / 2 + 8, 
      -ScreenManager.height / 2 + self.turnWindow.height / 2 + 8))
  -- Initial state
  self.windowList:add(self.turnWindow)
  self:setActiveWindow(self.turnWindow)
end

---------------------------------------------------------------------------------------------------
-- Camera focus
---------------------------------------------------------------------------------------------------

-- Overrides GUI:show.
local old_show = BattleGUI.show
function BattleGUI:show(...)
  FieldManager.renderer:moveToObject(BattleManager.currentCharacter)
  old_show(self, ...)
end

return BattleGUI
