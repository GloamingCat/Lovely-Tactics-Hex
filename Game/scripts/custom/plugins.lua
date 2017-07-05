
--[[===============================================================================================

Insert in the plugins list the plugin names to be loaded and their arguments.
Example:
  { 'plugin1', { a = 10, b = 'hello' } }
The second value may be nil/empty if it is not used in the plugin.

=================================================================================================]]

local plugins = {
  -- { 'plugin1', { a = 10, b = 'hello' } },
  -- { 'plugin2', { c = 20, d = 'world' } },
  -- { 'plugin3' }
}

---------------------------------------------------------------------------------------------------
-- Load
---------------------------------------------------------------------------------------------------

for i = 1, #plugins do
  local path = 'custom/plugins/' .. plugins[i][1]
  loadfile(path, plugins[i][2])
end