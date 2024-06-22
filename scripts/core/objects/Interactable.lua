
-- ================================================================================================

--- Base methods for objects with start/collision/interaction scripts.
-- It is created from a instance data table, which contains (x, y, h) coordinates, scripts, and 
-- passable and persistent properties.
-- The `Player` may also interact with this.
---------------------------------------------------------------------------------------------------
-- @fieldmod Interactable

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

--- Constructor.
-- @tparam table instData Instance data from field file.
-- @tparam[opt] table save Persistent data from save file.
function Interactable:init(instData, save)
	self.data = instData
	self:initScripts(instData)
	self.key = instData.key
	if save and save.passable ~= nil then
		self.passable = save.passable
	else
		self.passable = instData.passable
	end
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
--- Initializes the script lists from instance data or save data.
-- @tparam table instData Instance data from field file.
-- @tparam[opt] table save Persistent data from save file.
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
		self:resetScripts(instData)
		self.vars = {}
	end
	self.faceToInteract = false
	self.approachToInteract = true
end
--- Creates listeners from instance data.
-- @tparam table scripts Array of script data.
-- @tparam[opt] boolean repeatCollisions Flag to call the collision scripts regardless if the
--	character is already running the collision scripts or not. 
function Interactable:addScripts(scripts, repeatCollisions)
	for _, script in ipairs(scripts) do
		if script.onLoad then
			script = copyTable(script)
			script.vars = script.vars or {}
			self.loadScripts[#self.loadScripts + 1] = script
		end
		if script.onCollide then
			script = copyTable(script)
			script.vars = script.vars or {}
			script.repeatCollisions = repeatCollisions
			self.collideScripts[#self.collideScripts + 1] = script
		end
		if script.onInteract then
			script = copyTable(script)
			script.vars = script.vars or {}
			self.interactScripts[#self.interactScripts + 1] = script
		end
	end
end
--- Sets the scripts according to instance data.
-- @tparam table data Instance data from field file.
function Interactable:resetScripts(data) 
  data = data or self.data
	self.loadScripts = {}
	self.collideScripts = {}
	self.interactScripts = {}
	self:addScripts(data.scripts, data.repeatCollisions)
end

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Updates fiber list.
function Interactable:update()
	self.fiberList:update()
end
--- Removes from FieldManager.
function Interactable:destroy(permanent)
	if permanent then
		self.deleted = true
	end
	FieldManager.updateList:removeElement(self)
	self.fiberList:destroy()
	if self.persistent then
		FieldManager:storeCharData(FieldManager.currentField.id, self)
	end
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
				vars = scripts[i].vars }
		end
		return copy
	end
	return {
		vars = copyTable(self.vars),
		deleted = self.deleted,
		passable = self.passable,
		loadScripts = copyScripts(self.loadScripts),
		collideScripts = copyScripts(self.collideScripts),
		interactScripts = copyScripts(self.interactScripts),
		interacting = self.interacting,
		collider = self.collider,
		collided = self.collided }
end

-- ------------------------------------------------------------------------------------------------
-- Callbacks
-- ------------------------------------------------------------------------------------------------

--- Called when a character interacts with this object.
-- @coroutine
-- @treturn boolean Whether the interact script were executed or not.
function Interactable:onInteract()
	if self.deleted or #self.interactScripts == 0 then
		return false
	end
	self.interacting = true
	for _, script in ipairs(self.interactScripts) do
		self:runScript(script)
		if self.deleted then
			return true
		end
	end
	self.interacting = nil
	return true
end
--- Called when a character collides with this object.
-- @coroutine
-- @tparam string collided Key of the character who was collided with.
-- @tparam string collider Key of the character who started the collision.
-- @tparam boolean repeating Whether the script collision scripts of this character are already running.
-- @treturn boolean Whether the collision script were executed or not.
function Interactable:onCollide(collided, collider, repeating)
	if self.deleted or #self.collideScripts == 0 then
		return false
	end
	if repeating then
		local skip = true
		for _, script in ipairs(self.collideScripts) do
			if script.repeatCollisions then
				skip = false
				break
			end
		end
		if not skip then
			return false
		end
	end
	self.collided = collided
	self.collider = collider
	for _, script in ipairs(self.collideScripts) do
		if not repeating or script.repeatCollisions then
			self:runScript(script)
			if self.deleted then
				return true
			end
		end
	end
	self.collided = nil
	self.collider = nil
	return true
end
--- Called when this interactable is created.
-- @coroutine
-- @treturn boolean Whether the load scripts were executed or not.
function Interactable:onLoad()
	if self.deleted or #self.loadScripts == 0 then
		return false
	end
	for _, script in ipairs(self.loadScripts) do
		self:runScript(script)
		if self.deleted then
			return true
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
--- Runs scripts according to object's state (colliding or interacting).
-- @coroutine
function Interactable:resumeScripts()
	if self.collided then
		self:onCollide(self.collided, self.collider)
	end
	if self.interacting then
		self:onInteract()
	end
	self:collideTile(self:getTile())
end
-- For debugging.
function Interactable:__tostring()
	return 'Interactable: ' .. self.key
end	return Interactable
