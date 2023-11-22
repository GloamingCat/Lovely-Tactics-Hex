
-- ================================================================================================

--- Represents a battler's job.
---------------------------------------------------------------------------------------------------
-- @battlemod Job

-- ================================================================================================

-- Imports
local List = require('core/datastruct/List')
local SkillAction = require('core/battle/action/SkillAction')
local SkillList = require('core/battle/battler/SkillList')
local StatusList = require('core/battle/battler/StatusList')

-- Class table.
local Job = class()

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam Battler battler The battler with this class.
-- @tparam table save Persitent data from save.
function Job:init(battler, save)
  self.id = save and save.id or battler.data.jobID
  self.battler = battler
  local jobData = Database.jobs[self.id]
  self.data = jobData
  self.tags = Database.loadTags(jobData.tags)
  self.expCurve = loadformula(jobData.expCurve, 'lvl')
  self.build = {}
  for i, att in ipairs(Config.attributes) do
    self.build[att.key] = loadformula(jobData.build[i], 'lvl')
  end
  self.attackSkill = SkillAction:fromData(jobData.attackID)
  self.allSkills = List(jobData.skills)
  self.allSkills:sort(function(a, b) return a.level < b.level end)
  self.allStatuses = List(jobData.statuses)
  self.allStatuses:sort(function(a, b) return a.level < b.level end)
  if save then
    self.level = save.level
    self.exp = save.exp
  else
    self.level = battler.data.level
    self.exp = battler.data.exp + self.expCurve(self.level)
  end
  self.skillList = SkillList()
  self.statusList = StatusList()
  self.statusList.battler = self.battler
  self:learnSkills()
  self:applyStatuses()
end

-- ------------------------------------------------------------------------------------------------
-- Level-up
-- ------------------------------------------------------------------------------------------------

--- Increments experience and learns skill if leveled up.
-- @tparam number exp The quantity of EXP to be added.
-- @tparam[opt] Character character The current battle character of the battler.
function Job:addExperience(exp, character)
  if self.level == Config.battle.maxLevel then
    return
  end
  self.exp = self.exp + exp
  while self.exp >= self.expCurve(self.level + 1) do
    self.level = self.level + 1
    self:learnSkills()
    self:applyStatuses(character)
    if self.level == Config.battle.maxLevel then
      self.exp = self.expCurve(self.level)
      return
    end
  end
end
--- Learn all skills up to current level.
function Job:learnSkills()
  for i = 1, #self.allSkills do
    local skill = self.allSkills[i]
    if self.level >= skill.level then
      self.skillList:learn(skill.id)
    end
  end
end
--- Apply all statuses up to current level.
-- @tparam[opt] Character character The current battle character of the battler.
function Job:applyStatuses(character)
  for i = 1, #self.allStatuses do
    local status = self.allStatuses[i]
    if self.level >= status.level then
      self.statusList:addStatus(status.id, character)
    end
  end
end
--- Checks if the class levels up with the given EXP.
-- @tparam number exp The quantity of EXP to be added.
-- @treturn number The new level, or nil if did not level up.
function Job:levelsup(exp)
  local level = self.level
  exp = exp + self.exp
  while level < Config.battle.maxLevel and exp >= self.expCurve(level + 1) do
    level = level + 1
  end
  if level > self.level then
    return level
  else
    return nil
  end
end
--- Computes the EXP progress to towards the next level.
-- @treturn number Current EXP progress.
-- @treturn number The total EXP needed from the current level to the next.
function Job:nextLevelEXP()
  if self.level == Config.battle.maxLevel then
    local expMax = self.expCurve(self.level) - self.expCurve(self.level - 1)
    return expMax, expMax
  end
  local expCurrent = self.expCurve(self.level)
  local expNext = self.expCurve(self.level + 1)
  local expMax = expNext - expCurrent
  local exp = self.exp - expCurrent
  return exp, expMax
end

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Gets the persistent data.
-- @treturn table
function Job:getState()
  local state = {}
  state.id = self.id
  state.exp = self.exp
  state.level = self.level
  return state
end
-- For debugging.
function Job:__tostring()
  return 'Job: ' .. tostring(self.battler)
end

return Job
