
--[[===========================================================================

Path
-------------------------------------------------------------------------------
A generic path of nodes (steps).

=============================================================================]]

-- Imports
local List = require('core/datastruct/List')
local Stack = require('core/datastruct/Stack')

local Path = class()

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- @param(lastStep : unknown) the last node of the path
-- @param(previousPath : Path) The path to the last node (optional for initial).
-- @param(totalCost : number) The total cost of the path (optional for initial).
function Path:init(lastStep, previousPath, totalCost)
  totalCost = totalCost or 0
  self.lastStep = lastStep
  self.previousPath = previousPath
  self.totalCost = totalCost
end

---------------------------------------------------------------------------------------------------
-- Operators
---------------------------------------------------------------------------------------------------

-- Creates a new path with a new last node.
-- @param(step : unknown) The new step.
-- @param(cost : number) The cost of the movement to this node.
-- @ret(Path) The new path.
function Path:addStep(step, cost)
  return Path(step, self, self.totalCost + cost)
end
-- Reduces path until the total cost is less than or equal the maximum cost.
-- @param(maxCost : number) The maximum cost.
-- @ret(Path) The path to the furthest tile within reach.
function Path:getFurthestPath(maxCost)
  local path = self
  while path and path.totalCost > maxCost do
    path = path.previousPath
  end
  return path
end
-- Iterates through the tiles, from the final tile to the first.
-- @ret(function) The iterator function.
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

---------------------------------------------------------------------------------------------------
-- Convertion
---------------------------------------------------------------------------------------------------

-- Creates a list with all steps of this path, from the initial until the last.
-- @ret(List) The list of steps.
function Path:toList()
  local list = List()
  local path = self
  repeat
    list:add(path.lastStep)
    path = path.previousPath
  until path == nil
  return list
end
-- Converts to a stack of tiles.
-- @ret(Stack) A stack with the first tile of the path at the top.
function Path:toStack()
  local stack = Stack()
  for step in self:iterator() do
    stack:push(step)
  end
  stack:pop()
  return stack
end
-- Converting to string.
-- @ret(string) A string representation.
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
