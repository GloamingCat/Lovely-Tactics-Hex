
-- ================================================================================================

--- A priority queue with numeric keys. Be default, the element in the front will be the one with  
-- the lowest key. See more in: https://en.wikipedia.org/wiki/Priority_queue
---------------------------------------------------------------------------------------------------
-- @classmod PriorityQueue

-- ================================================================================================

-- Imports
local List = require('core/datastruct/List')

-- Alias
local sort = table.sort
local floor = math.floor

-- Class table.
local PriorityQueue = class()

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam function comp The function that compares two pairs (optional).
function PriorityQueue:init(comp)
  self.comp = comp or self.ascending
  self.size = 0
end

-- ------------------------------------------------------------------------------------------------
-- Comparison
-- ------------------------------------------------------------------------------------------------

--- Default compare function for ascending orders (lower value first).
function PriorityQueue.ascending(a, b)
  return a[2] < b[2]
end
--- Default compare function for descending orders (higher value first).
function PriorityQueue.descending(a, b)
  return a[2] > b[2]
end

-- ------------------------------------------------------------------------------------------------
-- Operators
-- ------------------------------------------------------------------------------------------------

--- Adds new pair to the queue.
-- @tparam unknown element The new element to add.
-- @tparam number v The priority of the element.
function PriorityQueue:enqueue(element, v)
  local new = {element, v}
  self.size = self.size + 1
  local n = self.size
  local p = (n - n % 2) / 2
  self[n] = new
  while n > 1 and self.comp(self[n], self[p]) do
    self[n], self[p] = self[p], self[n]
    n = p
    p = (n - n % 2) / 2
  end
end
--- Removes the front pair.
-- @treturn unknown The element removed.
-- @treturn number The key/priority of the element removed.
function PriorityQueue:dequeue()
  assert(self.size > 0, 'Priority queue is empty!')
  local pair = self[1]
  -- Only one element
  if self.size == 1 then
    self[1] = nil
    self.size = 0
    return pair[1], pair[2]
  end
  self[1] = self[self.size]
  self[self.size] = nil
  self.size = self.size - 1
  local size = self.size
  local root = 1
  local child = 2*root
  while child <= size do
    local comp1 = self.comp(self[root], self[child])
    local comp2 = true
    local comp3 = true
    if child + 1 <= size then
      comp2 = self.comp(self[root], self[child + 1])
      comp3 = self.comp(self[child], self[child + 1])
    end
    if comp1 and comp2 then
      break
    elseif comp3 then
      self[root], self[child] = self[child], self[root]
      root = child
    else
      self[root], self[child + 1] = self[child + 1], self[root]
      root = child + 1
    end
    child = 2*root
  end
  return pair[1], pair[2]
end
--- Gets the element with the highest priority.
-- @treturn unknown The front element.
-- @treturn number The key/priority of the front element.
function PriorityQueue:front()
  assert(self.size > 0, 'Priority queue is empty!')
  local pair = self[1]
  return pair[1], pair[2]
end
--- Checks if empty.
function PriorityQueue:isEmpty()
  return self.size == 0
end

-- ------------------------------------------------------------------------------------------------
-- Convertion
-- ------------------------------------------------------------------------------------------------

--- Converts this queue to a list of elements (does not include keys).
-- Empties the queue during the proccess.
-- @treturn List List of arbitrary elements.
function PriorityQueue:toList()
  local list = List()
  while self.size > 0 do
    local e = self:dequeue()
    list:add(e)
  end
  return list
end
--- Converts this queue to a list of elements (does not include keys).
-- @treturn List List of arbitrary elements.
function PriorityQueue:asList()
  local list = List()
  while self.size > 0 do
    local e, v = self:dequeue()
    list:add({e, v})
  end
  for i = 1, list.size do
    self:enqueue(list[i][1], list[i][2])
    list[i] = list[i][1]
  end
  return list
end
-- For debugging.
function PriorityQueue:__tostring()
  local list = self:asList()
  return tostring(list)
end

return PriorityQueue
