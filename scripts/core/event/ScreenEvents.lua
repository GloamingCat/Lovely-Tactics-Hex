
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
-- @tfield[opt=0] number time Duration of effect in frames (of pause time, for `focusParties`).
-- @tfield[opt] number speed Camera movement speed.
-- @tfield[opt] boolean wait Flag to wait until effect is finished.

--- Arguments for shader effect. Extends `FadeArguments`.
-- @table ShadeArguments
-- @extend FadeArguments
-- @tfield string name Shader's file name.

--- Arguments for color filter. Extends `FadeArguments`.
-- @table ColorArguments
-- @extend FadeArguments
-- @tfield number red Red component of the color filter.
-- @tfield number green Green component of the color filter.
-- @tfield number blue Blue component of the color filter.

--- Arguments for camera movement. Extends `FadeArguments`.
-- @table CameraArguments
-- @extend FadeArguments
-- @tfield string key Character's key, for `focusCharacter`.
-- @tfield number x Tile grid x, for `focusTile`.
-- @tfield number y Tile grid y, for `focusTile`.
-- @tfield[opt=1] number h Tile's height, for `focusTile`.

-- ------------------------------------------------------------------------------------------------
-- Shader Effect
-- ------------------------------------------------------------------------------------------------

--- Shows the effect of a shader.
-- @coroutine
-- @tparam FadeArguments args
function ScreenEvents:shaderin(args)
  ScreenManager.shader = ResourceManager:loadShader(args.name)
  local speed = args.speed
  if not speed and args.time then
    speed = (60 / args.time)
  end
  if speed then
    ScreenManager.shader:send('time', 0)
    local speed = args.speed or (60 / args.time)
    local time = GameManager:frameTime()
    while time < 1 do
      ScreenManager.shader:send('time', time)
      Fiber:wait()
      time = time + GameManager:frameTime() * speed
    end
  end
  ScreenManager.shader:send('time', 1)
end
--- Hides the effect of a shader.
-- @coroutine
-- @tparam FadeArguments args
function ScreenEvents:shaderout(args)
  local speed = args.speed
  if not speed and args.time then
    speed = (60 / args.time)
  end
  if speed then
    ScreenManager.shader:send('time', 1)
    local time = GameManager:frameTime()
    while time > 0 do
      ScreenManager.shader:send('time', time)
      Fiber:wait()
      time = time - GameManager:frameTime() * speed
    end
  end
  ScreenManager.shader:send('time', 0)
  ScreenManager.shader = nil
end
--- Lightens the screen.
-- @coroutine
-- @tparam FadeArguments args
function ScreenEvents:fadein(args)
  local time = args.time or -1
  local speed = args.speed or -1
  if time <= 0 and speed > 0 then
    time = (60 / speed)
  end
  FieldManager.renderer:fadein(time, args.wait)
end
--- Darkens the screen.
-- @coroutine
-- @tparam FadeArguments args
function ScreenEvents:fadeout(args)
  local time = args.time or -1
  local speed = args.speed or -1
  if time <= 0 and speed > 0 then
    time = (60 / speed)
  end
  FieldManager.renderer:fadeout(time, args.wait)
end
--- Applies a color filter to the camera.
-- @coroutine
-- @tparam ColorArguments args
function ScreenEvents:colorin(args)
  local time = args.time or -1
  local speed = args.speed or -1
  if time <= 0 and speed > 0 then
    time = (60 / speed)
  end
  FieldManager.renderer:colorizeTo(args.red, args.green, args.blue, 1, time, args.wait)
end

-- ------------------------------------------------------------------------------------------------
-- Camera
-- ------------------------------------------------------------------------------------------------

--- Makes camera start following given character.
-- @coroutine
-- @tparam CameraArguments args
function ScreenEvents:focusCharacter(args)
  local time = args.time or -1
  local speed = args.speed or -1
  if speed < 0 then
    if time > 0 then
      speed = (60 / time)
    else
      speed = nil
    end
  end
  local char = self:findCharacter(args.key)
  FieldManager.renderer.focusObject = nil
  FieldManager.renderer:moveToObject(char, speed, args.wait)
  FieldManager.renderer.focusObject = char
end
--- Makes camera focus on given tile.
-- @coroutine
-- @tparam CameraArguments args
function ScreenEvents:focusTile(args)
  local time = args.time or -1
  local speed = args.speed or -1
  if speed < 0 then
    if time > 0 then
      speed = (60 / time)
    else
      speed = nil
    end
  end
  local tile = FieldManager.currentField:getObjectTile(args.x, args.y, args.h or 1)
  FieldManager.renderer.focusObject = nil
  FieldManager.renderer:moveToTile(tile, speed, args.wait)
end
--- Makes camera focus on each party in the field.
-- @coroutine
-- @tparam CameraArguments args
function ScreenEvents:focusParties(args)
  FieldManager.renderer:showParties(args.speed, args.time)
end

-- ------------------------------------------------------------------------------------------------
-- Images
-- ------------------------------------------------------------------------------------------------

--- Setup image.
-- @coroutine
-- @tparam EventUtil.VisibilityArguments args
function ScreenEvents:setupImage(args)
  local name = args.name or args.key
  local img = FieldManager.renderer.images[name]
  if not img then
    local icon = Config.icons[name]
    assert(icon, 'Image not found: ' .. name)
    img = ResourceManager:loadIcon(FieldManager.renderer, icon)
    FieldManager.renderer.images[name] = img
  end
  if args.visible ~= nil then
    self:fadeSprite(img, args.visible, args.fade or args.time, args.wait)
  end
end

return ScreenEvents
