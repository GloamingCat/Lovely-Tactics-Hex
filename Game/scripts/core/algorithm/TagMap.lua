
--[[===============================================================================================

TagMap
---------------------------------------------------------------------------------------------------
An usable map generated from a tag list from an object of the database.

=================================================================================================]]

local TagMap = class()

-- Constructor.
-- @param(data : table) an array of tag items
function TagMap:init(data)
  for i = 1, #data do
    self:add(data[i])
  end
end

-- Adds new tag item.
-- @param(tag : table) tag item (with key and value fields)
function TagMap:add(tag)
  local old = self[tag.key]
  if old then
    if type(old) == 'string' then
      self[tag.key] = { old, tag.value }
    else
      old[#old + 1] = tag.value
    end
  else
    self[tag.key] = tag.value
  end
end

return TagMap
