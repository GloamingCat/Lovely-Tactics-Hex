
--[[===============================================================================================

SkillList
---------------------------------------------------------------------------------------------------
A special kind of list that provides functions to manage battler's list of skills.

=================================================================================================]]

-- Imports
local SkillAction = require('core/battle/action/SkillAction')
local List = require('core/datastruct/List')

-- Alias
local copyTable = util.copyTable
local rand = love.math.random

local SkillList = class(List)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Overrides List:init.
-- @param(battler : Battler)
-- @param(save : table)
function SkillList:init(battler, save)
  List.init(self)
  self.battler = battler
  local skills = battler.data.skills
  if save then
    skills = save.skills or save
  end
  for i = 1, #skills do
    local s = skills[i]
    self:add(type(s) == 'number' and SkillAction:fromData(s) or s)
  end
end

---------------------------------------------------------------------------------------------------
-- Check / Change
---------------------------------------------------------------------------------------------------

-- @param(id : number) Skill's ID.
-- @ret(boolean)
function SkillList:containsSkill(id)
  for i = 1, self.size do
    if self[i].data.id == id then
      return true
    end
  end
  return false
end
-- @param(skill : number | SkillAction) The skill or the skill's ID.
function SkillList:learn(skill)
  local id = skill
  if type(skill) == 'number' then
    skill = nil
  else
    id = skill.data.id
  end
  if not self:containsSkill(id) then
    self:add(skill or SkillAction:fromData(id))
  end
end
-- @param(list : table) Array of skill IDs. 
function SkillList:learnAll(list)
  for i = 1, #list do
    self:learn(list[i])
  end
end

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Converting to string.
-- @ret(string) A string representation.
function SkillList:__tostring()
  return 'SkillList: ' .. tostring(self.battler)
end
-- @ret(table) Array with skills' IDs.
function SkillList:getState()
  local state = {}
  for i = 1, self.size do
    state[i] = self[i].data.id
  end
  return state
end
-- @ret(SkillList)
function SkillList:clone()
  return SkillList(self.battler, self)
end

return SkillList
