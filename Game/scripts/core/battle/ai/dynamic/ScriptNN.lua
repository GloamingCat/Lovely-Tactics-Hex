
--[[===============================================================================================

ScriptNN
---------------------------------------------------------------------------------------------------
Script that determines the rule to use using a neural network.

=================================================================================================]]

-- Imports
local PriorityQueue = require('core/algorithm/PriorityQueue')
local NeuralNetwork = require('core/battle/ai/NeuralNetwork')
local Script = require('core/battle/ai/dynamic/Script')

-- Alias
local newArray = util.newArray

local ScriptNN = class(Script)

---------------------------------------------------------------------------------------------------
-- Shared patterns
---------------------------------------------------------------------------------------------------

local patterns = {}

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- @param(key : string)
-- @param(battler : Battler)
-- @param(param : string)
local old_init = Script.init
function ScriptNN:init(key, battler, param)
  self.battler = battler
  old_init(self, key)
  self.inputs = self:createInputs()
  if param == 'sample' then
    -- Creating samples.
    if not patterns[key] then
      patterns[key] = BattleManager.params[key] or self:loadJsonData('_pat') or {}
    end
  elseif param == 'train' then
    -- Train from samples.
    if not patterns[key] then
      self.network = self:createNetwork(nil, true)
      local data = BattleManager.params[key] or self:loadJsonData('_pat')
      self.network:train(data, 1)
      patterns[key] = { self.network.inputWeights, self.network.hiddenWeights }
      self:saveJsonData(patterns[key])
    else
      self.network = self:createNetwork(patterns[key], true)
    end
  else
    -- Execute from training.
    local data = BattleManager.params[key] or self:loadJsonData()
    self.network = self:createNetwork(data, false)
  end
end

-- Creates the network from the data.
-- @param(data : table) layer data (if nil, creates initial network)
-- @param(training : boolean) true if in the training mode
function ScriptNN:createNetwork(data, training)
  local inputCount = #self.inputs
  local outputCount = #self.rules
  return NeuralNetwork(inputCount, inputCount + outputCount, outputCount, data, training)
end

---------------------------------------------------------------------------------------------------
-- Execution
---------------------------------------------------------------------------------------------------

-- Overrides ArtificialInteligence:nextAction.
function ScriptNN:nextAction(it, user)
  local inputs = {}
  for i = 1, #self.inputs do
    inputs[i] = self.inputs[i](self, user)
  end
  if self.network then
    return self:fromNetworkTest(user, inputs)
  else
    return self:fromPlayerInput(user, inputs)
  end
end

-- Gets rule ID from neural network test.
-- @param(user : Character)
-- @param(inputs : table) input values
-- @ret(number) action time cost
function ScriptNN:fromNetworkTest(user, inputs)
  local outputs = self.network:test(inputs)
  local queue = PriorityQueue()
  for i = 1, #outputs do
    queue:enqueue(i, outputs[i])
  end
  while not queue:isEmpty() do
    local id = queue:dequeue()
    local cost = self:executeRule(user, id)
    if cost then
      return cost
    end
  end
  return 0
end

-- Gets rule ID from player's input, using the RuleGUI.
-- @param(user : Character)
-- @param(inputs : table) input values
-- @ret(number) action time cost
function ScriptNN:fromPlayerInput(user, inputs)
  local cost = nil
  repeat
    local id = GUIManager:showGUIForResult('battle/RuleGUI', self.rules)
    cost = self:executeRule(user, id)
    if cost then
      local outputs = newArray(#self.rules, 0)
      outputs[id] = 1
      local pat = patterns[self.key]
      pat[#pat + 1] = { inputs, outputs }
    end
  until cost
  return cost
end

-- Callback to train the network and store the result.
-- @param(user : Character)
function ScriptNN:onBattleEnd(user)
  if not self.network and patterns[self.key] then
    local pat = patterns[self.key]
    patterns[self.key] = nil
    self:saveJsonData(pat, '_pat')
  end
end

---------------------------------------------------------------------------------------------------
-- Default Inputs
---------------------------------------------------------------------------------------------------

-- Generates the input vector from the current battle state.
-- @ret(table) array of functions that generate each input value
function ScriptNN:createInputs()
  return {self.userHP, self.userSP, self.allyHP, self.allySP, 
    self.enemyHP, self.enemySP, self.bias}
end

function ScriptNN:userHP(user)
  return (user.battler.currentHP / user.battler.maxHP())
end

function ScriptNN:userSP(user)
  return (user.battler.currentSP / user.battler.maxSP())
end

function ScriptNN:allyHP(user)
  local s, ms = 0, 0
  for char in TroopManager.characterList:iterator() do
    if char.battler.party == user.battler.party then
      s = s + char.battler.currentHP
      ms = ms + char.battler.maxHP()
    end
  end
  return s / ms
end

function ScriptNN:allySP(user)
  local s, ms = 0, 0
  for char in TroopManager.characterList:iterator() do
    if char.battler.party == user.battler.party then
      s = s + char.battler.currentSP
      ms = ms + char.battler.maxSP()
    end
  end
  return s / ms
end

function ScriptNN:enemyHP(user)
  local s, ms = 0, 0
  for char in TroopManager.characterList:iterator() do
    if char.battler.party ~= user.battler.party then
      s = s + char.battler.currentHP
      ms = ms + char.battler.maxHP()
    end
  end
  return s / ms
end

function ScriptNN:enemySP(user)
  local s, ms = 0, 0
  for char in TroopManager.characterList:iterator() do
    if char.battler.party ~= user.battler.party then
      s = s + char.battler.currentSP
      ms = ms + char.battler.maxSP()
    end
  end
  return s / ms
end

function ScriptNN:bias()
  return 1
end

return ScriptNN
