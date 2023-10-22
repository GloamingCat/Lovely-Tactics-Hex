
-- ================================================================================================

--- A TerrainTile is a tile composed by a set of renderers (for each corner), 
-- with possible animation, that stores the id of the associated terrain.
---------------------------------------------------------------------------------------------------
-- @classmod TerrainTile

-- ================================================================================================

-- Imports
local Animation = require('core/graphics/Animation')
local Sprite = require('core/graphics/Sprite')
local Vector = require('core/math/Vector')

-- Alias
local mathf = math.field
local newQuad = love.graphics.newQuad

-- Constants
local origins = {}
origins[1] = {0, 0}
origins[2] = {0.5, 0}
origins[3] = {0, 0.5}
origins[4] = {0.5, 0.5}

-- Class table.
local TerrainTile = class()

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam Layer layer The layer that the tile is in.
-- @tparam number x The x coordinate of the tile.
-- @tparam number y The x coordinate of the tile.
-- @tparam number order The rendering order for the layer.
-- @tparam number initialID The initial terrain ID from data file.
function TerrainTile:init(layer, x, y, order, initialID)
  self.layer = layer
  self.x = x
  self.y = y
  self.order = order
  self.data = Database.terrains[initialID]
  self.moveCost = 0
  self.center = Vector(math.field.tile2Pixel(self:coordinates()))
end
--- Gets its grid coordinates.
-- @treturn number Tile's grid x.
-- @treturn number Tile's grid y.
-- @treturn number Tile's height.
function TerrainTile:coordinates()
  return self.x, self.y, self.layer.height
end
--- Updates each animation.
function TerrainTile:update(dt)
  if self.animations then
    for i = 1, 4 do
      self.animations[i]:update(dt)
    end
  end
end
--- Diposes of all animations.
function TerrainTile:destroy()
  if self.animations then
    for i = 1, 4 do
      self.animations[i]:destroy()
    end
  end
end

-- ------------------------------------------------------------------------------------------------
-- Terrain graphics
-- ------------------------------------------------------------------------------------------------

--- Sets the terrain type.
-- @tparam number id The ID of the terrain.
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
--- Updates the terrain's graphics.
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
    self.tags = Database.loadTags(nil)
    self.animations = nil
    return
  end
  -- Create new terrain images.
  self:setMoveCost(self.data)
  self.tags = self.data and Database.loadTags(self.data.tags)
  if self.data.animID >= 0 then
    local rows = mathf.autoTileRows(self.layer, self.x, self.y, self.layer.sameType)
    local imageData = Database.animations[self.data.animID]
    local depth = self.order + imageData.transform.offsetDepth
    self.quarters = self:createQuarters(imageData, rows, depth)
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
--- Creates the animations for the terrain type.
-- @tparam table data The terrain's quad table.
-- @tparam table rows The autotile row of each quarter.
-- @tparam number depth The tile's depth in world coordinates.
-- @treturn table Array with each quarter graphics.
function TerrainTile:createQuarters(data, rows, depth)
  local texture = ResourceManager:loadTexture(data.quad.path)
  -- Create quarter renderers.
  local quarters = {}
  for i = 1, 4 do
    local w, h = data.quad.width / data.cols, data.quad.height / data.rows
    local x, y = origins[i][1] * w, origins[i][2] * h
    local quad = newQuad(x + data.quad.x, y + data.quad.y + rows[i] * h, 
      w / 2, h / 2, texture:getWidth(), texture:getHeight())
    local d = (0.5 - origins[i][2]) * Config.grid.depthPerY
    quarters[i] = Sprite(FieldManager.renderer, texture, quad)
    quarters[i]:setPosition(self.center)
    quarters[i]:setTransformation(data.transform)
    quarters[i]:setOffset(data.transform.offsetX - x, data.transform.offsetY - y, depth + d)
  end
  return quarters
end

-- ------------------------------------------------------------------------------------------------
-- Move Cost
-- ------------------------------------------------------------------------------------------------

--- Gets the move cost for given character.
-- @tparam Character char
-- @treturn number
function TerrainTile:getMoveCost(char)
  if not char.battler or not self.jobMoveCost then
    return self.moveCost / 100
  end
  return (self.jobMoveCost[char.battler.job.id] or self.moveCost) / 100
end
--- Sets move cost according to data.
-- @tparam table data Terrain data from database.
function TerrainTile:setMoveCost(data)
  if type(data) == 'number' then
    self.moveCost = data
    self.jobMoveCost = nil
  else
    self.moveCost = data.moveCost
    self.jobMoveCost = data.jobMoveCost and Database.loadBonusTable(data.jobMoveCost)
  end
end
-- For debugging.
function TerrainTile:__tostring()
  return 'TerrainTile (' .. self.x .. ', ' ..  self.y .. ', ' .. self.layer.height .. ', ' .. self.layer.order .. ')' 
end

return TerrainTile
