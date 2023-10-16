
--[[===============================================================================================

@classmod SkillList
---------------------------------------------------------------------------------------------------
A special kind of list that provides functions to manage battler's list of skills.

=================================================================================================]]

-- Imports
local SkillAction = require('core/battle/action/SkillAction')
local List = require('core/datastruct/List')

-- Alias
local copyTable = util.copyTable
local rand = love.math.random

-- Class table.
local SkillList = class(List)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Overrides List:init.
-- @tparam Battler battler
-- @tparam table save
function SkillList:init(battler, save)
  List.init(self)
  self.battler = battler
  local skills = save or battler and battler.data.skills
  if not skills then
    return
  end
  for i = 1, #skills do
    local s = skills[i]
    self:add(type(s) == 'number' and SkillAction:fromData(s) or s)
  end
end

-- ------------------------------------------------------------------------------------------------
-- Check / Change
-- ------------------------------------------------------------------------------------------------

-- @tparam number|string id Skill's ID or key.
-- @treturn number The position of the skill if found, nil if not found.
function SkillList:containsSkill(id)
  local data = Database.skills[id]
  for i = 1, self.size do
    if self[i].data == data then
      return i
    end
  end
  return nil
end
-- @tparam number|string|SkillAction skill The skill or the skill's ID or key.
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
-- @tparam table list Array of skill IDs.
function SkillList:learnAll(list)
  for i = 1, #list do
    self:learn(list[i])
  end
end

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Converting to string.
-- @treturn string A string representation.
function SkillList:__tostring()
  return 'SkillList: ' .. tostring(self.battler)
end
-- @treturn table Array with skills' IDs.
function SkillList:getState()
  local state = {}
  for i = 1, self.size do
    state[i] = self[i].data.id
  end
  return state
end
-- @treturn SkillList
function SkillList:clone()
  return SkillList(self.battler, self)
end
-- @treturn List
function SkillList:toList()
  return List(self)
end

return SkillList
