
--[[===============================================================================================

CharacterWindow
---------------------------------------------------------------------------------------------------
Horizontal window to select a character.

=================================================================================================]]

-- Imports
local Button = require('core/gui/Button')
local Battler = require('core/battle/Battler')
local GridWindow = require('core/gui/GridWindow')

-- Constants
local battlerVariables = Database.variables.battler

local CharacterWindow = class(GridWindow)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(members : table) array of battler IDs (optional, all party members by default)
function CharacterWindow:init(GUI, members)
  local vars = {}
  for i = 1, #battlerVariables do
    local var = battlerVariables[i]
    if var.targetGUI then
      vars[#vars + 1] = var
    end
  end
  self.vars = vars
  self.members = members or PartyManager:currentBattlersIDs()
  GridWindow.init(self, GUI)
end
-- Creates a button for each character.
function CharacterWindow:createButtons()
  for i, id in ipairs(self.members) do
    local battler = Battler(id, TroopManager.playerParty or 0)
    local text = self:battlerText(battler)
    local icon = self:battlerIcon(battler)
    Button(self, text, icon, self.onButtonConfirm)
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

function CharacterWindow:buttonWidth()
  return 80
end

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