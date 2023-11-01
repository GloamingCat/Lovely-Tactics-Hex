
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

--- Common arguments for delete/hide commands.
-- @table HideArguments
-- @tfield string key They key of the character.
-- @tfield[opt] boolean optional Flag to raise an error when the character is not found.
-- @tfield[opt] boolean permanent Flag to create the character again when field if reloaded.
-- @tfield[opt] number fade Duration of fading animation.
-- @tfield[opt] boolean deactive Flag to erase the character's scripts.
-- @tfield[opt] boolean passable Flag to make the character passable during the fading animation.

--- Common arguments for animation commands.
-- @table AnimArguments
-- @tfield string key They key of the character.
-- @tfield string name Name of specific animation of a default animation for the character.

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Destroys and removes a character from the field.
-- @tparam HideArguments args
function CharacterEvents:deleteChar(args)
  local char = self:findCharacter(args.key, args.optional)
  if not char then
    return
  end
  char:destroy(args.permanent)
end
--- Hides a character without deleting it.
-- @tparam HideArguments args
function CharacterEvents:hideChar(args)
  local char = self:findCharacter(args.key, args.optional)
  if not char then
    return
  end
  if args.deactivate then
    char.interactScripts = {}
    char.collideScripts = {}
    char.loadScripts = {}
  end
  if args.passable then
    char:removeFromTiles()
    char.collisionTiles = {}
  end
  if args.fade and args.fade > 0 then
    local speed = 60 / args.fade
    char:colorizeTo(nil, nil, nil, 0, speed)
    char:waitForColor()
  else
    char:setRGBA(nil, nil, nil, 0)
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
