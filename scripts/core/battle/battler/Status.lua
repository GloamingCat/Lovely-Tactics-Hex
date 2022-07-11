
--[[===============================================================================================

Status
---------------------------------------------------------------------------------------------------
A generic status effect that a battler may have.
The effects of them on battle and field depend on each individual implementation.

=================================================================================================]]

-- Imports
local BattlerAI = require('core/battle/ai/BattlerAI')
local PopupText = require('core/battle/PopupText')

local Status = class()

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(data : table) Status' data from database file.
-- @param(list : StatusList) The list that included this status.
-- @param(caster : string) Key of the character who casted this status 
--  (null if it did not come from a character). 
-- @param(state : table) The persistent state of the status.
function Status:init(data, list, caster, state)
  -- General
  self.data = data
  self.statusList = list
  self.lifeTime = state and state.lifeTime or 0
  self.caster = state and state.caster or caster
  if self.data.duration >= 0 then
    self.duration = self.data.duration
  else
    self.duration = math.huge
  end
  self.tags = Database.loadTags(self.data.tags)
  -- Attribute bonus
  self.attAdd = {}
  self.attMul = {}
  for i = 1, #data.attributes do
    local bonus = data.attributes[i]
    self.attAdd[bonus.key] = (bonus.add or 0) / 100
    self.attMul[bonus.key] = (bonus.mul or 0) / 100
  end
  -- Element bonus
  self.elementAtk = {}
  self.elementDef = {}
  self.elementBuff = {}
  for i = 1, #data.elements do
    local b = data.elements[i]
    if b.type == 0 then
      self.elementDef[b.id] = b.value / 100 - 1
    elseif b.type == 1 then
      self.elementAtk[b.id] = b.value / 100
    else
      self.elementBuff[b.id] = b.value / 100 - 1
    end
  end
  -- AI
  if data.behavior and #data.behavior > 0 then
    self.AI = BattlerAI(list.battler, data.behavior)
  end
end
-- Loads Status class from data.
-- @ret(Status) New status.
function Status:fromData(data, ...)
  local class = self
  if data.script and data.script ~= '' then
    class = require('custom/' .. data.script)
  end
  return class(data, ...)
end

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Converting to string.
-- @ret(string) A string representation.
function Status:__tostring()
  return 'Status: ' .. self.data.id .. ' (' .. self.data.name .. ')'
end
-- Gets status persistent data. Must include its ID.
-- @ret(table) State data.
function Status:getState()
  return { id = self.data.id,
    lifeTime = self.lifeTime,
    caster = self.caster }
end

---------------------------------------------------------------------------------------------------
-- Drain / Regen
---------------------------------------------------------------------------------------------------

-- Applies drain effect.
-- @param(char : Character) The battle character with this status.
function Status:drain(char)
  local pos = char.position
  local popupText = PopupText(pos.x, pos.y - 20, pos.z - 60)
  local value = self.data.drainValue
  if self.data.percentage then
    value = math.floor(char.battler['m' .. self.data.drainAtt]() * value / 100)
  end
  if value < 0 then -- Heal
    popupText:addHeal {key = self.data.drainAtt, value = value}
    char.battler:heal(self.data.drainAtt, value)
  else
    popupText:addDamage {key = self.data.drainAtt, value = value}
    char.battler:damage(self.data.drainAtt, value)
  end
  popupText:popup()
  if not char.battler:isAlive() then
    char:playKOAnimation()
  end
end

---------------------------------------------------------------------------------------------------
-- Battle callbacks
---------------------------------------------------------------------------------------------------

-- Removes status in case it's battle-only.
function Status:onBattleEnd()
  if self.data.battleOnly then
    self.statusList:removeStatus(self)
  end
end

---------------------------------------------------------------------------------------------------
-- Turn callbacks
---------------------------------------------------------------------------------------------------

-- Removes status in case its lifetime is over.
-- @param(character : Character) Character with this status.
-- @param(partyTurn : boolean) True if it's the first turn of the whole party.
function Status:onTurnStart(character, partyTurn)
  if partyTurn and self.data.drainAtt ~= '' then
    self:drain(character)
  end
end

---------------------------------------------------------------------------------------------------
-- Skill callbacks
---------------------------------------------------------------------------------------------------

-- Removes status in case it's removable by damage.
-- @param(input : ActionInput) The action input that was executed.
-- @param(results : table) The results of the skill effect.
function Status:onSkillEffect(input, results, char)
  local battler = self.statusList.battler
  if results.damage and self.data.removeOnDamage then
    self.statusList:removeStatus(self, char)
  end
end
-- Removes status in case it's removable by KO.
-- @param(input : ActionInput) The action input that was executed.
-- @param(results : table) The results of the skill effect.
function Status:onSkillResult(input, results, char)
  local battler = self.statusList.battler
  if self.data.removeOnKO and not battler:isAlive() then
    self.statusList:removeStatus(self, char)
  end
end

return Status
