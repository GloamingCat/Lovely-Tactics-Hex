
return function(script)
  
  -- Event 1: play animation on collision
  script:addEvent(function()
    local char = FieldManager:search(script.char.collided)
    if char then
      char:playIdleAnimation()
    end
  end)
  
  -- Event 2: start battle
  script:addEvent(script.startBattle,
  FieldManager.playerInput and script:collidedWith('player'),
  {
    intro = true,
    escapeEnabled = true,
    gameOverCondition = script.args.gameOverCondition or 'survive',
    fieldID = tonumber(script.args.fieldID) or 0,
    fade = 60
  })

  -- Event 3: aftermath
  script:addEvent(function()
    if BattleManager:playerEscaped() then
      script.char.cooldown = 180
    else
      script:deleteChar { permanent = true, key = 'self' }
    end
    script:finishBattle { fade = 60, wait = true }
    print(script.battleLog)
  end)
  
end
