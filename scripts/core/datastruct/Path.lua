
--[[===========================================================================

Path
-------------------------------------------------------------------------------
A generic path of nodes (steps).

=============================================================================]]

-- Imports
local List = require('core/datastruct/List')

local Path = class()

-- @param(lastStep : unknown) the last node of the path
-- @param(previousPath : Path) the path to the last node (optional for initial)
-- @param(totalCost : number) the total cost of the path (optional for initial)
function Path:init(lastStep, previousPath, totalCost)
  totalCost = totalCost or 0
  self.lastStep = lastStep
  self.previousPath = previousPath
  self.totalCost = totalCost
end

-- Creates a new path with a new last node.
-- @param(step : unknown) the new step
-- @param(cost : number) the cost of the movement to this node
-- @ret(Path) the new path
function Path:addStep(step, cost)
  return Path(step, self, self.totalCost + cost)
end

-- Iterates through the tiles, from the final tile to the first.
-- @ret(function) the iterator function
function Path:iterator()
  local p = self
  return function()
    if p ~= nil then
      local step = p.lastStep
      p = p.previousPath
      return step
    end
  end
end

-- Creates a list with all steps of this path, from the initial until the last.
-- @ret(List) the list of steps
function Path:toList()
  local list = List()
  local path = self
  repeat
    list:add(path.lastStep)
    path = path.previousPath
  until path == nil
  return list
end

-- Converting to string.
-- @ret(string) A string representation
function Path:__tostring()
  local list = self:toList()
  if list.size == 0 then
    return 'Path {}'
  end
  local string = 'Path {'
  for i = 1, list.size - 1 do
    string = string .. tostring(list[i]) .. ', '
  end
  return string .. tostring(list[list.size]) .. '}'
end

return Path
