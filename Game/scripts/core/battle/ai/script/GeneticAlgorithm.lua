
--[[===============================================================================================

GeneticAlgorithm
---------------------------------------------------------------------------------------------------
An implementation of a generic genetic algorithm.

=================================================================================================]]

-- Alias
local rand = love.math.random
local writeFile = love.filesystem.write
local arrayMax = util.arrayMax
local arrayMean = util.arrayMean

local GeneticAlgorithm = class()

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- @param(geneLength : number) the number of genes per individual
-- @param(geneMin : number) the minimum value of a gene
-- @param(geneMax : number) the maximum value of a gene
-- @param(fitnessFunc : function) the fitness evaluator of an individual;
-- @param(integer : boolean) true if the genes are integers (optional, float genes by default)
--  must take a single array of genes as argument and return a number
function GeneticAlgorithm:init(geneLength, geneMin, geneMax, fitnessFunc, integer)
  self.geneLength = geneLength
  self.geneMin = geneMin
  self.geneMax = geneMax
  self.elitism = true
  self.maxGenerations = 40
  self.minFitness = 1
  self.mutationRate = 0.025
  self.populationSize = 10
  self.tournamentSize = 5
  self.getFitness = fitnessFunc
  if integer then
    self.randomGene = self.integerGene
  else
    self.randomGene = self.floatGene
  end
  self.log = {}
end

-- Creates a new population of random individuals.
-- @param(size : number) number of individuals
-- @ret(table) array of individuals
function GeneticAlgorithm:newPopulation()
  local p = {}
  for i = 1, self.populationSize do
    p[i] = self:newIndividual()
  end
  return p
end

-- Creates a new individual with random or given genes.
-- @param(original : table) original array of genes to be copied (optional)
-- @ret(table) the array of genes
function GeneticAlgorithm:newIndividual(original)
  local genes = {}
  if original then
    for i = 1, self.geneLength do
      genes[i] = original[i]
    end
  else
    for i = 1, self.geneLength do
      genes[i] = self:randomGene()
    end
  end
  return genes
end

-- Creates a new random gane.
-- @ret(number) the value of the gene
function GeneticAlgorithm:integerGene()
  return rand(self.geneMin, self.geneMax)
end

-- Creates a new random gane.
-- @ret(number) the value of the gene
function GeneticAlgorithm:floatGene()
  return rand() * (self.geneMax - self.geneMin) + self.geneMin
end

---------------------------------------------------------------------------------------------------
-- Log
---------------------------------------------------------------------------------------------------

-- Adds new fitness log to the log array.
-- @param(p : table) the population after calculating fitness
-- @param(i : number) the generation index
function GeneticAlgorithm:logFitness(p, i)
  local fit = {}
  for i = 1, #p do
    fit[i] = p[i].fitness
  end
  self.log[i] = fit
end

-- Saves log in a file.
-- @param(key : string) the base of the file name
function GeneticAlgorithm:saveLog(key)
  local max, mean = '', ''
  for i = 1, #self.log do
    max = max .. i .. ' ' .. arrayMax(self.log[i]) .. '\n'
    mean = mean .. i .. ' ' .. arrayMean(self.log[i]) .. '\n'
  end
  writeFile(key .. '_max.txt', max)
  writeFile(key .. '_mean.txt', mean)
end

---------------------------------------------------------------------------------------------------
-- Evolution
---------------------------------------------------------------------------------------------------

-- Evaluates the individuals and gets the fittest.
-- @param(p : table) an array of individuals
-- @ret(table) the best individual as an array of genes
-- @ret(number) the index of the individual in the population
function GeneticAlgorithm:getFittest(p)
  local fittest = 1
  p[fittest].fitness = p[fittest].fitness or self.getFitness(p[fittest])
  for i = 2, #p do
    local ind = p[i]
    ind.fitness = ind.fitness or self.getFitness(ind)
    if ind.fitness > p[fittest].fitness then
      fittest = i
    end
  end
  return p[fittest], fittest
end

-- Creates a new population starting from the given one.
-- It stops evolving when the maximum number of generations is reached or
-- there's an individual with the minimum fitness value.
-- @param(p : table) array of individuals
-- @ret(table) a new array of individuals
-- @ret(number) the number of generations taken to reach the new population
function GeneticAlgorithm:evolvePopulation(p)
  for i = 1, self.maxGenerations do
    -- Get fittest individual
    local fittest, j = self:getFittest(p)
    print('Fittest: ' .. fittest.fitness, 'Generation: ' .. i)
    self:logFitness(p, i)
    if fittest.fitness >= self.minFitness then
      return p, i
    end
    -- Reserves fittest
    local newp = {}
    local elitismOffset = 1
    if self.elitism then
      p[1], p[j] = p[j], p[1]
      newp[1] = fittest
      elitismOffset = 2
    end
    -- Crossover
    if self.tournamentSize > 0 then
      for i = elitismOffset, #p do
        newp[i] = self:crossover(p)
      end
    else
      for i = elitismOffset, #p do
        newp[i] = p[i]
      end
    end
    -- Mutation
    for i = elitismOffset, #newp do
      self:mutate(newp[i])
    end
    p = newp
  end
  return p, self.maxGenerations + 1
end

---------------------------------------------------------------------------------------------------
-- Operator
---------------------------------------------------------------------------------------------------

-- Mutates the given individual.
-- @param(ind : table) the individual as array of genes
function GeneticAlgorithm:mutate(ind)
  for i = 1, #ind do
    if rand() <= self.mutationRate then
      ind[i] = self:randomGene()
    end
  end
  ind.fitness = nil
end

-- Selects the fittest individual random a sub-population of the given population.
-- @param(p : table) the population as an array of individuals
-- @ret(table) the fittest individual as an array of genes
function GeneticAlgorithm:tournamentSelection(p)
  local newp = {}
  for i = 1, self.tournamentSize do
    local r = rand(#p)
    newp[i] = p[r]
  end
  return self:getFittest(newp)
end

-- Creates a new individual from a crossover of two selected parent from the given population.
-- @param(p : table) the population as an array of individuals
-- @ret(table) the new individual
function GeneticAlgorithm:crossover(p)
  local ind1 = self:tournamentSelection(p)
  local ind2 = self:tournamentSelection(p)
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

return GeneticAlgorithm
