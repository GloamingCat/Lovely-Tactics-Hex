
--[[===============================================================================================

DefaultNN
---------------------------------------------------------------------------------------------------
A ScriptNN that generates each rule from user's skill list considering Rush, Attack, Defend, Hide, 
Run Away and Wait rules.

=================================================================================================]]

-- Imports
local NeuralNetworkAI = require('core/battle/ai/generator/NeuralNetworkAI')
local RushRule = require('custom/ai/rule/RushRule')
local AttackRule = require('custom/ai/rule/AttackRule')
local DefendRule = require('custom/ai/rule/DefendRule')
local HideRule = require('custom/ai/rule/HideRule')
local RunAwayRule = require('custom/ai/rule/RunAwayRule')
local WaitRule = require('custom/ai/rule/WaitRule')

local DefaultNN = class(NeuralNetworkAI)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- @param(battler : Battler)
-- @param(param : string)
function DefaultNN:init(battler, param)
  NeuralNetworkAI.init(self, 'DefaultNN' .. battler.battlerID, battler, self:decodeParam(param))
end

-- Inserts the default skill rules in the array.
local function addRules(r, skill)
  local name = skill.skillID
  r[#r + 1] = RushRule(skill)
  r[#r + 1] = AttackRule(skill)
  r[#r + 1] = DefendRule(skill)
  r[#r + 1] = HideRule(skill)
end

-- Overrides ScriptNN:createRules.
function DefaultNN:createRules()
  local r = {}
  addRules(r, self.battler.attackSkill) 
  local skills = self.battler.skillList
  for skill in self.battler.skillList:iterator() do
    addRules(r, skill)
  end
  r[#r + 1] = RunAwayRule()
  r[#r + 1] = WaitRule()
  return r
end

return DefaultNN
