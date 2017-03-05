
local Vector = require('core.math.Vector')
local Line = require('core.math.Line')

--[[
@module

Holds data about the ramp.

]]

local Ramp = require('class'):new()

-- @param(data : table) the data from file
function Ramp:init(data)
  self.pixelX = 0
  self.pixelY = 0
  self.minHeight = 0
  self.maxHeight = data.height
  self.height = data.height
  self.top = self:calculateTop(data.points)
  self.bottom = self:calculateBottom(data.points)
end

-- Sets the ramp's center.
-- @param(x : number) position's x in pixels
-- @param(y : number) position's y in pixels
function Ramp:setPosition(x, y)
  self.pixelX = x
  self.pixelY = y
end

-- Sets the height of the ramp's base.
-- @param(h : number) height in tiles
function Ramp:setHeight(h)
  self.minHeight = h
  self.maxHeight = self.height + h
end

-- Calculares implicit equation for the edge between two vertexes.
-- @param(p1 : Vector) the first line's point
-- @param(p2 : Vector) the second line's point
-- @ret(Line) the edge between vertexes
function Ramp:getEdge(p1, p2)
  local a = p2.y - p1.y
  local b = p1.x - p2.x
  return Line(a, b, - a*p2.x - b*p1.y)
end

-- Calculates the line that separates the ramp and the top layer.
-- @ret(Line) the top line
function Ramp:calculateTop(points)
  local p1 = Vector(points.t1x, points.t1y)
  local p2 = Vector(points.t2x, points.t2y)
  return self:getEdge(p1, p2)
end

-- Calculates the line that separates the ramp and the bottom layer.
-- @ret(Line) the bottom line
function Ramp:calculateBottom(points)
  local p1 = Vector(points.b1x, points.b1y)
  local p2 = Vector(points.b2x, points.b2y)
  return self:getEdge(p1, p2)
end

-- Gets the height in the position (tileX, tileY).
-- @param(position : Vector) the position in pixels
-- @ret(number) the height in tiles
function Ramp:getHeight(position)
  local x = position.x - self.pixelX
  local y = position.y - self.pixelY
  local d1 = self.bottom:distance(position.x, position.y)
  local d2 = self.top:distance(position.x, position.y)
  local t = 0.5 + (d2 - d1) / (d2 + d1)
  return self.minHeight * (1 - t) + self.maxHeight * t
end

function Ramp:toString()
  return 'Ramp <Bottom: ' .. self.bottom:toString() .. ', Top: ' .. self.top:toString() .. '>'
end

return Ramp
