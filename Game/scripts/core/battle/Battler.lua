
--[[===============================================================================================

Battler
---------------------------------------------------------------------------------------------------
A class the holds character's information for battle formula.

=================================================================================================]]

-- Imports
local List = require('core/datastruct/List')
local SkillAction = require('core/battle/action/SkillAction')
local Inventory = require('core/battle/Inventory')
local StatusList = require('core/battle/StatusList')

-- Alias
local max = math.max
local min = math.min
local ceil = math.ceil
local newArray = util.newArray
local readFile = love.filesystem.read
local copyArray = util.copyArray
local copyTable = util.shallowCopyTable

-- Constants
local battlerVariables = Database.variables.battler
local attConfig = Database.attributes
local elementCount = #Config.elements
local turnLimit = Battle.turnLimit
local lifeName = battlerVariables[Config.battle.attLifeID + 1].shortName
local turnName = attConfig[Config.battle.attTurnID + 1].shortName
local jumpName = attConfig[Config.battle.attJumpID + 1].shortName
local stepName = attConfig[Config.battle.attStepID + 1].shortName
local weightName = attConfig[Config.battle.attWeightID + 1].shortName

local Battler = class()

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- @param(id : table) the battler's ID in database
-- @param(party : number) this battler's party number
function Battler:init(id, party)
  local data = Database.battlers[id + 1]
  self.id = id
  self.data = data
  self.name = data.name
  self.party = party
  self.tags = util.createTags(data.tags)
  local persistentData = self:loadPersistentData(data.persistent)
  self:createAttributes(persistentData)
  self:createStateValues(persistentData, data.attributes, data.build, data.level)
  self:initializeSkillList(data.skills, data.attackID)
  self:initializeElements(persistentData, data.elements or {})
  self:initializeStatusList(persistentData, data.status or {})
  self:initializeInventory(persistentData, data.items or {})
  self:initializeAI(data.scriptAI)
  self:initializeRewards(data.partyRewards, data.battlerRewards)
end
-- Creates and sets the list of usable skills.
-- @param(skills : table) array of skill IDs
-- @param(attackID : number) ID of the battler's "Attack" skill
function Battler:initializeSkillList(skills, attackID)
  self.skillList = List()
  for i = 1, #skills do
    local id = skills[i]
    self.skillList:add(SkillAction.fromData(id))
  end
  self.attackSkill = SkillAction.fromData(attackID)
end
-- Creates and sets and array of element factors.
-- @param(elements : table) array of element factors 
--  (in percentage, 100 is neutral)
function Battler:initializeElements(persistentData, elements)
  if persistentData then
    self.elementFactors = persistentData.elementFactors
  else
    local e = newArray(elementCount, 0)
    for i = 1, #elements do
      e[elements[i].id + 1] = elements[i].value - 100
    end
    self.elementFactors = e
  end
end
-- Creates the initial status list.
function Battler:initializeStatusList(persistentData, initialStatus)
  self.statusList = StatusList(persistentData, initialStatus)
end
-- Initializes inventory from the given initial items slots.
function Battler:initializeInventory(persistentData, items)
  self.inventory = Inventory(persistentData and persistentData.items or items)
end
-- Sets data of this battler's AI.
-- @param(ai : table) the script data table (with strings path and param)
function Battler:initializeAI(ai)
  if ai.path ~= '' then
    self.AI = require('custom/' .. ai.path)(self, ai.param)
  else
    self.AI = nil
  end
end
-- Initializes reward tables.
function Battler:initializeRewards(partyRewards, battlerRewards)
  local function initRewards(name, rewards)
    self[name] = {}
    for i = 1, #rewards do
      local reward = Database.variables[name][i]
      local init = loadformula(rewards[i] or '0', 'att, level')
      self[name][reward.shortName] = init(self.att, self.data.level)
    end
  end
  initRewards('partyRewards', partyRewards)
  initRewards('battlerRewards', battlerRewards)
end
-- Converting to string.
-- @ret(string) a string representation
function Battler:__tostring()
  return 'Battler: ' .. self.name .. ' [Party ' .. self.party .. ']'
end

---------------------------------------------------------------------------------------------------
-- Persistent Data
---------------------------------------------------------------------------------------------------

-- Gets the data from save if persistent, nil if not.
-- @ret(table) the battler's data in the save
function Battler:loadPersistentData()
  return SaveManager.current.battlerData[self.id .. '']
end
-- Stores battler's persistent data in game save.
function Battler:savePersistentData()
  SaveManager.current.battlerData[self.id .. ''] = self:createPersistentData()
end
-- Creates a table that holds all battler's persistent data.
-- @ret(table)
function Battler:createPersistentData()
  local data = {}
  data.attAdd = copyArray(self.attAdd)
  data.attMul = copyArray(self.attMul)
  data.attBase = copyArray(self.attBase)
  data.state = copyTable(self.state)
  data.elementFactors = copyArray(self.elementFactors)
  data.inventory = self.inventory:asTable()
  data.status = self.statusList:asTable()
  return data
end

---------------------------------------------------------------------------------------------------
-- Attributes
---------------------------------------------------------------------------------------------------

-- Creates attribute functions from script data.
function Battler:createAttributes()
  self.att = {}
  for i = 1, #attConfig do
    local shortName = attConfig[i].shortName
    local script = attConfig[i].script
    if script == '' then
      self.att[shortName] = function()
        return self.attAdd[shortName] + self.attMul[shortName] * 
          self.attBase[shortName]
      end
    else
      local base = loadformula(script, 'att')
      self.att[shortName] = function()
        return self.attAdd[shortName] + self.attMul[shortName] *
          (self.attBase[shortName] + base(self.att))
      end
    end
  end
  self.turnStep = self.att[turnName]
  self.jumpPoints = self.att[jumpName]
  self.maxSteps = self.att[stepName]
  self.maxWeight = self.att[weightName]
end
-- Initializes battler's state.
-- @param(data : table) persistent data
-- @param(attBase : table) array of the base values of each attribute
-- @param(build : table) the build with the base functions for each attribute
-- @param(level : number) battler's level
function Battler:createStateValues(data, attBase, build, level)
  self.steps = 0
  self.turnCount = 0
  self.state = data and data.state or {}
  -- Attribute bonud
  if not data or not data.attAdd or not data.attMul or not data.attBase then
    self.attAdd = {}
    self.attMul = {}
    self.attBase = {}
    if build.path ~= '' then
      build = require('custom/' .. build.path)
    else
      build = nil
    end
    for i = 1, #attConfig do
      local shortName = attConfig[i].shortName
      local b = attBase[i] or 0
      if build and build[shortName] then
        b = b + build[shortName](level)
      end
      self.attBase[shortName] = b
      self.attAdd[shortName] = 0
      self.attMul[shortName] = 1
    end
  end
  -- Min / max
  self.stateMax = {}
  self.stateMin = {}
  for i = 1, #battlerVariables do
    local shortName = battlerVariables[i].shortName
    local max = loadformula(battlerVariables[i].max, 'att')
    local min = loadformula(battlerVariables[i].min, 'att')
    self.stateMax[shortName] = function()
      return max(self.att)
    end
    self.stateMin[shortName] = function()
      return min(self.att)
    end
    if data and data[shortName] then
      self:setStateValue(shortName, data[shortName])
    else
      local init = loadformula(battlerVariables[i].initial, 'att')
      self:setStateValue(shortName, init(self.att))
    end
  end
end

---------------------------------------------------------------------------------------------------
-- Turn
---------------------------------------------------------------------------------------------------

-- Increments turn count by the turn attribute.
-- @param(time : number) a multiplier to the step (used for time bar animation)
function Battler:incrementTurnCount(time)
  self.turnCount = self.turnCount + self.turnStep() * time
end
-- Decrements turn count by a value. It never reaches a negative value.
-- @param(value : number)
function Battler:decrementTurnCount(value)
  self.turnCount = max(self.turnCount - value, 0)
end
-- Returns the number of steps needed to reach turn limit.
-- @ret(number) the number of steps (float)
function Battler:remainingTurnCount()
  return (turnLimit - self.turnCount) / self.turnStep()
end

---------------------------------------------------------------------------------------------------
-- Turn callbacks
---------------------------------------------------------------------------------------------------

-- Callback for when a new turn begins.
-- @param(iterations : number) the number of turn iterations since the previous turn
function Battler:onTurnStart(char, turnChar, iterations)
  if self.AI and self.AI.onTurnStart then
    self.AI:onTurnStart(char, turnChar, iterations)
  end
  self.statusList:onTurnStart(char, turnChar, iterations)
end
-- Callback for when a turn ends.
-- @param(iterations : number) the number of turn iterations since the previous turn
function Battler:onTurnEnd(char, turnChar, iterations)
  if self.AI and self.AI.onTurnEnd then
    self.AI:onTurnEnd(char, turnChar, iterations)
  end
  self.statusList:onTurnEnd(char, turnChar, iterations)
end
-- Callback for when this battler's turn starts.
-- @param(iterations : number) the number of turn iterations since the previous turn
function Battler:onSelfTurnStart(char, iterations)
  self.steps = self.maxSteps()
end
-- Callback for when this battler's turn ends.
-- @param(iterations : number) the number of turn iterations since the previous turn
-- @param(actionCost : number) the time the battler spent during the turn
function Battler:onSelfTurnEnd(char, iterations, actionCost)
  local stepCost = self.steps / self.maxSteps()
  self:decrementTurnCount(ceil((stepCost + actionCost) * turnLimit / 2))
end

---------------------------------------------------------------------------------------------------
-- Skill callbacks
---------------------------------------------------------------------------------------------------

-- Callback for when the character finished using a skill.
function Battler:onSkillUseStart(input)
  self.statusList:onSkillUseStart(input.user, input)
end
-- Callback for when the character finished using a skill.
function Battler:onSkillUseEnd(input)
  local costs = input.action.costs
  for i = 1, #costs do
    local value = costs[i].cost(self.att)
    self:damage(costs[i].name, value)
  end
  self.statusList:onSkillUseEnd(input.user, input)
end
-- Callback for when the characters starts receiving a skill's effect.
function Battler:onSkillEffectStart(char, input, dmg)
  self.statusList:onSkillEffectStart(char, input, dmg)
end
-- Callback for when the characters ends receiving a skill's effect.
function Battler:onSkillEffectEnd(char, input, dmg)
  self.statusList:onSkillEffectEnd(char, input, dmg)
end

---------------------------------------------------------------------------------------------------
-- Other callbacks
---------------------------------------------------------------------------------------------------

-- Callback for when the battle ends.
function Battler:onBattleStart(char)
  if self.AI and self.AI.onBattleStart then
    self.AI:onBattleStart(char)
  end
  self.statusList:onBattleStart(char)
end
-- Callback for when the battle ends.
function Battler:onBattleEnd(char)
  if self.AI and self.AI.onBattleEnd then
    self.AI:onBattleEnd(char)
  end
  self.statusList:onBattleEnd(char)
end
-- Callback for when the character moves.
-- @param(path : Path) the path that the battler just walked
function Battler:onMove(path)
  if path.lastStep:isControlZone(self) then
    self.steps = 0
  else
    self.steps = self.steps - path.totalCost
  end
end

---------------------------------------------------------------------------------------------------
-- State Values
---------------------------------------------------------------------------------------------------

-- Sets a value to a state attribute.
-- @param(name : string) the name of the state attribute
-- @param(value : number) the new state attribute's value
-- @ret(number) -1 if it's less than the minimum, 1 if it's more than the maximum, nil otherwise
function Battler:setStateValue(name, value)
  local maxValue = self.stateMax[name](self.att) or math.huge
  local minValue = self.stateMin[name](self.att) or -math.huge
  if value < minValue then
    self.state[name] = minValue
    return -1
  elseif value > maxValue then
    self.state[name] = maxValue
    return 1
  else
    self.state[name] = value
    return nil
  end
end
-- Decreases a state attribute.
-- @param(name : string) the name of the state attribute
-- @param(value : number) the value to be decreased
-- @ret(number) -1 if it's less than the minimum, 1 if it's more than the maximum, nil otherwise
function Battler:damage(name, value)
  return self:setStateValue(name, self.state[name] - value)
end
-- Gets the normalized turn count.
-- @ret(number) the turn count
function Battler:relativeTurnCount()
  return self.turnCount / turnLimit
end

---------------------------------------------------------------------------------------------------
-- Life points
---------------------------------------------------------------------------------------------------

-- Checks if battler is still alive by its HP.
-- @ret(boolean) true if HP greater then zero, false otherwise
function Battler:isAlive()
  return self.state[lifeName] > 0
end
-- Sets its life points to 0.
function Battler:kill()
  self.state[lifeName] = 0
end
-- Gets the total life points.
-- @ret(number)
function Battler:absoluteLifePoints()
  return self.state[lifeName]
end
-- Gets life points relative to the maximum.
-- @ret(number) between 0 and 1
function Battler:relativeLifePoints()
  return self.state[lifeName] / self.stateMax[lifeName](self.att)
end
-- Gets the maximum life points.
-- @ret(number)
function Battler:maxLifePoints()
  return self.stateMax[lifeName](self.att)
end

return Battler
