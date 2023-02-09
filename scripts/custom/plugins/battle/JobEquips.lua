
--[[===============================================================================================

JobEquips
---------------------------------------------------------------------------------------------------
Provides a way to restrict the available equipment items for a certain job.
Add 'equip' tags on a Job to indicate which types of item it can equip.
Add 'equip' tag on an item indicate the type of the item.
Jobs with no equip tags have no restrictions.

=================================================================================================]]

-- Imports
local Inventory = require('core/battle/Inventory') 

-- Alias
local indexOf = util.array.indexOf

---------------------------------------------------------------------------------------------------
-- Inventory
---------------------------------------------------------------------------------------------------

-- Checks if given item can be equipped by a job with the given equip tags available.
-- @param(item : data) The item to be equipped.
-- @param(equipTags : table) Array of equip types allowed.
-- @ret(boolean) Whether or not there's intersection between the equip types allowed and
--  the item's equip types.
local function canEquip(item, equipTags)
  for _, tag in ipairs(item.tags) do
    if tag.key == 'equip' and indexOf(equipTags, tag.value) then
      return true
    end
  end
  return false
end
-- Override. Filters out equips that cannot be equiped by the given job.
local Inventory_getEquipItems = Inventory.getEquipItems
function Inventory:getEquipItems(key, member)
  local items = Inventory_getEquipItems(self, key, member)
  if member.job.tags.equip then
    local availableEquips = member.job.tags:getAll('equip')
    for i = #items, 1, -1 do
      if not canEquip(Database.items[items[i].id], availableEquips) then
        table.remove(items, i)
      end
    end
  end
  return items
end
