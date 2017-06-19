
--[[===============================================================================================

This module provides a few general functions to be used in convenient situations.

=================================================================================================]]

util = {}

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
-- Tables
---------------------------------------------------------------------------------------------------

-- Creates a copy of the given table.
-- @param(table : table) the table with the (key, value) entries to be copied
-- @ret(table) the copy of the table
function util.copyTable(table)
  local copy = {}
  util.addTable(copy, table)
  return copy
end

-- Combines multiple tables' keys and values into a single one.
-- @param(tables : table) a table of tables
-- @ret(table) the joined tables
function util.joinTables(tables)
  local new = {}
  for i = 1, #tables do
    local table = tables[i]
    util.addTable(new, table)
  end
  return new
end

-- Adds the seconde table's key and values to the first one.
-- @param(table : table) the table to be modified
-- @param(entries : table) a table of (key, value) entries to be added
function util.addTable(table, entries)
  for k, v in pairs(entries) do
    table[k] = v
  end
end
