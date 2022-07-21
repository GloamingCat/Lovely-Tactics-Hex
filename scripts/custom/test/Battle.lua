
--[[===============================================================================================

Battle Test
---------------------------------------------------------------------------------------------------
Starts a battle when this collides with player.

=================================================================================================]]

return function(script)
  
  coroutine.yield()

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
  end
  
  ::afterBattle::
  
  script.char.cooldown = 180

  if BattleManager:playerWon() then
    print 'You won!'
    FieldManager.fiberList:fork(script.deleteChar, script, { key = "self", fade = 60, permanent = true })
  elseif BattleManager:enemyWon() then
    assert(script.args.loseEnabled, "Player shouldn't have the option to continue.")
    print 'You lost...'
  elseif BattleManager:drawed() then
    print 'Draw.'
    FieldManager.fiberList:fork(script.deleteChar, script, { key = "self", fade = 60, permanent = true })
  elseif BattleManager:playerEscaped() then
    print 'You escaped!'
  elseif BattleManager:enemyEscaped() then
    print 'The enemy escaped...'
    FieldManager.fiberList:fork(script.deleteChar, script, { key = "self", fade = 60, permanent = true })
  end
  
  script:finishBattle { fade = 60 }

end
