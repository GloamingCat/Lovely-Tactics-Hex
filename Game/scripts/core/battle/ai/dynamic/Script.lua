
--[[===============================================================================================

Script
---------------------------------------------------------------------------------------------------
A base for dynamic scripts that rely on rule database.
Must override the init method to create the rules.

=================================================================================================]]

-- Imports
local ArtificialInteligence = require('core/battle/ai/ArtificialInteligence')

-- Alias
local readFile = love.filesystem.read
local writeFile = love.filesystem.write

local Script = class(ArtificialInteligence)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

function Script:init(key)
  self.key = key
  self.rules = self:createRules()
end

-- Creates the set of rules of this script.
function Script:createRules()
  return nil -- Abstract.
end

function Script:__tostring()
  return 'Dynamic Script: ' .. self.key
end

---------------------------------------------------------------------------------------------------
-- Execution
---------------------------------------------------------------------------------------------------

-- Generates the ActionInput from the rule and executes it.
-- @param(id : number)
-- @ret(number) the time cost of the action, or nil if rule could not execute
function Script:executeRule(id)
  local rule = self.rules[id]
  return rule:execute()
end

---------------------------------------------------------------------------------------------------
-- Script Data
---------------------------------------------------------------------------------------------------

-- Loads the file from AI data folder.
-- @ret(string) the data in the file
function Script:loadData()
  return readFile('data/ai/' .. self.key .. '.json')
end

-- Loads the file from AI data folder.
-- @param(data : string) the data to write
function Script:saveData(data)
  return writeFile('data/ai/' .. self.key .. '.json', data)
end

return Script
