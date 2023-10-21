
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
-- General
-- ------------------------------------------------------------------------------------------------

--- Removes a character from the field.
-- @tparam table args
--  args.key (string): The key of the character.
--  args.permanent (boolean): If false, character shows up again when field if reloaded.
--  args.optional (boolean): If false, raises an error when the character is not found.
function CharacterEvents:deleteChar(args)
  local char = self:findCharacter(args.key, args.optional)
  if not char then
    return
  end
  char:destroy(args.permanent)
end
--- Hides a character.
-- @tparam table args
--  args.key (string): The key of the character.
--  args.fade (number): Duration of fading animation.
--  args.deactive (boolean): Erase the character's scripts.
--  args.passable (boolean): Make the character passable during the fading animation.
--  args.optional (boolean): If false, raises an error when the character is not found.
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
-- @tparam table args
--  args.key (string): The key of the character.
--  args.x (number): Tile x difference (0 by default).
--  args.y (number): Tile y difference (0 by default).
--  args.h (number): Tile height difference (0 by default).
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
-- @tparam table args
--  args.key (string): The key of the character.
--  args.angle (number): The direction in degrees.
--  args.distance (number): The distance to move (in tiles).
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
-- @tparam table args
--  args.key (string): The key of the character.
--  args.x (number): Destination tile's x.
--  args.y (number): Destination tile's y.
--  args.h (number): Destination tile's height.
--  args.limit (number): The maxium length of the path to be calculated.
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
-- @tparam table args
--  args.key (string): The key of the character.
--  args.other (string): Key of a character in the target tile (optional, uses args.x and args.y if nil).
--  args.x (number): The target tile's x (optional, uses target character's x position if nil).
--  args.y (number): The target tile's y (optional, uses target character's y position if nil).
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
-- @tparam table args
--  args.key (string): The key of the character.
--  args.angle (number): The direction angle in degrees.
function CharacterEvents:turnCharDir(args)
  local char = self:findCharacter(args.key)
  char:setDirection(args.angle)
end

-- ------------------------------------------------------------------------------------------------
-- Animations
-- ------------------------------------------------------------------------------------------------

--- Plays the idle animation.
-- @tparam table args
--  args.key (string): The key of the character.
function CharacterEvents:stopChar(args)
  local char = self:findCharacter(args.key)
  char:playIdleAnimation()
end
--- Plays the specified animation.
-- @tparam table args
--  args.key (string): The key of the character.
--  args.name (string): Name of specific animation of a default animation for the character.
function CharacterEvents:playCharAnim(args)
  local char = self:findCharacter(args.key)
  if args.name:find('Anim') then
    char:playAnimation(char[args.name])
  else
    char:playAnimation(args.name)
  end
end

return CharacterEvents
