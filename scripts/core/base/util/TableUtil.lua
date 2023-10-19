
-- ================================================================================================

--- General utilities for tables.
---------------------------------------------------------------------------------------------------
-- @module TableUtil

-- ================================================================================================

local util = {}

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Creates a copy of the given table.
-- @tparam table table The table with the (key, value) entries to be copied.
-- @treturn table The copy of the table.
function util.shallowCopy(table)
  local copy = {}
  util.shallowAdd(copy, table)
  return copy
end
--- Adds the seconde table's key and values to the first one.
-- @tparam table table The table to be modified.
-- @tparam table entries A table of (key, value) entries to be added.
function util.shallowAdd(table, entries)
  for k, v in pairs(entries) do
    table[k] = v
  end
end
--- Creates a copy of the given table.
-- @tparam table table The table with the (key, value) entries to be copied.
-- @treturn table The copy of the table.
function util.deepCopy(table)
  local copy = {}
  util.deepAdd(copy, table)
  return copy
end
--- Adds the seconde table's key and values to the first one.
-- @tparam table table The table to be modified.
-- @tparam table entries A table of (key, value) entries to be added.
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
--- Combines multiple tables' keys and values into a single one.
-- @tparam table tables A table of tables.
-- @treturn table The joined tables.
function util.join(tables)
  local new = {}
  for i = 1, #tables do
    local table = tables[i]
    util.shallowAdd(new, table)
  end
  return new
end
--- Iterates a numeric table in order.
-- @tparam table t A table with numeric keys.
-- @treturn func Iterator of <key, value, position of key>.
function util.sortedIterator(t)
  local keys = {}
  for k, v in pairs(t) do
    keys[#keys + 1] = k
  end
  table.sort(keys)
  local i = 0
  return function()
    if i >= #keys then
      return nil
    end
    i = i + 1
    return keys[i], t[keys[i]], i
  end
end
--- Prints each (key, value) entry on the table.
-- @tparam table t
function util.printEntries(t)
  for k, v in pairs(t) do
    print(k, v)
  end
end
--- Accesses a deep-located value in a path.
-- @tparam table root Root path when path is empty.
-- @tparam string path Fields to be accessed, separated by dots.
-- @treturn unknown The value if found, nil otherwise.
function util.access(root, path)
  if path == '' or path:endswith('.') then
    return nil
  end
  local value = root
  local parts = path:split('%.')
  for _, k in ipairs(parts) do
    value = value[k]
    if value == nil then
      return nil
    end
  end
  return value
end

return util
