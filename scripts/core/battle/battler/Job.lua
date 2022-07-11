
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
  self.battler = battler
  if save and save.job then
    self.id = save.job.id
    self.level = save.job.level
    self.exp = save.job.exp
  else
    self.id = battler.data.jobID
    self.level = battler.data.level
  end
  local jobData = Database.jobs[self.id]
  self.data = jobData
  self.expCurve = loadformula(jobData.expCurve, 'lvl')
  self.build = {}
  for i, att in ipairs(Config.attributes) do
    self.build[att.key] = loadformula(jobData.build[i], 'lvl')
  end
  self.skills = List(jobData.skills)
  self.skills:sort(function(a, b) return a.level < b.level end)
  self.exp = self.exp or self.expCurve(self.level)
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
    for i = 1, #self.skills do
      local skill = self.skills[i]
      if self.level >= skill.level then
        self.battler.skillList:learn(skill)
      end
    end
    if self.level == Config.battle.maxLevel then
      self.exp = self.expCurve(self.level)
      return
    end
  end
end
-- Checks if the class levels up with the given EXP.
-- @param(exp : number) The quantity of EXP to be added.
-- @ret(number) The new level, or nil if did not level up.
function Job:levelsup(exp)
  if self.level == Config.battle.maxLevel then
    return nil
  end
  local level = self.level
  exp = exp + self.exp
  while exp >= self.expCurve(level + 1) do
    level = level + 1
  end
  if level > self.level then
    return level
  end
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
