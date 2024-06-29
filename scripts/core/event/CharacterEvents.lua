
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
-- @tfield number distance The distance to move (in tiles).
-- @tfield[opt=0] number angle The direction in degrees.
-- @tfield[opt] string other Key of a character whose direction will be added to the angle.
-- @tfield[opt] boolean wait Flag to wait for the movement to finish.

--- Common arguments for move/turn commands towards a tile.
-- @table TileArguments
-- @tfield string key The key of the character.
-- @tfield[opt=0] number x Tile x difference.
-- @tfield[opt=0] number y Tile y difference.
-- @tfield[opt=0] number h Tile height difference.
-- @tfield[opt] string other Key of a character in the tile that will be used as "origin" (added to x, y and h).
-- @tfield[opt=inf] number limit The maxium length of the path to be calculated.
-- @tfield[opt] boolean wait Flag to wait for the movement to finish.

--- Common arguments for jump commands towards a tile.
-- @table JumpArguments
-- @tfield string key The key of the character.
-- @tfield number duration To total duration of the jump animation, in frames.
-- @tfield[opt] number height The height of the jump, in pixels.
--  If not specified, if uses that value of gravity instead.
-- @tfield[opt=30] number gravity The deceleration, in pixels/frame².
-- @tfield[opt] boolean wait Flag to wait for the jump to finish.

--- Arguments for delete commands.
-- @table DeleteArguments
-- @tfield string key They key of the character.
-- @tfield[opt] boolean optional Flag to not raise an error when the character is not found.
-- @tfield[opt] boolean permanent Flag to create the character again when field if reloaded.
-- @tfield[opt=0] number time Number of frames to wait before destroying the character.
-- @tfield[opt] boolean wait Flag to wait until the character is deleted.

--- Common arguments for animation commands.
-- @table PropArguments
-- @tfield string key They key of the character.
-- @tfield PropType prop The code of the property to change.
-- @tfield string value The expression for the value of the property.

--- Arguments for character setup.
-- @table PropClassArguments
-- @tfield string key They key of the character.
-- @tfield[opt] boolean props Flag to reset character's properties.
-- @tfield[opt] boolean tile Flag to reset character to its original tile.
-- @tfield[opt] boolean scripts Flag to reset character's scripts variables.

--- Common arguments for animation commands.
-- @table AnimArguments
-- @tfield string key They key of the character.
-- @tfield[opt="Idle"] string name Name of specific animation of a default animation for the character.
-- @tfield[opt] boolean wait Flag to wait for the animation to finish (ignores looping parts).

--- Types of scope for script variables.
-- @enum PropType
-- @field global Global variables.
-- @field script Variables that are only accessible within the same script.
-- @field object Variables associated with the script's object/character.
CharacterEvents.PropType = {
  passable = 0,
  active = 1,
  speed = 2,
  autoAnim = 3,
  autoTurn = 4
}

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
  local fiber = self:fork(function()
    if args.time and args.time > 0 then
      self:wait(args.time)
    end
    char:transferTile(char:originalCoordinates())
    char:initProperties(char.data)
    char:initScripts(char.data)
    char:destroy(args.permanent)
  end)
  if args.wait then
    fiber:waitForEnd()
  end
end
--- Changes a character's properties.
-- @tparam PropClassArguments args
function CharacterEvents:resetChar(args)
  local char = self:findCharacter(args.key, args.optional)
  if not char then
    return
  end
  if args.tile then
    char:transferTile(char:originalCoordinates())
  end
  if args.props then
    char:initProperties(char.data)
  end
  if args.vars then
    char:initVariables()
  end
  if args.scripts then
    char:initScripts(char.data)
  end
end
--- Changes a character's properties.
-- @tparam PropArguments args
function CharacterEvents:setCharProperty(args)
  local char = self:findCharacter(args.key, args.optional)
  if not char then
    return
  end
  local prop = self.PropType[args.prop] or args.prop
  if prop == self.PropType.speed then
    char.speed = self:evaluate(args.value) / 100 * Config.player.walkSpeed
  elseif prop == self.PropType.passable then
    char.passable = self:evaluate(args.value)
  elseif prop == self.PropType.active then
    char.active = self:evaluate(args.value)
  elseif prop == self.PropType.autoAnim then
    char.autoAnim = not self:evaluate(args.value)
  elseif prop == self.PropType.autoTurn then
    char.autoTurn = not self:evaluate(args.value)
  end
end
--- Changes a character's properties.
-- @tparam EventUtil.VisibilityArguments args
function CharacterEvents:setCharVisibility(args)
  local char = self:findCharacter(args.key, args.optional)
  if not char then
    return
  end
  if char.shadow then
    self:fadeSprite(char.shadow, args.visible, args.fade or args.time, false)
  end
  self:fadeSprite(char.sprite, args.visible, args.fade or args.time, args.wait)
end
--- Changes the properties of a character's shadow graphics.
-- @tparam EventUtil.VisibilityArguments args
function CharacterEvents:setShadowVisibility(args)
  local char = self:findCharacter(args.key, args.optional)
  if not char then
    return
  end
  self:fadeSprite(char.shadow, args.visible, args.fade or args.time, args.wait)
end
--- Prints basic properties of a character.
-- @tparam PropClassArguments args
function CharacterEvents:logProperties(args)
  local char = self:findCharacter(args.key, true)
  if not char then
    print("Character not found: " .. args.key)
    return
  end
  print("===> " .. tostring(char) .. " log")
  if args.props then
    print("Active", char.active)
    print("Passable", char.passable)
    print("Persistent", char.persistent)
    print("Variables:")
    for k, v in pairs(char.vars) do
      print("", k, v)
    end
  end
  if args.scripts then
    local function printScripts(scripts)
      for _, s in pairs(scripts) do
        print("", "- " .. s.name)
        print("", "- Script Variables:")
        for k, v in pairs(s.vars) do
          print("", "", k, v)
        end
      end
    end 
    print("Load scripts:")
    printScripts(char.loadScripts)
    print("Interact scripts:")
    printScripts(char.interactScripts)
    print("Collide scripts:")
    printScripts(char.collideScripts)
  end
  if args.tile then
    local x, y, h = char:tileCoordinates()
    local coord = tostring(x) .. ', ' .. tostring(y) .. ', ' .. tostring(h)
    print("Tile", coor .. ', ' .. tostring(char.direction) .. '°')
  end
end

-- ------------------------------------------------------------------------------------------------
-- Movement
-- ------------------------------------------------------------------------------------------------

--- Moves straight to the given tile.
-- @tparam TileArguments args
function CharacterEvents:moveCharTile(args)
  local char = self:findCharacter(args.key)
  local x, y, h = args.x or 0, args.y or 0, args.h or 0
  if args.other and args.other ~= '' then
    local other = self:findCharacter(args.other)
    local x2, y2, h2 = other:tileCoordinates()
    x, y, h = x + x2, y + y2, h + h2
  end
  if char.autoTurn then
    local charTile = char:getTile()
    char:turnToTile(x, y)
  end
  local fiber = self:fork(function()
    if char.autoAnim then
      char:playMoveAnimation()
    end
    char:removeFromTiles()
    char:walkToTile(x, y, h)
    char:addToTiles()
    if char.autoAnim then
      char:playIdleAnimation()
    end
  end)
  if args.wait then
    fiber:waitForEnd()
  end
end
--- Moves in the given direction.
-- @tparam DirArguments args
function CharacterEvents:moveCharDir(args)
  local char = self:findCharacter(args.key)
  local angle = args.angle or 0
  if args.other and args.other ~= '' then
    if args.other == 'self' then
      angle = angle + self.char.direction
    else
      local other = self:findCharacter(args.other)
      local x, y, h = other:tileCoordinates()
      angle = angle + char:tileToAngle((args.x or 0) + x, (args.y or 0) + y, (args.h or 0) + h)
    end
  end
  local nextTile = char:getFrontTiles(angle)[1]
  if nextTile then
    local ox, oy, oh = char:tileCoordinates()
    local dx, dy, dh = nextTile:coordinates()
    dx, dy, dh = dx - ox, dy - oy, dh - oh
    dx, dy, dh = dx * args.distance, dy * args.distance, dh * args.distance
    if char.autoTurn then
      char:turnToTile(ox + dx, oy + dy)
    end
    local fiber = self:fork(function()
      if char.autoAnim then
        char:playMoveAnimation()
      end
      char:removeFromTiles()
      char:walkToTile(ox + dx, oy + dy, oh + dh)
      char:addToTiles()
      if char.autoAnim then
        char:playIdleAnimation()
      end
    end)
    if args.wait then
      fiber:waitForEnd()
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
  local fiber = self:forkMethod(input.action, 'execute', input)
  if args.wait then
    fiber:waitForEnd()
  end
end

-- ------------------------------------------------------------------------------------------------
-- Jump
-- ------------------------------------------------------------------------------------------------

--- Makes character jump in place.
-- @tparam JumpArguments args
function CharacterEvents:jumpChar(args)
  local char = self:findCharacter(args.key)
  -- h = (-g * t) * t + g * t * t / 2
  -- 0 = v0 + g * t
  -- h = g * t * t / 2
  local g = char.defaultGravity
  if args.speed and args.speed > 0 then
    g = args.speed / 60
  end
  if not args.time or args.time <= 0 then
    assert(args.height and args.height > 0, "Either time or height should be specified.")
    local h = args.height -- pixels
    local t = math.sqrt(2 * h / g) -- frames
    char:jump(t, args.speed)
  elseif args.height and args.height > 0 then
    local h = args.height -- pixels
    local t = args.time / 2 -- frames
    g = 2 * h / t / t
    char:jump(args.time, g)
  else
    char:jump(args.time, g)
  end
  if args.wait then
    char:waitForJump()
  end
end

-- ------------------------------------------------------------------------------------------------
-- Direction
-- ------------------------------------------------------------------------------------------------

--- Turns character to the given tile.
-- @tparam TileArguments args
function CharacterEvents:turnCharTile(args)
  local char = self:findCharacter(args.key)
  if args.other and args.other ~= '' then
    local other = self:findCharacter(args.other)
    local x, y = other:tileCoordinates()
    char:turnToTile((args.x or 0) + x, (args.y or 0) + y)
  else
    char:turnToTile(args.x, args.y)
  end
end
--- Turn character to the given direction.
-- @tparam DirArguments args
function CharacterEvents:turnCharDir(args)
  local char = self:findCharacter(args.key)
  if args.other and args.other ~= '' then
    local other = self:findCharacter(args.other)
    char:setDirection((args.angle or 0) + other.direction)
  else
    char:setDirection(args.angle)
  end
end

-- ------------------------------------------------------------------------------------------------
-- Animations
-- ------------------------------------------------------------------------------------------------

--- Plays the idle animation.
-- @tparam AnimArguments args
function CharacterEvents:stopChar(args)
  local char = self:findCharacter(args.key)
  local animation = char:playIdleAnimation()
  if args.wait and not animation.loop then
    self:wait(animation.duration)
  end
end
--- Plays the specified animation.
-- @tparam AnimArguments args
function CharacterEvents:playCharAnim(args)
  local char = self:findCharacter(args.key)
  local animation
  if args.name:find('Anim') then
    animation = char:playAnimation(char[args.name])
  else
    animation = char:playAnimation(args.name)
  end
  if args.wait and not animation.loop then
    self:wait(animation.duration)
  end
end

return CharacterEvents
