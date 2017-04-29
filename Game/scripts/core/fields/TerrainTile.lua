
--[[===========================================================================

TerrainTile
-------------------------------------------------------------------------------
A TerrainTile is a tile composed by a set of renderers (for each corner), 
with possible animation, that stores the id of the associated terrain.

=============================================================================]]

-- Imports
local Vector = require('core/math/Vector')
local Sprite = require('core/graphics/Sprite')
local Animation = require('core/graphics/Animation')

-- Alias
local mathf = math.field
local newQuad = love.graphics.newQuad
local newImage = love.graphics.newImage

-- Constants
local tileW = Config.grid.tileW
local tileH = Config.grid.tileH
local tileB = Config.grid.tileB
local tileS = Config.grid.tileS
local viewports = {}
viewports[1] = {0, 0}
viewports[2] = {tileW / 2, 0}
viewports[3] = {0, tileH / 2}
viewports[4] = {tileW / 2, tileH / 2}

local TerrainTile = class()

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
  self.id = initialID
  self.terrainData = nil
  self.moveCost = 0
  self.depth = 0
  self.center = Vector(math.field.tile2Pixel(self.x, self.y, self.layer.height))
end

-- @ret(number) tile's grid x
-- @ret(number) tile's grid y
-- @ret(number) tile's height
function TerrainTile:coordinates()
  return self.x, self.y, self.layer.height
end

-- Sets the terrain type.
-- @param(id : number) the ID of the terrain
function TerrainTile:setTerrain(id)
  -- Check if it needs any change.
  if (id == self.id) then
    return
  end
  self.id = id
  -- Delete previous terrain's images.
  if self.quarters then
    for i = 1, 4 do
      self.quarters[i]:dispose()
    end
  end
  -- Check if id representes a terrain.
  if id < 0 then
    self.terrainData = nil
    self.moveCost = 0
    self.depth = 0
    return
  end
  -- Create new terrain images.
  local terrainData = Database.terrains[id + 1]
  self.terrainData = terrainData
  self.moveCost = terrainData.moveCost / 100
  self.depth = terrainData.depth - self.order
  if terrainData.imagePath ~= '' then
    local rows = mathf.autoTileRows(self.layer.grid, self.x, self.y)
    self:setQuarters(terrainData.quad, rows)
    -- Create animation.
    if terrainData.frameCount > 1 then
      self.animations = {}
      for i = 1, 4 do
        local rows = 8
        local cols = terrainData.frameCount
        self.animations[i] = Animation(terrainData.duration, rows, cols, 
          tileW, tileH, true, false, self.quarters[i])
      end
    end
  end
end

-- Creates the animations for the terrain type
-- @param(quadData : table) the terrain's quad table
-- @param(rows : table) the autotile row of each quarter
function TerrainTile:setQuarters(quadData, rows)
  local texture = newImage('images/' .. quadData.imagePath)
  -- Temp function to create a quad
  local function createQuad(x, y)
    return newQuad(x + quadData.x, y + quadData.y, tileW / 2, tileH / 2, 
      texture:getWidth(), texture:getHeight())
  end
  -- Create quarter renderers
  self.quarters = {}
  for i = 1, 4 do
    local x, y = viewports[i][1], viewports[i][2]
    local quad = createQuad(x, y + rows[i] * tileH)
    local depth = (1 - y / tileH) * self.depth
    self.quarters[i] = Sprite(FieldManager.renderer, texture, quad)
    self.quarters[i]:setPosition(self.center)
    self.quarters[i]:setOffset(tileW / 2 - x, tileH / 2 - y, depth)
  end
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

return TerrainTile
