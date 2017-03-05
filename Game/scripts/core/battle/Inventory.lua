
local List = require('core/algorithm/List')
local Random = love.math.random

--[[===========================================================================



=============================================================================]]

local Inventory = List:inherit()

local old_init = Inventory.init
function Inventory:init(list)
  old_init(self)
  if list then
    for i = 1, #list do
      local r = Random(100)
      if r <= list[i].rate then
        self:add(list[i].id)
      end
    end
  end
end

-- Converting to string.
-- @ret(string) A string representation
function Inventory:toString()
  if self.size == 0 then
    return 'Inventory {}'
  end
  local string = 'Inventory {'
  for i = 1, self.size - 1 do
    string = string .. tostring(self[i]) .. ', '
  end
  return string .. tostring(self[self.size]) .. '}'
end

return Inventory
