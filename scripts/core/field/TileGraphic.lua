
--[[===============================================================================================

TileGraphic
---------------------------------------------------------------------------------------------------
Used for single-row tile graphics. It is composed by the top half ans bottom half sprites,
such that the top half sprite's depth is greater by 0.5 tile.

=================================================================================================]]

-- Imports
local Animation = require('core/graphics/Animation')
local Sprite = require('core/graphics/Sprite')
local Vector = require('core/math/Vector')

-- Alias
local newQuad = love.graphics.newQuad

local TileGraphic = class()

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(animID : number) Graphic's animation ID.
-- @param(x : number) Tile's center pixel x.
-- @param(y : number) Tile's center pixel y.
-- @param(z : number) Tile's center pixel depth.
function TileGraphic:init(animID, x, y, z)
  self.data = Database.animations[animID]
  self.halfDepth = Config.grid.depthPerY / 2
  -- Top half
  local topSprite = self:createSprite(0)
  self.topAnim = Animation(topSprite, self.data)
  topSprite:setXYZ(x, y, z)
  -- Bottom half
  local bottomSprite = self:createSprite(1)
  self.bottomAnim = Animation(bottomSprite, self.data)
  bottomSprite:setXYZ(x, y, z)
end
-- Creates a sprite for half of the tile.
-- @param(y : number) 0 for top half, 1 for bottom half.
function TileGraphic:createSprite(y)
  local texture = ResourceManager:loadTexture(self.data.quad.path)
  local w = self.data.quad.width / self.data.cols
  local h = self.data.quad.height / self.data.rows / 2
  local quad = newQuad(self.data.quad.x, self.data.quad.y + y * h, 
    w, h, texture:getWidth(), texture:getHeight())
  local sprite = Sprite(FieldManager.renderer, texture, quad)
  local t = self.data.transform
  sprite:setOffset(t.offsetX, t.offsetY - y * h)
  return sprite
end
-- Updates each animation.
function TileGraphic:update()
  self.topAnim:update()
  self.bottomAnim:update()
end
-- Erases both sprites.
function TileGraphic:destroy()
  self.topAnim:destroy()
  self.bottomAnim:destroy()
end
-- Adds the depth offset to the original offset (from animation's transform).
-- @param(depth : number) Depth offset.
function TileGraphic:setDepth(depth)
  local t = self.data.transform
  self.topAnim.sprite:setOffset(nil, nil, t.offsetDepth + depth + self.halfDepth)
  self.bottomAnim.sprite:setOffset(nil, nil, t.offsetDepth + depth)
end
-- Shows/hides sprites.
-- @param(value : boolean)
function TileGraphic:setVisible(value)
  self.topAnim.sprite:setVisible(value)
  self.bottomAnim.sprite:setVisible(value)
end
-- Sets sprites's color.
-- @param(color : table) Color table, with red, green, blue and alpha values.
function TileGraphic:setColor(color)
  self.topAnim.sprite:setColor(color)
  self.bottomAnim.sprite:setColor(color)
end
-- Converts to string.
-- @ret(string) The string representation.
function TileGraphic:__tostring()
  return 'TileGraphic (' .. self.data.id ..  ')' 
end

return TileGraphic
