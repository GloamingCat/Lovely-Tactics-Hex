

-- Imports
local ScriptNN = require('core/battle/ai/ScriptNN')

local MageScriptNN = class(ScriptNN)

local old_init = MageScriptGA.init
function MageScriptGA:init()
  old_init("MageScript")
end

return MageScriptGA