-- ================================================================================================

--- NPC that walks towards the player.
---------------------------------------------------------------------------------------------------
-- @event Stalker

--- Script parameters.
-- @tags Script
-- @tfield number pause Pause time in frames between each step.
-- @tfield number pauseVar Variation of the pause in frames (optional, 0 by default).
-- @tfield number vision Maximum distance in tiles.

-- ================================================================================================

-- Alias
local rand = love.math.random

return function(script)

  local vision = tonumber(script.args.vision) or 4
  local pause = tonumber(script.args.pause) or 60
  local pauseVar = tonumber(script.args.pauseVar) or 0
  while true do
    if not FieldManager.player:isBusy() and FieldManager.playerInput then
      if script.char.cooldown and script.char.cooldown > 0 then
        script.char.cooldown = script.char.cooldown - GameManager:frameTime() * 60
      else
        if script.char:tryPathMovement(FieldManager.player:getTile(), vision) and script.char:consumePath() then
          script.char:playIdleAnimation()
          script:wait(pause + rand(-pauseVar, pauseVar))
        end
      end
    end
    Fiber:wait()
  end
end
