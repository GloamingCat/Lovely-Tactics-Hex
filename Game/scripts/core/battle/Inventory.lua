
--[[===============================================================================================

Inventory
---------------------------------------------------------------------------------------------------
A special kind of list that stores pairs (item ID, quantity).

=================================================================================================]]

-- Imports
local List = require('core/algorithm/List')

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
      if r <= list[i].rate then
        self:addItem(list[i].id, list[i].count)
      end
    end
  end
end
-- Gets the number of items of given ID.
-- @param(id : number) item's ID in databse
-- @ret(number) the item's count
function Inventory:getCount(id)
  for i = 1, self.size do
    if self[i].id == id then
      return self[i].count
    end
  end
  return 0
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
function Inventory:addItem(id, count)
  count = count or 1
  for i = 1, self.size do
    if self[i].id == id then
      self[i].count = self[i].count + count
      return
    end
  end
  self:add({id = id, count = count})
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
      else
        self[i].count = self[i].count - count
      end
      return
    end
  end
end

---------------------------------------------------------------------------------------------------
-- Sub-inventories
---------------------------------------------------------------------------------------------------

-- Gets an array of slots of items that are usable.
-- @param(restriction : number) the usa restriction: 1 for battle, 2 for field, 0 for any
--  (optional, 0 by default)
-- @ret(table) array of item slots (ID and count)
function Inventory:getUsableItems(restriction)
  restriction = restriction or 0
  local items = {}
  for itemSlot in self:iterator() do
    local item = Database.items[itemSlot.id + 1]
    if item.skillID >= 0 then
      local skill = Database.skills[item.skillID + 1]
      if skill.restriction == 0 or self.restriction == restriction then
        items[#items + 1] = itemSlot
      end
    end
  end
  return items
end

function Inventory:getSellableItems()
  local items = {}
  for itemSlot in self:iterator() do
    local item = Database.items[itemSlot.id + 1]
    if item.sellable then
      items[#items + 1] = itemSlot
    end
  end
  return items
end

function Inventory:getEquipment()
  local items = {}
  for itemSlot in self:iterator() do
    local item = Database.items[itemSlot.id + 1]
    if item.equipment then
      items[#items + 1] = itemSlot
    end
  end
  return items
end

return Inventory
