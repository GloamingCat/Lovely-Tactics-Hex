
--[[===============================================================================================

BattlerBase
---------------------------------------------------------------------------------------------------
A class the holds character's information for battle formula.
Used only for access and display in GUI.

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
local sum = util.array.sum

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
-- @param(data : table) battler's data from database
function BattlerBase:init(data, save, troopID)
  self.troopID = troopID
  self.data = data
  self.save = save
  self.classData = Database.classes[data.classID]
  self.name = data.name
  self.tags = TagMap(data.tags)
  self:initializeSkillList(data.skills or {}, data.attackID)
  self:initializeElements(data.elements or {})
  self:initializeStatusList(data.status or {})
  self:initializeInventory(data.items or {})
  self:createAttributes()
  self:createStateValues(data.attributes, data.level)
end
-- Creates and sets the list of usable skills.
-- @param(skills : table) array of skill IDs
-- @param(attackID : number) ID of the battler's "Attack" skill
function BattlerBase:initializeSkillList(skills, attackID)
  -- Get from troop's persistent data
  if self.save then
    skills = self.save.skills or skills
    attackID = self.save.attackID or attackID
  end
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
function BattlerBase:initializeElements(elements)
  self.elementFactors = self.save and copyArray(self.save.elements)
  if not self.elementFactors then
    local e = newArray(elementCount, 0)
    for i = 1, #elements do
      e[elements[i].id] = (elements[i].value - 100) / 100
    end
    self.elementFactors = e
  end
end
-- Creates the initial status list.
function BattlerBase:initializeStatusList(initialStatus)
  initialStatus = self.save and self.save.status
  self.statusList = StatusList(initialStatus)
end
-- Initializes inventory from the given initial items slots.
function BattlerBase:initializeInventory(items)
  items = self.save and self.save.items
  self.inventory = Inventory(items)
end

---------------------------------------------------------------------------------------------------
-- Attributes
---------------------------------------------------------------------------------------------------

-- Creates attribute functions from script data.
function BattlerBase:createAttributes()
  self.att = {}
  for i = 1, #attConfig do
    local key = attConfig[i].key
    local script = attConfig[i].script
    if script == '' then
      self.att[key] = function()
        local add, mul = self.statusList:attBonus(key)
        return add + mul * self.attBase[key]
      end
    else
      local base = loadformula(script, 'att')
      self.att[key] = function()
        local add, mul = self.statusList:attBonus(key)
        return add + mul * (self.attBase[key] + base(self.att))
      end
    end
  end
  self.jumpPoints = self.att[jumpName]
  self.maxSteps = self.att[stepName]
  self.maxWeight = self.att[weightName]
  self.mhp = self.att[mhpName]
  self.msp = self.att[mspName]
end
-- Initializes battler's state.
-- @param(data : table) persistent data
-- @param(attBase : table) array of the base values of each attribute
-- @param(build : table) the build with the base functions for each attribute
-- @param(level : number) battler's level
function BattlerBase:createStateValues(attBase, level)
  self.steps = 0
  if self.save then
    self.state = copyTable(save.state)
    self.attBase = copyTable(save.attBase)
    self.exp = save.exp
    self.level = save.level
  else
    self.state = {}
    self.attBase = {}
    for i = 1, #attConfig do
      local key = attConfig[i].key
      local b = attBase[key] or 0
      if self.classData.build[key] then
        local formula = loadformula(self.classData.build[key], 'lvl')
        b = b + formula(level)
      end
      self.attBase[key] = b
    end
    self.exp = loadformula(self.classData.expCurve, 'lvl')(level)
    self.level = level
    self.state.hp = self.mhp()
    self.state.sp = self.msp()
  end
end

---------------------------------------------------------------------------------------------------
-- Save
---------------------------------------------------------------------------------------------------

function BattlerBase:createPersistentData()
  local data = {}
  data.level = self.level
  data.exp = self.exp
  data.state = self.state
  data.attBase = self.attBase
  return data
end

return BattlerBase
