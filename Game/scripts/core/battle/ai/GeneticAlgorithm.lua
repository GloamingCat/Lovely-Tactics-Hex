
--[[===============================================================================================

NeuralNetwork
---------------------------------------------------------------------------------------------------
Generic implementation of a neural network.
The bias is optional and must be added manually in the inputs.

=================================================================================================]]

local rand = love.math.random

local GeneticAlgorithm = class()

function GeneticAlgorithm:init(geneLength, geneMin, geneMax, fitnessFunction)
  self.geneLength = geneLength
  self.geneMin = geneMin
  self.geneMax = geneMax
  self.mutationRate = 0.015
  self.tournamentSize = 5
  self.elitism = true
  self.getFitness = fitnessFunction
end

function GeneticAlgorithm:newPopulation(size)
  local p = {}
  for i = 1, size do
    p[i] = self:newIndividual()
  end
  return p
end

function GeneticAlgorithm:randomGene()
  return rand() * (self.geneMax - self.geneMin) + self.geneMin
end

function GeneticAlgorithm:newIndividual()
  local genes = {}
  for i = 1, self.geneLength do
    genes[i] = self:randomGene()
  end
  return genes
end

function GeneticAlgorithm:getFittest(p)
  local fittest = p[1]
  fittest.fitness = fittest.fitness or self.getFitness(fittest)
  for i = 2, #p do
    local ind = p[i]
    ind.fitness = ind.fitness or self.getFitness(ind)
    if ind.fitness > fittest.fitness then
      fittest = ind
    end
  end
  return fittest
end

function GeneticAlgorithm:evolvePopulation(p)
  local newp = {}
  local elitismOffset = 0
  if self.elitism then
    newp[1] = self:getFittest(p)
    elitismOffset = 1
  end
  for i = elitismOffset, #p do
    local ind1 = self:tournamentSelection(p)
    local ind2 = self:tournamentSelection(p)
    local newInd = self:crossover(ind1, ind2)
    newp[i] = newInd
  end
  for i = elitismOffset, #newp do
    self:mutate(newp[i])
  end
  return newp
end

function GeneticAlgorithm:tournamentSelection(p)
  local newp = {}
  for i = 1, self.tournamentSize do
    local r = rand(#p)
    newp[i] = p[r]
  end
  return self:getFittest(newp)
end

function GeneticAlgorithm:crossover(ind1, ind2)
  local newInd = {}
  for i = 1, self.geneLength do
    if rand() <= 0.5 then
      newInd[i] = ind1[i]
    else
      newInd[i] = ind2[i]
    end
  end
  return newInd
end

function GeneticAlgorithm:mutate(ind)
  for i = 1, #ind do
    if rand() <= self.mutationRate then
      ind[i] = self:randomGene()
    end
  end
  ind.fitness = nil
end

return GeneticAlgorithm
