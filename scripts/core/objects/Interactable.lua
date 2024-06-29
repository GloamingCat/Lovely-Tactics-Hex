
-- ================================================================================================

--- Base methods for objects with load/collision/interaction/exit scripts.
-- It is created from a instance data table, which contains (x, y, h) coordinates, scripts, and 
-- passable and persistent properties.
-- The `Player` may also interact with this.
---------------------------------------------------------------------------------------------------
-- @fieldmod Interactable
-- @extend Object

-- ================================================================================================

-- Imports
local FiberList = require('core/fiber/FiberList')
local Object = require('core/objects/Object')

-- Alias
local copyTable = util.table.deepCopy

-- Class table.
local Interactable = class(Object)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor. Extends `Object:init` and initialize variables, scripts, and adds the object to
-- `FieldManager`'s `updateList` and `characterList`.
-- @tparam table instData Instance data from field file.
-- @tparam[opt] table save Persistent data from save file. 
function Interactable:init(instData, save)
  local tile = FieldManager.currentField:getObjectTile(instData.x, instData.y, instData.h)
  Object.init(self, instData, tile, save)
  self:initVariables(save and save.vars)
  self:initScripts(instData, save)
  FieldManager.updateList:add(self)
  FieldManager.characterList:add(self)
  FieldManager.characterList[self.key] = self
end
--- Extends `Object:initProperties`.
-- Sets generic properties, like key, passability, activeness, and persistency.
-- @override
function Interactable:initProperties(instData, save)
  Object.initProperties(self, instData, save)
  if save and save.passable ~= nil then
    self.passable = save.passable
  else
    self.passable = instData.passable
  end
  if save and save.active ~= nil then
    self.active = save.active
  else
    self.active = instData.active
  end
  self.persistent = instData.persistent
end
--- Initializes the script lists from instance data or save data.
-- @tparam[opt] table saveVars Persistent variables from save ftile.
function Interactable:initVariables(saveVars)
  self.vars = saveVars and copyTable(saveVars) or {}
end
--- Initializes the script lists from instance data or save data.
-- @tparam table instData Instance data from field file.
-- @tparam[opt] table save Persistent data from save file.
function Interactable:initScripts(instData, save)
  self.fiberList = FiberList(self)
  if save then
    self.loadScripts = copyTable(save.loadScripts or {})
    self.collideScripts = copyTable(save.collideScripts or {})
    self.interactScripts = copyTable(save.interactScripts or {})
    self.exitScripts = copyTable(save.interactScripts or {})
  else
    self.loadScripts = {}
    self.collideScripts = {}
    self.interactScripts = {}
    self.exitScripts = {}
    self:addScripts(instData.scripts)
    self.vars = {}
  end
  self.faceToInteract = false
  self.approachToInteract = true
end
--- Creates listeners from instance data.
-- @tparam table scripts Array of script data.
function Interactable:addScripts(scripts)
  for _, script in ipairs(scripts) do
    if script.onLoad then
      script = copyTable(script)
      script.vars = script.vars or {}
      self.loadScripts[#self.loadScripts + 1] = script
    end
    if script.onCollide then
      script = copyTable(script)
      script.vars = script.vars or {}
      self.collideScripts[#self.collideScripts + 1] = script
    end
    if script.onInteract then
      script = copyTable(script)
      script.vars = script.vars or {}
      self.interactScripts[#self.interactScripts + 1] = script
    end
    if script.onExit then
      script = copyTable(script)
      script.vars = script.vars or {}
      self.exitScripts[#self.exitScripts + 1] = script
    end
  end
end

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Updates fiber list.
function Interactable:update()
  self.fiberList:update()
end
--- Overrides `Object:destroy`.
-- @override
function Interactable:destroy(permanent)
  Object.destroy(self)
  self.fiberList:destroy()
  FieldManager.updateList:removeElement(self)
  FieldManager.characterList:removeElement(self)
  FieldManager.characterList[self.key] = false
  if permanent then
    self.deleted = true
  end
  if self.persistent then
    FieldManager:storeCharData(FieldManager.currentField.id, self)
  end
  print(self, 'destroyed')
end
--- Check if the character in still present in the current field's character list.
-- @treturn boolean Whether this character was removed from the field.
function Interactable:wasDestroyed()
  return not FieldManager.characterList:contains(self)
end
--- Gets data with fiber list's state and local variables.
-- @treturn table State data to be saved.
function Interactable:getPersistentData()
  local function copyScripts(scripts)
    local copy = {}
    for i = 1, #scripts do
      copy[i] = {
        name = scripts[i].name,
        global = scripts[i].global,
        block = scripts[i].block,
        wait = scripts[i].wait,
        tags = scripts[i].tags,
        vars = copyTable(scripts[i].vars) }
    end
    return copy
  end
  return {
    vars = copyTable(self.vars),
    deleted = self.deleted,
    passable = self.passable,
    active = self.active,
    loadScripts = copyScripts(self.loadScripts),
    collideScripts = copyScripts(self.collideScripts),
    interactScripts = copyScripts(self.interactScripts),
    exitScripts = copyScripts(self.exitScripts) }
end

-- ------------------------------------------------------------------------------------------------
-- Tile
-- ------------------------------------------------------------------------------------------------

--- Looks for collisions with characters in the given tile.
-- @tparam ObjectTile tile The tile that the player is in or is trying to go.
-- @treturn boolean True if there was any blocking collision, false otherwise.
function Interactable:collideTile(tile)
  if not tile then
    return false
  end
  local blocking = false
  for char in tile.characterList:iterator() do
    if char ~= self  then
      local selfFiber = self.fiberList:forkMethod(self, 'onCollide', char.key, self.key)
      local charFiber = char.fiberList:forkMethod(char, 'onCollide', char.key, self.key)
      selfFiber:waitForEnd()
      charFiber:waitForEnd()
      if not char.passable then
        blocking = true
      end
    end
  end
  return blocking
end
--- Implements `Object:addToTiles`.
-- @override
function Interactable:addToTiles()
  self:getTile().characterList:add(self)
end
--- Implements `Object:removeFromTiles`.
-- @override
function Interactable:removeFromTiles()
  self:getTile().characterList:removeElement(self)
end

-- ------------------------------------------------------------------------------------------------
-- Scripts
-- ------------------------------------------------------------------------------------------------

--- Called when a character interacts with this object.
-- @coroutine
-- @tparam boolean interacting True if the interaction occured now, false if loaded from save.
-- @treturn boolean Whether the interact script were executed or not.
function Interactable:onInteract(interacting)
  if self.deleted or not self.active or #self.interactScripts == 0 then
    return false
  end
  for _, script in ipairs(self.interactScripts) do
    if script.vars.interacting or interacting then
      script.vars.interacting = script.vars.interacting or interacting
      self:runScript(script)
      if self.deleted then
        break
      end
    end
  end
  return true
end
--- Called when a character collides with this object.
-- @coroutine
-- @tparam string collided Key of the character who was collided with.
--  Nil if loaded from save.
-- @tparam string collider Key of the character who started the collision.
--  Nil if loaded from save.
-- @treturn boolean Whether the collision script were executed or not.
function Interactable:onCollide(collided, collider)
  if self.deleted or not self.active or #self.collideScripts == 0 then
    return false
  end
  for _, script in ipairs(self.collideScripts) do
    if script.vars.collider or collider then
      script.vars.collided = script.vars.collided or collided
      script.vars.collider = script.vars.collider or collider
      self:runScript(script)
      if self.deleted then
        break
      end
    end
  end
  return true
end
--- Called when the field is loaded.
-- @coroutine
-- @tparam boolean loading True if the field was loaded now, false if loaded from save.
-- @treturn boolean Whether the load scripts were executed or not.
function Interactable:onLoad(loading)
  if self.deleted or not self.active or #self.loadScripts == 0 then
    return false
  end
  for _, script in ipairs(self.loadScripts) do
    if script.vars.loading or loading then
      script.vars.loading = script.vars.loading or loading
      self:runScript(script)
      if self.deleted then
        break
      end
    end
  end
  return true
end
--- Called when the field is unloaded.
-- @coroutine
-- @tparam string exit The key of the object that originated the exit transition.
-- @treturn boolean Whether the load scripts were executed or not.
function Interactable:onExit(exit)
  if self.deleted or not self.active or #self.exitScripts == 0 then
    return false
  end
  for _, script in ipairs(self.exitScripts) do
    if script.vars.exit or exit then
      script.vars.exit = script.vars.exit or exit
      self:runScript(script)
      if self.deleted then
        break
      end
    end
  end
  return true
end
--- Creates a new event sheet from the given script data.
-- @coroutine
-- @tparam table script Script initialization info.
function Interactable:runScript(script)
  if script.running then
    return
  end
  local fiberList = script.global and FieldManager.fiberList or self.fiberList
  local fiber = fiberList:forkFromScript(script, self)
  if script.wait then
    fiber:waitForEnd()
  end
end
-- For debugging.
function Interactable:__tostring()
  return 'Interactable: ' .. self.key
end  return Interactable
