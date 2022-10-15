
--[[===============================================================================================

Job
---------------------------------------------------------------------------------------------------
Represents a battler's job.

=================================================================================================]]

-- Imports
local List = require('core/datastruct/List')

local Job = class()

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(battler : Battler) The battler with this class.
-- @param(save : table) Persitent data from save.
function Job:init(battler, save)
  self.id = save and save.id or battler.data.jobID
  self.battler = battler
  local jobData = Database.jobs[self.id]
  self.data = jobData
  self.expCurve = loadformula(jobData.expCurve, 'lvl')
  self.build = {}
  for i, att in ipairs(Config.attributes) do
    self.build[att.key] = loadformula(jobData.build[i], 'lvl')
  end
  self.skills = List(jobData.skills)
  self.skills:sort(function(a, b) return a.level < b.level end)
  if save then
    self.level = save.level
    self.exp = save.exp
  else
    self.level = battler.data.level
    self.exp = battler.data.exp + self.expCurve(self.level)
  end
  self:learnSkills()
end

---------------------------------------------------------------------------------------------------
-- Level-up
---------------------------------------------------------------------------------------------------

-- Increments experience and learns skill if leveled up.
-- @param(exp : number) The quantity of EXP to be added.
function Job:addExperience(exp)
  if self.level == Config.battle.maxLevel then
    return
  end
  self.exp = self.exp + exp
  while self.exp >= self.expCurve(self.level + 1) do
    self.level = self.level + 1
    self:learnSkills(self.level)
    if self.level == Config.battle.maxLevel then
      self.exp = self.expCurve(self.level)
      return
    end
  end
end
-- Learn all skills up to current level.
function Job:learnSkills()
  for i = 1, #self.skills do
    local skill = self.skills[i]
    if self.level >= skill.level then
      self.battler.skillList:learn(skill.id)
    end
  end
end
-- Checks if the class levels up with the given EXP.
-- @param(exp : number) The quantity of EXP to be added.
-- @ret(number) The new level, or nil if did not level up.
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
-- Computes the EXP progress to towards the next level.
-- @ret(number) Current EXP progress.
-- @ret(number) The total EXP needed from the current level to the next.
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

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Converting to string.
-- @ret(string) A string representation.
function Job:__tostring()
  return 'Job: ' .. tostring(self.battler)
end
-- @ret(table) Persistent data table.
function Job:getState()
  local state = {}
  state.id = self.id
  state.exp = self.exp
  state.level = self.level
  return state
end

return Job
