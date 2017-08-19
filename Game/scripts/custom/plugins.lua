
--[[===============================================================================================

Insert in the plugins list the plugin names to be loaded and their arguments.
Example:
  { 'plugin1', { a = 10, b = 'hello' } }
The second value may be nil/empty if it is not used in the plugin.

=================================================================================================]]

local killCheat = { 'KillCheat',
  key = 'k'
}

local individualTurn = { 'IndividualTurn',
  attName = 'AGI',
  turnLimit = 2000,
  turnBarAnim = false
}

---------------------------------------------------------------------------------------------------
-- Plugin list
---------------------------------------------------------------------------------------------------

local plugins = { killCheat, individualTurn }

---------------------------------------------------------------------------------------------------
-- Load
---------------------------------------------------------------------------------------------------

for i = 1, #plugins do
  --local path = 'scripts/custom/plugins/' .. plugins[i][1] .. '.lua'
  --loadfile(path)(plugins[i])
  args = plugins[i]
  require('custom/plugins/' .. plugins[i][1])
end
args = nil
