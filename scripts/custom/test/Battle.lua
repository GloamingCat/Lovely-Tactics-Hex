
--[[===============================================================================================

Battle Test
---------------------------------------------------------------------------------------------------
Starts a battle when this collides with player.

=================================================================================================]]

return function(script)
  
  Fiber:wait()

  if script.char.deleted then
    -- Already dead
    return
  end

  if script.char.collider ~= 'player' and script.char.collided ~= 'player' then
    -- Collided with something else
    return
  end
  
  if script.vars.onBattle then
    goto afterBattle
  end
  
  FieldManager.player:playIdleAnimation()
  
  if not FieldManager.playerInput then
    -- Player is busy with something else.
    return
  end
  
  do
    local gameOverCondition = 1
    local conditionName = (script.args.gameOverCondition or ''):trim():lower()
    if conditionName == 'survive' then
      gameOverCondition = 2 -- Must win.
    elseif conditionName == 'kill' then
      gameOverCondition = 1 -- Must win or draw.
    elseif conditionName == 'none' then
      gameOverCondition = 0 -- Never gets a game over.
    end
    script:startBattle { 
      fieldID = tonumber(script.args.fieldID) or 0, 
      fade = 60, 
      intro = true, 
      gameOverCondition = gameOverCondition,
      escapeEnabled = true 
    }
    return
  end
  
  ::afterBattle::
  
  script.char.cooldown = 180

  if BattleManager:playerWon() then
    print 'You won!'
    script:deleteChar { key = "self", permanent = true }
  elseif BattleManager:enemyWon() then
    assert(BattleManager.params.gameOverCondition < 2, "Player shouldn't have the option to continue.")
    print 'You lost...'
  elseif BattleManager:drawed() then
    print 'Draw.'
    script:deleteChar { key = "self", permanent = true }
  elseif BattleManager:playerEscaped() then
    print 'You escaped!'
  elseif BattleManager:enemyEscaped() then
    print 'The enemy escaped...'
    script:deleteChar { key = "self", permanent = true }
  end
  
  --FieldManager.fiberList:forkEvent(script.finishBattle, script, { fade = 60 })
  script:finishBattle { fade = 60 }
  
  Fiber:wait()

end
