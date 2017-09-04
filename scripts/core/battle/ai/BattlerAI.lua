
--[[===============================================================================================

BattlerAI
---------------------------------------------------------------------------------------------------
Implements basic functions to be used in AI classes.

=================================================================================================]]

-- Imports
local ActionInput = require('core/battle/action/ActionInput')

-- Alias
local rand = love.math.random
local readFile = love.filesystem.read
local writeFile = love.filesystem.write

-- Static
local thread = nil

local BattlerAI = class()

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(key : string) the AI's identifier (needs to be set by children of this class)
-- @param(battler : Battler)
-- @param(parallel : boolean)
function BattlerAI:init(key, battler, parallel)
  self.key = key
  self.battler = battler
  self.parallel = parallel
end

-- String identifier.
-- @ret(string)
function BattlerAI:__tostring()
  return 'AI: ' .. self.key
end

function BattlerAI:decodeParam(param)
  if param == '' then
    return nil
  else
    return JSON.decode(param)
  end
end

---------------------------------------------------------------------------------------------------
-- Execution
---------------------------------------------------------------------------------------------------

-- Executes next action of the current character, when it's the character's turn.
-- By default, just skips turn, with no time loss.
-- @param(it : number) the number of iterations since last turn
-- @param(user : Character)
-- @ret(number) action time cost
function BattlerAI:runTurn()
  TurnManager:characterTurnStart()
  local rule = nil
  if self.parallel then
    thread = thread or love.thread.newThread('core/Thread')
    local channel = love.thread.newChannel()
    thread:start(channel, self.nextRule, self, it, user)
    while thread:isRunning() do
      coroutine.yield()
    end
    rule = channel:peek()
  else
    rule = self:nextRule()
  end
  local result = nil
  if rule:canExecute() then
    result = rule:execute()
  else
    result = self.waitRule:execute()
  end
  TurnManager:characterTurnEnd(result)
  return result
end

-- Selects a rule to be executed.
function BattlerAI:nextRule()
  return nil -- Abstract.
end

---------------------------------------------------------------------------------------------------
-- Action Selection
---------------------------------------------------------------------------------------------------

-- @param(character : Character)
-- @ret(table) array of actions
function BattlerAI:getCharacterActions(character)
  local b = character.battler
  return {b.attackSkill, unpack(b.skillList)} -- TODO: add Wait
end

-- Gets a random action from the action list given by BattlerAI:getCharacterActions.
-- @param(character : Character)
-- @ret(BattleAction)
function BattlerAI:getRandomAction(character)
  local actions = self:getCharacterActions(character)
  return actions[rand(#actions)]
end

---------------------------------------------------------------------------------------------------
-- Script Data
---------------------------------------------------------------------------------------------------

-- Loads the file from AI data folder and decodes from JSON.
-- @ret(unknown) the data in the file
function BattlerAI:loadJsonData(sufix)
  local data = self:loadData(sufix)
  if data then
    return JSON.decode(data)
  else
    return nil
  end
end

-- Encodes the data as JSON saves in AI data folder.
-- @param(data : unknown) the data to write
function BattlerAI:saveJsonData(data, sufix)
  self:saveData(JSON.encode(data), sufix)
end

-- Loads the file from AI data folder.
-- @ret(string) the data in the file
function BattlerAI:loadData(sufix)
  return readFile(self.key .. (sufix or '') .. '.json')
end

-- Saves the data in AI data folder.
-- @param(data : string) the data to write
function BattlerAI:saveData(data, sufix)
  writeFile(self.key .. (sufix or '')  .. '.json', data)
end

return BattlerAI
