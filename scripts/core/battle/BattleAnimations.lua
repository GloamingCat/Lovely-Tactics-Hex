
--[[===============================================================================================

BattleAnimations
---------------------------------------------------------------------------------------------------
Module with helper functions to play battle effects.

=================================================================================================]]

local BattleAnimations = {}

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- [COROUTINE] Plays a battle animation.
-- @param(animID : number) the animation's ID from database
-- @param(x : number) pixel x of the animation
-- @param(y : number) pixel y of the animation
-- @param(z : number) pixel depth of the animation
-- @param(mirror : boolean) mirror the sprite in x-axis
-- @param(wait : boolean) true to wait until first loop finishes (optional)
-- @ret(Animation) the newly created animation
function BattleAnimations.play(manager, animID, x, y, z, mirror, wait)
  local animation = ResourceManager:loadAnimation(animID, manager.renderer)
  if animation.sprite then
    animation.sprite:setXYZ(x, y, z - 10)
    animation.sprite:setTransformation(animation.data.transform)
    if mirror then
      animation.sprite:setScale(-animation.sprite.scaleX, animation.sprite.scaleY)
    end
  end
  manager.updateList:add(animation)
  local fiber = manager.fiberList:fork(function()
    _G.Fiber:wait(animation.duration)
    manager.updateList:removeElement(animation)
    animation:destroy()
  end)
  if wait then
    fiber:waitForEnd()
  end
  return animation
end
-- Play animation in field.
function BattleAnimations.playOnField(animID, x, y, z, mirror, wait)
  return BattleAnimations.play(FieldManager, animID, x, y, z, mirror, wait)
end
-- Play animation in GUI.
function BattleAnimations.playOnMenu(animID, wait)
  return BattleAnimations.play(GUIManager, animID, 0, 0, 200, false, wait)
end

---------------------------------------------------------------------------------------------------
-- Skill
---------------------------------------------------------------------------------------------------

-- @param(skill : table) Skill data.
-- @param(pos : Vector) Animation position.
-- @param(dir : number) Looking angle.
-- @ret(number) The duration of the animation.
function BattleAnimations.loadEffect(skill, pos, dir)
  -- Load animation (effect on tile)
  if skill.loadAnimID >= 0 then
    local mirror = skill.mirror and dir > 90 and dir <= 270
    local anim = BattleAnimations.playOnField(skill.loadAnimID, 
      pos.x, pos.y, pos.z - 1, mirror)
    return anim.duration
  end
  return 0
end
-- @param(skill : table) Skill data.
-- @param(tile : ObjectTile) Target tile.
-- @param(dir : number) Looking angle.
-- @ret(number) The duration of the animation.
function BattleAnimations.castEffect(skill, tile, dir)
  -- Cast animation (effect on tile)
  if skill.castAnimID >= 0 then
    local mirror = skill.mirror and dir > 90 and dir <= 270
    local x, y, z = tile.center:coordinates()
    local anim = BattleAnimations.playOnField(skill.castAnimID,
      x, y, z - 1, mirror)
    return anim.duration
  end
  return 0
end
-- @param(skill : table) Skill data.
-- @param(char : Character) Target character.
-- @param(tile : ObjectTile) Skill's origin tile.
-- @ret(number) The duration of the animation.
function BattleAnimations.targetEffect(skill, char, tile)
  if skill.individualAnimID >= 0 then
    local dir = char:tileToAngle(tile.x, tile.y)
    local mirror = dir > 90 and dir <= 270
    local pos = char.position
    local anim = BattleAnimations.playOnField(skill.individualAnimID,
      pos.x, pos.y, pos.z - 10, mirror)
    return anim.duration
  end
  return 0
end

return BattleAnimations
