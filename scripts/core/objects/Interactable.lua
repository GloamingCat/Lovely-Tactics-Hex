
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
  if save then
    self.loadScripts = save.loadScripts
    self.collideScripts = save.collideScripts
    self.interactScripts = save.interactScripts
    self.vars = copyTable(save.vars)
  else
    self.loadScripts = {}
    self.collideScripts = {}
    self.interactScripts = {}
    for _, script in ipairs(instData.scripts) do
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
  local data = {}
  data.vars = copyTable(self.vars)
  data.deleted = self.deleted
  data.loadScripts = self.loadScripts
  data.collideScripts = self.collideScripts
  data.interactScripts = self.interactScripts
  return data
end

---------------------------------------------------------------------------------------------------
-- Callbacks
---------------------------------------------------------------------------------------------------

-- Called when a character interacts with this object.
-- @param(event : table) Table with tile and origin (usually player) and dest (this) objects.
function Interactable:onInteract(tile)
  if #self.interactScripts == 0 then
    return false
  end
  self.interacting = true
  FieldManager.player.interacting = true
  for _, script in ipairs(self.interactScripts) do
    local fiberList = script.global and FieldManager.fiberList or self.fiberList
    local fiber = fiberList:forkFromScript(script, self)
    fiber.tile = self.tile
    if script.wait then
      fiber:waitForEnd()
    end
  end
  self.interacting = false
  FieldManager.player.interacting = false
  return true
end
-- Called when a character collides with this object.
-- @param(event : table) Table with tile and origin and dest (this) objects.
function Interactable:onCollide(tile, collided, collider)
  if #self.collideScripts == 0 then
    return false
  end
  self.colliding = true
  for _, script in ipairs(self.collideScripts) do
    local fiberList = script.global and FieldManager.fiberList or self.fiberList
    local fiber = fiberList:forkFromScript(script, self)
    fiber.tile = tile
    fiber.collided = collided
    fiber.collider = collider
    if script.wait then
      fiber:waitForEnd()
    end
  end
  self.colliding = false
  return true
end
-- Called when this interactable is created.
-- @param(event : table) Table with origin (this).
function Interactable:onLoad()
  if #self.loadScripts == 0 then
    return false
  end
  self.loading = true
  for _, script in ipairs(self.loadScripts) do
    local fiberList = script.global and FieldManager.fiberList or self.fiberList
    local fiber = fiberList:forkFromScript(script, self)
    fiber.tile = self.tile
    if script.wait then
      fiber:waitForEnd()
    end
  end
  self.loading = false
  return true
end

return Interactable
