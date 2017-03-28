
--[[===========================================================================

Battler
-------------------------------------------------------------------------------
A class the holds character's information for battle formula.

=============================================================================]]

-- Imports
local List = require('core/algorithm/List')
local Skill = require('core/battle/Skill')
local Inventory = require('core/battle/Inventory')

-- Alias
local max = math.max

-- Constants
local elementCount = #Config.elements

local Battler = require('core/class'):new()

-------------------------------------------------------------------------------
-- General
-------------------------------------------------------------------------------

-- @param(data : table) the battler's data from file
-- @param(party : number) this battler's party number
function Battler:init(data, party)
  self.party = party
  self.att = self:createAttributes(data.attributes, data.level, data.build)
  self.currentHP = data.currentHP or self.att:maxHP()
  self.currentSP = data.currentSP or self.att:maxSP()
  self.data = data
  self.turnCount = 0
  self.attackSkillID = data.attackID
  self.inventory = Inventory(data.items)
  self.skillList = List()
  -- Store skills
  for i = 1, #data.skills do
    self.skillList:add(Skill(data.skills[i]))
  end
  -- Store elements
  local e = {}
  for i = 1, #data.elements do
    e[data.elements[i].id + 1] = data.elements[i].value
  end
  for i = 1, elementCount do
    if not e[i] then
      e[i] = 0
    end
  end
  self.elementFactors = e
  -- Create AI
  local ai = data.scriptAI
  if data.scriptAI.path ~= '' then
    self.AI = require('custom/ai/' .. ai.path)
    self.AI.param = ai.param
  end
end

-- Converting to string.
-- @ret(string) a string representation
function Battler:toString()
  return 'Battler: ' .. self.data.name .. ' [Party ' .. self.party .. ']'
end

-------------------------------------------------------------------------------
-- Attributes
-------------------------------------------------------------------------------

-- Creates attribute functions from script data.
-- @param(data : table) a table of base values.
-- @ret(table) an array of attribute functions
function Battler:createAttributes(base, level, build)
  if build.path ~= '' then
    build = require('custom/' .. build.path)
  else
    build = nil
  end
  local att = {}
  local attConfig = Config.attributes
  for i = 1, #attConfig do
    local shortName = attConfig[i].shortName
    local script = attConfig[i].script
    local b = base[i] or 0
    if build and script == '' then
      b = b + build[shortName](level)
    end
    att[shortName] = self:createAttribute(b, script)
  end
  att.maxHP = att[attConfig[Config.battle.attHPID + 1].shortName]
  att.maxSP = att[attConfig[Config.battle.attSPID + 1].shortName]
  att.turn = att[attConfig[Config.battle.attTurnID + 1].shortName]
  att.steps = att[attConfig[Config.battle.attStepID + 1].shortName]
  return att
end

-- Creates an attribute access function.
-- @param(baseValue : number) attribute's base value from battler
-- @param(script : number) attribute's formula script
-- @ret(function) the function for this attribute
function Battler:createAttribute(baseValue, script)
  if script == '' then
    return function()
      return baseValue
    end
  end
  if baseValue > 0 then
    script = script .. ' + ' .. baseValue
  end
  local funcString = 'function(att) return ' .. script .. ' end'
  return loadstring('return ' .. funcString)()
end

-------------------------------------------------------------------------------
-- Turn
-------------------------------------------------------------------------------

-- Increments turn count by the turn attribute.
-- @param(limit : number) the turn limit to start the turn
-- @ret(boolean) true if the limit was reached, false otherwise
function Battler:incrementTurnCount(limit)
  self.turnCount = self.turnCount + self.att:turn()
  if self.turnCount >= limit then
    self.turnCount = self.turnCount - limit
    return true
  else
    return false
  end
end

-- Decrements turn count by a value. It never reaches a negative value.
-- @param(value : number)
function Battler:decrementTurnCount(value)
  self.turnCount = max(self.turnCount - value, 0)
end

-- Callback for when a new turn begins.
-- @param(iterations : number) the number of turn iterations since the previous turn
function Battler:onTurnStart(iterations)
  if BattleManager.currentCharacter.battler == self then
    self.currentSteps = self.att:steps()
  end
end

-- Callback for when a turn ends.
-- @param(iterations : number) the number of turn iterations since the previous turn
function Battler:onTurnEnd(iterations)
end

-------------------------------------------------------------------------------
-- Battle
-------------------------------------------------------------------------------

-- Checks if battler is still alive by its HP.
-- @ret(boolean) true is HP is zero, false otherwise
function Battler:isAlive()
  return self.currentHP == 0
end

-- Decreases Hit Points.
-- @param(value : number) damage value (may be negative to cure)
function Battler:damageHP(value)
  self.currentHP = self.currentHP - value
end

-- Decreases Skill Points.
-- @param(value : number) damage value (may be negative to cure)
function Battler:damageSP(value)
  self.currentSP = self.currentSP - value
end

-------------------------------------------------------------------------------
-- Skills
-------------------------------------------------------------------------------

-- Gets that skill that is called when this battler "attacks".
-- @ret(Skill) the skill data
function Battler:getAttackSkill()
  return Skill(self.attackSkillID)
end

return Battler
