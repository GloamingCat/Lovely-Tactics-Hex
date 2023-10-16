
--[[===============================================================================================

@classmod List
---------------------------------------------------------------------------------------------------
A list datatype implementation. See more in:
http://en.wikipedia.org/wiki/List_(abstract_data_type)

=================================================================================================]]

-- Alias
local insert = table.insert
local remove = table.remove

-- Class table.
local List = class()

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

-- @tparam table content An array of initial elements, 
--  indexed continously starting from 1 (optional).
function List:init(content)
  if content then
    self.size = #content
    for i = 1, self.size do
      self[i] = content[i]
    end
  else
    self.size = 0
  end
end

-- ------------------------------------------------------------------------------------------------
-- Add
-- ------------------------------------------------------------------------------------------------

--- Insert new element to the list.
-- @tparam unknown element The new element.
function List:add(element, pos)
  assert(element, 'Element cannot be nil')
  if pos then
    insert(self, pos, element)
  else
    self[self.size + 1] = element
  end
  self.size = self.size + 1
end
--- Add all elements in the given array/list.
-- @tparam table arr Array with the elements.
function List:addAll(arr)
  for i = 1, #arr do
    self[self.size + i] = arr[i]
  end
  self.size = self.size + #arr
end

-- ------------------------------------------------------------------------------------------------
-- Remove
-- ------------------------------------------------------------------------------------------------

--- Removes the element in the given position.
-- @tparam number pos The position index.
-- @treturn unknown The removed element.
function List:remove(pos)
  local element = remove(self, pos)
  if element then
    self.size = self.size - 1
    return element
  end
end
--- Removes given element from the list.
-- @tparam unknown element Element to remove.
-- @treturn boolean True if the element was found, false otherwise.
function List:removeElement(element)
  assert(element, 'Element cannot be nil')
  local i = self:indexOf(element)
  if i then
    self:remove(i)
    return true
  else
    return false
  end
end
--- Removes given element from the list.
-- @tparam table arr Array of elements to be removed from this list.
function List:removeAll(arr)
  for i, element in ipairs(arr) do
    self:removeElement(element)
  end
end
--- Removes all elements that satisfy a given condition.
-- @tparam function remove A function that receives an element 
--  and returns true if it must be removed or false if not.
-- @treturn number Returns the number of elements removed.
function List:conditionalRemove(remove)
  local oldsize = self.size
  local size = 0
  for i = 1, self.size do
    local el = self[i]
    self[i] = nil
    if not remove(el, i) then
      size = size + 1
      self[size] = el
    end
  end
  self.size = size
  return oldsize - self.size
end
--- Removes all elements.
function List:clear()
  for i = 1, self.size do
    self[i] = nil
  end
  self.size = 0
end

-- ------------------------------------------------------------------------------------------------
-- Search
-- ------------------------------------------------------------------------------------------------

--- Searchs for the element in the list.
-- @tparam unknown element The element to search for.
-- @treturn number The index of the element in the list (nil if not in the list).
function List:indexOf(element)
  if not element then
    return nil
  end
  for i = 1, self.size do
    if self[i] == element then
      return i
    end
  end
  return nil
end
--- Checks if given element is in the list.
-- @tparam unknown element The element to check.
-- @treturn boolean Whether if it's in the list or not.
function List:contains(element)
  return self:indexOf(element) ~= nil
end

-- ------------------------------------------------------------------------------------------------
-- Sort
-- ------------------------------------------------------------------------------------------------

-- Default compare function for ascending orders
function List.ascending(a, b)
  return a[2] < b[2]
end
-- Default compare function for descending orders
function List.descending(a, b)
  return a[2] > b[2]
end
--- Sorts all elements.
-- @tparam function comp The function that compares two elements (optional).
function List:sort(comp)
  table.sort(self, comp or self.ascending)
end

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Checks if list is empty.
-- @treturn boolean True if emtpty, false otherwise.
function List:isEmpty()
  return self.size == 0
end
--- List iterator to user in a for.
-- @treturn function The iterator function.
function List:iterator()
  local i = 0
  return function()
    i = i + 1
    if i <= self.size then
      return self[i]
    end
  end
end
--- Call all items with given arguments (items must be all functions).
-- @tparam(...) Call arguments.
function List:notify(...)
  for i = 1, self.size do
    self[i](...)
  end
end

-- ------------------------------------------------------------------------------------------------
-- Convertion
-- ------------------------------------------------------------------------------------------------

--- Converting to string.
-- @treturn string A string representation.
function List:__tostring()
  if self.size == 0 then
    return 'List {}'
  end
  local string = 'List {'
  for i = 1, self.size - 1 do
    string = string .. tostring(self[i]) .. ', '
  end
  return string .. tostring(self[self.size]) .. '}'
end

return List
