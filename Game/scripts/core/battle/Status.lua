
--[[===============================================================================================

Status
---------------------------------------------------------------------------------------------------
A generic status effect that a battler may have.
The effects of them on battle and field depend on each individual implementation.

=================================================================================================]]

-- Constants
local attConfig = Database.attributes

local Status = class()

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

function Status:init(id, state, char, param)
  self.id = id
  self.data = Database.status[id + 1]
  self.state = state or { lifeTime = 0 }
  if self.data.duration >= 0 then
    self.duration = self.data.duration * 60
  else
    self.duration = math.huge
  end
  self.tags = util.createTags(self.data.tags)
  self:addAttributeBonus(char)
  self:addElements(char)
end

function Status.fromData(id, state, char)
  local data = Database.status[id + 1]
  if data.script.path ~= '' then
    local class = require('custom/' .. data.script.path)
    return class(id, state, char, data.script.param)
  else
    return Status(id, state, char)
  end
end

function Status:remove(char)
  local status = char.battler.state.status
  local i = util.arrayIndexOf(status, self)
  table.remove(status, i)
  self:removeAttributeBonus(char)
  self:removeElements(char)
end

function Status:__tostring()
  return 'Status: ' .. self.id .. ' (' .. self.data.name .. ')'
end

---------------------------------------------------------------------------------------------------
-- Attribute bonus
---------------------------------------------------------------------------------------------------

function Status:addAttributeBonus(char)
  local attAdd = self.data.attAdd
  local bAttAdd = char.battler.attAdd
  for i = 1, #bAttAdd do 
    local bonus = bAttAdd[i]
    local name = attConfig[bonus.id + 1].shortName
    bAttAdd[name] = bAttAdd[name] + bonus.value
  end
  local attMul = self.data.attMul
  local bAttMul = char.battler.attMul
  for i = 1, #bAttMul do 
    local bonus = bAttMul[i]
    local name = attConfig[bonus.id + 1].shortName
    bAttMul[name] = bAttMul[name] * bonus.value
  end
end

function Status:removeAttributeBonus(char)
  local attAdd = self.data.attAdd
  local bAttAdd = char.battler.attAdd
  for i = 1, #bAttAdd do 
    local bonus = char.attAdd[i]
    local name = attConfig[bonus.id + 1].shortName
    bAttAdd[name] = bAttAdd[name] - bonus.value
  end
  local attMul = self.data.attMul
  local bAttMul = char.battler.attMul
  for i = 1, #bAttMul do 
    local bonus = char.attMul[i]
    local name = attConfig[bonus.id + 1].shortName
    bAttMul[name] = bAttMul[name] / bonus.value
  end
end

---------------------------------------------------------------------------------------------------
-- Elements
---------------------------------------------------------------------------------------------------

function Status:addElements(char)
  local el = self.data.elements
  local elements = char.battler.elementFactors
  for i = 1, #el do
    local id = el[i].id
    elements[id] = elements[id] + el[i].value
  end
end

function Status:removeElements(char)
  local el = self.data.elements
  local elements = char.battler.elementFactors
  for i = 1, #el do
    local id = el[i].id
    elements[id] = elements[id] - el[i].value
  end
end

---------------------------------------------------------------------------------------------------
-- Callbacks
---------------------------------------------------------------------------------------------------

function Status:onAdd(char)
  
end

function Status:onBattleStart(char)
  self:onAdd(char)
end

function Status:onBattleEnd(char)
  if self.data.removeOnBattleEnd then
    self:remove(char)
  end
end

function Status:onTurnStart(char, turnChar, it)
  self.state.lifeTime = self.state.lifeTime + it
  if self.state.lifeTime > self.duration then
    self:remove(char)
  end
end

function Status:onTurnEnd(char, turnChar, it)
end

function Status:onSkillUseStart(char, input)
end

function Status:onSkillUseEnd(char, input)
end

function Status:onSkillEffectStart(char, input, dmg)
end

function Status:onSkillEffectEnd(char, skill, dmg)
end

return Status
