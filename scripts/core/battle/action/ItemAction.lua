
-- ================================================================================================

--- Uses an item from the inventory.
-- It is executed when players chooses the "Item" button during battle.
-- It is a type of SkillAction that gets its effect from item data.
---------------------------------------------------------------------------------------------------
-- @battlemod ItemAction
-- @extend SkillAction

-- ================================================================================================

-- Imports
local SkillAction = require('core/battle/action/SkillAction')

-- Class table.
local ItemAction = class(SkillAction)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam number skillID Item's skill ID.
-- @tparam table item Item data.
function ItemAction:init(skillID, item)
  self.item = item
  SkillAction.init(self, skillID)
  -- Effects
  for i = 1, #item.effects do
    self:addEffect(item.effects[i])
  end
end

-- ------------------------------------------------------------------------------------------------
-- Item
-- ------------------------------------------------------------------------------------------------

--- Overrides `SkillAction:canExecute`. 
-- @override
function ItemAction:canExecute(input)
  return input.user.battler.troop.inventory:getCount(self.item.id) > 0 and 
    SkillAction.canExecute(self, input)
end
--- Overrides `SkillAction:battleUse`. 
-- @override
function ItemAction:battleUse(input)
  if self.item.consume then
    input.user.battler.troop.inventory:removeItem(self.item.id)
  end
  return SkillAction.battleUse(self, input)
end
--- Overrides `SkillAction:menuUse`. 
-- @override
function ItemAction:menuUse(input)
  if self.item.consume then
    input.user.troop.inventory:removeItem(self.item.id)
  end
  return SkillAction.menuUse(self, input)
end

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

-- For debugging.
function ItemAction:__tostring()
  return 'ItemAction (' .. self.skillID .. ': ' .. self.data.name .. ')'
end

return ItemAction
