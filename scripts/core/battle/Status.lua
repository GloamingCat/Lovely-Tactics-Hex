
--[[===============================================================================================

Status
---------------------------------------------------------------------------------------------------
A generic status effect that a battler may have.
The effects of them on battle and field depend on each individual implementation.

=================================================================================================]]

-- Imports
local TagMap = require('core/datastruct/TagMap')

local Status = class()

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(id : number) the ID of the status in the database
-- @param(state : table) the persistent state of the status
-- @param(char : Character) the character with the status
function Status:init(id, state, char)
  -- General
  self.id = id
  self.data = Database.status[id + 1]
  self.state = state or { lifeTime = 0 }
  if self.data.duration >= 0 then
    self.duration = self.data.duration * 60
  else
    self.duration = math.huge
  end
  self.tags = TagMap(self.data.tags)
  -- Attribute bonus
  self.attAdd = {}
  self.attMul = {}
  for i = 1, #self.data.attributes do
    local bonus = self.data.attributes[i]
    local name = Database.attributes[bonus.id + 1].shortName
    self.attAdd[name] = bonus.add
    self.attMul[name] = bonus.mul
  end
  -- Element bonus
  self.elements = {}
  for i = 1, #self.data.elements do
    local bonus = self.data.elements[i]
    self.elements[bonus.id] = bonus.value
  end
end
-- Creates the status from its ID in the database, loading the correct script.
-- @param(id : number) the ID of the status in the database
-- @param(state : table) the persistent state of the status
-- @param(char : Character) the character with the status
function Status.fromData(id, state, char)
  local data = Database.status[id + 1]
  if data.script.path ~= '' then
    local class = require('custom/' .. data.script.path)
    return class(id, state, char)
  else
    return Status(id, state, char)
  end
end

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Removes this status from the character's status list.
-- @param(char : Character) the character with the status
function Status:remove(char)
  char.battler.statusList:removeElement(self)
end
-- String representation.
function Status:__tostring()
  return 'Status: ' .. self.id .. ' (' .. self.data.name .. ')'
end

---------------------------------------------------------------------------------------------------
-- Turn Callbacks
---------------------------------------------------------------------------------------------------

function Status:onTurnStart(char, partyTurn)
  self.state.lifeTime = self.state.lifeTime + 1
  if self.state.lifeTime > self.duration then
    self:remove(char)
  end
end

function Status:onTurnEnd(char, partyTurn)
end

function Status:onSelfTurnStart(char)
end

function Status:onSelfTurnEnd(char, result)
end

---------------------------------------------------------------------------------------------------
-- Skill Callbacks
---------------------------------------------------------------------------------------------------

function Status:onSkillUseStart(char, input)
end

function Status:onSkillUseEnd(char, input)
end

function Status:onSkillEffectStart(char, input, results)
end

function Status:onSkillEffectEnd(char, input, results)
end

---------------------------------------------------------------------------------------------------
-- Other Callbacks
---------------------------------------------------------------------------------------------------

function Status:onBattleStart(char)
end

function Status:onBattleEnd(char)
end

return Status
