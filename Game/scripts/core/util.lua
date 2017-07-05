
--[[===============================================================================================

This module provides a few general functions to be used in convenient situations.

=================================================================================================]]

util = {}

---------------------------------------------------------------------------------------------------
-- Tables
---------------------------------------------------------------------------------------------------

-- Creates a copy of the given table.
-- @param(table : table) the table with the (key, value) entries to be copied
-- @ret(table) the copy of the table
function util.shallowCopyTable(table)
  local copy = {}
  util.addTable(copy, table)
  return copy
end

-- Adds the seconde table's key and values to the first one.
-- @param(table : table) the table to be modified
-- @param(entries : table) a table of (key, value) entries to be added
function util.shallowAddTable(table, entries)
  for k, v in pairs(entries) do
    table[k] = v
  end
end

-- Creates a copy of the given table.
-- @param(table : table) the table with the (key, value) entries to be copied
-- @ret(table) the copy of the table
function util.deepCopyTable(table)
  local copy = {}
  util.deepAddTable(copy, table)
  return copy
end

-- Adds the seconde table's key and values to the first one.
-- @param(table : table) the table to be modified
-- @param(entries : table) a table of (key, value) entries to be added
function util.deepAddTable(table, entries)
  for k, v in pairs(entries) do
    local typ = type(v)
    if typ == 'table' then
      table[k] = util.deepCopyTable(v)
    else
      table[k] = v
    end
  end
end

-- Combines multiple tables' keys and values into a single one.
-- @param(tables : table) a table of tables
-- @ret(table) the joined tables
function util.joinTables(tables)
  local new = {}
  for i = 1, #tables do
    local table = tables[i]
    util.shallowAddTable(new, table)
  end
  return new
end

---------------------------------------------------------------------------------------------------
-- Arrays
---------------------------------------------------------------------------------------------------

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

-- Creates a copy of the given table.
-- @param(table : table) the table with the (key, value) entries to be copied
-- @ret(table) the copy of the table
function util.copyArray(array)
  local copy = {}
  util.addArray(copy, array)
  return copy
end

-- Combines an array of arrays into a single array.
-- @param(arrays : table) array of arrays
-- @ret(table) the joined arrays
function util.joinArrays(arrays)
  local new = {}
  for i = 1, #arrays do
    local arr = arrays[i]
    util.addArray(new, arr)
  end
  return new
end

-- Inserts all the elements from the second array in the first one.
-- @param(array : table) array to be modified
-- @param(elements : table) array containing the elements to be inserted
function util.addArray(array, elements)
  for i = 1, #elements do
    array[#array + 1] = elements[i]
  end
end

---------------------------------------------------------------------------------------------------
-- Array Stats
---------------------------------------------------------------------------------------------------

-- Sums all the elements in a array of numbers (or objects with the + operator).
-- @param(arr : table) array containing the elements
-- @ret(unknown) the sum of all elements
function util.arraySum(arr)
  local s = 0
  for i = 1, #arr do
    s = s + arr[i]
  end
  return s
end

-- Gets the maximum element from an array of numbers (or objects with the > operator).
-- @param(arr : table) array containing the elements
-- @ret(unknown) the maximum element
function util.arrayMax(arr)
  if #arr == 0 then
    return nil
  end
  local m = 1
  for i = 2, #arr do
    if arr[i] > arr[m] then
      m = i
    end
  end
  return arr[m], m
end

-- Gets the mean value from an array of numbers (or objects with + and / operators).
-- @param(arr : table) array containing the elements
-- @ret(unknown) the mean
function util.arrayMean(arr)
  return util.arraySum(arr) / #arr
end

---------------------------------------------------------------------------------------------------
-- Other
---------------------------------------------------------------------------------------------------

-- Creates a tag map of JSON values.
-- @param(tags : table) the array of tags from databse file
-- @ret(table) a table mapping each tag name to its JSON value
function util.createTags(tags)
  local t = {}
  for i = 1, #tags do
    t[tags[i].name] = JSON.decode(tags[i].value)
  end
  return t
end
