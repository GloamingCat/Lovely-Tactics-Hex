
local ListButtonWindow = require('core/gui/ListButtonWindow')
local SkillAction = require('core/battle/action/SkillAction')
local Vector = require('core/math/Vector')

--[[===========================================================================

The GUI that is open to choose a item from character's inventory.

=============================================================================]]

local ItemWindow = ListButtonWindow:inherit()

local old_init = ItemWindow.init
function ItemWindow:init(GUI, list)
  old_init(self, list, GUI)
end

-- Creates a button from an item ID.
-- @param(id : number) the item ID
function ItemWindow:createButton(id)
  local item = Database.items[id + 1]
  if item.skillID >= 0 then
    local button = self:addButton(item.name, nil, self.onButtonConfirm)
    button.item = item
  end
end

-- Called when player chooses an item.
-- @param(button : Button) the button selected
function ItemWindow:onConfirm(button)
  local actionType = SkillAction
  local skill = Database.skills[button.item.skillID + 1]
  if skill.script.path ~= '' then
    actionType = require('custom/' .. skill.script.path)
  end
  -- Executes action grid selecting.
  BattleManager:selectAction(actionType(skill, skill.script.param))
  local result = GUIManager:showGUIForResult('battle/ActionGUI')
  if result == 1 then
    -- End of turn.
    button.window.result = 1
  end
end

-- New button width.
function ItemWindow:buttonWidth()
  return 80
end

-- New row count.
function ItemWindow:rowCount()
  return 6
end

return ItemWindow
