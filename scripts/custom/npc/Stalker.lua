-- ================================================================================================

--- NPC that walks towards the player.
---------------------------------------------------------------------------------------------------
-- @event Stalker

--- Script parameters.
-- @tags Script
-- @tfield[opt=60] number pause Pause time in frames between each step.
-- @tfield[opt=0] number pauseVar Variation of the pause in frames.
-- @tfield[opt=4] number vision Maximum distance in tiles.

-- ================================================================================================

-- Alias
local rand = love.math.random

return function(script)

  local vision = tonumber(script.args.vision) or 4
  local pause = tonumber(script.args.pause) or 60
  local pauseVar = tonumber(script.args.pauseVar) or 0
  while true do
    if not FieldManager.player:isBusy() and FieldManager.playerInput then
      if script.char.vars.cooldown and script.char.vars.cooldown > 0 then
        script.char.vars.cooldown = script.char.vars.cooldown - GameManager:frameTime() * 60
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
