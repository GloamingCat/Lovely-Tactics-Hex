
-- ================================================================================================

--- A type of SkillAction that gets its effect from item data.
-- ------------------------------------------------------------------------------------------------
-- @classmod ItemAction

-- ================================================================================================

-- Imports
local SkillAction = require('core/battle/action/SkillAction')

-- Class table.
local ItemAction = class(SkillAction)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Overrides SkillAction:init. Adds item effects.
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

--- Overrides SkillAction:canExecute.
function ItemAction:canExecute(input)
  return input.user.battler.troop.inventory:getCount(self.item.id) > 0 and 
    SkillAction.canExecute(self, input)
end
--- Overrides SkillAction:battleUse.
function ItemAction:battleUse(input)
  if self.item.consume then
    input.user.battler.troop.inventory:removeItem(self.item.id)
  end
  return SkillAction.battleUse(self, input)
end
--- Overrides SkillAction:menuUse.
function ItemAction:menuUse(input)
  if self.item.consume then
    input.user.troop.inventory:removeItem(self.item.id)
  end
  return SkillAction.menuUse(self, input)
end

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Converting to string.
-- @treturn string A string with skill's ID and name.
function ItemAction:__tostring()
  return 'ItemAction (' .. self.skillID .. ': ' .. self.data.name .. ')'
end

return ItemAction
