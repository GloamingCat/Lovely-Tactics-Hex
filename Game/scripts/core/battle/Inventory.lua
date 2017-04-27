
--[[===============================================================================================

Inventory
---------------------------------------------------------------------------------------------------
A special kind of list that stores pairs (item ID, quantity).

=================================================================================================]]

-- Imports
local List = require('core/algorithm/List')

-- Alias
local Random = love.math.random

local Inventory = List:inherit()

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Overides List:init.
local old_init = Inventory.init
function Inventory:init(list)
  old_init(self)
  if list then
    for i = 1, #list do
      local r = Random(100)
      if r <= list[i].rate then
        self:addItem(list[i].id)
      end
    end
  end
end

-- Adds new item to inventory.
-- @param(id : number) the item ID
-- @param(count : number) the quantity (optional)
function Inventory:addItem(id, count)
  count = count or 1
  for i = 1, self.count do
    if self[i].id == id then
      self[i].count = self[i].count + count
      return
    end
  end
  self:add({id = id, count = count})
end

-- Removes items from the bag.
-- @param(id : number) the ID of the item type in the database
-- @param(count : number) the number of items of that type to be removed (1 by default)
function Inventory:removeItem(id, count)
  count = count or 1
  for i = 1, self.count do
    if self[i].id == id then
      if self[i].count <= count then
        table.remove(self, i)
      else
        self[i].count = self[i].count - count
      end
      return
    end
  end
end

-- Converting to string.
-- @ret(string) A string representation
function Inventory:toString()
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
