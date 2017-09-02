
--[[===============================================================================================

TagMap
---------------------------------------------------------------------------------------------------
Transforms an array of tags into a map.

=================================================================================================]]

local TagMap = class()

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

function TagMap:init(tags)
  self.tags = {}
  for i = 1, #tags do
    local arr = self.tags[tags[i].name]
    if not arr then
      arr = {}
      self.tags[tags[i].name] = arr
    end
    arr[#arr + 1] = tags[i].value
  end
end

---------------------------------------------------------------------------------------------------
-- Access
---------------------------------------------------------------------------------------------------

function TagMap:get(name)
  local arr = self.tags[name]
  if arr then
    return arr[1]
  else
    return nil
  end
end

function TagMap:getAll(name)
  return self.tags[name]
end

return TagMap
