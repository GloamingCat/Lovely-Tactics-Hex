
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

--- Arguments for camera follow. Extends `FadeArguments`.
-- @table CharArguments
-- @extend FadeArguments
-- @tfield[opt] string key Character's key.

--- Arguments for camera movement. Extends `FadeArguments`.
-- @table TileArguments
-- @extend FadeArguments
-- @tfield[opt=0] number x Tile grid x. It's added to the origin tile.
-- @tfield[opt=0] number y Tile grid y. It's added to the origin tile.
-- @tfield[opt=0] number h Tile's height. It's added to the origin tile.
-- @tfield[opt] string other Key of the reference character. If nil, origin is (0, 0, 0).

-- ------------------------------------------------------------------------------------------------
-- Shader Effect
-- ------------------------------------------------------------------------------------------------

--- Shows the effect of a shader.
-- @coroutine
-- @tparam FadeArguments args Argument table.
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
-- @tparam FadeArguments args Argument table.
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
-- @tparam FadeArguments args Argument table.
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
-- @tparam FadeArguments args Argument table.
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
-- @tparam ColorArguments args Argument table.
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
-- @tparam CharArguments args Argument table.
function ScreenEvents:focusCharacter(args)
  local time = args.time or -1
  local speed = args.speed or -1
  if time == 0 then
    speed = 0
  elseif speed < 0 then
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
-- @tparam TileArguments args Argument table.
function ScreenEvents:focusTile(args)
  local time = args.time or -1
  local speed = args.speed or -1
  if time == 0 then
    speed = 0
  elseif speed < 0 then
    if time > 0 then
      speed = (60 / time)
    else
      speed = nil
    end
  end
  local x = args.x or 0
  local y = args.y or 0
  local h = args.h or 0
  if args.other and args.other ~= '' then
    local char = self:findCharacter(args.other)
    local tile = char:getTile()
    x = x + tile.x
    y = y + tile.y
    h = h + tile.layer.height
  end
  local tile = FieldManager.currentField:getObjectTile(x, y, h)
  FieldManager.renderer.focusObject = nil
  FieldManager.renderer:moveToTile(tile, speed, args.wait)
end
--- Makes camera focus on each party in the field.
-- @coroutine
-- @tparam CameraArguments args Argument table.
function ScreenEvents:focusParties(args)
  FieldManager.renderer:showParties(args.speed, args.time)
end

-- ------------------------------------------------------------------------------------------------
-- Images
-- ------------------------------------------------------------------------------------------------

--- Setup image.
-- @coroutine
-- @tparam EventUtil.VisibilityArguments args Argument table.
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
