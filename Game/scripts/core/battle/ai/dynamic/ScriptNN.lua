
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
-- Initialization
---------------------------------------------------------------------------------------------------

-- @param(key : string)
-- @param(trainig : boolean)
local old_init = Script.init
function ScriptNN:init(param)
  old_init(self)
  if param == 'train' then
    self.patterns = {}
  end
  self.inputs = self:createInputs()
  local data = JSON.decode(self:loadData())
  self.network = self:createNetwork(data, training)
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
function ScriptNN:nextAction(user)
  local inputs = {}
  for i = 1, self.inputs do
    inputs[i] = self.inputs[i](self, user)
  end
  if self.patterns then
    return self:fromPlayerInput(user, inputs)
  else
    return self:fromNetworkTest(user, inputs)
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
    local cost = self:executeRule(id)
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
    cost = self:executeRule(id)
    if cost then
      local outputs = newArray(#self.rules, 0)
      outputs[id] = 1
      self.patterns[#self.patterns + 1] = {inputs, outputs}
    end
  until cost
  return cost
end

-- Callback to train the network and store the result.
-- @param(user : Character)
function ScriptNN:onBattleEnd(user)
  if self.patterns then
    self.network:train(self.patterns, 5)
    local weights = {self.network.inputWeights, self.network.hiddenWeights}
    local data = JSON.encode(weights)
    self:saveData(data)
  end
end

---------------------------------------------------------------------------------------------------
-- Inputs
---------------------------------------------------------------------------------------------------

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
      s = s + user.battler.currentHP
      ms = ms + user.battler.HP()
    end
  end
  return s / ms
end

function ScriptNN:allySP(user)
  local s, ms = 0, 0
  for char in TroopManager.characterList:iterator() do
    if char.battler.party == user.battler.party then
      s = s + user.battler.currentSP
      ms = ms + user.battler.SP()
    end
  end
  return s / ms
end

function ScriptNN:enemyHP(user)
  local s, ms = 0, 0
  for char in TroopManager.characterList:iterator() do
    if char.battler.party ~= user.battler.party then
      s = s + user.battler.currentHP
      ms = ms + user.battler.HP()
    end
  end
  return s / ms
end

function ScriptNN:enemySP(user)
  local s, ms = 0, 0
  for char in TroopManager.characterList:iterator() do
    if char.battler.party ~= user.battler.party then
      s = s + user.battler.currentSP
      ms = ms + user.battler.SP()
    end
  end
  return s / ms
end

function ScriptNN:bias()
  return 1
end

-- Generates the input vector from the current battle state.
-- @ret(table) array of functions that generate each input value
function ScriptNN:createInputs()
  return {self.userHP, self.userSP, self.allyHP, self.allySP, 
    self.enemyHP, self.enemySP, self.bias}
end

return ScriptNN
