
-- ================================================================================================

--- A `FiberList` that runs field/character scripts.
---------------------------------------------------------------------------------------------------
-- @basemod ScriptList

-- ================================================================================================

-- Imports
local FiberList = require('core/fiber/FiberList')

-- Alias
local copyTable = util.table.deepCopy

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

local ScriptList = class(FiberList)

--- Initializes the script lists from instance data or save data.
-- @tparam table scripts Array of scripts from instante data.
-- @tparam InteractableObject|Field object The object that owns this list.
-- @tparam[opt] table save Persistent data from save file.
function ScriptList:init(scripts, object, save)
  FiberList.init(self, object)
  self.active = true
  if save then
    self.active = save.active
  end
  self.scripts = scripts
  if save then
    self.onLoadScripts = copyTable(save.onLoadScripts or {})
    self.onCollideScripts = copyTable(save.onCollideScripts or {})
    self.onInteractScripts = copyTable(save.onInteractScripts or {})
    self.onExitScripts = copyTable(save.onExitScripts or {})
    self.onDestroyScripts = copyTable(save.onDestroyScripts or {})
  else
    self:reset()
  end
end
--- Resets the script list to its original configuration.
function ScriptList:reset()
  self.onLoadScripts = {}
  self.onCollideScripts = {}
  self.onInteractScripts = {}
  self.onExitScripts = {}
  self.onDestroyScripts = {}
  for i = 1, self.size do
    self[i]:interrupt()
    self[i] = nil
  end
  self.size = 0
  self:addScripts(self.scripts)
end
--- Creates listeners from instance data.
-- @tparam table scripts Array of script data.
function ScriptList:addScripts(scripts)
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

--- Gets data with fiber list's state and local variables.
-- @treturn table State data to be saved.
function ScriptList:getPersistentData()
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
    onLoadScripts = copyScripts(self.onLoadScripts),
    onCollideScripts = copyScripts(self.onCollideScripts),
    onInteractScripts = copyScripts(self.onInteractScripts),
    onExitScripts = copyScripts(self.onExitScripts),
    onDestroyScripts = copyScripts(self.onDestroyScripts) }
end

-- ------------------------------------------------------------------------------------------------
-- Run
-- ------------------------------------------------------------------------------------------------

--- Creates a fiber to run the scripts for a given trigger type.
-- @tparam string name Name of the trigger (starting with "on").
-- @treturn Fiber The fiber that will execute the scripts, or nil if there's nothing to run.
function ScriptList:trigger(name, ...)
  local list = self[name .. "Scripts"]
  if self.finished or self.char.deleted or not self.active or #list == 0 then
    return nil
  else
    return self:forkMethod(self, name, ...)
  end
end
--- Called when the field is loaded.
-- @coroutine
-- @tparam boolean loading True if the field was loaded now, false if loaded from save.
function ScriptList:onLoad(loading)
  for _, script in ipairs(self.onLoadScripts) do
    if script.vars.loading or loading then
      script.vars.loading = script.vars.loading or loading
      self:runScript(script)
      if self.finished or self.char.deleted then
        break
      end
    end
  end
end
--- Called when the field is unloaded.
-- @coroutine
-- @tparam string exit The key of the object that originated the exit transition.
function ScriptList:onExit(exit)
  for _, script in ipairs(self.onExitScripts) do
    if script.vars.exit or exit then
      script.vars.exit = script.vars.exit or exit
      self:runScript(script)
      if self.finished or self.char.deleted then
        break
      end
    end
  end
end
--- Called when a character interacts with this object.
-- @coroutine
-- @tparam boolean interacting True if the interaction occured now, false if loaded from save.
function ScriptList:onInteract(interacting)
  for _, script in ipairs(self.onInteractScripts) do
    if script.vars.interacting or interacting then
      script.vars.interacting = script.vars.interacting or interacting
      self:runScript(script)
      if self.finished or self.char.deleted then
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
function ScriptList:onCollide(collided, collider)
  for _, script in ipairs(self.onCollideScripts) do
    if script.vars.collider or collider then
      script.vars.collided = script.vars.collided or collided
      script.vars.collider = script.vars.collider or collider
      self:runScript(script)
      if self.finished or self.char.deleted then
        break
      end
    end
  end
end
--- Called when the field is unloaded.
-- @coroutine
-- @tparam string destroyer The key of the object that originated the destroy command.
function ScriptList:onDestroy(destroyer)
  for _, script in ipairs(self.onDestroyScripts) do
    if script.vars.destroyer or destroyer then
      script.vars.destroyer = script.vars.destroyer or destroyer
      self:runScript(script)
      if self.finished or self.char.deleted then
        break
      end
    end
  end
end
--- Creates a new event sheet from the given script data.
-- @coroutine
-- @tparam table script Script initialization info.
function ScriptList:runScript(script)
  if script.running then
    return
  end
  local fiberList = script.global and FieldManager.fiberList or self
  local fiber = fiberList:forkFromScript(script, self.char)
  if script.wait then
    fiber:waitForEnd()
  end
end
-- For debugging.
function ScriptList:__tostring()
  return 'ScriptList: ' .. tostring(self.name)
end

return ScriptList
