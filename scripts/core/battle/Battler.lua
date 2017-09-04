
--[[===============================================================================================

Battler
---------------------------------------------------------------------------------------------------
A class the holds character's information for battle formula.
Used to represent a battler during battle.roops[self.party]

=================================================================================================]]

-- Imports
local BattlerBase = require('core/battle/BattlerBase')

local Battler = class(BattlerBase)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(data : table) battler's data rom database
-- @param(character : Character)
-- @param(troop : Troop)
function Battler:init(data, character, troop)
  BattlerBase.init(self, data)
  self.party = character.party
  -- Initialize AI
  local ai = data.scriptAI
  if ai.path ~= '' then
    self.AI = require('custom/' .. ai.path)(self, ai.param)
  else
    self.AI = nil
  end
end

---------------------------------------------------------------------------------------------------
-- Turn callbacks
---------------------------------------------------------------------------------------------------

-- Callback for when a new turn begins.
function Battler:onTurnStart(char, partyTurn)
  if self.AI and self.AI.onTurnStart then
    self.AI:onTurnStart(char, partyTurn)
  end
  self.statusList:onTurnStart(char, partyTurn)
  if partyTurn then
    self.steps = self.maxSteps()
  end
end
-- Callback for when a turn ends.
function Battler:onTurnEnd(char, partyTurn)
  if self.AI and self.AI.onTurnEnd then
    self.AI:onTurnEnd(char, partyTurn)
  end
  self.statusList:onTurnEnd(char, partyTurn)
end
-- Callback for when this battler's turn starts.
function Battler:onSelfTurnStart(char)
end
-- Callback for when this battler's turn ends.
function Battler:onSelfTurnEnd(char, result)
end

---------------------------------------------------------------------------------------------------
-- Skill callbacks
---------------------------------------------------------------------------------------------------

-- Callback for when the character finished using a skill.
function Battler:onSkillUseStart(input)
  self.statusList:onSkillUseStart(input.user, input)
end
-- Callback for when the character finished using a skill.
function Battler:onSkillUseEnd(input)
  local costs = input.action.costs
  for i = 1, #costs do
    local value = costs[i].cost(self.att)
    self:damage(costs[i].name, value)
  end
  self.statusList:onSkillUseEnd(input.user, input)
end
-- Callback for when the characters starts receiving a skill's effect.
function Battler:onSkillEffectStart(char, input, dmg)
  self.statusList:onSkillEffectStart(char, input, dmg)
end
-- Callback for when the characters ends receiving a skill's effect.
function Battler:onSkillEffectEnd(char, input, dmg)
  self.statusList:onSkillEffectEnd(char, input, dmg)
end

---------------------------------------------------------------------------------------------------
-- Other callbacks
---------------------------------------------------------------------------------------------------

-- Callback for when the battle ends.
function Battler:onBattleStart(char)
  if self.AI and self.AI.onBattleStart then
    self.AI:onBattleStart(char)
  end
  self.statusList:onBattleStart(char)
end
-- Callback for when the battle ends.
function Battler:onBattleEnd(char)
  if self.AI and self.AI.onBattleEnd then
    self.AI:onBattleEnd(char)
  end
  self.statusList:onBattleEnd(char)
end
-- Callback for when the character moves.
-- @param(path : Path) the path that the battler just walked
function Battler:onMove(path)
  self.steps = self.steps - path.totalCost
end

---------------------------------------------------------------------------------------------------
-- HP and SP damage
---------------------------------------------------------------------------------------------------

-- Damages HP.
-- @param(value : number) the number of the damage
-- @ret(boolean) true if reached 0, otherwise
function Battler:damageHP(value)
  value = self.state.hp - value
  if value <= 0 then
    self.state.hp = 0
    return true
  else
    self.state.hp = value
    return false
  end
end
-- Damages SP.
-- @param(value : number) the number of the damage
-- @ret(boolean) true if reached 0, otherwise
function Battler:damageSP(value)
  value = self.state.sp - value
  if value <= 0 then
    self.state.sp = 0
    return true
  else
    self.state.sp = value
    return false
  end
end

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Checks if battler is still alive by its HP.
-- @ret(boolean) true if HP greater then zero, false otherwise
function Battler:isAlive()
  return self.state.hp > 0
end
-- Sets its life points to 0.
function Battler:kill()
  self.state.hp = 0
end
-- Checks if the character is considered active in the battle.
-- @ret(boolean)
function Battler:isActive()
  return self:isAlive()
end
-- Converting to string.
-- @ret(string) a string representation
function Battler:__tostring()
  return 'Battler: ' .. self.name .. ' [Party ' .. self.party .. ']'
end

return Battler
