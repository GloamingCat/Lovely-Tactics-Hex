
local Vector = require('core/math/Vector')
local Sprite = require('core/graphics/Sprite')
local Animation = require('core/graphics/Animation')
local mathf = math.field
local tileW = Config.tileW
local tileH = Config.tileH
local tileB = Config.tileB
local tileS = Config.tileS

--[[===========================================================================

A TerrainTile is a tile composed by a set of renderers (for each corner), with possible animation,
that stores the id of the associated terrain.

=============================================================================]]

local TerrainTile = require('core/class'):new()

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
    for i = 0, 4 do
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
    local texture = love.graphics.newImage('images/' .. terrainData.imagePath)
    local rows = mathf.autoTileRows(self.layer.grid, self.x, self.y)
    self:setQuarters(texture, rows)
    -- Create animation.
    if terrainData.frameCount > 1 then
      self.animations = {}
      for i = 1, 4 do
        local rows = 8
        local cols = terrainData.frameCount
        self.animations[i] = Animation(terrainData.duration, rows, cols, 
          tileW, tileH, self.quarters[i])
      end
      FieldManager.updateList:add(self)
    end
  end
end

-- Creates the animations for the terrain type
-- @param(texture : Texture) the terrain's image
-- @param(position : Vector) the pixel position of the tile's center
-- @param(rows : table) the autotile row of each quarter
-- @param(terrainData : table) information about the terrain
function TerrainTile:setQuarters(texture, rows)
  -- Temp function to create a quad
  local function quad(x, y)
    return love.graphics.newQuad(x, y, tileW / 2, tileH / 2, 
      texture:getWidth(), texture:getHeight())
  end
  -- Temp quarter array
  local viewports = {}
  viewports[1] = {0, 0}
  viewports[2] = {tileW / 2, 0}
  viewports[3] = {0, tileH / 2}
  viewports[4] = {tileW / 2, tileH / 2}
  -- Create quarter renderers
  self.quarters = {}
  for i = 1, 4 do
    local x, y = viewports[i][1], viewports[i][2]
    local quad = quad(x, y + rows[i] * tileH)
    local depth = (1 - y / tileH) * self.depth
    self.quarters[i] = Sprite(texture, quad, FieldManager.renderer)
    self.quarters[i]:setPosition(self.center)
    self.quarters[i]:setOffset(tileW / 2 - x, tileH / 2 - y, depth)
  end
end

-- Updates each animation.
function TerrainTile:update()
  for i = 1, 4 do
    self.animations[i]:update()
  end
end

function TerrainTile:toString()
  return 'TerrainTile (' .. self.x .. ', ' ..  self.y .. ', ' .. self.layer.height .. ', ' .. self.layer.order .. ')' 
end

return TerrainTile
