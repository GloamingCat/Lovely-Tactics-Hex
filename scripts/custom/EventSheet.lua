
--[[===============================================================================================

@script EventSheet
---------------------------------------------------------------------------------------------------
-- Execute an event sheet from the database. 
-- 
-- Parameters:
--  * <sheet> is the ID or key of the sheet to be executed.

=================================================================================================]]

return function (script)
  
  local data = Database.events[script.args.sheet]
  
  for _, e in ipairs(data.events) do
    local args = Database.loadTags(e.tags)
    local condition = e.condition ~= '' and loadformula(e.condition, 'script')
    if e.name == 'setLabel' then
      if not condition or condition(script) then
        script:setLabel(args.name, args.index)
      end
    else
      if e.name == 'skipEvents' then
        args = args.events
      elseif e.name == 'setEvent' then
        args = args.index
      elseif e.name == 'jumpTo' then
        args = args.name
      end
      script:addEvent(e.name, condition or nil, args)
    end
  end

end