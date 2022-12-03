
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
    animation:setXYZ(x, y, z - 10)    
    if mirror then
      animation.sprite:setScale(-animation.sprite.scaleX, animation.sprite.scaleY)
    end
  end
  animation:setOneshot(true)
  manager.updateList:add(animation)
  if wait then
    while not animation.destroyed do
      _G.Fiber:wait()
    end
  end
  return animation
end
-- Play animation in field.
function BattleAnimations.playOnField(animID, x, y, z, mirror, wait)
  return BattleAnimations.play(FieldManager, animID, x, y, z, mirror, wait)
end
-- Play animation in GUI.
function BattleAnimations.playOnMenu(animID, x, y, z, wait)
  return BattleAnimations.play(GUIManager, animID, x or 0, y or 0, z or -50, false, wait)
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
-- Plays the visual effect for the skill's target.
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
-- Plays the visual effect for the skill's target.
-- @param(skill : table) Skill data.
-- @param(x : number) Position x of the target (in pixels).
-- @param(y : number) Position y of the target (in pixels).
-- @ret(number) The duration of the animation.
function BattleAnimations.menuTargetEffect(skill, x, y)
  if skill.castAnimID >= 0 then
    return BattleAnimations.playOnMenu(skill.castAnimID, x, y, -50, false)
  end
  return 0
end

return BattleAnimations
