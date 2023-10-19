
-- ================================================================================================

--- Screen-related functions that are loaded from the EventSheet.
---------------------------------------------------------------------------------------------------
-- @module ScreenEvents

-- ================================================================================================

local ScreenEvents = {}

-- ------------------------------------------------------------------------------------------------
-- Shader Effect
-- ------------------------------------------------------------------------------------------------

--- Shows the effect of a shader.
-- @tparam table args
--  args.name (string): Shader's file name.
--  args.speed (number): Speed of the transition, in a fraction (0 to 1) per second (optional, 1 by default).
function ScreenEvents:shaderin(args)
  ScreenManager.shader = ResourceManager:loadShader(args.name)
  ScreenManager.shader:send('time', 0)
  local time = GameManager:frameTime()
  while time < 1 do
    ScreenManager.shader:send('time', time)
    Fiber:wait()
    time = time + GameManager:frameTime() * (args.speed or 1)
  end
  ScreenManager.shader:send('time', 1)
end
--- Hides the effect of a shader.
-- @tparam table args
--  args.speed (number): Speed of the transition, in a fraction (0 to 1) per second (optional, 1 by default).
function ScreenEvents:shaderout(args)
  ScreenManager.shader:send('time', 1)
  local time = GameManager:frameTime()
  while time > 0 do
    ScreenManager.shader:send('time', time)
    Fiber:wait()
    time = time - GameManager:frameTime() * (args.speed or 1)
  end
  ScreenManager.shader:send('time', 0)
  ScreenManager.shader = nil
end
--- Lightens the screen.
-- @tparam table args
--  args.time (number): Duration of effect in frames.
--  args.wait (boolean): True to wait until effect is finished.
function ScreenEvents:fadein(args)
  FieldManager.renderer:fadein(args.time, args.wait)
end
--- Darkens the screen.
-- @tparam table args
--  args.time (number): Duration of effect in frames.
--  args.wait (boolean): True to wait until effect is finished.
function ScreenEvents:fadeout(args)
  FieldManager.renderer:fadeout(args.time, args.wait)
end

-- ------------------------------------------------------------------------------------------------
-- Camera
-- ------------------------------------------------------------------------------------------------

--- Makes camera start following given character.
-- @tparam table args
--  args.key (string): Character's key.
--  args.speed (number): Camera movement speed (optional).
--  args.wait (boolean): Wait until movement is complete (optional).
function ScreenEvents:focusCharacter(args)
  local char = self:findCharacter(args.key)
  FieldManager.renderer.focusObject = nil
  FieldManager.renderer:moveToObject(char, args.speed, args.wait)
  FieldManager.renderer.focusObject = char
end
--- Makes focus on given tile.
-- @tparam table args
--  args.x (number): Tile grid x.
--  args.y (number): Tile grid y.
--  args.h (number): Tile's height (optional, 1 by default).
--  args.speed (number): Camera movement speed (optional).
--  args.wait (boolean): Wait until movement is complete (optional).
function ScreenEvents:focusTile(args)
  local tile = FieldManager.currentField:getObjectTile(args.x, args.y, args.h or 1)
  FieldManager.renderer.focusObject = nil
  FieldManager.renderer:moveToTile(tile, args.speed, args.wait)
end

return ScreenEvents
