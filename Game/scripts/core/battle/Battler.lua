
--[[===============================================================================================

Battler
---------------------------------------------------------------------------------------------------
A class the holds character's information for battle formula.

=================================================================================================]]

-- Imports
local BattlerBase = require('core/battle/BattlerBase')

local Battler = class(BattlerBase)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- @param(id : table) the battler's ID in database
-- @param(party : number) this battler's party number
function Battler:init(character)
  local data = Database.battlers[character.data.battlerID]
  BattlerBase.init(self, data)
  self.party = character.data.partyID
  self:initializeAI(data.scriptAI)
end
-- Sets data of this battler's AI.
-- @param(ai : table) the script data table (with strings path and param)
function Battler:initializeAI(ai)
  if ai.path ~= '' then
    self.AI = require('custom/' .. ai.path)(self, ai.param)
  else
    self.AI = nil
  end
end
-- Converting to string.
-- @ret(string) a string representation
function Battler:__tostring()
  return 'Battler: ' .. self.name .. ' [Party ' .. self.party .. ']'
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
  if path.lastStep:isControlZone(self) then
    self.steps = 0
  else
    self.steps = self.steps - path.totalCost
  end
end

return Battler
