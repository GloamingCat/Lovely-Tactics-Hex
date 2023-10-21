
-- ================================================================================================

--- Allows a battle action to use a ring area instead of a grid mask.
-- A ring is defined by the minimum distance, or the radius of the smallest circle - `near`
-- value -, and the maximum distance, or the radius of the largest circle - `far` value.
-- The ring is the set of tiles within these limits.  
-- It is also possible to define the maximum and minimum height differences, `minh` and `maxh`.  
-- The `cast_` tags refer to the range of the skill, i. e. the distance between the user and the
-- center target tile, and the `effect_` tags refer to the effect area, i. e. the distance between
-- the center target tile and the target character around it.
--
-- Notes:
-- 
--  * If no `cast_` tag is found in the skill, then the default cast mask is used. The same for
--  the `effect_` tags.
--  * If `near` is bigger than `far` value, the set is empty.
--  * If `far` and `near` are the same value `X`, the ring is the set of tiles that distantiates
--  from the center by exactly `X`.
--  * If `far` and `near` are `0`, the set contains only the center tile.
---------------------------------------------------------------------------------------------------
-- @plugin RingArea

--- Parameters in the Skill tags.
-- @tags Skill
-- @tfield number cast_far The maximum distance for the range of the skill.
-- @tfield number cast_near The minimum distance for the range of the skill.
-- @tfield number cast_maxh The maximum height different for the range of the skill.
-- @tfield number cast_minh The minimum height different for the range of the skill.
-- @tfield number effect_far The maximum distance from the target tile for the effect area of the skill.
-- @tfield number effect_near The minimum distance from the target tile for the effect area of the skill.
-- @tfield number effect_maxh The maximum height different from the target tile for the effect area of the skill.
-- @tfield number effect_minh The minimum height different from the target tile for the effect area of the skill.
-- @tfield boolean wholeField Flag to make the skill affect the whole field.

-- ================================================================================================

-- Imports
local FieldAction = require('core/battle/action/FieldAction')
local SkillAction = require('core/battle/action/SkillAction')
local ActionGUI = require('core/gui/battle/ActionGUI')

-- Alias
local mathf = math.field

-- ------------------------------------------------------------------------------------------------
-- SkillAction
-- ------------------------------------------------------------------------------------------------

--- Rewrites `SkillAction:init`. Creates ring masks if parameters are set in the tags.
-- @override SkillAction_init
local SkillAction_init = SkillAction.init
function SkillAction:init(...)
  SkillAction_init(self, ...)
  local t = self.tags
  if t.cast_maxh or t.cast_minh or t.cast_far or t.cast_near then
    self.range = self:createRingMask(t.cast_far or 1, t.cast_near, t.cast_minh, t.cast_maxh)
    self.moveAction.range = self.range
  end
  if t.effect_maxh or t.effect_minh or t.effect_far or t.effect_near then
    self.area = self:createRingMask(t.effect_far, t.effect_near, t.effect_minh, t.effect_maxh)
  end
  if t.wholeField then
    self.area = nil
    self.range = self:createRingMask() -- Only the center tile.
    self.moveAction.range = self.range
  end
end
--- Overrides `BattleAction:onActionGUI`.
-- @override SkillAction:onActionGUI
local SkillAction_onActionGUI = SkillAction.onActionGUI
function SkillAction:onActionGUI(input)
  SkillAction_onActionGUI(self, input)
  local far = self.tags.cast_far
  local near = self.tags.cast_near
  if not self.showStepWindow and self:isLongRanged() and (far or near) then
    far = far or 1
    near = near or 1
    input.GUI:createPropertyWindow('range', near > 1 and (near .. '-' .. far) or far):show()
  end
end
--- Creates a mask for the ring format.
-- @tparam number far The radius of the largest circle (maximum distance).
-- @tparam number near The radius of the smallest circle (minimum distance).
-- @tparam number minh Minimum height difference (usually negative).
-- @tparam number maxh Minimum height difference (usually positive).
function SkillAction:createRingMask(far, near, minh, maxh)
  far = far or 0
  near = near or 0
  minh = minh or 0
  maxh = maxh or 0
  local grid = mathf.radiusMask(far, minh, maxh)
  for i, j in mathf.radiusIterator(near - 1, far + 1, far + 1,
      far * 2 + 1, far * 2 + 1) do
    for h = 1, maxh - minh + 1 do
      grid[h][i][j] = false
    end
  end
  return { grid = grid,
    centerH = -minh + 1,
    centerX = far + 1,
    centerY = far + 1 }
end

-- ------------------------------------------------------------------------------------------------
-- FieldAction
-- ------------------------------------------------------------------------------------------------

--- Checks whether the skill's area represents whole field or not.
-- @treturn boolean
function FieldAction:wholeField()
  return self.area == nil
end
--- Rewrites `FieldAction:resetAffectedTiles`.
-- @override FieldAction_resetAffectedTiles
local FieldAction_resetAffectedTiles = FieldAction.resetAffectedTiles
function FieldAction:resetAffectedTiles(input)
  if self:wholeField() then
    local affectedTiles = self:getAllAffectedTiles(input)
    for i = 1, #affectedTiles do
      affectedTiles[i].gui.affected = true
    end
  else
    return FieldAction_resetAffectedTiles(self, input)
  end
end
--- Rewrites `FieldAction:isSelectable`.
-- @override FieldAction_isSelectable
local FieldAction_isSelectable = FieldAction.isSelectable
function FieldAction:isSelectable(input, tile)
  if self:wholeField() then
    -- User only
    return input.user:getTile() == tile
  else
    return FieldAction_isSelectable(self, input, tile)
  end
end
--- Rewrites `FieldAction:isArea`.
-- @override FieldAction_isArea
local FieldAction_isArea = FieldAction.isArea
function FieldAction:isArea()
  if self:wholeField() then
    return true
  end
  return FieldAction_isArea(self)
end
--- Rewrites `FieldAction:getAreaTiles`.
-- @override FieldAction_getAreaTiles
local FieldAction_getAreaTiles = FieldAction.getAreaTiles
function FieldAction:getAreaTiles(input, centerTile)
  if self:wholeField() then
    local tiles = {}
    for tile in self.field:gridIterator() do
      if tile and self.field:isGrounded(tile:coordinates()) then
        tiles[#tiles + 1] = tile
      end
    end
    return tiles
  else
    return FieldAction_getAreaTiles(self, input, centerTile)
  end
end
