
-- ================================================================================================

--- Screen-related functions that are loaded from the EventSheet.
---------------------------------------------------------------------------------------------------
-- @module ScreenEvents

-- ================================================================================================

local ScreenEvents = {}

-- ------------------------------------------------------------------------------------------------
-- Tables
-- ------------------------------------------------------------------------------------------------

--- Arguments for fading effects.
-- @table FadeArguments
-- @tfield number time Duration of effect in frames.
-- @tfield[opt] boolean wait Flag to wait until effect is finished.
-- @tfield string name Shader's file name.

--- Arguments for camera movement.
-- @table CameraArguments
-- @tfield[opt] number speed Camera movement speed.
-- @tfield[opt] bolean wait Flag to wait until movement is complete.
-- @tfield string key Character's key, for `focusCharacter`.
-- @tfield number x Tile grid x, for `focusTile`.
-- @tfield number y Tile grid y, for `focusTile`.
-- @tfield[opt=1] number h Tile's height, for `focusTile`.

-- ------------------------------------------------------------------------------------------------
-- Shader Effect
-- ------------------------------------------------------------------------------------------------

--- Shows the effect of a shader.
-- @tparam FadeArguments args
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
-- @tparam FadeArguments args
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
-- @tparam FadeArguments args
function ScreenEvents:fadein(args)
  FieldManager.renderer:fadein(args.time, args.wait)
end
--- Darkens the screen.
-- @tparam FadeArguments args
function ScreenEvents:fadeout(args)
  FieldManager.renderer:fadeout(args.time, args.wait)
end

-- ------------------------------------------------------------------------------------------------
-- Camera
-- ------------------------------------------------------------------------------------------------

--- Makes camera start following given character.
-- @tparam CameraArguments args
function ScreenEvents:focusCharacter(args)
  local char = self:findCharacter(args.key)
  FieldManager.renderer.focusObject = nil
  FieldManager.renderer:moveToObject(char, args.speed, args.wait)
  FieldManager.renderer.focusObject = char
end
--- Makes focus on given tile.
-- @tparam CameraArguments args
function ScreenEvents:focusTile(args)
  local tile = FieldManager.currentField:getObjectTile(args.x, args.y, args.h or 1)
  FieldManager.renderer.focusObject = nil
  FieldManager.renderer:moveToTile(tile, args.speed, args.wait)
end

return ScreenEvents
