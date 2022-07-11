
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

  if script.char.cooldown and script.char.cooldown > 0 then
    -- After-battle cooldown (escape or lose)
    script.char.cooldown = script.char.cooldown - GameManager:frameTime() * 60
  end

  if script.collider ~= script.player and script.collided ~= script.player then
    -- Collided with something else
    return
  end
  
  if script.player:isBusy() or script.player.blocks > 1 then
    -- Player is moving, on battle, or waiting for GUI input
    return
  end
  
  script.player:playIdleAnimation()
  local previousBgm = AudioManager:pauseBGM()
  script:startBattle { 
    fieldID = tonumber(script.args.fieldID) or 0, 
    fade = 60, 
    intro = true, 
    gameOverCondition = script.args.loseEnabled == 'true' and 0 or 1, 
    escapeEnabled = true 
  }
  if previousBgm then
    AudioManager:playBGM(previousBgm)
  end
  
  script.char.cooldown = 120
  if BattleManager:playerWon() then
    print 'You won!'
    FieldManager.fiberList:fork(script.deleteChar, script, { key = "self", fade = 60, permanent = true })
  elseif BattleManager:enemyWon() then
    print 'You lost...'
  elseif BattleManager:drawed() then
    print 'Draw.'
  elseif BattleManager:playerEscaped() then
    print 'You escaped!'
  elseif BattleManager:enemyEscaped() then
    print 'The enemy escaped...'
    FieldManager.fiberList:fork(script.deleteChar, script, { key = "self", fade = 60, permanent = true })
  end

end
