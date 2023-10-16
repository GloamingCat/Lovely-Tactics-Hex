
--[[===============================================================================================

@script Scene
---------------------------------------------------------------------------------------------------
-- Pre-battle cutscene test.

=================================================================================================]]


return function(script)

  script:showDialogue { id = 1, character = "Arthur", portrait = "BigIcon", message = 
    Vocab.dialogues.scene.ThisIsA
  }
  
  script:closeDialogueWindow { id = 1 }
  
end
