
-- ================================================================================================

--- Checks whether the enemy was already defeated.
---------------------------------------------------------------------------------------------------
-- @event Battle

-- ================================================================================================

return function(script)

  --- Contains the tags from the Script's data.
  -- @table param
  -- @tfield number fieldID The ID of the battle field.
  -- @tfield BattleManager.GameOverCondition|GeneralEvents.VictoryCondition gameOverCondition The condition to block the "Continue" option from
  --  the Game Over screen (optional, "survive" by default).
  -- @tfield boolean deactivate Flag to deactivate the character's script when its hidden.
  -- @tfield boolean permanent Flag to permanently remove the character if the player wins.
  -- @tfield number cooldown Time in frames to wait after the player escapes (optional, 180 by default).
  local param = script.args

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
        gameOverCondition = param.gameOverCondition or 'survive',
        fieldID = param.fieldID or 0,
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
      script.char.cooldown = param.cooldown or 180
    else
      script:hideChar { deactivate = param.deactivate, key = 'self' }
    end
    script:finishBattle { fade = 60, wait = true }
    print(script.battleLog)
    if not escaped then
      script.char.vars.defeated = true
      script:deleteChar { permanent = param.permanent, key = 'self' }
    end
  end)
  
end
