
--[[===============================================================================================

NeuralNetwork
---------------------------------------------------------------------------------------------------
Generic implementation of a neural network.
The bias is optional and must be added manually in the inputs.

=================================================================================================]]

-- Alias
local pow = math.pow
local sigmoid = math.sigmoid
local dsigmoid = math.dsigmoid
local mulVector = math.mulVectors
local newArray = util.newArray

local NeuralNetwork = class()

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Initialize layers.
-- @param(inputCount : number) the number of initial inputs
-- @param(neuronCount : number) the number of neurons in the hidden layer
-- @param(outputCount : number) the number of final outputs
-- @param(weights : table) initial weights
function NeuralNetwork:init(inputCount, neuronCount, outputCount, weights, training)
  self.inputCount = inputCount
  self.neuronCount = neuronCount
  self.outputCount = outputCount
  self.inputWeights = (weights and weights[1]) or self:newLayer(inputCount, neuronCount, 1)
  self.hiddenWeights = (weights and weights[2]) or self:newLayer(neuronCount, outputCount, 1)
  if training then
    self.inputChanges = self:newLayer(inputCount, neuronCount, 0)
    self.hiddenChanges = self:newLayer(neuronCount, outputCount, 0)
    self.learningRate = 0.5
    self.momentum = 0.1
  end
end

-- Creates new neuron layer.
-- @param(inputCount : number) number of inputs for the layer
-- @param(outputCount : number) number of outpout of the layer
-- @param(value : number) initial weight
function NeuralNetwork:newLayer(inputCount, outputCount, value)
  local n = {}
  for i = 1, outputCount do
    n[i] = newArray(inputCount, value)
  end
  return n
end

---------------------------------------------------------------------------------------------------
-- Testing
---------------------------------------------------------------------------------------------------

-- Execute the network for the given input set.
-- @param(input : table) the array of input values
-- @ret(table) the array of output values from hidden layer
-- @ret(table) the array of output values from input layer
function NeuralNetwork:test(inputs)
  assert(#inputs == self.inputCount, "Wrong number of inputs: " .. 
    #inputs .. " instead of " .. self.inputCount)
  -- Result of input layer
  local ir = {}
  for i = 1, self.neuronCount do
    local value = 0
    for j = 1, self.inputCount do
      value = value + self.inputWeights[i][j] + inputs[j]
    end
    ir[i] = value
  end
  -- Result of hidden layer
  local hr = {}
  for i = 1, self.outputCount do
    local value = 0
    for j = 1, self.neuronCount do
      value = value + self.hiddenWeights[i][j] + ir[j]
    end
    hr[i] = value
  end
  return hr, ir
end

---------------------------------------------------------------------------------------------------
-- Training
---------------------------------------------------------------------------------------------------

-- @param(patterns : table) the table of patterns {inputs, outputs}
-- @param(it : number) number of iterations
function NeuralNetwork:train(patterns, it)
  for i = 1, it do
    local err = 0
    for p = 1, #patterns do
      local pat = patterns[p]
      local inputs = pat[1]
      local outputs = pat[2]
      local hr, ir = self:test(inputs)
      err = err + self:backpropagate(inputs, ir, hr, outputs)
    end
  end
end

-- @param(a : table) activations
-- @param(outputs : table) output values
function NeuralNetwork:backpropagate(ai, ah, ao, outputs)
  assert(#outputs == self.outputCount, "Wrong number of outputs: " .. 
    #outputs .. " instead of " .. self.outputCount)
  -- Hidden layer result deltas
  local od = {}
  for i = 1, self.outputCount do
    local err = outputs[i] - ao[i]
    od[i] = dsigmoid(ao[i]) * err
  end
  -- Input layer result deltas
  local hd = {}
  for i = 1, self.neuronCount do
    local err = 0
    for j = 1, self.outputCount do
      err = err + od[j] * self.hiddenWeights[j][i]
    end
    hd[i] = dsigmoid(ah[i]) * err
  end
  -- Update hidden layer weights
  for i = 1, self.neuronCount do
    for j = 1, self.outputCount do
      local d = od[j] * ah[i]
      self:updateWeight(self.hiddenWeights[j], self.hiddenChanges[j], d, i)
    end
  end
  -- Update input layer weights
  for i = 1, self.inputCount do
    for j = 1, self.neuronCount do
      local d = hd[j] * ai[i]
      self:updateWeight(self.inputWeights[j], self.inputChanges[j], d, i)
    end
  end
  -- Total error
  local err = 0
  for i = 1, self.outputCount do
    local d = outputs[i] - ao[i]
    err = err + d*d / 2
  end
  return err
end

-- @param(weights : table) weight array
-- @param(changes : table) changes array
-- @param(d : number) delta
-- @param(i : number) input index
function NeuralNetwork:updateWeight(weights, changes, d, i)
  weights[i] = weights[i] + self.learningRate * d + self.momentum * changes[i]
  changes[i] = d
end

return NeuralNetwork
