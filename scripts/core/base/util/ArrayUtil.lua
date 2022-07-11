
--[[===============================================================================================

Array Utilities
---------------------------------------------------------------------------------------------------
General utilities for arrays.

=================================================================================================]]

local util = {}

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Creates a new array of given size with all elements starting with the given value.
-- @param(size : number) Size of the array.
-- @param(value : unknown) Initial value of all elements.
-- @ret(table) The newly created array.
function util.new(size, value)
  local a = {}
  for i = 1, size do
    a[i] = value
  end
  return a
end
-- Creates a shallow copy (only object references) of the given array.
-- @param(array : table) The array with the object references to be copied.
-- @ret(table) The shallow copy of the array.
function util.shallowCopy(array)
  local copy = {}
  util.addAll(copy, array)
  return copy
end
-- Combines an array of arrays into a single array.
-- @param(arrays : table) Array of arrays.
-- @ret(table) The joined arrays.
function util.join(arrays)
  local new = {}
  for i = 1, #arrays do
    local arr = arrays[i]
    util.addAll(new, arr)
  end
  return new
end
-- Inserts all the elements from the second array in the first one.
-- @param(array : table) Array to be modified.
-- @param(elements : table) Array containing the elements to be inserted.
function util.addAll(array, elements)
  for i = 1, #elements do
    array[#array + 1] = elements[i]
  end
end
-- Inserts an element at the given position. Shifts remaining elements accordingly.
-- @param(array : table) Array to be modified.
-- @param(index : number) Position of the inserted element.
function util.insert(array, index, element)
  for i = #array, index, -1 do
    array[i + 1] = array[i]
  end
  array[index] = element
end
-- Remoes the element in the given position. Shifts remaining elements accordingly.
-- @param(array : table) Array to be modified.
-- @param(index : number) Position of the element to be removed.
function util.remove(array, index)
  for i = index, #array do
    array[i] = array[i + 1]
  end
end

---------------------------------------------------------------------------------------------------
-- Search
---------------------------------------------------------------------------------------------------

-- Gets the index of the given element in the given array.
-- @param(array : table) The array potencionally with the given element.
-- @param(el : unknown) The element to be searched.
-- @ret(number) The index of the element if found (nil if not found).
function util.indexOf(array, el)
  for i = 1, #array do
    if array[i] == el then
      return i
    end
  end
  return nil
end
-- Searches for an element with the given key.
-- @param(array : table) Array of table elements.
-- @param(key : string) Key of the element.
-- @ret(table) Elements of the array with the given key (nil if not found).
function util.findByKey(array, key)
  for i = 1, #array do
    if array[i].key == key then
      return array[i]
    end
  end
end
-- Searches for an element with the given key.
-- @param(arr : table) Array of table elements.
-- @param(name : string) Name of the element.
-- @ret(table) Elements of the array with the given name (nil if not found).
function util.findByName(array, name)
  for i = 1, #array do
    if array[i].name == name then
      return array[i]
    end
  end
end

---------------------------------------------------------------------------------------------------
-- Array Stats
---------------------------------------------------------------------------------------------------

-- Sums all the elements in a array of numbers (or objects with the + operator).
-- @param(array : table) Array containing the population.
-- @ret(unknown) The sum of all elements.
function util.sum(array)
  local s = 0
  for i = 1, #array do
    s = s + array[i]
  end
  return s
end
-- Multiples all the elements in a array of numbers (or objects with the * operator).
-- @param(array : table) Array containing the population.
-- @ret(unknown) The product of all elements.
function util.mul(array)
  local m = 1
  for i = 1, #array do
    m = m * array[i]
  end
  return m
end
-- Gets the maximum element from an array of numbers (or objects with the > operator).
-- @param(array : table) Array containing the population.
-- @ret(unknown) The maximum element.
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
-- Gets the mean value from an array of numbers (or objects with + and / operators).
-- @param(array : table) Array containing the population.
-- @ret(unknown) The average element.
function util.mean(array)
  return util.sum(array) / #array
end

return util
