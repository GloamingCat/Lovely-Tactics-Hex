
-- ================================================================================================

--- Test script that starts battle when field is loaded.
---------------------------------------------------------------------------------------------------
-- @event LoadBattle

--- Script parameters.
-- @tags Script
-- @tfield[opt="survive"] string gameOverCondition The condition to block the "Continue" option
--  from the Game Over screen.

-- ================================================================================================

return function(script)
    
  script:addEvent(function()
    script:addMember { key = 'Test' }
    script:hideMember { key = 'Arthur' }
  end)

  script:addEvent(script.runBattle, nil, {
    skipIntro = false,
    disableEscape = false,
    gameOverCondition = script.args.gameOverCondition or 'survive',
    fieldID = 7,
    fade = 60
  })

  script:addEvent(function()
    script:hideMember { key = 'Test' }
    script:addMember { key = 'Arthur' }
    FieldManager.hud:show()
  end)

end
