
--[[===========================================================================

Skill
-------------------------------------------------------------------------------
The BattleAction that is executed when players chooses a skill to use.

=============================================================================]]

-- Imports
local SkillAction = require('core/battle/action/SkillAction')

-- Constants
local elementCount = #Config.elements

local Skill = require('core/class'):new()

-------------------------------------------------------------------------------
-- General
-------------------------------------------------------------------------------

-- @param(skillID : number) the skill's ID in database
function Skill:init(skillID)
  local data = Database.skills[skillID + 1]
  self.data = data
  self.id = skillID
  -- Skill type
  if data.type == 0 then
    self.type = 'general'
  elseif data.type == 1 then
    self.type = 'attack'
  elseif data.type == 2 then
    self.type = 'support'
  end
  -- Formulae
  if data.basicResult ~= '' then
    self.calculateBasicResult = self:loadFormulae(data.basicResult, 
      'action, a, b, rand')
  end
  if data.successRate ~= '' then
    self.calculateSuccessRate = self:loadFormulae(data.successRate, 
      'action, a, b, rand')
  end
  -- Store elements
  local e = {}
  for i = 1, #data.elements do
    e[data.elements[i].id + 1] = data.elements[i].value
  end
  for i = 1, elementCount do
    if not e[i] then
      e[i] = 0
    end
  end
  self.elementFactors = e
end

-- Converting to string.
-- @ret(string) a string representation
function Skill:toString()
  return 'Skill: ' .. self.skillID .. ' (' .. self.data.name .. ')'
end

-- Generates a function from a formulae in string.
-- @param(formulae : string) the formulae expression
-- @param(param : string) the param needed for the function (optional)
-- @ret(function) the function that evaluates the formulae
function Skill:loadFormulae(formulae, param)
  formulae = 'return ' .. formulae
  if param and param ~= '' then
    local funcString = 
      'function(' .. param .. ') ' ..
        formulae ..
      ' end'
    return loadstring('return ' .. funcString)()
  else
    return loadstring(formulae)
  end
end

-- Creates the SkillAction instance of this skill.
-- @ret(SkillAction) the action to be used during battle
function Skill:asAction()
  local actionType = SkillAction
  if self.data.script.path ~= '' then
    actionType = require('custom/' .. skill.data.script.path)
  end
  return actionType(nil, nil, self, self.data.script.param)
end

return Skill
