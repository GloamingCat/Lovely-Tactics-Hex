
--[[===============================================================================================

Battler
---------------------------------------------------------------------------------------------------
A class the holds character's information for battle formula.

=================================================================================================]]

-- Imports
local List = require('core/datastruct/List')
local SkillAction = require('core/battle/action/SkillAction')
local Inventory = require('core/battle/Inventory')

-- Alias
local max = math.max
local min = math.min
local ceil = math.ceil
local newArray = util.newArray
local readFile = love.filesystem.read
local copyArray = util.copyArray

-- Constants
local stateVariables = Config.stateVariables
local attConfig = Database.attributes
local elementCount = #Config.elements
local turnLimit = Battle.turnLimit
local turnName = attConfig[Config.battle.attTurnID + 1].shortName
local jumpName = attConfig[Config.battle.attJumpID + 1].shortName
local stepName = attConfig[Config.battle.attStepID + 1].shortName
local lifeName = stateVariables[Config.battle.attLifeID + 1].shortName

local Battler = class()

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- @param(battlerID : table) the battler's ID in database
-- @param(party : number) this battler's party number
function Battler:init(battlerID, party)
  local data = Database.battlers[battlerID + 1]
  self.data = data
  self.name = data.name
  self.battlerID = battlerID
  self.party = party
  self.tags = util.createTags(data.tags)
  local persistentData = self:loadPersistentData(battlerID, data.persistent, data.items)
  self:createAttributes(data.attributes, data.level, data.build)
  self:createStateValues(persistentData)
  self:setSkillList(data.skills, data.attackID)
  self:setElements(data.elements)
  self:setAI(data.scriptAI)
end
-- Gets the data from save if persistent, nil if not.
-- @ret(table) the battler's data in the save
function Battler:loadPersistentData(id, persistent, items)
  if persistent then
    local data = SaveManager.current.battlerData[id .. '']
    if not data then
      data = { inventory = Inventory(items) }
      SaveManager.current.battlerData[id .. ''] = data
    end
    self.inventory = data.inventory
    return data
  else
    self.inventory = Inventory(items)
    return nil
  end
end
-- Sets data of this battler's AI.
-- @param(ai : table) the script data table (with strings path and param)
function Battler:setAI(ai)
  if ai.path ~= '' then
    self.AI = require('custom/' .. ai.path)(self, ai.param)
  else
    self.AI = nil
  end
end
-- Creates and sets and array of element factors.
-- @param(elements : table) array of element factors 
--  (in percentage, 100 is neutral)
function Battler:setElements(elements)
  local e = newArray(elementCount, 0)
  for i = 1, #elements do
    e[elements[i].id + 1] = elements[i].value - 100
  end
  self.elementFactors = e
end
-- Creates and sets the list of usable skills.
-- @param(skills : table) array of skill IDs
-- @param(attackID : number) ID of the battler's "Attack" skill
function Battler:setSkillList(skills, attackID)
  self.skillList = List()
  for i = 1, #skills do
    local id = skills[i]
    self.skillList:add(SkillAction.fromData(id))
  end
  self.attackSkill = SkillAction.fromData(attackID)
end
-- Converting to string.
-- @ret(string) a string representation
function Battler:__tostring()
  return 'Battler: ' .. self.name .. ' [Party ' .. self.party .. ']'
end

---------------------------------------------------------------------------------------------------
-- Attributes
---------------------------------------------------------------------------------------------------

-- Creates attribute functions from script data.
-- @param(base : table) a table of base values
-- @param(level : number) battler's level
-- @param(build : table) the build with the base functions for each attribute
function Battler:createAttributes(base, level, build)
  if build.path ~= '' then
    build = require('custom/' .. build.path)
  else
    build = nil
  end
  self.att = {}
  for i = 1, #attConfig do
    local shortName = attConfig[i].shortName
    local script = attConfig[i].script
    local b = base[i] or 0
    if build and script == '' then
      b = b + build[shortName](level)
    end
    local base = self:createAttributeBase(b, script)
    self.att[shortName] = function()
      return base(self.att) * self.state.attMul[shortName]
        + self.state.attAdd[shortName]
    end
  end  
  self.turnStep = self.att[turnName]
  self.jumpPoints = self.att[jumpName]
  self.maxSteps = self.att[stepName]
end
-- Initializes battler's state.
-- @param(data : table) persistent data
function Battler:createStateValues(data)
  local initState = {}
  for i = 1, #self.data.stateVariables do
    local var = self.data.stateVariables[i]
    local name = stateVariables[var.id + 1].name
    initState[name] = var.value
  end
  self.state = data or {}
  self.state.steps = 0
  self.state.turnCount = 0
  -- Attribute bonus
  if not data or not data.attAdd or not data.attMul then
    self.state.attAdd = {}
    self.state.attMul = {}
    for i = 1, #attConfig do
      local shortName = attConfig[i].shortName
      self.state.attAdd[shortName] = 0
      self.state.attMul[shortName] = 1
    end
  end
  -- Min / max
  self.stateMax = {}
  self.stateMin = {}
  for i = 1, #stateVariables do
    local shortName = stateVariables[i].shortName
    local max = loadformula(stateVariables[i].max, 'att')
    local min = loadformula(stateVariables[i].min, 'att')
    self.stateMax[shortName] = function()
      return max(self.att)
    end
    self.stateMin[shortName] = function()
      return min(self.att)
    end
    if data and data[shortName] then
      self:setStateValue(shortName, data[shortName])
    elseif initState[shortName] then
      self:setStateValue(shortName, initState[shortName])
    else
      local init = loadformula(stateVariables[i].initial, 'att')
      self:setStateValue(shortName, init(self.att))
    end
  end
end
-- Creates an attribute access function.
-- @param(baseValue : number) attribute's base value from battler
-- @param(script : number) attribute's formula script
-- @ret(function) the function for this attribute
function Battler:createAttributeBase(baseValue, script)
  if script == '' then
    return function()
      return baseValue
    end
  end
  if baseValue > 0 then
    script = script .. ' + ' .. baseValue
  end
  return loadformula(script, 'att')
end

---------------------------------------------------------------------------------------------------
-- Turn
---------------------------------------------------------------------------------------------------

-- Increments turn count by the turn attribute.
-- @param(time : number) a multiplier to the step (used for time bar animation)
function Battler:incrementTurnCount(time)
  self.state.turnCount = self.state.turnCount + self.turnStep() * time
end
-- Decrements turn count by a value. It never reaches a negative value.
-- @param(value : number)
function Battler:decrementTurnCount(value)
  self.state.turnCount = max(self.state.turnCount - value, 0)
end
-- Returns the number of steps needed to reach turn limit.
-- @ret(number) the number of steps (float)
function Battler:remainingTurnCount()
  return (turnLimit - self.state.turnCount) / self.turnStep()
end
-- Callback for when a new turn begins.
-- @param(iterations : number) the number of turn iterations since the previous turn
function Battler:onTurnStart(iterations)
  if self.AI and self.AI.onTurnStart then
    self.AI:onTurnStart(self, iterations)
  end
end
-- Callback for when a turn ends.
-- @param(iterations : number) the number of turn iterations since the previous turn
function Battler:onTurnEnd(iterations)
  if self.AI and self.AI.onTurnEnd then
    self.AI:onTurnEnd(self, iterations)
  end
end
-- Callback for when this battler's turn starts.
-- @param(iterations : number) the number of turn iterations since the previous turn
function Battler:onSelfTurnStart(iterations)
  self.state.steps = self.maxSteps()
end
-- Callback for when this battler's turn ends.
-- @param(iterations : number) the number of turn iterations since the previous turn
-- @param(actionCost : number) the time the battler spent during the turn
function Battler:onSelfTurnEnd(iterations, actionCost)
  local stepCost = self.state.steps / self.maxSteps()
  self:decrementTurnCount(ceil((stepCost + actionCost) * turnLimit / 2))
end

---------------------------------------------------------------------------------------------------
-- Other callbacks
---------------------------------------------------------------------------------------------------

-- Callback for when the battle ends.
function Battler:onBattleEnd()
  if self.AI and self.AI.onBattleEnd then
    self.AI:onBattleEnd(self)
  end
end
-- Callback for when the character moves.
-- @param(path : Path) the path that the battler just walked
function Battler:onMove(path)
  if path.lastStep:isControlZone(self) then
    self.state.steps = 0
  else
    self.state.steps = self.state.steps - path.totalCost
  end
end
-- Callback for when the character uses a skill.
-- @param(action : BattleAction) the skill that the battler just used
function Battler:onSkillUse(action)
  local costs = action.costs
  for i = 1, #costs do
    local value = costs[i].cost(self.att)
    self:damage(costs[i].name, value)
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
  return self.state.turnCount / turnLimit
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

return Battler
