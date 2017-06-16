
--[[===============================================================================================

This module provides a few general functions to be used in convenient situations.

=================================================================================================]]

util = {}

-- Creates a new array of given size with all elements starting with the given value.
-- @param(size : number) size of the array
-- @param(value : unknown) initial value of all elements
-- @ret(table) the newly created array
function util.newArray(size, value)
  local a = {}
  for i = 1, size do
    a[i] = value
  end
  return a
end

-- Combines an array of arrays into a single array.
-- @param(arrays : table) array of arrays
-- @ret(table) the joined arrays
function util.joinArray(arrays)
  local new = {}
  for i = 1, #arrays do
    local arr = arrays[i]
    for j = 1, #arr do
      new[#new + 1] = arr[j]
    end
  end
  return new
end
