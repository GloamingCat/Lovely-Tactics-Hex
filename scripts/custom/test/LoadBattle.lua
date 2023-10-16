
--[[===============================================================================================

@script LoadBattle
---------------------------------------------------------------------------------------------------
Test script that starts battle when field is loaded.

=================================================================================================]]

return function(script)
    
  script:addEvent(function()
    script:addMember { key = 'Test' }
    script:hideMember { key = 'Arthur' }
  end)

  script:addEvent(script.startBattle, nil, {
    intro = true,
    escapeEnabled = true,
    gameOverCondition = script.args.gameOverCondition or 'survive',
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
