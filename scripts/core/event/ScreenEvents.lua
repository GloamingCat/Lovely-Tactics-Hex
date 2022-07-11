
--[[===============================================================================================

Screen Utilities
---------------------------------------------------------------------------------------------------
Functions that are loaded from the EventSheet.

=================================================================================================]]

local EventSheet = {}

---------------------------------------------------------------------------------------------------
-- Shader Effect
---------------------------------------------------------------------------------------------------

-- Shows the effect of a shader.
-- @param(args.name : string)
function EventSheet:shaderin(args)
  ScreenManager.shader = ResourceManager:loadShader(args.name)
  ScreenManager.shader:send('time', 0)
  local time = GameManager:frameTime()
  while time < 1 do
    ScreenManager.shader:send('time', time)
    coroutine.yield()
    time = time + GameManager:frameTime() * (args.speed or 1)
  end
  ScreenManager.shader:send('time', 1)
end
-- Hides the effect of a shader.
-- @param(args.name : string)
function EventSheet:shaderout(args)
  ScreenManager.shader:send('time', 1)
  local time = GameManager:frameTime()
  while time > 0 do
    ScreenManager.shader:send('time', time)
    coroutine.yield()
    time = time - GameManager:frameTime() * (args.speed or 1)
  end
  ScreenManager.shader:send('time', 0)
  ScreenManager.shader = nil
end

---------------------------------------------------------------------------------------------------
-- Camera
---------------------------------------------------------------------------------------------------

-- Makes camera start following given character.
-- @param(args.key : string) Character's key.
-- @param(args.speed : number) Camera movement speed (optional).
-- @param(args.wait : bool) Wait until movement is complete (optional).
function EventSheet:focusCharacter(args)
  local character = self:findCharacter(args.key)
  FieldManager.renderer.focusObject = nil
  FieldManager.renderer:moveToObject(character, args.speed, args.wait)
  FieldManager.renderer.focusObject = character
end
-- Makes focus on given tile.
-- @param(args.x : number) Tile grid x.
-- @param(args.y : number) Tile grid y.
-- @param(args.h : number) Tile's height (optional).
-- @param(args.speed : number) Camera movement speed (optional).
-- @param(args.wait : bool) Wait until movement is complete (optional).
function EventSheet:focusTile(args)
  local tile = FieldManager.currentField:getObjectTile(args.x, args.y, args.h or 1)
  FieldManager.renderer.focusObject = nil
  FieldManager.renderer:moveToTile(tile, args.speed, args.wait)
end

return EventSheet
