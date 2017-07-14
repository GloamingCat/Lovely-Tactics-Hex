
--[[===============================================================================================

CharacterOnly
---------------------------------------------------------------------------------------------------
A class for generic attack skills that targets only enemies.
Possible arguments are:
  "living ally" => any living ally
  "living enemy" => any living enemy
  "living" => any living character
  "dead ally" => any dead ally
  "dead enemy" => any dead enemy
  "dead" => any dead character
  "ally" => any ally
  "enemy" => any enemy
  "" => any chacter

=================================================================================================]]

-- Imports
local CharacterOnlySkill = require('core/battle/action/CharacterOnlySkill')

local CharacterOnly = class(CharacterOnlySkill)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
function CharacterOnly:init(...)
  CharacterOnlySkill.init(self, ...)
  local getArgs = string.gmatch(self.data.script.param, '%S+')
  local arg1 = getArgs()
  local arg2 = getArgs()
  if arg2 then
    self.targetParty = arg2
    self.targetState = arg1 or ''
  else
    self.targetParty = arg1
  end
end

---------------------------------------------------------------------------------------------------
-- Filter characters
---------------------------------------------------------------------------------------------------

-- Overrides CharacterOnlyAction:isCharacterSelectable.
function CharacterOnly:isCharacterSelectable(input, char)
  -- Party
  if self.targetParty == 'ally' then
    if char.battler.party ~= input.user.battler.party then
      return false
    end
  elseif self.targetParty == 'enemy' then
    if char.battler.party == input.user.battler.party then
      return false
    end
  elseif self.targetParty ~= '' then
    error('Not recognized target party: ' .. self.targetParty)
  end
  -- State
  if self.targetState == 'living' then
    if not char.battler:isAlive() then
      return false
    end
  elseif self.targetState == 'dead' then
    if char.battler:isAlive() then
      return false
    end
  elseif self.targetParty ~= '' then
    error('Not recognized target state: ' .. self.targetParty)
  end
  return true
end

return CharacterOnly
