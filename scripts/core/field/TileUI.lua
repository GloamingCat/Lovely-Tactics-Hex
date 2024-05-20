
-- ================================================================================================

--- The `ObjectTile` graphics for tile selection.
-- It contains a `TileGraphic` for the base animation (the cell image for all tiles in the 
-- grid) and the highlight animation (the cell image for selected tiles). The ID/keys of both
-- animations should defined in the `Config.animations` table, with the field `tile` for the base
-- animation and `tileCursor` for the highlight animation. The highlight is shown on top of the
-- base animation.
---------------------------------------------------------------------------------------------------
-- @fieldmod TileUI

-- ================================================================================================

-- Imports
local TileGraphic = require('core/field/TileGraphic')

-- Alias
local min = math.min

-- Class table.
local TileUI = class()

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam ObjectTile tile The tile this object belongs to.
-- @tparam data baseAnim The animation data for the tile's base image.
-- @tparam data highlightAnim The animation data for the tile's selection highlight.
function TileUI:init(tile, baseAnim, highlightAnim)
  local x, y, z = tile.center:coordinates()
  if baseAnim and Config.animations.tile >= 0 then
    self.baseAnim = TileGraphic(Config.animations.tile, x, y, z)
  end
  if highlightAnim and Config.animations.tileCursor >= 0 then
    self.highlightAnim = TileGraphic(Config.animations.tileCursor, x, y, z)
  end
  self.x, self.y, self.h = tile:coordinates()
  self.grounded = FieldManager.currentField:isGrounded(tile:coordinates())
  self:updateDepth()
  self:hide()
end

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Updates graphics.
-- @tparam number dt The duration of the previous frame.
function TileUI:update(dt)
  if self.highlightAnim then
    self.highlightAnim:update(dt)
  end
  if self.baseAnim then
    self.baseAnim:update(dt)
  end
end
--- Erases any sprites.
function TileUI:destroy()
  if self.baseAnim then
    self.baseAnim:destroy()
  end
  if self.highlightAnim then
    self.highlightAnim:destroy()
  end
end

-- ------------------------------------------------------------------------------------------------
-- Graphics
-- ------------------------------------------------------------------------------------------------

--- Refreshes the relative pixel depths of the sprites.
function TileUI:updateDepth()
  if not self.grounded then
    return
  end
  if self.baseAnim then
    self.baseAnim:setDepth(2)
  end
  if self.highlightAnim then
    self.highlightAnim:setDepth(1)
  end
end
--- Selects / deselects this tile.
-- @tparam boolean value True to select, false to deselect.
function TileUI:setSelected(value)
  if self.highlightAnim then
    self.highlightAnim:setVisible(value)
  end
end
--- Sets color to the color with the given label.
-- @tparam string name Color label.
function TileUI:setColor(name)
  self.colorName = name
  if name == nil or name == '' then
    name = 'nothing'
  end
  name = 'tile_' .. name
  if not self.selectable then
    name = name .. '_off'
  end
  local c = Color[name]
  self.baseAnim:setColor(c)
end

-- ------------------------------------------------------------------------------------------------
-- Show / Hide
-- ------------------------------------------------------------------------------------------------

--- Shows tile edges.
function TileUI:show()
  if self.baseAnim then
    self.baseAnim:setVisible(self.grounded)
  end
end
--- Hides tile edges.
function TileUI:hide()
  if self.baseAnim then
    self.baseAnim:setVisible(false)
  end
  self:setSelected(false)
end

return TileUI
