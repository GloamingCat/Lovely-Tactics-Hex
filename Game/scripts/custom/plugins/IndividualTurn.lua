
--[[===============================================================================================

IndividualTurn
---------------------------------------------------------------------------------------------------
System of turns per characters instead of per party.

=================================================================================================]]

-- Imports
local Battler = require('core/battle/Battler')
local Status = require('core/battle/Status')
local BattleAction = require('core/battle/action/BattleAction')
local SkillAction = require('core/battle/action/SkillAction')
local PriorityQueue = require('core/datastruct/PriorityQueue')
local TurnManager = require('core/battle/TurnManager')

-- Alias
local max = math.max
local min = math.min
local ceil = math.ceil
local yield = coroutine.yield
local time = love.timer.getDelta

-- Parameters
local turnBarAnim = args.animation
local turnLimit = args.turnLimit
local attName = args.attName

---------------------------------------------------------------------------------------------------
-- Turn Manager
---------------------------------------------------------------------------------------------------

local old_init = TurnManager.init
function TurnManager:init()
  old_init(self)
  self.turnLimit = turnLimit
end

-- Override.
function TurnManager:updateTurnCharacters()
  local char, iterations = self:getNextTurn()
  self.iterations = iterations
  self.turnCharacters = { char }
  self.characterIndex = 1
end
-- [COROUTINE] Searchs for the next character turn and starts.
-- @ret(Character) the next turn's character
-- @ret(number) the number of iterations it took from the previous turn
function TurnManager:getNextTurn()
  local turnQueue = self:getTurnQueue()
  local currentCharacter, iterations = turnQueue:front()
  if turnBarAnim then
    local i = 0
    while i < iterations do
      i = i + time() * 60
      self:incrementTurnCount(time() * 60)
      yield()
    end
  else
    self:incrementTurnCount(iterations)
  end
  return currentCharacter, iterations
end
-- Sorts the characters according to which one's turn will star first.
-- @ret(PriorityQueue) the queue where which element is a character 
--  and each key is the remaining turn count until it's the character's turn
function TurnManager:getTurnQueue()
  local queue = PriorityQueue()
  for char in TroopManager.characterList:iterator() do
    if char.battler:isAlive() then
      local time = char.battler:remainingTurnCount()
      queue:enqueue(char, time)
    end
  end
  return queue
end
-- Increments all character's turn count.
-- @param(time : number) the number of time iterations (1 by default)
-- @ret(Character) the character that reached turn limit (nil if none did)
function TurnManager:incrementTurnCount(time)
  time = time or 1
  for bc in TroopManager.characterList:iterator() do
    if bc.battler:isAlive() then
      bc.battler:incrementTurnCount(time)
    end
  end
end

---------------------------------------------------------------------------------------------------
-- Battler
---------------------------------------------------------------------------------------------------

-- Override.
local old_createStateValues = Battler.createStateValues
function Battler:createStateValues(...)
  self.turnCount = 0
  old_createStateValues(self, ...)
end
-- Increments turn count by the turn attribute.
-- @param(time : number) a multiplier to the step (used for time bar animation)
function Battler:incrementTurnCount(time)
  self.turnCount = self.turnCount + self.att[attName]() * time
end
-- Decrements turn count by a value. It never reaches a negative value.
-- @param(value : number)
function Battler:decrementTurnCount(value)
  self.turnCount = max(self.turnCount - value, 0)
end
-- Returns the number of steps needed to reach turn limit.
-- @ret(number) the number of steps (float)
function Battler:remainingTurnCount()
  return (turnLimit - self.turnCount) / self.att[attName]()
end
-- Override. Decrements turn count.
function Battler:onSelfTurnEnd(char, result)
  local stepCost = self.steps / self.maxSteps()
  local cost = result.timeCost or 0
  self:decrementTurnCount(ceil((stepCost + result.timeCost) * turnLimit / 2))
end

---------------------------------------------------------------------------------------------------
-- Status
---------------------------------------------------------------------------------------------------

-- Override.
function Status:onTurnStart(char)
  self.state.lifeTime = self.state.lifeTime + _G.TurnManager.iterations
  if self.state.lifeTime > self.duration then
    self:remove(char)
  end
end

---------------------------------------------------------------------------------------------------
-- SkillAction
---------------------------------------------------------------------------------------------------

local SkillAction_init = SkillAction.init
function SkillAction:init(...)
  SkillAction_init(self, ...)
  if self.tags.timeCost then
    self.timeCost = loadformula(self.tags.timeCost, 'action, att')
  end
end

---------------------------------------------------------------------------------------------------
-- BattleAction
---------------------------------------------------------------------------------------------------

local BattleAction_execute = BattleAction.execute
function BattleAction:execute(input)
  local result = BattleAction_execute(self, input)
  if self.timeCost then
    result.timeCost = self.timeCost(self, input.user.battler.att)
  else
    result.timeCost = 100
  end
  return result
end

---------------------------------------------------------------------------------------------------
-- TurnWindow
---------------------------------------------------------------------------------------------------

