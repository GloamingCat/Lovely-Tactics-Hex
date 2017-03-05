
--[[

A generic path of nodes.

]]

local Path = require('core/class'):new()

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

return Path