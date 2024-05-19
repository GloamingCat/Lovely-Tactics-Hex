
-- ================================================================================================

--- A generic status effect that a battler may have.
-- The effects of them on battle and field depend on each individual implementation.
---------------------------------------------------------------------------------------------------
-- @battlemod Status

-- ================================================================================================

-- Imports
local BattlerAI = require('core/battle/ai/BattlerAI')
local PopText = require('core/graphics/PopText')

-- Class table.
local Status = class()

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam table data Status's data from database file.
-- @tparam StatusList list The list that included this status.
-- @tparam string caster Key of the character who casted this status 
--  (null if it did not come from a character). 
-- @tparam table state The persistent state of the status.
function Status:init(data, list, caster, state)
  -- General
  self.data = data
  self.statusList = list
  self.lifeTime = state and state.lifeTime or 0
  self.caster = state and state.caster or caster
  if data.duration >= 0 then
    self.duration = data.duration
  else
    self.duration = math.huge
  end
  self.cancel = data.cancel
  self.tags = Database.loadTags(self.data.tags)
  -- Attribute bonus
  self.attAdd = {}
  self.attMul = {}
  for i = 1, #data.attributes do
    local bonus = data.attributes[i]
    self.attAdd[bonus.key] = (bonus.add or 0) / 100
    self.attMul[bonus.key] = (bonus.mul or 0) / 100
  end
  -- Element and status bonuses
  self.elementAtk, self.elementDef, self.elementBuff,
    self.statusDef, self.statusBuff = self:statusBonuses(data)
  if data.statusDef then
    for _, id in ipairs(data.statusDef) do
      self.statusDef[id] = 0
    end
  end
  -- AI
  if data.behavior and #data.behavior > 0 then
    self.AI = BattlerAI(list.battler, data.behavior)
  end
end
--- Loads Status class from data.
-- @tparam table Status data from database file.
-- @param ... Any arguments passed to the constructor.
-- @treturn Status New status.
function Status:fromData(data, ...)
  local class = self
  if data.script and data.script ~= '' then
    class = require('custom/' .. data.script)
  end
  return class(data, ...)
end

-- ------------------------------------------------------------------------------------------------
-- Effects
-- ------------------------------------------------------------------------------------------------

--- Applies drain effect.
-- @tparam Character char The battle character with this status.
function Status:drain(char)
  local pos = char.position
  local popText = PopText(pos.x, pos.y - 20, FieldManager.renderer)
  local value = self.data.drainValue
  if self.data.percentage then
    value = math.floor(char.battler['m' .. self.data.drainAtt]() * value / 100)
  end
  if value < 0 then -- Heal
    popText:addHeal {key = self.data.drainAtt, value = value}
    char.battler:heal(self.data.drainAtt, value)
  else
    popText:addDamage {key = self.data.drainAtt, value = value}
    char.battler:damage(self.data.drainAtt, value)
  end
  popText:popUp()
  if not char.battler:isAlive() then
    char:playKOAnimation()
  end
end
--- Gets the table of status's element bonus.
-- @tparam table data Status data.
-- @treturn table Array for attack elements.
-- @treturn table Array for element immunity.
-- @treturn table Array for element damage.
function Status:statusBonuses(data)
  local eatk, edef, ebuff, sdef, sbuff = {}, {}, {}, {}, {}
  local list = data.bonuses or data.elements
  for i = 1, #list do
    local b = list[i]
    if b.type == 0 then
      edef[b.id + 1] = b.value / 100 - 1
    elseif b.type == 1 then
      eatk[b.id + 1] = b.value / 100
    elseif b.type == 2 then
      ebuff[b.id + 1] = b.value / 100 - 1
    elseif b.type == 3 then
      sdef[b.id] = 1 - b.value / 100
    elseif b.type == 4 then
      sbuff[b.id] = b.value / 100 - 1
    end
  end
  return eatk, edef, ebuff, sdef, sbuff
end

-- ------------------------------------------------------------------------------------------------
-- Battle callbacks
-- ------------------------------------------------------------------------------------------------

--- Removes status in case it's battle-only.
function Status:onBattleEnd()
  if self.data.battleOnly then
    self.statusList:removeStatus(self)
  end
end

-- ------------------------------------------------------------------------------------------------
-- Turn callbacks
-- ------------------------------------------------------------------------------------------------

--- Removes status in case its lifetime is over.
-- @tparam Character char Character with this status.
-- @tparam boolean skipStart Skip persistent turn start effects (when loaded from save).
function Status:onTurnStart(char, skipStart)
  if not skipStart then
    self.lifeTime = self.lifeTime + 1
    if TurnManager.initialTurnCharacters[char.key] and self.data.drainAtt ~= '' then
      self:drain(char)
    end
  end
end

-- ------------------------------------------------------------------------------------------------
-- Skill callbacks
-- ------------------------------------------------------------------------------------------------

--- Removes status in case it's removable by damage.
-- @tparam ActionInput input The action input that was executed.
-- @tparam table results The results of the skill effect.
-- @tparam Character char Character with this status.
function Status:onSkillEffect(input, results, char)
  local battler = self.statusList.battler
  if results.damage and self.data.removeOnDamage then
    self.statusList:removeStatus(self, char)
  end
end
--- Removes status in case it's removable by KO.
-- @tparam ActionInput input The action input that was executed.
-- @tparam table results The results of the skill effect.
-- @tparam Character char Character with this status.
function Status:onSkillResult(input, results, char)
  local battler = self.statusList.battler
  if self.data.removeOnKO and not battler:isAlive() then
    self.statusList:removeStatus(self, char)
  end
end

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Gets status's persistent data.
-- Includes its ID, its remaining life time, and the key of the original caster (if any).
-- @treturn table State data.
function Status:getState()
  return { id = self.data.id,
    lifeTime = self.lifeTime,
    caster = self.caster }
end
-- For debugging.
function Status:__tostring()
  return 'Status: ' .. self.data.id .. ' (' .. self.data.name .. ')'
end

return Status
