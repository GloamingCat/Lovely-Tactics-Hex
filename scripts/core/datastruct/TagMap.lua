
-- ================================================================================================

--- Transforms an array of tags into a map.
---------------------------------------------------------------------------------------------------
-- @classmod TagMap

-- ================================================================================================

-- Imports
local Serializer = require('core/save/Serializer')

-- Class table.
local TagMap = class()

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam table tags Array with (name, value) tags.
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
  local value = Serializer.decode(str)
  if value == nil then
    value = str
  end
  arr[#arr + 1] = value
  self[name] = self[name] or value
end
--- Inserts a set of tag pairs.
-- @tparam table tags Array with (name, value) tags.
function TagMap:addAll(tags)
  for i = 1, #tags do
    local name = tags[i].key
    local str = tags[i].value
    local arr = self.tags[name]
    if not arr then
      arr = {}
      self.tags[name] = arr
    end
    local value = Serializer.decode(str)
    if value == nil then
      value = str
    end
    arr[#arr + 1] = value
    self[name] = self[name] or value
  end
end

-- ------------------------------------------------------------------------------------------------
-- Conversion
-- ------------------------------------------------------------------------------------------------

-- @treturn table A table with unique keys. It will include only the first value of each key.
function TagMap:toTable()
  local t = {}
  for k, v in pairs(self.tags) do
    t[k] = v[1]
  end
  return t
end
-- @treturn table Array of {key, value} entries.
function TagMap:toList()
  local list = {}
  for k, v in pairs(self.tags) do
    for i = 1, #v do
      list[#list + 1] = { key = k, v = v[i] }
    end
  end
  return list
end
-- @treturn string String identifier.
function TagMap:__tostring()
  local s = '{'
  for k, v in pairs(self.tags) do
    for i = 1, #v do
      s = s .. ', ' .. k .. ' = ' .. v[i]
    end
  end
  s = s:gsub(', ', '', 1)
  return s .. '}'
end

return TagMap
