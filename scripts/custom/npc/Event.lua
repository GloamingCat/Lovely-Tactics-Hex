
--[[===============================================================================================

Event
---------------------------------------------------------------------------------------------------
Executes a generic command.

-- Arguments:
<command> The code string that goes inside the function. Can have multiple.
<condition> A boolean expression. If defined, the command will only execute if the expression
returns true.

Both functions receive a <script> argument.

=================================================================================================]]

return function(script)
  if script.args.condition then
    local func = loadformula(script.args.condition, 'script')
    if not func(script) then
      return
    end
  end
  local commands = script.args:getAll('command')
  for i = 1, #commands do
    loadfunction(commands[i], 'script')(script)
  end
end
