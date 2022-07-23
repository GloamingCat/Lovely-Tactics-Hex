
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
  self.interacting = save and save.interacting
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
    collider = self.collider,
    collided = self.collided,
    interacting = self.interacting }
end

---------------------------------------------------------------------------------------------------
-- Callbacks
---------------------------------------------------------------------------------------------------

-- Called when a character interacts with this object.
-- @param(event : table) Table with tile and origin (usually player) and dest (this) objects.
function Interactable:onInteract()
  if #self.interactScripts == 0 then
    return false
  end
  self.interacting = true
  for _, script in ipairs(self.interactScripts) do
    self:runScript(script)
  end
  self.interacting = false
  return true
end
-- Called when a character collides with this object.
-- @param(event : table) Table with tile and origin and dest (this) objects.
function Interactable:onCollide(collided, collider)
  if #self.collideScripts == 0 then
    return false
  end
  self.collided = collided
  self.collider = collider
  for _, script in ipairs(self.collideScripts) do
    self:runScript(script)
  end
  self.collided = nil
  self.collider = nil
  return true
end
-- Called when this interactable is created.
-- @param(event : table) Table with origin (this).
function Interactable:onLoad()
  if #self.loadScripts == 0 then
    return false
  end
  for _, script in ipairs(self.loadScripts) do
    self:runScript(script)
  end
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
  if self.collider then
    self:onCollide(self.collided, self.collider)
  end
  if self.interacting then
    self:onInteract()
  end
end

return Interactable
