
--[[===============================================================================================

SimpleNN
---------------------------------------------------------------------------------------------------
A ScriptNN that generates each rule from user's skill list considering Rusher, Chicken, Ofensive,
Defensive and Wait rules.

=================================================================================================]]

-- Imports
local ScriptNN = require('core/battle/ai/dynamic/ScriptNN')
local RushRule = require('custom/ai/rule/RushRule')
local AttackRule = require('custom/ai/rule/AttackRule')
local DefendRule = require('custom/ai/rule/DefendRule')
local HideRule = require('custom/ai/rule/HideRule')
local RunAwayRule = require('custom/ai/rule/RunAwayRule')
local WaitRule = require('custom/ai/rule/WaitRule')

local SimpleNN = class(ScriptNN)

-- Overrides ScriptNN:createRules.
function SimpleNN:createRules(user)
  local r = { 
    RushRule(user.battler.attackSkill),
    AttackRule(user.battler.attackSkill),
    DefendRule(user.battler.attackSkill),
    HideRule(user.battler.attackSkill)
  }
  local skills = user.battler.skillList
  for skill in user.battler.skillList:iterator() do
    r[#r + 1] = RushRule(skill)
    r[#r + 1] = AttackRule(skill)
    r[#r + 1] = DefendRule(skill)
    r[#r + 1] = HideRule(skill)
  end
  r[#r + 1] = RunAwayRule()
  r[#r + 1] = WaitRule()
  return r
end

return SimpleNN
