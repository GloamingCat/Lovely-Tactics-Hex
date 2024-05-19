
-- ================================================================================================

--- A special kind of list that stores pairs (item ID, quantity).
---------------------------------------------------------------------------------------------------
-- @battlemod Inventory
-- @extend List

-- ================================================================================================

-- Imports
local List = require('core/datastruct/List')

-- Alias
local rand = love.math.random

-- Class table.
local Inventory = class(List)

-- ------------------------------------------------------------------------------------------------
-- Tables
-- ------------------------------------------------------------------------------------------------

--- An item slot entry.
-- @table Slot
-- @tfield number|string id Item's id or key from the database.
-- @tfield number count The quantity of the item.
-- @tfield[opt=100] number rate The chance to get the item(s). 
Inventory.emptySlot = {
  id = -1,
  count = 0,
  rate = 100
}

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam table list An array of `Slot` entries from database.
function Inventory:init(list)
  List.init(self)
  if list then
    for i = 1, #list do
      local r = rand(100)
      if r <= (list[i].value or 100) then
        self:addItem(list[i].id, list[i].count)
      end
    end
  end
end
--- Gets all slots of this inventory in a basic table.
-- @treturn table Array of `Slot` entries.
function Inventory:getState()
  local t = {}
  for i = 1, self.size do
    t[i] = {
      id = self[i].id, 
      count = self[i].count }
  end
  return t
end
--- Gets the number of items of given ID.
-- @tparam number id Item's ID in databse.
-- @treturn number The item's count.
function Inventory:getCount(id)
  local slot = self:getSlot(id)
  return slot and slot.count or 0
end
--- Gets the slot of the given item.
-- @tparam number id Item's ID in database.
-- @treturn Slot The item's slot, if found.
function Inventory:getSlot(id)
  for i = 1, self.size do
    if self[i].id == id then
      return self[i]
    end
  end
  return nil
end

-- ------------------------------------------------------------------------------------------------
-- Add / Remove
-- ------------------------------------------------------------------------------------------------

--- Adds new item to inventory.
-- @tparam number id The item ID.
-- @tparam[opt=1] number count The quantity.
-- @treturn boolean True if new slot was created, false if item already existed in inventory.
function Inventory:addItem(id, count)
  count = count or 1
  for i = 1, self.size do
    if self[i].id == id then
      self[i].count = self[i].count + count
      return false
    end
  end
  self:add({id = id, count = count})
  return true
end
--- Removes items from the bag.
-- @tparam number id The ID of the item type in the database.
-- @tparam[opt=1] number count The number of items of that type to be removed.
function Inventory:removeItem(id, count)
  count = count or 1
  for i = 1, self.size do
    if self[i].id == id then
      if self[i].count <= count then
        self:remove(i)
        return false
      else
        self[i].count = self[i].count - count
        return true
      end
    end
  end
  return false
end
--- Adds all items from another inventory.
-- @tparam table|List inventory An array or list of `Slot` entries.
function Inventory:addAllItems(inventory)
  for i = 1, #inventory do
    local slot = inventory[i]
    self:addItem(slot.id, slot.count)
  end
end

-- ------------------------------------------------------------------------------------------------
-- Sub-inventories
-- ------------------------------------------------------------------------------------------------

--- Gets an array of slots of items that are usable.
-- @tparam[opt=0] number restriction The use restriction: 1 for battle, 2 for field, 0 for any.
-- @treturn table Array of `Slot` entries.
function Inventory:getUsableItems(restriction)
  restriction = restriction or 0
  local items = {}
  for itemSlot in self:iterator() do
    local item = Database.items[itemSlot.id]
    if item.skillID >= 0 then
      local skill = Database.skills[item.skillID]
      if skill.restriction == 0 or skill.restriction == restriction then
        items[#items + 1] = itemSlot
      end
    end
  end
  return items
end
--- Gets an array of slots of items that are sellable.
-- @treturn table Array of `Slot` entries.
function Inventory:getSellableItems()
  local items = {}
  for itemSlot in self:iterator() do
    local item = Database.items[itemSlot.id]
    if item.sellable then
      items[#items + 1] = itemSlot
    end
  end
  return items
end
--- Gets an array of slots of items that are equipment.
-- @tparam[opt] string key The type of equipment (nil if all types).
-- @treturn table Array of `Slot` entries.
function Inventory:getEquipItems(key)
  local items = {}
  for itemSlot in self:iterator() do
    local item = Database.items[itemSlot.id]
    if item.slot ~= '' and (key == nil or key:find(item.slot)) then
      items[#items + 1] = itemSlot
    end
  end
  return items
end
-- For debugging.
function Inventory:__tostring()
  if self.size == 0 then
    return 'Inventory {}'
  end
  local string = 'Inventory {'
  for i = 1, self.size - 1 do
    string = string .. tostring(self[i]) .. ', '
  end
  return string .. tostring(self[self.size]) .. '}'
end

return Inventory
