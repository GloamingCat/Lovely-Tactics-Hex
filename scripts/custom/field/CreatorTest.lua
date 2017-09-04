
--[[===============================================================================================

CreatorTest
---------------------------------------------------------------------------------------------------
A script to test the ScriptGenerator.

=================================================================================================]]

-- Imports
local ScriptGenerator = require('core/battle/ai/script/ScriptGenerator')

-- Constants
local matches = { 1, 1 }
local repeats = 5
local battlerID = 5

---------------------------------------------------------------------------------------------------
-- Run
---------------------------------------------------------------------------------------------------

return function()
  local generator = ScriptGenerator(matches, repeats, battlerID)
  generator:generateAll()
  local v = 0
  for i = 1, 100 do
    if generator:test(true) then
      v = v + 1
    end
  end
  print(v)
end
