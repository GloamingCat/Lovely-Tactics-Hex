
-- ================================================================================================

--- Checks whether the enemy was already defeated.
---------------------------------------------------------------------------------------------------
-- @event Battle

--- Script parameters.
-- @tags Script
-- @tfield[opt=0] number fieldID The ID of the battle field.
-- @tfield[opt="survive"] BattleManager.GameOverCondition|GeneralEvents.VictoryCondition gameOverCondition
--  The condition to block the "Continue" option from the Game Over screen.
-- @tfield[opt] boolean deactivate Flag to deactivate the character's script when its hidden.
-- @tfield[opt] boolean permanent Flag to permanently remove the character if the player wins.
-- @tfield[opt=180] number cooldown Time in frames to wait after the player escapes.

-- ================================================================================================

return function(script)

  local fade = script.args.fade or 60
  local lastBattleTime = fade + 1
  if not FieldManager:loadedFromSave() and GameManager.vars.lastBattle then
    lastBattleTime = GameManager.frame - GameManager.vars.lastBattle
  end

  -- Event 1: start battle
  script:addEvent(function()
    if FieldManager.playerInput and script:collidedWith('player') and lastBattleTime > fade then
      FieldManager.player:playIdleAnimation()
      script:turnCharTile { key = 'self', other = 'player' }
      script:turnCharTile { key = 'player', other = 'self' }
      script:showEmotionBalloon { key = script.char.collided, emotion = '!' }
      Fiber:wait(30)
      script:startBattle {
        skipIntro = false,
        disableEscape = false,
        gameOverCondition = script.args.gameOverCondition or 'survive',
        fieldID = script.args.fieldID or 0,
        fade = fade
      }
    else
      script:skipEvents(1)
    end
  end)

  -- Event 2: aftermath
  script:addEvent(function()
    GameManager.vars.lastBattle = GameManager.frame
    local escaped = BattleManager:playerEscaped()
    if escaped then
      script.char.vars.cooldown = script.args.cooldown or 180
    else
      script:setupChar { visible = false, deactivate = script.args.deactivate, key = 'self' }
    end
    script:finishBattle { fade = fade, wait = true }
    print(script.battleLog)
    if not escaped then
      script.char.vars.defeated = true
      script:deleteChar { permanent = script.args.permanent, key = 'self' }
    end
  end)
  
end
