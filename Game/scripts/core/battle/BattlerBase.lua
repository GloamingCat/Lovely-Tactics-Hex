
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
local TagMap = require('core/datastruct/TagMap')

-- Alias
local readFile = love.filesystem.read
local newArray = util.array.new
local copyArray = util.array.copy
local copyTable = util.table.shallowCopy

-- Constants
local attConfig = Config.attributes
local elementCount = #Config.elements
local mhpName = Config.battle.attHP
local mspName = Config.battle.attSP
local jumpName = Config.battle.attJump
local stepName = Config.battle.attStep
local weightName = Config.battle.attWeight

local BattlerBase = class()

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(data : table) Battler's data from database
function BattlerBase:init(data)
  self.data = data
  self.name = data.name
  self.tags = TagMap(data.tags)
  local persistentData = self:loadPersistentData(data.persistent)
  self:createAttributes(persistentData)
  self:createStateValues(persistentData, data.attributes, data.build, data.level)
  self:initializeSkillList(data.skills, data.attackID)
  self:initializeElements(persistentData, data.elements or {})
  self:initializeStatusList(persistentData, data.status or {})
  self:initializeInventory(persistentData, data.items or {})
  self:initializeRewards(data.partyRewards, data.battlerRewards)
end

-- Creates and sets the list of usable skills.
-- @param(skills : table) array of skill IDs
-- @param(attackID : number) ID of the battler's "Attack" skill
function BattlerBase:initializeSkillList(skills, attackID)
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
function BattlerBase:initializeElements(persistentData, elements)
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
function BattlerBase:initializeStatusList(persistentData, initialStatus)
  self.statusList = StatusList(persistentData, initialStatus)
end
-- Initializes inventory from the given initial items slots.
function BattlerBase:initializeInventory(persistentData, items)
  self.inventory = Inventory(persistentData and persistentData.items or items)
end
-- Initializes reward tables.
function BattlerBase:initializeRewards(partyRewards, battlerRewards)
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

---------------------------------------------------------------------------------------------------
-- Attributes
---------------------------------------------------------------------------------------------------

-- Creates attribute functions from script data.
function BattlerBase:createAttributes()
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
  self.jumpPoints = self.att[jumpName]
  self.maxSteps = self.att[stepName]
  self.maxWeight = self.att[weightName]
end
-- Initializes battler's state.
-- @param(data : table) persistent data
-- @param(attBase : table) array of the base values of each attribute
-- @param(build : table) the build with the base functions for each attribute
-- @param(level : number) battler's level
function BattlerBase:createStateValues(data, attBase, build, level)
  self.steps = 0
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
-- Persistent Data
---------------------------------------------------------------------------------------------------

-- Gets the data from save if persistent, nil if not.
-- @ret(table) the battler's data in the save
function BattlerBase:loadPersistentData()
  return SaveManager.current.battlerData[self.id .. '']
end
-- Stores battler's persistent data in game save.
function BattlerBase:savePersistentData()
  SaveManager.current.battlerData[self.id .. ''] = self:createPersistentData()
end
-- Creates a table that holds all battler's persistent data.
-- @ret(table)
function BattlerBase:createPersistentData()
  local data = {}
  data.attAdd = copyArray(self.attAdd)
  data.attMul = copyArray(self.attMul)
  data.attBase = copyArray(self.attBase)
  data.state = copyTable(self.state)
  data.elementFactors = copyArray(self.elementFactors)
  data.inventory = self.inventory:getState()
  data.status = self.statusList:getState()
  return data
end

---------------------------------------------------------------------------------------------------
-- State Values
---------------------------------------------------------------------------------------------------

-- Sets a value to a state attribute.
-- @param(name : string) the name of the state attribute
-- @param(value : number) the new state attribute's value
-- @ret(number) -1 if it's less than the minimum, 1 if it's more than the maximum, nil otherwise
function BattlerBase:setStateValue(name, value)
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
function BattlerBase:damage(name, value)
  return self:setStateValue(name, self.state[name] - value)
end

---------------------------------------------------------------------------------------------------
-- Life points
---------------------------------------------------------------------------------------------------

-- Checks if battler is still alive by its HP.
-- @ret(boolean) true if HP greater then zero, false otherwise
function BattlerBase:isAlive()
  return self.state[lifeName] > 0
end
-- Sets its life points to 0.
function BattlerBase:kill()
  self.state[lifeName] = 0
end
-- Gets the total life points.
-- @ret(number)
function BattlerBase:absoluteLifePoints()
  return self.state[lifeName]
end
-- Gets life points relative to the maximum.
-- @ret(number) between 0 and 1
function BattlerBase:relativeLifePoints()
  return self.state[lifeName] / self.stateMax[lifeName](self.att)
end
-- Gets the maximum life points.
-- @ret(number)
function BattlerBase:maxLifePoints()
  return self.stateMax[lifeName](self.att)
end
-- Checks if the character is considered active in the battle.
function BattlerBase:isActive()
  return self:isAlive()
end

return BattlerBase