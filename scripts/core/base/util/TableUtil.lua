
--[[===============================================================================================

Table Utilities
---------------------------------------------------------------------------------------------------
General utilities for tables.

=================================================================================================]]

local util = {}

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Creates a copy of the given table.
-- @param(table : table) The table with the (key, value) entries to be copied.
-- @ret(table) The copy of the table.
function util.shallowCopy(table)
  local copy = {}
  util.shallowAdd(copy, table)
  return copy
end
-- Adds the seconde table's key and values to the first one.
-- @param(table : table) The table to be modified.
-- @param(entries : table) A table of (key, value) entries to be added.
function util.shallowAdd(table, entries)
  for k, v in pairs(entries) do
    table[k] = v
  end
end
-- Creates a copy of the given table.
-- @param(table : table) The table with the (key, value) entries to be copied.
-- @ret(table) The copy of the table.
function util.deepCopy(table)
  local copy = {}
  util.deepAdd(copy, table)
  return copy
end
-- Adds the seconde table's key and values to the first one.
-- @param(table : table) The table to be modified.
-- @param(entries : table) A table of (key, value) entries to be added.
function util.deepAdd(table, entries)
  for k, v in pairs(entries) do
    local typ = type(v)
    if typ == 'table' then
      table[k] = util.deepCopy(v)
    else
      table[k] = v
    end
  end
end
-- Combines multiple tables' keys and values into a single one.
-- @param(tables : table) A table of tables.
-- @ret(table) The joined tables.
function util.join(tables)
  local new = {}
  for i = 1, #tables do
    local table = tables[i]
    util.shallowAdd(new, table)
  end
  return new
end

return util
