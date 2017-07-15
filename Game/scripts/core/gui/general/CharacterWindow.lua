
--[[===============================================================================================

CharacterWindow
---------------------------------------------------------------------------------------------------
Horizontal window to select a character.

=================================================================================================]]

-- Imports
local Battler = require('core/battle/Battler')
local ButtonWindow = require('core/gui/ButtonWindow')

-- Constants


local CharacterWindow = class(ButtonWindow)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(members : table) array of battler data tables (from database)
--  (optional, all party members by default)
function CharacterWindow:init(GUI, members)
  local vars = {}
  for i = 1, #stateVariables do
    local var = stateVariables[i]
    if var.targetGUI then
      vars[#vars + 1] = var
    end
  end
  self.vars = vars
  self.members = members or PartyManager:currentBattlers()
  ButtonWindow.init(self, GUI)
end
-- Creates a button for each character.
function CharacterWindow:createButtons()
  for i, member in ipairs(self.members) do
    local battler = Battler(member, TroopManager.playerParty or 0)
    local text = self:battlerText(battler)
    local icon = self:battlerIcon(battler)
    self:addButton(text, icon, self.onButtonConfirm)
  end
end

---------------------------------------------------------------------------------------------------
-- Buttons
---------------------------------------------------------------------------------------------------

-- Gets the description text for the given battler.
function CharacterWindow:battlerText(battler)
  
end
-- Gets the image for the given battler.
function CharacterWindow:battlerIcon(battler)
  
end
-- Confirm callback for each button, returns the chosen battle.
function CharacterWindow:onButtonConfirm(button)
  self.result = button.battler
end

---------------------------------------------------------------------------------------------------
-- Properties
---------------------------------------------------------------------------------------------------

function CharacterWindow:buttonHeight()
  return #self.vars * 10 + 5
end

function CharacterWindow:colCount()
  return 1
end

function CharacterWindow:rowCount()
  return 1
end

return CharacterWindow