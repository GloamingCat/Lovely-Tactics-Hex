
--[[===============================================================================================

StatusList
---------------------------------------------------------------------------------------------------
A special kind of list that provides functions to manage battler's list of status effects.

=================================================================================================]]

-- Imports
local Status = require('core/battle/Status')
local List = require('core/datastruct/List')

-- Alias
local copyTable = util.copyTable

local StatusList = class(List)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(persistentData : table) the battler's saved data (optional)
-- @param(initialStatus : table) the array with the battler's initiat status (optional)
function StatusList:init(persistentData, initialStatus)
  List.init(self)
  if persistentData then
    for i = 1, #persistentData.status do
      local s = persistentData.status[i]
      self:add(Status.fromData(s.id, s.state, self))
    end
  elseif initialStatus then
    for i = 1, #initialStatus do
      self:add(Status(initialStatus[i], nil, self))
    end
  end
end

---------------------------------------------------------------------------------------------------
-- Add / Remove
---------------------------------------------------------------------------------------------------

-- Add a new status.
-- @param(id : number) the status' ID
-- @param(char : Character) the character with the status
function StatusList:addStatus(id, char)
  local data = Database.status[id + 1]
  local s = self:findStatus(id)
  if s and not data.cumulative then
    s.state.lifeTime = 0
  else
    s = Status.fromData(id, nil, char)
    self:add(s)
    char.balloon:addStatus(s.data.icon)
  end
  return s
end
-- Removes a status from the list.
function StatusList:removeStatus(id, char)
  local status = self:findStatus(id)
  if status then
    local icon = status.data.icon
    while status do
      self:removeElement(status)
      status = self:findStatus(id)
    end
    char.balloon:removeStatus(icon)
  end
end

---------------------------------------------------------------------------------------------------
-- Search
---------------------------------------------------------------------------------------------------

-- Gets the status with the higher priority.
-- @ret(Status)
function StatusList:getTopStatus()
  if #self == 0 then
    return nil
  end
  local s = self[1]
  for i = 2, #self do
    if self[i].data.priority > s.data.priority then
      s = self[i]
    end
  end
  return s
end
-- Gets the status with the given ID (the first created).
-- @param(id : number) the status' ID in the database
-- @ret(Status)
function StatusList:findStatus(id)
  for status in self:iterator() do
    if status.id == id then
      return status
    end
  end
  return nil
end
-- Gets all the status states.
-- @ret(table) an array with the state tables
function StatusList:getState()
  local status = {}
  for i = 1, #self do
    local s = self[i]
    status[i] = { 
      id = s.id, 
      state = copyTable(s.state) }
  end
  return status
end

---------------------------------------------------------------------------------------------------
-- Status effects
---------------------------------------------------------------------------------------------------

function StatusList:attBonus(name)
  local mul = 1
  local add = 0
  for i = 1, #self do
    add = add + self[i].attAdd[name] or 0
    mul = mul * self[i].attMul[name] or 1
  end
  return add, mul
end

function StatusList:elementBonus(id)
  local e = 0
  for i = 1, #self do
    e = e + (self[i].elements[id] or 0)
  end
  return e
end

function StatusList:isDeactive()
  for i = 1, #self do
    if self[i].data.deactivate then
      return true
    end
  end
  return false
end

---------------------------------------------------------------------------------------------------
-- Skill Callbacks
---------------------------------------------------------------------------------------------------

-- Callback for when the character finished using a skill.
function StatusList:onSkillUseStart(char, input)
  for status in self:iterator() do
    status:onSkillUseStart(char, input)
  end
end
-- Callback for when the character finished using a skill.
function StatusList:onSkillUseEnd(char, input)
  for status in self:iterator() do
    status:onSkillUseEnd(char, input)
  end
end
-- Callback for when the characters starts receiving a skill's effect.
function StatusList:onSkillEffectStart(char, input, results)
  for status in self:iterator() do
    status:onSkillEffectStart(char, input, results)
  end
end
-- Callback for when the characters ends receiving a skill's effect.
function StatusList:onSkillEffectEnd(char, input, results)
  for status in self:iterator() do
    status:onSkillEffectEnd(char, input, results)
  end
end

---------------------------------------------------------------------------------------------------
-- Turn Callbacks
---------------------------------------------------------------------------------------------------

function StatusList:onTurnStart(char, partyTurn)
  for status in self:iterator() do
    status:onTurnStart(char, partyTurn)
  end
end

function StatusList:onTurnEnd(char, partyTurn)
  for status in self:iterator() do
    status:onTurnEnd(char, partyTurn)
  end
end

function StatusList:onSelfTurnStart(char)
  for status in self:iterator() do
    status:onSelfTurnStart(char)
  end
end

function StatusList:onTurnEnd(char, result)
  for status in self:iterator() do
    status:onSelfTurnEnd(char, result)
  end
end

---------------------------------------------------------------------------------------------------
-- Other Callbacks
---------------------------------------------------------------------------------------------------

function StatusList:onBattleStart(char)
  for status in self:iterator() do
    status:onBattleStart(char)
  end
end

function StatusList:onBattleEnd(char)
  local i = 1
  while i < #self do
    if self[i].data.removeOnBattleEnd then
      self[i]:remove(char)
    else
      i = i + 1
    end
  end
end

return StatusList
