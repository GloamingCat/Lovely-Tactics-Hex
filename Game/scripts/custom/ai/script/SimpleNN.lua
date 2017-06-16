
--[[===============================================================================================

SimpleNN
---------------------------------------------------------------------------------------------------
A ScriptNN that generates each rule from user's skill list considering Rush, Attack, Defend, Hide, 
Run Away and Wait rules.

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

local function addRules(rules, skill)
  local s = #rules
  local name = tostring(skill)
  rules[s + 1] = RushRule('Rush - ' .. name, skill)
  rules[s + 2] = AttackRule('Attack - ' .. name, skill)
  rules[s + 3] = DefendRule('Defend - ' .. name, skill)
  rules[s + 4] = HideRule('Hide - ' .. name, skill)
end

-- Overrides ScriptNN:createRules.
function SimpleNN:createRules(user)
  local r = {}
  addRules(r, user.battler.attackSkill) 
  local skills = user.battler.skillList
  for skill in user.battler.skillList:iterator() do
    addRules(r, skill)
  end
  r[#r + 1] = RunAwayRule('RunArray')
  r[#r + 1] = WaitRule('Wait')
  return r
end

return SimpleNN
