
-- ================================================================================================

--- A special kind of list that provides functions to manage battler's list of skills.
---------------------------------------------------------------------------------------------------
-- @classmod SkillList
-- @extend List

-- ================================================================================================

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

--- Overrides `List:init`. 
-- @override
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

--- Checks whether the skill is present in this list.
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
--- Add a skill to the list if not already present.
-- @tparam number|string|SkillAction skill The skill or the skill's ID or key.
-- @treturn SkillAction The newly added skill or nil if the skill as already present.
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
--- Adds a set of skills of this list.
-- @tparam table list Array of skill IDs or keys.
function SkillList:learnAll(list)
  for i = 1, #list do
    self:learn(list[i])
  end
end

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Gets the persistent data.
-- @treturn table Array with skills' IDs.
function SkillList:getState()
  local state = {}
  for i = 1, self.size do
    state[i] = self[i].data.id
  end
  return state
end
--- Creates a copy of this list.
-- @treturn SkillList
function SkillList:clone()
  return SkillList(self.battler, self)
end
--- Creates a copy of this list as a List type.
-- @treturn List
function SkillList:toList()
  return List(self)
end
-- For debugging.
function StatusList:__tostring()
  return tostring(self.battler) .. ' Skill' .. getmetatable(List).__tostring(self)
end

return SkillList
