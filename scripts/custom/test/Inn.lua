
--[[===============================================================================================

@script Inn
---------------------------------------------------------------------------------------------------

=================================================================================================]]

return function(script)

  -- Event 1: choice
  script:addEvent(function()
    script:stopChar { key = 'player' }
    script:turnCharTile { key = 'player', other = 'self' }
    AudioManager:playSFX { name = 'buttonConfirm', pitch = 100, volume = 100 }
    script:showMessage { id = 3, wait = false, width = 180, height = 60, message = 
      Vocab.dialogues.npc.Inn
    }
    script:openChoiceWindow { width = 70, y = 60,
      choices = {
        'yes',
        'no'
      }
    }
    script:closeMessageWindow { id = 3 }
  end)

  -- Event 2: Heal
  script:addEvent(function()
    script:fadeout { time = 60, wait = true }
    AudioManager:playSFX { name = 'heal', pitch = 100, volume = 100 }
    script:wait(90)
    script:healAll { status = { 0, 1, 17, 18, 15, 16 } }
    script:fadein { time = 60, wait = true }
    script:showMessage { id = 3, wait = true, width = 180, height = 60, message = 
      Vocab.dialogues.npc.Healed
    }
    AudioManager:playSFX { name = 'buttonConfirm', pitch = 100, volume = 100 }
    script:closeMessageWindow { id = 3 }
  end, 
  function() return script.char.vars.choiceInput == 1 end)

end
