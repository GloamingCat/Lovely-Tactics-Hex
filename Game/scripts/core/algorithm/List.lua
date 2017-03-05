
local insert = table.insert
local remove = table.remove

--[[===========================================================================

A list datatype implementation. See more in:
http://en.wikipedia.org/wiki/List_(abstract_data_type)

=============================================================================]]

local List = require('core/class'):new()

-- @param(content : table) an array of initial elements, 
--  indexed continously starting from 1 (optional)
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

-- Insert new element to the list.
-- @param(element : unknown) The new element
function List:add(element, pos)
  assert(element, 'Element cannot be nil')
  if pos then
    insert(self, element, pos)
  else
    self[self.size + 1] = element
  end
  self.size = self.size + 1
end

-- Removes the element in the given position.
-- @param(pos) the position
-- @ret(unknown) the removed element
function List:remove(pos)
  local element = remove(self, pos)
  if element then
    self.size = self.size - 1
    return element
  end
end

-- Removes given element from the list.
-- @param(element : unknown) element to remove
-- @ret(boolean) true if the element was found, false otherwise
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

-- Removes all elements that satisfy a given condition.
-- @param(func : function) a function that receives an element 
--  and returns true if it must be removed or false if not
-- @ret(number) returns the number of elements removed
function List:conditionalRemove(func)
  local oldsize = self.size
  for i = 1, self.size do
    while i <= self.size and func(i, self[i]) do
      table.remove(self, i)
      self.size = self.size - 1
    end
  end
  return oldsize - self.size
end

-- Searchs for the element in the list.
-- @param(element : unknown) the element to search for
-- @ret(number) the index of the element in the list (nil if not in the list)
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

-- Checks if given element is in the list.
-- @param(element : unknown) the element to check
-- @ret(boolean) either if it's in the list or not
function List:contains(element)
  return self:indexOf(element) ~= nil
end

-- @ret(boolean) whether or not the list is empty
function List:isEmpty()
  return self.size == 0
end

-- List iterator to user in a for.
-- @ret(function) the iterator function
function List:iterator()
  return ipairs(self)
end

-- Converting to string.
-- @ret(string) A string representation
function List:toString()
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
