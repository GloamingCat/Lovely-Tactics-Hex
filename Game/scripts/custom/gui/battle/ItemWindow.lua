
local ListButtonWindow = require('core/gui/ListButtonWindow')
local ActionWindow = require('custom/gui/battle/ActionWindow')
local SkillAction = require('core/battle/action/SkillAction')
local Vector = require('core/math/Vector')

--[[===========================================================================

The GUI that is open to choose an item from character's inventory.

=============================================================================]]

local ItemWindow = require('core/class'):inherit(ListButtonWindow, ActionWindow)

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
  local skill = Database.skills[button.item.skillID + 1]
  self:selectSkill(skill)
end

-- Called when player cancels.
function ItemWindow:onCancel()
  self:changeWindow(self.GUI.turnWindow)
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
