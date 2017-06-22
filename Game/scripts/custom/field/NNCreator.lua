
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
local battlerID = 5
local matches = { 1, 0 }
local repeats = 5
local generations = 10

---------------------------------------------------------------------------------------------------
-- Evaluation
---------------------------------------------------------------------------------------------------

-- Converts a gene to network weights.
-- @param(genes : table) the array of genes
-- @param(net : NeuralNetwork) the neural network in which the weights will be used
-- @ret(table) a table with the matrix of input weights and the matrix of hidden weights
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
  local hiddenWeights = net:newLayer(net.neuronCount, net.outputCount, 0)
  for i = 1, net.outputCount do
    for j = 1, net.neuronCount do
      hiddenWeights[i][j] = genes[(i - 1) * net.neuronCount + j + off]
    end
  end
  return { inputWeights, hiddenWeights }
end

-- Runs battles to get the winning rates, using the specified matches.
--  Each match[i] is the ID of the field;
--  and each match[i + 1] is the party to check the winning rate.
-- @param(param : table) battle params
-- @ret(number) the percentage of victory
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

-- Tests the generated AI.
-- @param(skipAnimations : boolean)
-- @ret(boolean) true if the party to check actually won
local function test(skipAnimations)
  local winner = FieldManager:loadBattle(matches[1], { skipAnimations = skipAnimations })
  print('Test Winner: ' .. winner)
  return winner == matches[2]
end

---------------------------------------------------------------------------------------------------
-- Generation
---------------------------------------------------------------------------------------------------

-- Generates the weights and saves in the file.
local function generate() 
  
  -- Gets the network AI
  local battler = Battler(nil, battlerID, -1)
  assert(battler.AI.network, 'Battler ' .. battlerID .. ' (' .. 
    battler.data.name .. ') does not have a neural network AI.')
  
  -- Genetic Algorithm args
  local ic = battler.AI.network.inputCount
  local nc = battler.AI.network.neuronCount
  local oc = battler.AI.network.outputCount
  local length = ic * nc + nc * oc
  local params = { skipAnimations = true }
  local function getFitness(genes)
    params[battler.AI.key] = toWeights(genes, battler.AI.network)
    local fitness = getWinningRate(params, battler.AI.key)
    print(fitness)
    return fitness
  end
  
  -- Initialization
  local ga = GeneticAlgorithm(length, 0, 1, getFitness)
  local pop = battler.AI:loadJsonData('_pop') or ga:newPopulation(10)
  
  repeat
    -- Generates better population
    pop = ga:evolvePopulation(pop)
    
    -- Clear and save individuals
    local fittest = ga:getFittest(pop)
    for i = 1, #pop do
      pop[i].fitness = nil
    end
    
    -- Saves the weights and population in a file
    local weights = toWeights(fittest, battler.AI.network)
    battler.AI:saveJsonData(weights)
    battler.AI:saveJsonData(pop, '_pop')
    
    -- Tests the result
    local testWinner = test(true)
  until testWinner
end

---------------------------------------------------------------------------------------------------
-- Run
---------------------------------------------------------------------------------------------------

return function()
  generate()
  test()
end
