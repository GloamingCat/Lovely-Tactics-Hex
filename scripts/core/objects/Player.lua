
-- ================================================================================================

--- A character freely controlled by the player.
-- This is a special character that can me controlled directly with keyboard or mouse.
-- It only exists in exploration fields, not in battle fields.
---------------------------------------------------------------------------------------------------
-- @fieldmod Player
-- @extend Character

-- ================================================================================================

-- Imports
local Character = require('core/objects/Character')
local FieldMenu = require('core/gui/menu/FieldMenu')
local Vector = require('core/math/Vector')

-- Alias
local coord2Angle = math.coord2Angle
local indexOf = util.array.indexOf
local rand = love.math.random
local now = love.timer.getTime

-- Class table.
local Player = class(Character)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam table transition Transition data (tile, direction and field ID).
-- @tparam table save Save data of player character.
function Player:init(transition, save)
  local troopData = Database.troops[TroopManager.playerTroopID]
  local leader = troopData.members[1]
  local data = {
    id = -1,
    key = 'player',
    persistent = false,
    battlerID = leader.battlerID,
    charID = leader.charID,
    x = transition.x,
    y = transition.y,
    h = transition.h,
    defaultSpeed = 100,
    active = true,
    direction = transition.direction,
    animation = 'Idle',
    scripts = { Config.player.loadScript }
  }
  Character.init(self, data, save)
end
--- Overrides `Character:initProperties`. 
-- @override
function Player:initProperties(instData, save)
  Character.initProperties(self, instData, save)
  self.inputDelay = 6 / 60
  self.walkSpeed = Config.player.walkSpeed
  self.dashSpeed = self.walkSpeed * Config.player.dashSpeed / 100
  -- Step sound
  self.stepCount = 0
  self.freq = 16
  self.varFreq = 0.1
  self.varPitch = 0.1
  self.varVolume = 0.2
end

-- ------------------------------------------------------------------------------------------------
-- Input
-- ------------------------------------------------------------------------------------------------

--- Overrides `AnimatedInteractable:update`. 
-- @override
function Player:update(dt)
  if FieldManager.playerInput then
    self:refreshSpeed()
  end
  Character.update(self, dt)
  if self:moving() then
    self:updateStepCount(dt)
  end
end
--- Checks movement and interaction inputs.
function Player:checkFieldInput()
  if InputManager.keys['cancel']:isTriggered() or InputManager.keys['mouse2']:isTriggered() or FieldManager.hud:checkInput() then
    self:openMenu()
  elseif InputManager.keys['confirm']:isTriggered() then
    self:interact()
  elseif InputManager.keys['mouse1']:isPressingGap() then
    self:moveByMouse('mouse1')
  elseif InputManager.keys['touch']:isPressingGap() then
    self:moveByMouse('touch')
  else
    local dx, dy, move = self:inputAxis()
    self:moveByKeyboard(dx, dy, move)
  end
end
-- Checks if player is waiting for an action to finish, like a movement animation, 
---  Menu input, battle, or a blocking event.
-- @treturn boolean True if some action is running.
function Player:isBusy()
  return BattleManager.onBattle or MenuManager:isWaitingInput()
    or not FieldManager.currentField.blockingFibers:isEmpty()
end
--- Gets the keyboard move/turn input. 
-- @treturn number The x-axis input.
-- @treturn number The y-axis input.
-- @treturn boolean True if it was pressed for long enough to move. 
---  If false, the character just turns to the input direction, but does not move.
function Player:inputAxis()
  local dx = InputManager:axisX(0, 0)
  local dy = InputManager:axisY(0, 0)
  if self.pressTime then
    if now() - self.pressTime > self.inputDelay * self.walkSpeed / self.speed then
      self.pressX = dx
      self.pressY = dy
      if dx == 0 and dy == 0 then
        self.pressTime = nil
      end
      return self.pressX, self.pressY, true
    end
    if dx ~= 0 then
      self.pressX = dx
    end
    if dy ~= 0 then
      self.pressY = dy
    end
    return self.pressX, self.pressY, false
  else
    if dx ~= 0 or dy ~= 0 then
      self.pressTime = now()
    end
    self.pressX = dx
    self.pressY = dy
    return dx, dy, false
  end
end
--- Sets the speed according to dash input.
function Player:refreshSpeed()
  local dash = InputManager.keys['dash']:isPressing()
  local auto = InputManager.autoDash or false
  if dash ~= auto then
    self.speed = self.dashSpeed
  else
    self.speed = self.walkSpeed
  end
end
  
-- ------------------------------------------------------------------------------------------------
-- Mouse Movement
-- ------------------------------------------------------------------------------------------------

--- Moves player to the mouse coordinate.
-- @coroutine
-- @tparam string button Key of the button used to move (mouse1 or touch).
function Player:moveByMouse(button)
  local tile = FieldManager.currentField:getHoveredTile()
  if tile then
    if not self:tryInteract(tile) then
      local moved = self:tryPathMovement(tile, Config.player.pathLength or 12) 
      if not moved then
        self:playIdleAnimation()
      end
    end
  else
    self:playIdleAnimation()
  end
end
--- Checks if the tile is within reach to interact then interacts.
-- @tparam ObjectTile tile Selected tile.
-- @treturn boolean Whether of not the player interacted with this tile.
function Player:tryInteract(tile)
  local currentTile = self:getTile()
  if math.field.tileDistance(tile.x, tile.y, currentTile.x, currentTile.y) > 1 then
    return false
  end
  return self:interactTile(tile)
end

-- ------------------------------------------------------------------------------------------------
-- Keyboard Movement
-- ------------------------------------------------------------------------------------------------

--- Moves player depending on input.
-- @coroutine
-- @tparam number dx The x-axis input.
-- @tparam number dy The x-axis input.
-- @tparam boolean move False if character is just turning to the given direction, true if it
--  must move.
function Player:moveByKeyboard(dx, dy, move)
  if dx ~= 0 or dy ~= 0 then
    self.path = nil
    local angle = coord2Angle(dx, dy)
    local result = move and (self:tryAngleMovement(angle)
      or self:tryAngleMovement(angle - 45)
      or self:tryAngleMovement(angle + 45))
    if not result then
      self:setDirection(angle)
      self:playIdleAnimation()
    end
  elseif not self:moveFromPath() then
    self:playIdleAnimation()
  end
end
--- Follow the current path, if any.
-- @treturn boolean Whether the character moved or not.
function Player:moveFromPath()
  if not self.path then
    return false
  end
  local path = self.path
  local walked, tile = self:consumePath()
  if not walked and #path == 0 then
    self:interactTile(tile, true)
  end
  return walked
end

-- ------------------------------------------------------------------------------------------------
-- Terrain
-- ------------------------------------------------------------------------------------------------

--- Plays terrain step sound.
-- @tparam number dt The duration of the previous frame.
function Player:updateStepCount(dt)
  self.stepCount = self.stepCount + self.speed / Config.player.walkSpeed * 60 * dt
  if self.stepCount > self.freq then
    local sounds = FieldManager.currentField:getTerrainSounds(self:tileCoordinates())
    if sounds and #sounds > 0 then
      local sound = sounds[rand(#sounds)]
      local pitch = sound.pitch * (rand() * self.varPitch * 2 - self.varPitch + 1)
      local volume = sound.volume * (rand() * self.varVolume * 2 - self.varVolume + 1)
      if sound then
        AudioManager:playSFX({name = sound.name, pitch = pitch, volume = volume})
      end
    end
    self.stepCount = self.stepCount - self.freq * (rand() * self.varFreq * 2 - self.varFreq + 1)
  end
end

-- ------------------------------------------------------------------------------------------------
-- Menu
-- ------------------------------------------------------------------------------------------------

--- Opens game's main Menu.
function Player:openMenu()
  self:playIdleAnimation()
  FieldManager.playerInput = false
  AudioManager:playSFX(Config.sounds.menu)
  FieldManager.hud:hide()
  self.menu = FieldMenu(nil)
  MenuManager:showMenuForResult(self.menu)
  self.menu = nil
  FieldManager.hud:show()
  FieldManager.playerInput = true
end

return Player
