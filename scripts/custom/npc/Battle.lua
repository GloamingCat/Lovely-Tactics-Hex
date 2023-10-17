
-- ================================================================================================

--- Checks whether the enemy was already defeated.
-- 
-- Parameters:
--  * <fieldID> The ID of the battle field.
--  * <gameOverCondition> The conditions to lose or win the battle:
--      * 'none' -> There is no gameover regardless of who wins;
--      * 'survive' -> The game is over if the player loses;
--      * 'kill' -> The game is over if the player loses or it's a draw.
-- ------------------------------------------------------------------------------------------------
-- @event Battle

-- ================================================================================================

return function(script)
  
  -- Event 1: start battle
  script:addEvent(function()
    if FieldManager.playerInput and script:collidedWith('player') then
      FieldManager.player:playIdleAnimation()
      script:turnCharTile { key = 'self', other = 'player' }
      script:turnCharTile { key = 'player', other = 'self' }
      script:showEmotionBalloon { key = script.char.collided, emotion = '!' }
      Fiber:wait(30)
      script:startBattle {
        intro = true,
        escapeEnabled = true,
        gameOverCondition = script.args.gameOverCondition or 'survive',
        fieldID = tonumber(script.args.fieldID) or 0,
        fade = 60
      }
    else
      script:skip(1)
    end
  end)

  -- Event 2: aftermath
  script:addEvent(function()
    local escaped = BattleManager:playerEscaped()
    if escaped then
      script.char.cooldown = 180
    else
      script:hideChar { deactivate = script.args.deactivate, key = 'self' }
    end
    script:finishBattle { fade = 60, wait = true }
    print(script.battleLog)
    if not escaped then
      script.char.vars.defeated = true
      script:deleteChar { permanent = script.args.permanent, key = 'self' }
    end
  end)
  
end
