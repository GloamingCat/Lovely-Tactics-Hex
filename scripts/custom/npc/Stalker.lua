--[[===============================================================================================

Stalker
---------------------------------------------------------------------------------------------------
NPC that walks towards the player.

-- Arguments:
<pause> Pause in frames between each step.
<pauseVar> Variation of the pause in frames.

=================================================================================================]]

-- Alias
local rand = love.math.random

return function(script)
  local pause = tonumber(script.args.pause) or 60
  local pauseVar = tonumber(script.args.pauseVar) or 0
  while true do
    script.char:playIdleAnimation()
    if script.char.cooldown and script.char.cooldown > 0 then
      script.char.cooldown = script.char.cooldown - GameManager:frameTime() * 60
    elseif not FieldManager.player:isBusy() and FieldManager.player.blocks == 0 then
      script:wait(pause + rand(-pauseVar, pauseVar))
      script.char:turnToPoint(FieldManager.player.position.x, FieldManager.player.position.z)
      script.char:tryAngleMovement(script.char:getRoundedDirection())
    end
    coroutine.yield()
  end
end
