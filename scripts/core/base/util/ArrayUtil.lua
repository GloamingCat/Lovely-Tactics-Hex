
-- ================================================================================================

--- General utilities for arrays.
---------------------------------------------------------------------------------------------------
-- @module ArrayUtil

-- ================================================================================================

local util = {}

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Creates a new array of given size with all elements starting with the given value.
-- @tparam number size Size of the array.
-- @tparam unknown value Initial value of all elements.
-- @treturn table The newly created array.
function util.new(size, value)
  local a = {}
  for i = 1, size do
    a[i] = value
  end
  return a
end
--- Creates a shallow copy (only object references) of the given array.
-- @tparam table array The array with the object references to be copied.
-- @treturn table The shallow copy of the array.
function util.shallowCopy(array)
  local copy = {}
  util.addAll(copy, array)
  return copy
end
--- Combines an array of arrays into a single array.
-- @tparam table arrays Array of arrays.
-- @treturn table The joined arrays.
function util.join(arrays)
  local new = {}
  for i = 1, #arrays do
    local arr = arrays[i]
    util.addAll(new, arr)
  end
  return new
end
--- Inserts all the elements from the second array in the first one.
-- @tparam table array Array to be modified.
-- @tparam table elements Array containing the elements to be inserted.
function util.addAll(array, elements)
  for i = 1, #elements do
    array[#array + 1] = elements[i]
  end
end
--- Inserts an element at the given position. Shifts remaining elements accordingly.
-- @tparam table array Array to be modified.
-- @tparam number index Position of the inserted element.
-- @tparam unknown element Element to be added.
function util.insert(array, index, element)
  for i = #array, index, -1 do
    array[i + 1] = array[i]
  end
  array[index] = element
end
--- Removes the element. Shifts remaining elements accordingly.
-- @tparam table array Array to be modified.
-- @tparam unknown element Element to be removed.
-- @treturn number Index of the removed element (nil if not found).
function util.remove(array, element)
  local i = util.indexOf(array, element)
  if i then
    table.remove(array, i)
  end
  return i
end
--- Puts the element into an array if it's not already an array.
-- @tparam unknown element
-- @treturn table `element` if it's an array, or a new array with `element` otherwise.
function util.toArray(element)
  if element == nil then
    return nil
  elseif type(element) ~= 'table' then
    return {element}
  else
    return element
  end
end

-- ------------------------------------------------------------------------------------------------
-- Search
-- ------------------------------------------------------------------------------------------------

--- Gets the index of the given element in the given array.
-- @tparam table array The array potencionally with the given element.
-- @tparam unknown el The element to be searched.
-- @treturn number The index of the element if found (nil if not found).
function util.indexOf(array, el)
  for i = 1, #array do
    if array[i] == el then
      return i
    end
  end
  return nil
end
--- Searches for an element with the given key.
-- @tparam table array Array of table elements.
-- @tparam string key Key of the element.
-- @treturn table Elements of the array with the given key (nil if not found).
function util.findByKey(array, key)
  for i = 1, #array do
    if array[i].key == key then
      return array[i]
    end
  end
end
--- Searches for an element with the given key.
-- @tparam table array Array of table elements.
-- @tparam string name Name of the element.
-- @treturn table Elements of the array with the given name (nil if not found).
function util.findByName(array, name)
  for i = 1, #array do
    if array[i].name == name then
      return array[i]
    end
  end
end

-- ------------------------------------------------------------------------------------------------
-- Log
-- ------------------------------------------------------------------------------------------------

--- Prints each element separating by given separator string and join them into a single string.
-- @tparam table items Array of elements to be printed.
-- @tparam string sep Separator.
-- @tparam[opt=#items] number The length of the array.
-- @treturn string String each the elements printed.
function util.concat(items, sep, size)
  size = size or #items
  sep = sep or ', '
  if size == 0 then
    return ""
  end
  local str = tostring(items[1])
  for i = 2, size do
    str = str .. sep .. tostring(items[i])
  end
  return str
end

-- ------------------------------------------------------------------------------------------------
-- Array Stats
-- ------------------------------------------------------------------------------------------------

--- Sums all the elements in a array of numbers (or objects with the + operator).
-- @tparam table array Array containing the population.
-- @treturn unknown The sum of all elements.
function util.sum(array)
  local s = 0
  for i = 1, #array do
    s = s + array[i]
  end
  return s
end
--- Multiples all the elements in a array of numbers (or objects with the * operator).
-- @tparam table array Array containing the population.
-- @treturn unknown The product of all elements.
function util.mul(array)
  local m = 1
  for i = 1, #array do
    m = m * array[i]
  end
  return m
end
--- Gets the maximum element from an array of numbers (or objects with the > operator).
-- @tparam table array Array containing the population.
-- @treturn unknown The maximum element.
function util.max(array)
  if #array == 0 then
    return nil
  end
  local m = 1
  for i = 2, #array do
    if array[i] > array[m] then
      m = i
    end
  end
  return array[m], m
end
--- Gets the mean value from an array of numbers (or objects with + and / operators).
-- @tparam table array Array containing the population.
-- @treturn unknown The average element.
function util.mean(array)
  return util.sum(array) / #array
end

return util
