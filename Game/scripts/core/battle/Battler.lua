
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
local attConfig = Config.attributes
local elementCount = #Config.elements

local Battler = require('core/class'):new()

-------------------------------------------------------------------------------
-- Initialization
-------------------------------------------------------------------------------

-- @param(data : table) the battler's data from file
-- @param(party : number) this battler's party number
function Battler:init(data, party)
  self.party = party
  self:createAttributes(data.attributes, data.level, data.build)
  self.currentHP = data.currentHP or self.maxHP()
  self.currentSP = data.currentSP or self.maxSP()
  self.data = data
  self.turnCount = 0
  self.inventory = Inventory(data.items)
  self:setPortraits(data.battleCharID)
  self:setSkillList(data.skills, data.attackID)
  self:setElements(data.elements)
  self:setAI(data.scriptAI)
end

-- Sets data of this battler's AI.
-- @param(ai : table) the script data table (with strings path and param)
function Battler:setAI(ai)
  if ai.path ~= '' then
    self.AI = require('custom/ai/' .. ai.path)
    self.AI.param = ai.param
  else
    self.AI = nil
  end
end

-- Creates and sets and array of element factors.
-- @param(elements : table) array of element factors 
--  (in percentage, 100 is neutral)
function Battler:setElements(elements)
  local e = {}
  for i = 1, #elements do
    e[elements[i].id + 1] = elements[i].value - 100
  end
  for i = 1, elementCount do
    if not e[i] then
      e[i] = 0
    end
  end
  self.elementFactors = e
end

-- Creates and sets the list of usable skills.
-- @param(skills : table) array of skill IDs
-- @param(attackID : number) ID of the battler's "Attack" skill
function Battler:setSkillList(skills, attackID)
  self.skillList = List()
  for i = 1, #skills do
    self.skillList:add(Skill(skills[i]))
  end
  self.attackSkill = Skill(attackID)
end

-- Creates and sets and table of portraits.
-- @param(charID : number) the battler's character ID
function Battler:setPortraits(charID)
  self.portraits = {}
  local charData = Database.charBattle[charID + 1]
  for i = 1, #charData.portraits do
    local p = charData.portraits[i]
    self.portraits[p.name] = p.quad
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
-- @param(data : table) a table of base values
function Battler:createAttributes(base, level, build)
  if build.path ~= '' then
    build = require('custom/' .. build.path)
  else
    build = nil
  end
  self.att = {}
  self.attAdd = {}
  self.attMul = {}
  for i = 1, #attConfig do
    local shortName = attConfig[i].shortName
    local script = attConfig[i].script
    local b = base[i] or 0
    if build and script == '' then
      b = b + build[shortName](level)
    end
    local base = self:createAttributeBase(b, script)
    self.attAdd[shortName] = 0
    self.attMul[shortName] = 1
    self.att[shortName] = function()
      return base(self.att) * self.attMul[shortName]
        + self.attAdd[shortName]
    end
  end
  self.maxHP = self.att[attConfig[Config.battle.attHPID + 1].shortName]
  self.maxSP = self.att[attConfig[Config.battle.attSPID + 1].shortName]
  self.turn = self.att[attConfig[Config.battle.attTurnID + 1].shortName]
  self.steps = self.att[attConfig[Config.battle.attStepID + 1].shortName]
  self.jump = self.att[attConfig[Config.battle.attJumpID + 1].shortName]
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
  self.turnCount = self.turnCount + self.turn()
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
    self.currentSteps = self.steps()
  end
end

-- Callback for when a turn ends.
-- @param(iterations : number) the number of turn iterations since the previous turn
function Battler:onTurnEnd(iterations)
end

-- Callback for when the battle ends.
function Battler:onBattleEnd()
  if self.data.persistent then
    -- TODO: update battler's data
  end
end

-------------------------------------------------------------------------------
-- Battle
-------------------------------------------------------------------------------

-- Checks if battler is still alive by its HP.
-- @ret(boolean) true if HP greater then zero, false otherwise
function Battler:isAlive()
  return self.currentHP > 0
end

-- Decreases Hit Points.
-- @param(value : number) damage value (may be negative to cure)
-- @ret(boolean) true if character was knocked out
function Battler:damageHP(value)  
  self.currentHP = self.currentHP - value
  if self.currentHP <= 0 then
    self.currentHP = 0
    return true
  else
    return false
  end
end

-- Decreases Skill Points.
-- @param(value : number) damage value (may be negative to cure)
function Battler:damageSP(value)
  self.currentSP = max(0, self.currentSP - value)
end

return Battler
