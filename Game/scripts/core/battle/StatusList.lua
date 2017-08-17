
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
-- General
---------------------------------------------------------------------------------------------------

function StatusList:addStatus(id, char)
  local s = Status.fromData(id, nil, char)
  self:add(s)
  s:onAdd(char)
  print(char.battler)
  return s
end

function StatusList:addAllStatus(status, char)
  for i = 1, #status do
    self:addStatus(status[i], char)
  end
end

function StatusList:asTable()
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

function StatusList:onTurnStart(char, turnChar, it)
  for status in self:iterator() do
    status:onTurnStart(char, turnChar, it)
  end
end

function StatusList:onTurnEnd(char, turnChar, it)
  for status in self:iterator() do
    status:onTurnEnd(char, turnChar, it)
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
  for status in self:iterator() do
    status:onBattleEnd(char)
  end
end

return StatusList
