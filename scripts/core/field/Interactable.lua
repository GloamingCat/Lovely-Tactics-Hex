
-- ================================================================================================

--- Base methods for objects with load/collision/interaction/exit scripts.
---------------------------------------------------------------------------------------------------
-- @fieldmod Interactable
-- @extend Object

-- ================================================================================================

-- Imports
local FiberList = require('core/fiber/FiberList')

-- Alias
local copyTable = util.table.deepCopy

-- Class table.
local Interactable = class()

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor. Extends `Object:init` and initialize variables, scripts, and adds the object to
-- `FieldManager`'s `updateList` and `characterList`.
-- @tparam table scripts List of scripts from instance data;
-- @tparam table vars Default variables from instance data;
-- @tparam[opt] table save Persistent data from save file. 
function Interactable:init(scripts, vars, save)
  self:resetVariables(save and save.vars or vars)
  self:initScripts(scripts, save)
  self.active = true
end
--- Initializes the script lists from instance data or save data.
-- @tparam[opt] table vars Default variables from instance data.
function Interactable:resetVariables(vars)
  self.vars = vars and copyTable(vars) or {}
end
--- Initializes the script lists from instance data or save data.
-- @tparam table scripts Default scripts from instance data.
-- @tparam[opt] table save Persistent data from save file.
function Interactable:initScripts(scripts, save)
  self.fiberList = FiberList(self)
  if save then
    self.onLoadScripts = copyTable(save.onLoadScripts or {})
    self.onCollideScripts = copyTable(save.onCollideScripts or {})
    self.onInteractScripts = copyTable(save.onInteractScripts or {})
    self.onExitScripts = copyTable(save.onExitScripts or {})
    self.onDestroyScripts = copyTable(save.onDestroyScripts or {})
  else
    self.onLoadScripts = {}
    self.onCollideScripts = {}
    self.onInteractScripts = {}
    self.onExitScripts = {}
    self.onDestroyScripts = {}
    self:addScripts(scripts)
  end
end
--- Creates listeners from instance data.
-- @tparam table scripts Array of script data.
function Interactable:addScripts(scripts)
  local function addScript(script, list)
      script = copyTable(script)
      script.vars = script.vars or {}
      list[#list + 1] = script
  end
  for _, script in ipairs(scripts) do
    if script.onLoad then
      addScript(script, self.onLoadScripts)
    end
    if script.onCollide then
      addScript(script, self.onCollideScripts)
    end
    if script.onInteract then
      addScript(script, self.onInteractScripts)
    end
    if script.onExit then
      addScript(script, self.onExitScripts)
    end
    if script.onDestroy then
      addScript(script, self.onDestroyScripts)
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
--- Terminates fiber list.
function Interactable:destroy()
  self.fiberList:destroy()
end
--- Gets data with fiber list's state and local variables.
-- @treturn table State data to be saved.
function Interactable:getPersistentData()
  local function copyScripts(scripts)
    local copy = {}
    for i = 1, #scripts do
      copy[i] = copyTable(scripts[i])
      copy[i].running = false
    end
    return copy
  end
  return {
    active = self.active,
    vars = copyTable(self.vars),
    onLoadScripts = copyScripts(self.onLoadScripts),
    onCollideScripts = copyScripts(self.onCollideScripts),
    onInteractScripts = copyScripts(self.onInteractScripts),
    onExitScripts = copyScripts(self.onExitScripts),
    onDestroyScripts = copyScripts(self.onDestroyScripts) }
end

-- ------------------------------------------------------------------------------------------------
-- Scripts
-- ------------------------------------------------------------------------------------------------

--- Creates a fiber to run the scripts for a given trigger type.
-- @tparam string name Name of the trigger (starting with "on").
-- @treturn Fiber The fiber that will execute the scripts, or nil if there's nothing to run.
function Interactable:trigger(name, ...)
  local list = self[name .. "Scripts"]
  if self.deleted or not self.active or #list == 0 then
    return nil
  else
    return self.fiberList:forkMethod(self, name, ...)
  end
end
--- Called when the field is loaded.
-- @coroutine
-- @tparam boolean loading True if the field was loaded now, false if loaded from save.
function Interactable:onLoad(loading)
  print('onLoad', self.deleted, self.active, #self.onLoadScripts, loading, self)
  for _, script in ipairs(self.onLoadScripts) do
    if script.vars.loading or loading then
      script.vars.loading = script.vars.loading or loading
      self:runScript(script)
      if self.deleted then
        break
      end
    end
  end
end
--- Called when the field is unloaded.
-- @coroutine
-- @tparam string exit The key of the object that originated the exit transition.
function Interactable:onExit(exit)
  print('onExit', self.deleted, self.active, #self.onExitScripts, exit, self)
  for _, script in ipairs(self.onExitScripts) do
    if script.vars.exit or exit then
      script.vars.exit = script.vars.exit or exit
      self:runScript(script)
      if self.deleted then
        break
      end
    end
  end
end
--- Called when a character interacts with this object.
-- @coroutine
-- @tparam boolean interacting True if the interaction occured now, false if loaded from save.
function Interactable:onInteract(interacting)
  for _, script in ipairs(self.onInteractScripts) do
    if script.vars.interacting or interacting then
      script.vars.interacting = script.vars.interacting or interacting
      self:runScript(script)
      if self.deleted then
        break
      end
    end
  end
end
--- Called when a character collides with this object.
-- @coroutine
-- @tparam string collided Key of the character who was collided with.
--  Nil if loaded from save.
-- @tparam string collider Key of the character who started the collision.
--  Nil if loaded from save.
function Interactable:onCollide(collided, collider)
  for _, script in ipairs(self.onCollideScripts) do
    if script.vars.collider or collider then
      script.vars.collided = script.vars.collided or collided
      script.vars.collider = script.vars.collider or collider
      self:runScript(script)
      if self.deleted then
        break
      end
    end
  end
end
--- Called when the field is unloaded.
-- @coroutine
-- @tparam string destroyer The key of the object that originated the destroy command.
function Interactable:onDestroy(destroyer)
  for _, script in ipairs(self.onDestroyScripts) do
    if script.vars.destroyer or destroyer then
      script.vars.destroyer = script.vars.destroyer or destroyer
      self:runScript(script)
      if self.deleted then
        break
      end
    end
  end
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
end

return Interactable
