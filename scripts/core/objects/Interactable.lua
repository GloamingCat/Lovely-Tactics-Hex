
--[[===============================================================================================

Interactable
---------------------------------------------------------------------------------------------------
Base methods for objects with start/collision/interaction scripts.
It is created from a instance data table, which contains (x, y, h) coordinates, scripts, and 
passable and persistent properties.

=================================================================================================]]

-- Imports
local FiberList = require('core/fiber/FiberList')

-- Alias
local copyTable = util.table.deepCopy

local Interactable = class()

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- @param(instData : table) Instance data from field file.
-- @param(save : table) Persistent data from save file (optional).
function Interactable:init(instData, save)
  self:initScripts(instData)
  self.key = instData.key
  self.passable = instData.passable
  self.persistent = instData.persistent
  local layer = FieldManager.currentField.objectLayers[instData.h]
  assert(layer, 'height out of bounds: ' .. instData.h)
  layer = layer.grid[instData.x]
  assert(layer, 'x out of bounds: ' .. instData.x)
  self.tile = layer[instData.y]
  assert(self.tile, 'y out of bounds: ' .. instData.y)
  self.tile.characterList:add(self)
  FieldManager.updateList:add(self)
end
-- Creates listeners from instance data.
-- @param(instData : table) Instance data from field file.
function Interactable:initScripts(instData, save)
  self.fiberList = FiberList(self)
  self.collider = save and save.collider
  self.collided = save and save.collided
  self.loadScriptIndex = save and save.loadScriptIndex
  self.collideScriptIndex = save and save.collideScriptIndex
  self.interactScriptIndex = save and save.interactScriptIndex
  if save then
    self.loadScripts = save.loadScripts or {}
    self.collideScripts = save.collideScripts or {}
    self.interactScripts = save.interactScripts or {}
    self.vars = copyTable(save.vars or {})
  else
    self.loadScripts = {}
    self.collideScripts = {}
    self.interactScripts = {}
    for _, script in ipairs(instData.scripts) do
      script = copyTable(script)
      script.vars = script.vars or {}
      if script.onLoad then
        self.loadScripts[#self.loadScripts + 1] = script
      end
      if script.onCollide then
        self.collideScripts[#self.collideScripts + 1] = script
      end
      if script.onInteract then
        self.interactScripts[#self.interactScripts + 1] = script
      end
    end
    self.vars = {}
  end
end

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Updates fiber list.
function Interactable:update()
  self.fiberList:update()
end
-- Removes from FieldManager.
function Interactable:destroy(permanent)
  if permanent then
    self.deleted = true
  end
  FieldManager.updateList:removeElement(self)
  for i = 1, self.fiberList.size do
    self.fiberList[i]:interrupt()
  end
  if self.persistent then
    FieldManager:storeCharData(FieldManager.currentField.id, self)
  end
end
-- @ret(string) String representation (for debugging).
function Interactable:__tostring()
  return 'Interactable: ' .. self.key
end
-- Data with fiber list's state and local variables.
-- @ret(table) Interactable's state to be saved.
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
        vars = scripts[i].vars }
    end
    return copy
  end
  return {
    vars = copyTable(self.vars),
    deleted = self.deleted,
    loadScripts = copyScripts(self.loadScripts),
    collideScripts = copyScripts(self.collideScripts),
    interactScripts = copyScripts(self.interactScripts),
    loadScriptIndex = self.loadScriptIndex,
    collideScriptIndex = self.collideScriptIndex,
    interactScriptIndex = self.interactScriptIndex,
    collider = self.collider,
    collided = self.collided }
end

---------------------------------------------------------------------------------------------------
-- Callbacks
---------------------------------------------------------------------------------------------------

-- Called when a character interacts with this object.
-- @param(event : table) Table with tile and origin (usually player) and dest (this) objects.
function Interactable:onInteract()
  if self.deleted or #self.interactScripts == 0 then
    return false
  end
  local skip = self.interactScriptIndex or 0
  self.interactScriptIndex = 0
  for _, script in ipairs(self.interactScripts) do
    self.interactScriptIndex = self.interactScriptIndex + 1
    if skip > 0 then
      skip = skip - 1
    else
      self:runScript(script)
    end
  end
  self.interactScriptIndex = nil
  return true
end
-- Called when a character collides with this object.
-- @param(event : table) Table with tile and origin and dest (this) objects.
function Interactable:onCollide(collided, collider)
  if self.deleted or #self.collideScripts == 0 then
    return false
  end
  local skip = self.collideScriptIndex or 0
  print('Skip ' .. tostring(skip) .. ' collision scripts')
  self.collided = collided
  self.collider = collider
  self.collideScriptIndex = 0
  for _, script in ipairs(self.collideScripts) do
    self.collideScriptIndex = self.collideScriptIndex + 1
    if skip > 0 then
      skip = skip - 1
    else
      self:runScript(script)
    end
  end
  self.collided = nil
  self.collider = nil
  self.collideScriptIndex = nil
  return true
end
-- Called when this interactable is created.
-- @param(event : table) Table with origin (this).
function Interactable:onLoad()
  if self.deleted or #self.loadScripts == 0 then
    return false
  end
  local skip = self.loadScriptIndex or 0
  self.loadScriptIndex = 0
  for _, script in ipairs(self.loadScripts) do
    self.loadScriptIndex = self.loadScriptIndex + 1
    if skip > 0 then
      skip = skip - 1
    else
      self:runScript(script)
    end
  end
  self.loadScriptIndex = nil
  return true
end
-- Creates a new event sheet from the given script data.
-- @param(script : table) Script initialization info.
function Interactable:runScript(script)
  if script.runningIndex then
    return
  end
  local fiberList = script.global and FieldManager.fiberList or self.fiberList
  local fiber = fiberList:forkFromScript(script, self)
  if script.wait then
    fiber:waitForEnd()
  end
end
-- Runs scripts according to object's state (colliding or interacting).
function Interactable:resumeScripts()
  if self.collideScriptIndex then
    self:onCollide(self.collided, self.collider)
  end
  if self.interactScriptIndex then
    self:onInteract()
  end
end

return Interactable
