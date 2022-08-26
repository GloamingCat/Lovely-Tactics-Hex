
--[[===============================================================================================

Battle Test
---------------------------------------------------------------------------------------------------
Starts a battle when this collides with player.

=================================================================================================]]

return function(script)
  
  Fiber:wait()

  if script.char.collider ~= 'player' and script.char.collided ~= 'player' then
    -- Collided with something else
    return
  end
  
  if not script.vars.onBattle then
    
    FieldManager.player:playIdleAnimation()
    
    if not FieldManager.playerInput then
      -- Player is busy with something else.
      return
    end
    
    script:startBattle { 
      fieldID = tonumber(script.args.fieldID) or 0, 
      fade = 60, 
      intro = true, 
      gameOverCondition = script.args.gameOverCondition,
      escapeEnabled = true 
    }

  else
    
    if not BattleManager:enemyWon() and not BattleManager:playerEscaped() then
      script:deleteChar { key = "self", permanent = true }
    end
    
    script:finishBattle { 
      fade = 60, 
      wait = true,
      cooldown = 180
    }
    
    Fiber:wait()
  
  end

end
