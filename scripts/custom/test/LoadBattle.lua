
-- ================================================================================================

--- Test script that starts battle when field is loaded.
---------------------------------------------------------------------------------------------------
-- @event LoadBattle

-- ================================================================================================

return function(script)

  --- Contains the tags from the Script's data.
  -- @table param
  -- @tfield string gameOverCondition The condition to block the "Continue" option from
  --  the Game Over screen (optional, "survive" by default).
  local param = script.args
    
  script:addEvent(function()
    script:addMember { key = 'Test' }
    script:hideMember { key = 'Arthur' }
  end)

  script:addEvent(script.startBattle, nil, {
    intro = true,
    escapeEnabled = true,
    gameOverCondition = param.gameOverCondition or 'survive',
    fieldID = 7,
    fade = 60
  })

  script:addEvent(script.finishBattle, nil, { fade = 60, wait = true })
  
  script:addEvent(function()
    script:hideMember { key = 'Test' }
    script:addMember { key = 'Arthur' }
    FieldManager.hud:show()
  end)

end
