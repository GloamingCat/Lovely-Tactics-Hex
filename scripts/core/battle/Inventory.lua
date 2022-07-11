
--[[===============================================================================================

Inventory
---------------------------------------------------------------------------------------------------
A special kind of list that stores pairs (item ID, quantity).

=================================================================================================]]

-- Imports
local List = require('core/datastruct/List')

-- Alias
local rand = love.math.random

local Inventory = class(List)

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(list : table) an array from database (elements with fields id, rate and count).
function Inventory:init(list)
  List.init(self)
  if list then
    for i = 1, #list do
      local r = rand(100)
      if r <= (list[i].rate or 100) then
        self:addItem(list[i].id, list[i].count)
      end
    end
  end
end
-- Gets all slots of this inventory in a simple table.
-- @ret(table)
function Inventory:getState()
  local table = {}
  for i = 1, self.size do
    table[i] = {
      id = self[i].id, 
      count = self[i].count }
  end
  return table
end
-- Gets the number of items of given ID.
-- @param(id : number) item's ID in databse
-- @ret(number) the item's count
function Inventory:getCount(id)
  local slot = self:getSlot(id)
  return slot and slot.count or 0
end
-- Gets the slot of the given item.
-- @param(id : number) item's ID in database
-- @ret(table) the item's slot
function Inventory:getSlot(id)
  for i = 1, self.size do
    if self[i].id == id then
      return self[i]
    end
  end
  return nil
end
-- Converting to string.
-- @ret(string) A string representation
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

---------------------------------------------------------------------------------------------------
-- Add / Remove
---------------------------------------------------------------------------------------------------

-- Adds new item to inventory.
-- @param(id : number) the item ID
-- @param(count : number) the quantity (optional, 1 by default)
-- @ret(boolean) true if new slot was created, false if item already existed in inventory
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
-- Removes items from the bag.
-- @param(id : number) the ID of the item type in the database
-- @param(count : number) the number of items of that type to be removed (optional, 1 by default)
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
-- Adds all items from another inventory.
-- @param(inventory : Inventory)
function Inventory:addAllItems(inventory)
  for i = 1, #inventory do
    local slot = inventory[i]
    self:addItem(slot.id, slot.count)
  end
end

---------------------------------------------------------------------------------------------------
-- Sub-inventories
---------------------------------------------------------------------------------------------------

-- Gets an array of slots of items that are usable.
-- @param(restriction : number) the use restriction: 1 for battle, 2 for field, 0 for any
--  (optional, 0 by default)
-- @ret(table) array of item slots (ID and count)
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
-- Gets an array of slots of items that are sellable.
-- @ret(table) array of item slots (ID and count)
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
-- Gets an array of slots of items that are equipment.
-- @param(key : string) the type of equipment (nil if all types)
-- @ret(table) array of item slots (ID and count)
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

return Inventory
