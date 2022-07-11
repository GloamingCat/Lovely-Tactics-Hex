
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
  local skills = save and save.skills or battler.data.skills
  for i = 1, #skills do
    local id = skills[i]
    self:add(SkillAction:fromData(id))
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
-- @param(skill : table | number) Entry in the list of skill to learn or skill's ID.
function SkillList:learn(skill)
  if type(skill) == 'table' then
    if self:containsSkill(skill.id) then
      return
    end
    for i = 1, #skill.requirements do
      if not self:containsSkill(skill.requirements[i]) then
        return
      end
    end
    skill = skill.id
  end
  skill = SkillAction:fromData(skill)
  self:add(skill)
  return skill
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

return SkillList
