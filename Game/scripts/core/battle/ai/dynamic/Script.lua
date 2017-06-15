
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

local Script = class(ArtificialInteligence)

function Script:init(key)
  self.key = key
  self.rules = {}
end

-- Generates the ActionInput from the rule and executes it.
-- @param(id : number)
-- @ret(number) the time cost of the action
function Script:executeRule(id)
  local rule = self.rules[id]
  local macro = rule:createMacro()
  -- TODO
end

function Script:loadData()
  return readFile('data/ai/' .. self.key .. '.json')
end

function Script:__tostring()
  return 'Dynamic Script: ' .. self.key
end

return Script
