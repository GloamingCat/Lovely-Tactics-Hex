
--[[===============================================================================================

Character Events
---------------------------------------------------------------------------------------------------
Functions that are loaded from the EventSheet.

=================================================================================================]]

-- Imports
local ActionInput = require('core/battle/action/ActionInput')
local MoveAction = require('core/battle/action/MoveAction')

local EventSheet = {}

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Removes a character from the field.
-- @param(args.permanent : boolean) If false, character shows up again when field if reloaded.
function EventSheet:deleteChar(args)
  local char = self:findCharacter(args.key, args.optional)
  if not char then
    return
  end
  char:destroy(args.permanent)
end
-- Hides a character.
-- @param(args.fade : number) Duration of fading animation.
-- @param(args.deactive : boolean) Erase the character's scripts.
-- @param(args.passable : booean) Make the character passable during the fading animation.
function EventSheet:hideChar(args)
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

---------------------------------------------------------------------------------------------------
-- Movement
---------------------------------------------------------------------------------------------------

-- General parameters:
-- @param(args.key : string) The key of the character.
--  "origin" or "dest" to refer to event's characters, or any other key to refer to any other
--  character in the current field.

-- Moves straight to the given tile.
-- @param(args.x : number) Tile x difference (0 by default).
-- @param(args.y : number) Tile y difference (0 by default).
-- @param(args.h : number) Tile height difference (0 by default).
function EventSheet:moveCharTile(args)
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
-- Moves in the given direction.
-- @param(args.angle : number) The direction in degrees.
-- @param(args.distance : number) The distance to move (in tiles).
function EventSheet:moveCharDir(args)
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
-- Moves a path to the given tile.
-- @param(args.x : number) Tile destination x.
-- @param(args.y : number) Tile destination y.
-- @param(args.h : number) Tile destination height.
-- @param(args.limit : number) The maxium length of the path to be calculated.
function EventSheet:moveCharPath(args)
  local char = self:findCharacter(args.key)
  local tile = FieldManager.currentField:getObjectTile(args.x, args.y, args.h)
  assert(tile, 'Tile not reachable: ', args.x, args.y, args.h)
  local action = MoveAction()
  action.pathLimit = args.limit or math.huge
  local input = ActionInput(action, char, tile)
  input.action:execute(input)
end

---------------------------------------------------------------------------------------------------
-- Direction
---------------------------------------------------------------------------------------------------

-- Turns character to the given tile.
-- @param(args.other : string) Key of a character in the destination tile (optional).
-- @param(args.x : number) Tile destination x.
-- @param(args.y : number) Tile destination y.
function EventSheet:turnCharTile(args)
  local char = self:findCharacter(args.key)
  if args.other then
    local other = self:findCharacter(args.other)
    local x, y = other:tileCoordinates()
    char:turnToTile(x, y)
  else
    char:turnToTile(args.x, args.y)
  end
end
-- Turn character to the given direction.
-- @param(args.angle : number) The direction angle in degrees.
function EventSheet:turnCharDir(args)
  local char = self:findCharacter(args.key)
  char:setDirection(args.angle)
end

return EventSheet
