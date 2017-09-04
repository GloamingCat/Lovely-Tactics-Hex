
--[[===============================================================================================

Stalker AI
---------------------------------------------------------------------------------------------------
An AI that selects a close character and keeps attacking until it's defeated.

=================================================================================================]]

-- Imports
local BattlerAI = require('core/battle/ai/BattlerAI')
local ActionInput = require('core/battle/action/ActionInput')
local BattleTactics = require('core/battle/ai/BattleTactics')

local Stalker = class(BattlerAI)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
function Stalker:init(battler, param)
  local key = 'Stalker ' .. battler.id
  BattlerAI.init(self, key, battler, self:decodeParam(param))
end

---------------------------------------------------------------------------------------------------
-- Execution
---------------------------------------------------------------------------------------------------

-- Overrides BattlerAI:runTurn.
function Stalker:runTurn()
  local user = TurnManager:currentCharacter()
  if not self.target or not self.target.battler:isAlive() then
    local skill = user.battler.attackSkill
    self.input = ActionInput(skill, user)
    self.input.action:onSelect(self.input)
    self.input.target = BattleTactics.closestCharacters(self.input):front()
    for char in self.input.target.characterList:iterator() do
      print(char.battler:isAlive())
      if char.battler and char.battler:isAlive() then
        self.target = char
        print(char)
        break
      end
    end
  end
  self.input.action:onSelect(self.input)
  self.input.target = self.target:getTile()
  return self.input.action:onConfirm(self.input)
end

return Stalker
