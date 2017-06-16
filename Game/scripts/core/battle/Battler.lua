
--[[===========================================================================

Battler
-------------------------------------------------------------------------------
A class the holds character's information for battle formula.

=============================================================================]]

-- Imports
local List = require('core/algorithm/List')
local SkillAction = require('core/battle/action/SkillAction')
local Inventory = require('core/battle/Inventory')

-- Alias
local max = math.max
local ceil = math.ceil
local newArray = util.newArray

-- Constants
local attConfig = Config.attributes
local elementCount = #Config.elements
local turnLimit = Battle.turnLimit

local Battler = class()

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
  self.currentSteps = 0
  self.data = data
  self.turnCount = 0
  self.inventory = Inventory(self, data.items)
  self:setPortraits(data.battleCharID)
  self:setSkillList(data.skills, data.attackID)
  self:setElements(data.elements)
  self:setAI(data.scriptAI)
end

-- Sets data of this battler's AI.
-- @param(ai : table) the script data table (with strings path and param)
function Battler:setAI(ai)
  if ai.path ~= '' then
    self.AI = require('custom/' .. ai.path)(ai.param)
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

-- Creates and sets a table of portraits.
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
function Battler:__tostring()
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
  return loadformula(script, 'att')
end

-------------------------------------------------------------------------------
-- Turn
-------------------------------------------------------------------------------

-- Increments turn count by the turn attribute.
-- @param(limit : number) the turn limit to start the turn
-- @ret(boolean) true if the limit was reached, false otherwise
function Battler:incrementTurnCount(time)
  self.turnCount = self.turnCount + self.turn() * time
end

-- Decrements turn count by a value. It never reaches a negative value.
-- @param(value : number)
function Battler:decrementTurnCount(value)
  self.turnCount = max(self.turnCount - value, 0)
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
function Battler:onSelfTurnStart(iterations)
  self.currentSteps = self.steps()
end

-- Callback for when this battler's turn ends.
function Battler:onSelfTurnEnd(iterations, actionCost)
  local stepCost = self.currentSteps / self.steps()
  self:decrementTurnCount(ceil((stepCost + actionCost) * turnLimit / 2))
end

-------------------------------------------------------------------------------
-- Other callbacks
-------------------------------------------------------------------------------

-- Callback for when the battle ends.
function Battler:onBattleEnd()
  if self.data.persistent then
    -- TODO: update battler's data
  end
  if self.AI and self.AI.onBattleEnd then
    self.AI:onBattleEnd(self)
  end
end

-- Callback for when the player moves.
function Battler:onMove(path)
  if path.lastStep:isControlZone(self) then
    self.currentSteps = 0
  else
    self.currentSteps = self.currentSteps - path.totalCost
  end
end

-------------------------------------------------------------------------------
-- State
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

-- The battler's current state in the battle. 
-- @ret(table) a table containing only mutable attributes
function Battler:getState()
  local attAdd = {}
  for k, v in pairs(self.attAdd) do
    attAdd[k] = v
  end
  local attMul = {}
  for k, v in pairs(self.attMul) do
    attMul[k] = v
  end
  return {
    hp = self.currentHP,
    sp = self.currentSP,
    steps = self.currentSteps,
    attAdd = attAdd,
    attMul = attMul,
    turnCount = self.turnCount
  }
end

-- Changes the battler's current info.
-- @param(state : table) the info about battler's mutable attributes
function Battler:setState(state)
  for k, v in pairs(state.attAdd) do
    self.attAdd[k] = v
  end
  for k, v in pairs(state.attMul) do
    self.attMul[k] = v
  end
  self.currentHP = state.hp
  self.currentSP = state.sp
  self.currentSteps = state.steps
  self.turnCount = state.turnCount
end

return Battler
