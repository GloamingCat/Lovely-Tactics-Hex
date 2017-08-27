
--[[===============================================================================================

Insert in the plugins list the plugin names to be loaded and their arguments.
Example:
  { 'plugin1', { a = 10, b = 'hello' } }
The second value may be nil/empty if it is not used in the plugin.

=================================================================================================]]

local killCheat = { 'KillCheat', on = true,
  key = 'k'
}

local individualTurn = { 'IndividualTurn', on = true,
  attName = 'AGI',
  turnLimit = 2000,
  turnBarAnim = false
}

local removeStatusOnDamage = { 'RemoveStatusOnDamage', on = true }

---------------------------------------------------------------------------------------------------
-- Plugin list
---------------------------------------------------------------------------------------------------

local plugins = { killCheat, individualTurn, removeStatusOnDamage }

---------------------------------------------------------------------------------------------------
-- Load
---------------------------------------------------------------------------------------------------

for i = 1, #plugins do
  args = plugins[i]
  if args.on then
    require('custom/plugins/' .. args[1])
  end
end
args = nil
