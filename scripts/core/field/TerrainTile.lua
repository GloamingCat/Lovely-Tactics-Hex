
--[[===============================================================================================

TerrainTile
---------------------------------------------------------------------------------------------------
A TerrainTile is a tile composed by a set of renderers (for each corner), 
with possible animation, that stores the id of the associated terrain.

=================================================================================================]]

-- Imports
local Vector = require('core/math/Vector')
local Sprite = require('core/graphics/Sprite')
local Animation = require('core/graphics/Animation')

-- Alias
local mathf = math.field
local newQuad = love.graphics.newQuad

-- Constants
local tileW = Config.grid.tileW
local tileH = Config.grid.tileH
local origins = {}
origins[1] = {0, 0}
origins[2] = {0.5, 0}
origins[3] = {0, 0.5}
origins[4] = {0.5, 0.5}

local TerrainTile = class()

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- @param(layer : Layer) the layer that the tile is in
-- @param(x : number) the x coordinate of the tile
-- @param(y : number) the x coordinate of the tile
-- @param(order : number) the rendering order for the layer
-- @param(initialID : number) the initial terrain ID from data file
function TerrainTile:init(layer, x, y, order, initialID)
  self.layer = layer
  self.x = x
  self.y = y
  self.order = order
  self.data = Database.terrains[initialID]
  self.moveCost = 0
  self.depth = self.order
  self.center = Vector(math.field.tile2Pixel(self.x, self.y, self.layer.height))
end
-- @ret(number) tile's grid x
-- @ret(number) tile's grid y
-- @ret(number) tile's height
function TerrainTile:coordinates()
  return self.x, self.y, self.layer.height
end
-- Updates each animation.
function TerrainTile:update()
  if self.animations then
    for i = 1, 4 do
      self.animations[i]:update()
    end
  end
end
-- Converts to string.
-- @ret(string) the string representation
function TerrainTile:__tostring()
  return 'TerrainTile (' .. self.x .. ', ' ..  self.y .. ', ' .. self.layer.height .. ', ' .. self.layer.order .. ')' 
end

---------------------------------------------------------------------------------------------------
-- Terrain graphics
---------------------------------------------------------------------------------------------------

-- Sets the terrain type.
-- @param(id : number) the ID of the terrain
function TerrainTile:setTerrain(id)
  -- Check if it needs any change.
  if (self.data and id == self.data.id) then
    return
  end
  self.data = Database.terrains[id]
  self:updateGraphics()
  for x, y in mathf.radiusIterator(1, self.x, self.y, self.layer.sizeX, self.layer.sizeY) do
    self.layer.grid[x][y]:updateGraphics()
  end
end
-- Updates the terrain's graphics.
function TerrainTile:updateGraphics()
  -- Delete previous terrain's images.
  if self.quarters then
    for i = 1, 4 do
      self.quarters[i]:destroy()
    end
  end
  self.quarters = nil
  -- Check if id representes a terrain.
  if self.data == nil then
    self.moveCost = 0
    self.depth = self.order
    self.animations = nil
    return
  end
  -- Create new terrain images.
  self.moveCost = self.data.moveCost / 100
  self.depth = self.data.depth + self.order
  if self.data.image >= 0 then
    local rows = mathf.autoTileRows(self.layer, self.x, self.y, self.layer.sameType)
    local imageData = Database.animations[self.data.image]
    self.quarters = self:createQuarters(imageData, rows)
    -- Create animation.
    if imageData.cols > 1 then
      self.animations = self.animations or {}
      for i = 1, 4 do
        self.animations[i] = Animation(self.quarters[i], imageData)
      end
    else
      self.animations = nil
    end
  end
end
-- Creates the animations for the terrain type
-- @param(quadData : table) the terrain's quad table
-- @param(rows : table) the autotile row of each quarter
-- @ret(table) array with each quarter graphics
function TerrainTile:createQuarters(data, rows)
  local texture = ResourceManager:loadTexture(data.path)
  -- Create quarter renderers
  local quarters = {}
  for i = 1, 4 do
    local w, h = data.width / data.cols, data.height / data.rows
    local x, y = origins[i][1] * w, origins[i][2] * h
    local quad = newQuad(x + data.x, y + data.y + rows[i] * h, w / 2, h / 2, texture:getWidth(), texture:getHeight())
    local depth = (1.5 - y / h) * self.depth
    quarters[i] = Sprite(FieldManager.renderer, texture, quad)
    quarters[i]:setPosition(self.center)
    quarters[i]:setOffset(w / 2 - x, h / 2 - y, depth)
  end
  return quarters
end

return TerrainTile
