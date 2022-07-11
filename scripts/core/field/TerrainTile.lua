
--[[===============================================================================================

TerrainTile
---------------------------------------------------------------------------------------------------
A TerrainTile is a tile composed by a set of renderers (for each corner), 
with possible animation, that stores the id of the associated terrain.

=================================================================================================]]

-- Imports
local Animation = require('core/graphics/Animation')
local Sprite = require('core/graphics/Sprite')
local Vector = require('core/math/Vector')

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

-- Constructor.
-- @param(layer : Layer) The layer that the tile is in.
-- @param(x : number) The x coordinate of the tile.
-- @param(y : number) The x coordinate of the tile.
-- @param(order : number) The rendering order for the layer.
-- @param(initialID : number) The initial terrain ID from data file.
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
-- Gets its grid coordinates.
-- @ret(number) Tile's grid x.
-- @ret(number) Tile's grid y.
-- @ret(number) Tile's height.
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
-- @ret(string) The string representation.
function TerrainTile:__tostring()
  return 'TerrainTile (' .. self.x .. ', ' ..  self.y .. ', ' .. self.layer.height .. ', ' .. self.layer.order .. ')' 
end

---------------------------------------------------------------------------------------------------
-- Terrain graphics
---------------------------------------------------------------------------------------------------

-- Sets the terrain type.
-- @param(id : number) The ID of the terrain.
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
    self.tags = Database.loadTags(nil)
    self.animations = nil
    return
  end
  -- Create new terrain images.
  self.moveCost = self.data.moveCost / 100
  self.depth = self.order
  self.tags = self.data and Database.loadTags(self.data.tags)
  if self.data.animID >= 0 then
    local rows = mathf.autoTileRows(self.layer, self.x, self.y, self.layer.sameType)
    local imageData = Database.animations[self.data.animID]
    self.depth = self.depth + imageData.transform.offsetDepth
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
-- Creates the animations for the terrain type.
-- @param(quadData : table) The terrain's quad table.
-- @param(rows : table) The autotile row of each quarter.
-- @ret(table) Array with each quarter graphics.
function TerrainTile:createQuarters(data, rows)
  local texture = ResourceManager:loadTexture(data.quad.path)
  -- Create quarter renderers.
  local quarters = {}
  for i = 1, 4 do
    local w, h = data.quad.width / data.cols, data.quad.height / data.rows
    local x, y = origins[i][1] * w, origins[i][2] * h
    local quad = newQuad(x + data.quad.x, y + data.quad.y + rows[i] * h, 
      w / 2, h / 2, texture:getWidth(), texture:getHeight())
    quarters[i] = Sprite(FieldManager.renderer, texture, quad)
    quarters[i]:setPosition(self.center)
    quarters[i]:setTransformation(data.transform)
    quarters[i]:setOffset(data.transform.offsetX - x, data.transform.offsetY - y, self.depth + 1 - origins[i][2] * 2)
  end
  return quarters
end

return TerrainTile
