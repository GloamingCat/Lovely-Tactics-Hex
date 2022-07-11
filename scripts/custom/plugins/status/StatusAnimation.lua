
--[[===============================================================================================

StatusAnimation
---------------------------------------------------------------------------------------------------
A battle animation over character's sprite.

-- Skill parameters:
Animation ID is defined by <animID>.
To override and erase previous status animations with less priority, set <animOverride>. If not
set, the animation will play above previous ones.
To apply character's transform to the animation, set <animTransform>.
The y-coordinate of the animation is offset by <animHeight> * target's height (in tiles).

=================================================================================================]]

-- Imports
local CharacterBase = require('core/objects/CharacterBase')
local StatusList = require('core/battle/battler/StatusList')

---------------------------------------------------------------------------------------------------
-- CharacterBase
---------------------------------------------------------------------------------------------------

-- Override. Updates animations' positions when character moves.
local CharacterBase_setXYZ = CharacterBase.setXYZ
function CharacterBase:setXYZ(x, y, z)
  CharacterBase_setXYZ(self, x, y, z)
  if self.statusAnimations then
    for _, v in ipairs(self.statusAnimations) do
      v.sprite:setXYZ(x, y, z)
    end
  end
end
-- Override. Updates balloon animation.
local CharacterBase_update = CharacterBase.update
function CharacterBase:update()
  CharacterBase_update(self)
  if not self.paused and self.statusAnimations then
    for _, v in ipairs(self.statusAnimations) do
      v:update()
    end
  end
end
-- Override. Destroys balloon with characters is destroyed.
local CharacterBase_destroy = CharacterBase.destroy
function CharacterBase:destroy(...)
  CharacterBase_destroy(self, ...)
  if self.statusAnimations then
    for _, v in ipairs(self.statusAnimations) do
      v:destroy()
    end
    self.statusAnimations = nil
  end
end

---------------------------------------------------------------------------------------------------
-- StatusList
---------------------------------------------------------------------------------------------------

-- Override. Refreshes character's status animations.
local StatusList_updateGraphics = StatusList.updateGraphics
function StatusList:updateGraphics(character)
  StatusList_updateGraphics(self, character)
  character.statusAnimations = character.statusAnimations or {}
  -- Collect anim IDs.
  local paramsPerID = {}
  local animList = {}
  local p = 0
  for i = 1, #self do
    local animID = tonumber(self[i].tags.animID)
    if animID then
      if self[i].tags.animOverride then
        animList = {}
        paramsPerID = {}
        p = 0
      end
      local params = paramsPerID[animID]
      if params then
        util.array.remove(animList, params[1])
        params[1] = #animList + 1
      else
        p = p + 1
        params = { p, self[i].tags.animTransform, self[i].tags.animHeight }
        paramsPerID[animID] = params
      end
      animList[p] = character.statusAnimations[animID]
    end
  end
  -- Delete removed status.
  for _, anim in ipairs(character.statusAnimations) do
    if not paramsPerID[anim.data.id] then
      anim:destroy()
    end
  end
  -- Create added status.
  for id, params in pairs(paramsPerID) do
    local priority = params[1]
    local anim = animList[priority]
    if not anim then -- If animation is new.
      anim = ResourceManager:loadAnimation(id, FieldManager.renderer)
      anim.sprite:setXYZ(character.position:coordinates())
      local applyTransform = params[2]
      local heightFactor = params[3]
      if applyTransform then
        anim.sprite:applyTransform(character.transform)
      end
      if heightFactor then
        local dy = character:getHeight() * tonumber(heightFactor)
        anim.sprite:setXYZ(nil, anim.sprite.position.y + dy)
      end
      animList[priority] = anim
    end
  end
  -- Update position according to priority.
  for i = 1, p do
    local sprite = animList[i].sprite
    sprite:setXYZ(nil, nil, sprite.position.z - p)
  end
  character.statusAnimations = animList
end
