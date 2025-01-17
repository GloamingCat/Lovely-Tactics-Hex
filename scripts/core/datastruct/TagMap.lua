
-- ================================================================================================

--- Transforms an array of tags into a map.
---------------------------------------------------------------------------------------------------
-- @basemod TagMap

-- ================================================================================================

-- Imports
local Serializer = require('core/save/Serializer')

-- Class table.
local TagMap = class()

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam table tags Array with (key, value) tags.
function TagMap:init(tags)
  self.tags = {}
  if tags then
    self:addAll(tags)
  end
end

-- ------------------------------------------------------------------------------------------------
-- Access
-- ------------------------------------------------------------------------------------------------

--- Gets the tag value from name.
-- @tparam string name Tag name.
-- @treturn string Tag value.
function TagMap:get(name)
  local arr = self.tags[name]
  if arr then
    return arr[1]
  else
    return nil
  end
end
--- Gets all tag values from name.
-- @tparam string name Tag name.
-- @treturn table Array of tag values (strings).
function TagMap:getAll(name)
  return self.tags[name]
end

-- ------------------------------------------------------------------------------------------------
-- Insertion
-- ------------------------------------------------------------------------------------------------

--- Inserts a new tag pair.
-- @tparam string name Tag name.
-- @tparam string str Tag value.
function TagMap:add(name, str)
  local arr = self.tags[name]
  if not arr then
    arr = {}
    self.tags[name] = arr
  end
  local value = self:evaluate(str)
  arr[#arr + 1] = value
  self[name] = self[name] or value
end
--- Inserts a set of tag pairs.
-- @tparam table tags Array with (key, value) tags.
function TagMap:addAll(tags)
  for i = 1, #tags do
    local name = tags[i].key
    local str = tags[i].value
    self:add(name, str)
  end
end
--- Converts the string value to another type.
-- @tparam string value The value in its original string format.
-- @return The evaluated expression.
function TagMap:evaluate(value)
  if type(value) == 'string' then
    local str = value:interpolate(Variables)
    local json = Serializer.decode(str)
    if json == nil then
      value = str
    else
      value = json
    end
  end
  return value
end

-- ------------------------------------------------------------------------------------------------
-- Conversion
-- ------------------------------------------------------------------------------------------------

--- Converts to native table.
-- @treturn table A table with unique keys. It will include only the first value of each key.
function TagMap:toTable()
  local t = {}
  for k, v in pairs(self.tags) do
    t[k] = v[1]
  end
  return t
end
--- Converts to an array of entries.
-- @treturn table Array of {key, value} entries.
function TagMap:toArray()
  local list = {}
  for k, v in pairs(self.tags) do
    for i = 1, #v do
      list[#list + 1] = { key = k, value = tostring(v[i]) }
    end
  end
  return list
end
-- For debugging.
function TagMap:__tostring()
  local s = '{'
  for k, v in pairs(self.tags) do
    for i = 1, #v do
      s = s .. ', ' .. k .. ' = ' .. tostring(v[i])
    end
  end
  s = s:gsub(', ', '', 1)
  return s .. '}'
end

return TagMap
