
--[[===============================================================================================

ScriptGA
---------------------------------------------------------------------------------------------------
A script with a pre-defined set of rules.
Here, each rule have priorities, and the priority is generated with a Generic Algorithm.

=================================================================================================]]

-- Imports
local ArtificialInteligence = require('core/battle/ai/ArtificialInteligence')

local ScriptGA = class(ArtificialInteligence)

-- @param(key : string)
local old_init 
function ScriptGA:init(key, priorities)
  old_init(self, key)
  self.priorities = priorities or JSON.decode(self:loadData())
end

-- Loads priority data from file.
function ScriptGA:loadPriorities()
  local json = 
  self.priorites = JSON.decode(json)
end

function ScriptGA:nextAction(user)
  
end

return ScriptGA
