
-- ================================================================================================

--- Cursor used to indicate current turn's character and the selected tile.
---------------------------------------------------------------------------------------------------
-- @battlemod BattleCursor

-- ================================================================================================

-- Imports
local Animation = require('core/graphics/Animation')

-- Alias
local mathf = math.field
local max = math.max

-- Constants
local tileW = Config.grid.tileW
local tileH = Config.grid.tileH
local pph = Config.grid.pixelsPerHeight

-- Class table.
local BattleCursor = class()

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Constructor.
function BattleCursor:init()
  local cursorAnimID = Config.animations.battleCursor
  if cursorAnimID >= 0 then
    self.anim = ResourceManager:loadAnimation(cursorAnimID, FieldManager.renderer)
  end
end
--- Updates animation.
-- @tparam number dt The duration of the previous frame.
function BattleCursor:update(dt)
  if self.anim then
    self.anim:update(dt)
  end
end
--- Sets as visible.
function BattleCursor:show()
  if self.anim then
    self.anim.sprite:setVisible(true)
  end
end
--- Sets as not visible.
function BattleCursor:hide()
  if self.anim then
    self.anim.sprite:setVisible(false)
  end
end
--- Removes from renderer.
function BattleCursor:destroy()
  if self.anim then
    self.anim.sprite:removeSelf()
  end
  self.destroyed = true
end

-- ------------------------------------------------------------------------------------------------
-- Position
-- ------------------------------------------------------------------------------------------------

--- Sets the position to the given tile.
-- @tparam ObjectTile tile The target tile.
function BattleCursor:setTile(tile)
  if not self.anim then
    return
  end
  local x, y, z = tile.center:coordinates()
  self.anim.sprite:setVisible(tile.ui.selectable)
  local maxH = 0
  for obj in tile.obstacleList:iterator() do
    maxH = max(maxH, obj:getHeight())
  end
  for obj in tile.characterList:iterator() do
    maxH = max(maxH, obj:getHeight())
  end
  self.anim.sprite:setXYZ(x, y - maxH * pph, z - 1)
end
--- Sets the position to the given character.
-- @tparam Character char The target character.
function BattleCursor:setCharacter(char)
  local x, y, z = char.position:coordinates()
  self.anim.sprite:setVisible(true)
  local maxH = char:getHeight()
  self.anim.sprite:setXYZ(x, y - maxH * pph, z - 1)
end

return BattleCursor
