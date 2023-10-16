
--[[===============================================================================================

@classmod BattleAnimations
---------------------------------------------------------------------------------------------------
Module with helper functions to play battle effects.

=================================================================================================]]

local BattleAnimations = {}

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- [COROUTINE] Plays a battle animation.
-- @tparam number animID The animation's ID from database.
-- @tparam number x Pixel x of the animation.
-- @tparam number y Pixel y of the animation.
-- @tparam number z Pixel depth of the animation.
-- @tparam boolean mirror mirror the sprite in x-axis.
-- @tparam boolean wait True to wait until first loop finishes (optional).
-- @treturn Animation The newly created animation.
function BattleAnimations.play(manager, animID, x, y, z, mirror, wait)
  local data = Database.animations[animID]
  local animation = ResourceManager:loadAnimation(data, manager.renderer)
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
--- Play animation in field.
function BattleAnimations.playOnField(animID, x, y, z, mirror, wait)
  return BattleAnimations.play(FieldManager, animID, x, y, z, mirror, wait)
end
--- Play animation in GUI.
function BattleAnimations.playOnMenu(animID, x, y, z, wait)
  return BattleAnimations.play(GUIManager, animID, x or 0, y or 0, z or -50, false, wait)
end

-- ------------------------------------------------------------------------------------------------
-- Skill
-- ------------------------------------------------------------------------------------------------

-- @tparam table skill Skill data.
-- @tparam Vector pos Animation position.
-- @tparam number dir Looking angle.
-- @treturn number The duration of the animation.
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
-- @tparam table skill Skill data.
-- @tparam ObjectTile tile Target tile.
-- @tparam number dir Looking angle.
-- @treturn number The duration of the animation.
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
--- Plays the visual effect for the skill's target.
-- @tparam table skill Skill data.
-- @tparam Character char Target character.
-- @tparam ObjectTile tile Skill's origin tile.
-- @treturn number The duration of the animation.
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
--- Plays the visual effect for a character's death.
-- @tparam Character char Target character.
-- @treturn number The duration of the animation.
function BattleAnimations.dieEffect(char)
  if char.data.koAnimID and char.data.koAnimID >= 0 then
    local x, y, z = char.position:coordinates()
    local anim = BattleAnimations.playOnField(char.data.koAnimID, x, y, z)
    return anim.duration
  end
  return 0
end
--- Plays the visual effect for the skill's target.
-- @tparam table skill Skill data.
-- @tparam number x Position x of the target (in pixels).
-- @tparam number y Position y of the target (in pixels).
-- @treturn number The duration of the animation.
function BattleAnimations.menuTargetEffect(skill, x, y)
  local t = 0
  if skill.castAnimID >= 0 then
    if skill.individualAnimID >= 0 then
      t = BattleAnimations.playOnMenu(skill.castAnimID, 0, 0, -50, false).duration
    else
      t = BattleAnimations.playOnMenu(skill.castAnimID, x, y, -50, false).duration
    end
  end
  if skill.individualAnimID >= 0 then
    t = math.max(BattleAnimations.playOnMenu(skill.individualAnimID, x, y, -50, false).duration, t)
  end
  return t
end

return BattleAnimations
