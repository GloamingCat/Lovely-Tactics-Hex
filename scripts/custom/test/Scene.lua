
-- ================================================================================================

--- Pre-battle cutscene test.
---------------------------------------------------------------------------------------------------
-- @event Scene

-- ================================================================================================

return function(script)

  script:showDialogue { id = 1, character = "Arthur", portrait = "BigIcon", message = 
    Vocab.dialogues.scene.ThisIsA
  }
  
  script:closeDialogueWindow { id = 1 }
  
end
