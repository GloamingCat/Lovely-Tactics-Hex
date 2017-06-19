
--[[===============================================================================================

NNCreator
---------------------------------------------------------------------------------------------------
A script that generates weights for a neural network.

=================================================================================================]]

-- Imports
local Battler = require('core/battle/Battler')
local GeneticAlgorithm = require('core/battle/ai/GeneticAlgorithm')

-- Alias
local readFile = love.filesystem.read
local writeFile = love.filesystem.write

-- Constants
local battlerID = 3
local matches = { 0, 1 }
local repeats = 1
local generations = 10

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

local function toWeights(genes, net)
  -- Get input weights
  local inputWeights = net:newLayer(net.inputCount, net.neuronCount, 0)
  for i = 1, net.neuronCount do
    for j = 1, net.inputCount do
      inputWeights[i][j] = genes[(i - 1) * net.inputCount + j]
    end
  end
  -- Get hidden weights
  local off = net.inputCount * net.neuronCount
  local hiddenWeights = net:newLayer(net.neuronCount, net.inputCount, 0)
  for i = 1, net.outputCount do
    for j = 1, net.neuronCount do
      hiddenWeights[i][j] = genes[off + (i - 1) * net.inputCount + j]
    end
  end
  return { inputWeights, hiddenWeights }
end

local function getWinningRate(params)
  local victories = 0
  local total = 0
  for i = 1, #matches, 2 do
    for k = 1, repeats do 
      local winner = FieldManager:loadBattle(matches[i], params)
      if winner == matches[i + 1] then
        victories = victories + 1
      end
      total = total + 1
    end
  end
  return victories / total
end

return function()
  local battler = Battler(nil, battlerID, -1)
  assert(battler.AI.network, 'Battler ' .. battlerID .. ' (' .. 
    battler.data.name .. ') does not have a neural network AI.')
  
  local ic = battler.AI.network.inputCount
  local nc = battler.AI.network.neuronCount
  local oc = battler.AI.network.outputCount
  local length = ic * nc + nc * oc
  local params = { skipAnimations = true }
  local function getFitness(genes)
    params[battler.AI.key] = toWeights(genes, battler.AI)
    return getWinningRate(params)
  end
  local ga = GeneticAlgorithm(length, 0, 1, getFitness)
  local pop = battler.AI:loadJsonData('_pop') or ga:newPopulation(20)
  for i = 1, generations do
    pop = ga:evolvePopulation(pop)
  end
  battler.AI:saveJsonData(pop, '_pop')
end
