
--[[===============================================================================================

StatusList
---------------------------------------------------------------------------------------------------
A special kind of list that provides functions to manage battler's list of status effects.

=================================================================================================]]

-- Imports
local Affine = require('core/math/Affine')
local List = require('core/datastruct/List')
local Status = require('core/battle/battler/Status')

-- Alias
local copyTable = util.copyTable
local rand = love.math.random

local StatusList = class(List)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(battler : Battler) The battler whose this list belongs to.
-- @param(initialStatus : table) The array with the battler's initiat status (optional).
function StatusList:init(battler, save)
  List.init(self)
  self.battler = battler
  local status = save and save.status
  if status then
    for i = 1, #status do
      local s = status[i]
      self:addStatus(s.id, s)
    end
  else
    status = battler.data.status
    if status then
      for i = 1, #status do
        self:addStatus(status[i])
      end
    end
  end
end

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Converting to string.
-- @ret(string) A string representation.
function StatusList:__tostring()
  return 'Status' .. getmetatable(List).__tostring(self)
end
-- Gets the status with the given ID (the first created).
-- @param(id : number) The status' ID in the database.
-- @ret(Status)
function StatusList:findStatus(id)
  for status in self:iterator() do
    if status.data.id == id then
      return status
    end
  end
  return nil
end
-- Finds a position in the list for a status with the given priority.
-- @param(priority : number)
-- @ret(number)
function StatusList:findPosition(priority)
  for i = #self, 1, -1 do
    if priority >= self[i].data.priority then
      return i
    end
  end
  return 1
end
-- Creates an array with the status icons, sorted by priority, with no repetition.
-- @ret(table)
function StatusList:getIcons()
  local addedIcons = {}
  local icons = {}
  for i = #self, 1, -1 do
    if self[i].data.visible then
      local icon = self[i].data.icon
      if icon and icon.id >= 0 then
        local key = icon.id .. '.' .. icon.col .. '.' .. icon.row
        if not addedIcons[key] then
          addedIcons[key] = icon
          icons[#icons + 1] = icon
        end
      end
    end
  end
  -- Invert
  local n = #icons + 1
  for i = 1, n / 2 do
    icons[i], icons[n - i] = icons[n - i], icons[i]
  end
  return icons
end

---------------------------------------------------------------------------------------------------
-- Add / Remove
---------------------------------------------------------------------------------------------------

-- Add a new status.
-- @param(id : number) The status' ID.
-- @param(state : table) The status persistent data.
-- @param(character : Character) The character with this status.
-- @param(caster : string) Key of the character who casted this status 
--  (null if it did not come from a character). 
-- @ret(Status) Newly added status (or old one, if non-cumulative).
function StatusList:addStatus(id, state, character, caster)
  local data = Database.status[id]
  assert(data, "Status does not exist: " .. tostring(id))
  local status = self:findStatus(id)
  if status and not data.cumulative then
    status.lifeTime = 0
  else
    local i = self:findPosition(data.priority)
    status = Status:fromData(data, self, caster, state)
    self:add(status, i)
    if status.onAdd then
      status:onAdd(self.battler, character)
    end
    for _, id in ipairs(status.cancel) do
      self:removeAllStatus(id, character)
    end
    if character then
      self:updateGraphics(character)
    end
  end
  return status
end
-- Removes a status from the list.
-- @param(status : Status | number) The status to be removed or its ID.
-- @ret(Status) The removed status.
function StatusList:removeStatus(status, character)
  if type(status) == 'number' then
    status = self:findStatus(status)
  end
  if status then
    self:removeElement(status)
    if status.onRemove then
      status:onRemove(self.battler, character)
    end
    if character then
      self:updateGraphics(character)
    end
    return status
  end
end
-- Removes all status instances of the given ID.
-- @param(id : number) Status' ID on database.
function StatusList:removeAllStatus(id, character)
  local all = {}
  local status = self:findStatus(id)
  while status do
    self:removeStatus(status, character)
    all[#all + 1] = status
    status = self:findStatus(id)
  end
  return all
end

---------------------------------------------------------------------------------------------------
-- Graphics
---------------------------------------------------------------------------------------------------

-- Updates the character's graphics (transform and animation) according to the current status.
-- @param(character : Character)
function StatusList:updateGraphics(character)
  local transform = nil
  for i = 1, #self do
    local data = self[i].data
    if data.override or not transform then
      transform = data.transform
    else
      transform = Affine.combineTransforms(character.statusTransform, transform)
    end
    if data.transformations then
      transform = Affine.createTransform(transform, data.transformations)
    end
  end
  character.statusTransform = transform
  character:setAnimations('Default')
  character:setAnimations('Battle')
  for i = 1, #self do
    local data = self[i].data
    if data.charAnim ~= '' then
      character:setAnimations(data.charAnim)
    end
  end
  character:replayAnimation()
end

---------------------------------------------------------------------------------------------------
-- Status effects
---------------------------------------------------------------------------------------------------

-- Gets the total attribute bonus given by the current status effects.
-- @param(name : string) The attribute's key.
-- @ret(number) Additive bonus.
-- @ret(number) Multiplicative bonus.
function StatusList:attBonus(name)
  local mul = 0
  local add = 0
  for i = 1, #self do
    add = add + (self[i].attAdd[name] or 0)
    mul = mul + (self[i].attMul[name] or 0)
  end
  return add, mul
end
-- Gets the total attack elements given by the current status effects.
-- @param(id : number) The element's ID (position in the elements database).
-- @ret(number) Element bonus.
function StatusList:elementAtk(id)
  local e = 0
  for i = 1, #self do
    e = e + (self[i].elementAtk[id] or 0)
  end
  return e
end
-- Gets the total element immunity given by the current status effects.
-- @param(id : number) The element's ID (position in the elements database).
-- @ret(number) Element bonus.
function StatusList:elementDef(id)
  local e = 0
  for i = 1, #self do
    e = e + (self[i].elementDef[id] or 0)
  end
  return e
end
-- Gets the total element damage bonus given by the current status effects.
-- @param(id : number) The element's ID (position in the elements database).
-- @ret(number) Element bonus.
function StatusList:elementBuff(id)
  local e = 0
  for i = 1, #self do
    e = e + (self[i].elementBuff[id] or 0)
  end
  return e
end
-- Gets the total status immunity given by the current status effects.
-- @param(id : number) The status ID.
-- @ret(number) Status immunity.
function StatusList:statusDef(id)
  local e = 1
  for i = 1, #self do
    e = e * (self[i].statusDef[id] or 1)
  end
  return e
end
-- Gets the total element damage bonus given by the current status effects.
-- @param(id : number) The element's ID (position in the elements database).
-- @ret(number) Element bonus.
function StatusList:statusBuff(id)
  local e = 1
  for i = 1, #self do
    e = e * (self[i].statusBuff[id] or 1)
  end
  return e
end
-- Checks if there's a deactivating status (like sleep or paralizis).
-- @ret(boolean)
function StatusList:isDeactive()
  for i = 1, #self do
    if self[i].data.deactivate then
      return true
    end
  end
  return false
end
-- Checks if there's a status that is equivalent to KO.
function StatusList:isDead()
  for i = 1, #self do
    if self[i].data.ko then
      return true
    end
  end
  return false
end
-- Gets predominant status behavior.
-- @ret(BattlerAI)
function StatusList:getAI()
  for i = #self, 1, -1 do
    if self[i].AI then
      return self[i].AI
    end
  end
end

---------------------------------------------------------------------------------------------------
-- Turn Callback
---------------------------------------------------------------------------------------------------

-- Called when the turn of the character starts.
function StatusList:onTurnStart(char, ...)
  local i = 1
  while i <= self.size do
    local status = self[i]
    status.lifeTime = status.lifeTime + 1
    status:onTurnStart(char, ...)
    if status.lifeTime > status.duration then
      self:removeStatus(status, char)
    else
      i = i + 1
    end
  end
end

---------------------------------------------------------------------------------------------------
-- Other Callbacks
---------------------------------------------------------------------------------------------------

-- Calls a certain function in all status in the list.
-- @param(name : string) The name of the event.
-- @param(...) Other parameters to the callback.
function StatusList:callback(name, ...)
  local i = 1
  name = 'on' .. name
  local list = List(self)
  for s in list:iterator() do
    if s[name] then
      s[name](s, ...)  
    end
  end
end

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Converting to string.
-- @ret(string) A string representation.
function StatusList:__tostring()
  return 'StatusList: ' .. tostring(self.battler)
end
-- Gets all the status states.
-- @ret(table) An array with the state tables.
function StatusList:getState()
  local status = {}
  for i = 1, #self do
    local s = self[i]
    if not s.equip then
      status[#status + 1] = s:getState()
    end
  end
  return status
end

return StatusList
