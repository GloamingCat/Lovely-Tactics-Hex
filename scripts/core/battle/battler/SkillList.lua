
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

-- @param(id : number | string) Skill's ID or key.
-- @ret(number) The position of the skill if found, nil if not found.
function SkillList:containsSkill(id)
  local data = Database.skills[id]
  for i = 1, self.size do
    if self[i].data == data then
      return i
    end
  end
  return nil
end
-- @param(skill : number | string | SkillAction) The skill or the skill's ID or key.
function SkillList:learn(skill)
  local id = skill
  if type(skill) == 'number' or type(skill) == 'string' then
    skill = nil
  else
    id = skill.data.id
  end
  if not self:containsSkill(id) then
    skill = skill or SkillAction:fromData(id)
    self:add(skill)
    return skill
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
