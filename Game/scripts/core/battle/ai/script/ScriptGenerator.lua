
--[[===============================================================================================

ScriptGenerator
---------------------------------------------------------------------------------------------------
Generates weights for the neural network of an AI script.

=================================================================================================]]

-- Imports
local GeneticAlgorithm = require('core/battle/ai/script/GeneticAlgorithm')
local Battler = require('core/battle/Battler')

-- Alias
local readFile = love.filesystem.read
local writeFile = love.filesystem.write

local ScriptGenerator = class()

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(matches : table) an array of matches, where:
--  matches[i] (odd) is the ID of the battle field
--  matches[i + 1] (even) if the party ID of the generated AI
-- @param(repeats : number) the number of times each match will be played
-- @param(battlerID : number) the ID of the battler in which the generated AI will be used
function ScriptGenerator:init(matches, repeats, battlerID)
  self.matches = matches
  self.repeats = repeats
  self.battlerID = battlerID
end

---------------------------------------------------------------------------------------------------
-- Evaluation
---------------------------------------------------------------------------------------------------

-- Converts a gene to network weights.
-- @param(genes : table) the array of genes
-- @param(net : NeuralNetwork) the neural network in which the weights will be used
-- @ret(table) a table with the matrix of input weights and the matrix of hidden weights
function ScriptGenerator:toWeights(genes, net)
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
function ScriptGenerator:getWinningRate(params)
  local victories = 0
  local total = 0
  for i = 1, #self.matches, 2 do
    for k = 1, self.repeats do 
      local winner = FieldManager:loadBattle(self.matches[i], params)
      if winner == self.matches[i + 1] then
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
function ScriptGenerator:test(skipAnimations)
  local winner = FieldManager:loadBattle(self.matches[1], { skipAnimations = skipAnimations })
  print('Test Winner: ' .. winner)
  return winner == self.matches[2]
end

---------------------------------------------------------------------------------------------------
-- Generation
---------------------------------------------------------------------------------------------------

function ScriptGenerator:createGA()
  -- Gets the network AI
  local battler = Battler(nil, self.battlerID, -1)
  assert(battler.AI.network, 'Battler ' .. self.battlerID .. ' (' .. 
    battler.data.name .. ') does not have a neural network AI.')
  -- Genetic Algorithm args
  local ic = battler.AI.network.inputCount
  local nc = battler.AI.network.neuronCount
  local oc = battler.AI.network.outputCount
  local length = ic * nc + nc * oc
  local params = { skipAnimations = true }
  --- Fitness function
  local function getFitness(genes)
    params[battler.AI.key] = self:toWeights(genes, battler.AI.network)
    local fitness = self:getWinningRate(params, battler.AI.key)
    print(fitness)
    return fitness
  end
  return GeneticAlgorithm(length, -1, 1, getFitness), battler
end

function ScriptGenerator:generateFittest(AI, ga, key, lastFittest)
  -- Generates better population
  local pop = ga:newPopulation()
  pop = ga:evolvePopulation(pop)
  local fittest = ga:getFittest(pop)
  -- Saves fittest
  if lastFittest == nil or fittest.fitness > lastFittest.fitness then
    local weights = self:toWeights(fittest, AI.network)
    AI:saveJsonData(weights)
    lastFittest = fittest
  end
  -- Save generations logs
  if key then
    ga:saveLog(AI.key .. '_gen_' ..  key)
  end
  return lastFittest
end

-- Generates the weights and saves in the file.
function ScriptGenerator:generateSingle()
  local ga, battler = self:createGA()
  ga.mutationRate = 0.0625
  ga.populationSize = 10
  ga.tournamentSize = 5
  return self:generateFittest(battler.AI, ga)
end

-- Generates the weights and saves in the file, with parameters variation.
function ScriptGenerator:generateAll() 
  local ga, battler = self:createGA()
  local fittest = nil
  for mutation = 0.0625, 0.25, 0.0625 do
    for popSize = 10, 20, 5 do
      for tournament = 0, popSize, 5 do
        ga.mutationRate = mutation
        ga.populationSize = popSize
        ga.tournamentSize = tournament
        local key = mutation .. '_' .. popSize .. '_' .. tournament
        fittest = self:generateFittest(battler.AI, ga, key, fittest)
      end
    end
  end
  return fittest
end

return ScriptGenerator
