
-- ================================================================================================

--- Character-related functions that are loaded from the EventSheet.
---------------------------------------------------------------------------------------------------
-- @module CharacterEvents

-- ================================================================================================

-- Imports
local ActionInput = require('core/battle/action/ActionInput')
local MoveAction = require('core/battle/action/MoveAction')

local CharacterEvents = {}

-- ------------------------------------------------------------------------------------------------
-- Tables
-- ------------------------------------------------------------------------------------------------

--- Common arguments for move/turn commands in a direction.
-- @table DirArguments
-- @tfield string key The key of the character.
-- @tfield number angle The direction in degrees.
-- @tfield number distance The distance to move (in tiles).

--- Common arguments for move/turn commands towards a tile.
-- @table TileArguments
-- @tfield string key The key of the character.
-- @tfield[opt=0] number x Tile x difference.
-- @tfield[opt=0] number y Tile y difference.
-- @tfield[opt=0] number h Tile height difference.
-- @tfield[opt] string other Key of a character in the target tile. If nil, uses `x`, `y` and `h`.
-- @tfield[opt=inf] number limit The maxium length of the path to be calculated.

--- Common arguments for jump commands towards a tile.
-- @table JumpArguments
-- @tfield string key The key of the character.
-- @tfield number duration To total duration of the jump animation, in frames.
-- @tfield[opt] number height The height of the jump, in pixels.
--  If not specified, if uses that value of gravity instead.
-- @tfield[opt=30] number gravity The deceleration, in pixels/frame².

--- Common arguments for delete/hide commands.
-- @table DeleteArguments
-- @tfield string key They key of the character.
-- @tfield[opt] boolean optional Flag to not raise an error when the character is not found.
-- @tfield[opt] boolean permanent Flag to create the character again when field if reloaded.

--- Common arguments for character setup.
-- @table SetupArguments
-- @tfield string key They key of the character.
-- @tfield[opt] boolean optional Flag to not raise an error when the character is not found.
-- @tfield[opt] boolean deactivate Flag to erase the character's scripts.
-- @tfield[opt] boolean passable Flag to make the character passable during the fading animation.
-- @tfield[opt] boolean visible Character's visibility.
-- @tfield[opt] number speed Character's speed.
-- @tfield[opt] number fade Duration of fading animation.

--- Common arguments for animation commands.
-- @table AnimArguments
-- @tfield string key They key of the character.
-- @tfield string name Name of specific animation of a default animation for the character.

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Destroys and removes a character from the field.
-- @tparam DeleteArguments args
function CharacterEvents:deleteChar(args)
  local char = self:findCharacter(args.key, args.optional)
  if not char then
    return
  end
  char:destroy(args.permanent)
end
--- Changes a character's properties.
-- @tparam SetupArguments args
function CharacterEvents:setupChar(args)
  local char = self:findCharacter(args.key, args.optional)
  if not char then
    return
  end
  if args.deactivate then
    char.interactScripts = {}
    char.collideScripts = {}
    char.loadScripts = {}
  elseif args.deactivate ~= nil then
    char:resetScripts()
  end
  if args.passable ~= nil then
    char.passable = args.passable
  end
  if args.speed ~= nil then
    char.speed = args.speed / 100 * Config.player.walkSpeed
  end
  if args.visible ~= nil and args.vibible ~= char.visible then
    local fade = args.visible and char.sprite.fadein or char.sprite.fadeout
    if args.wait then
      fade(char.sprite, args.fade)
    else
      self:fork(fade, char.sprite, args.fade)
    end
  end
end
--- Changes the properties of a character's shadow graphics.
-- @tparam SetupArguments args Ignores field `deactivate`, `passable` and `speed`.
function CharacterEvents:setupShadow(args)
  local char = self:findCharacter(args.key, args.optional)
  if not char then
    return
  end
  if args.visible ~= nil and args.vibible ~= char.visible then
    local fade = args.visible and char.shadow.fadein or char.shadow.fadeout
    if args.wait then
      fade(char.shadow, args.fade)
    else
      self:fork(fade, char.shadow, args.fade)
    end
  end
end

-- ------------------------------------------------------------------------------------------------
-- Movement
-- ------------------------------------------------------------------------------------------------

--- Moves straight to the given tile.
-- @tparam TileArguments args
function CharacterEvents:moveCharTile(args)
  local char = self:findCharacter(args.key)
  if char.autoTurn then
    local charTile = char:getTile()
    char:turnToTile(charTile.x + (args.x or 0), charTile.y + (args.y or 0))
  end
  if char.autoAnim then
    char:playMoveAnimation()
  end
  char:removeFromTiles()
  char:walkTiles(args.x or 0, args.y or 0, args.h or 0)
  char:addToTiles()
  if char.autoAnim then
    char:playIdleAnimation()
  end
end
--- Moves in the given direction.
-- @tparam DirArguments args
function CharacterEvents:moveCharDir(args)
  local char = self:findCharacter(args.key)
  local nextTile = char:getFrontTiles(args.angle)[1]
  if nextTile then
    local ox, oy, oh = char:tileCoordinates()
    local dx, dy, dh = nextTile:coordinates()
    dx, dy, dh = dx - ox, dy - oy, dh - oh
    dx, dy, dh = dx * args.distance, dy * args.distance, dh * args.distance
    if char.autoTurn then
      char:turnToTile(ox + dx, oy + dy)
    end
    if char.autoAnim then
      char:playMoveAnimation()
    end
    char:removeFromTiles()
    char:walkToTile(ox + dx, oy + dy, oh + dh)
    char:addToTiles()
    if char.autoAnim then
      char:playIdleAnimation()
    end
  end
end
--- Moves a path to the given tile.
-- @tparam TileArguments args
function CharacterEvents:moveCharPath(args)
  local char = self:findCharacter(args.key)
  local tile = FieldManager.currentField:getObjectTile(args.x, args.y, args.h)
  assert(tile, 'Tile not reachable: ', args.x, args.y, args.h)
  local action = MoveAction()
  action.pathLimit = args.limit or math.huge
  local input = ActionInput(action, char, tile)
  input.action:execute(input)
end
--- Makes character jump in place.
-- @tparam JumpArguments args
function CharacterEvents:jumpChar(args)
  local char = self:findCharacter(args.key)
  if args.height then
    local t = duration / 2 -- frames
    local h = args.height -- pixels
    -- h = (-g * t) * t + g * t * t / 2
    -- 0 = v0 + g * t
    -- h = g * t * t / 2
    local g = 2 * h / t / t
    char:jump(args.duration, g)
  else
    char:jump(args.duration, args.gravity)
  end
end

-- ------------------------------------------------------------------------------------------------
-- Direction
-- ------------------------------------------------------------------------------------------------

--- Turns character to the given tile.
-- @tparam TileArguments args
function CharacterEvents:turnCharTile(args)
  local char = self:findCharacter(args.key)
  if args.other then
    local other = self:findCharacter(args.other)
    local x, y = other:tileCoordinates()
    char:turnToTile(x, y)
  else
    char:turnToTile(args.x, args.y)
  end
end
--- Turn character to the given direction.
-- @tparam DirArguments args
function CharacterEvents:turnCharDir(args)
  local char = self:findCharacter(args.key)
  char:setDirection(args.angle)
end

-- ------------------------------------------------------------------------------------------------
-- Animations
-- ------------------------------------------------------------------------------------------------

--- Plays the idle animation.
-- @tparam AnimArguments args
function CharacterEvents:stopChar(args)
  local char = self:findCharacter(args.key)
  char:playIdleAnimation()
end
--- Plays the specified animation.
-- @tparam AnimArguments args
function CharacterEvents:playCharAnim(args)
  local char = self:findCharacter(args.key)
  if args.name:find('Anim') then
    char:playAnimation(char[args.name])
  else
    char:playAnimation(args.name)
  end
end

return CharacterEvents
