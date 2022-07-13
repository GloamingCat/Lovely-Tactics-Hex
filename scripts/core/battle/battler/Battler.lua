
--[[===============================================================================================

Battler
---------------------------------------------------------------------------------------------------
A class the holds character's information for battle formula.

=================================================================================================]]

-- Imports
local AttributeSet = require('core/battle/battler/AttributeSet')
local BattlerAI = require('core/battle/ai/BattlerAI')
local Job = require('core/battle/battler/Job')
local EquipSet = require('core/battle/battler/EquipSet')
local Inventory = require('core/battle/Inventory')
local PopupText = require('core/battle/PopupText')
local SkillAction = require('core/battle/action/SkillAction')
local SkillList = require('core/battle/battler/SkillList')
local StatusList = require('core/battle/battler/StatusList')

-- Alias
local copyArray = util.array.shallowCopy
local copyTable = util.table.deepCopy
local max = math.max
local min = math.min
local newArray = util.array.new

local Battler = class()

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(troop : Troop)
-- @param(save : table)
function Battler:init(troop, save)
  self.troop = troop
  local id = save and save.battlerID or -1
  if id < 0 then
    local charID = save and save.charID
    local charData = Database.characters[charID]
    id = charData.battlerID
  end
  local data = Database.battlers[id]
  self:initProperties(data, save)
  self:initState(data, save)
  if data.ai and #data.ai > 0 then
    self.AI = BattlerAI(self, data.ai)
  end
end
-- Initializes general battler information.
-- @param(data : table) the battler's data from database
-- @param(save : table) the data from save
function Battler:initProperties(data, save)
  self.key = save.key
  self.charID = save.charID
  self.data = data
  self.name = save and save.name or data.name
  self.tags = Database.loadTags(data.tags)
end
-- Initializes battle state.
-- @param(data : table) the battler's data from database
-- @param(save : table) the data from save
function Battler:initState(data, save)
  self.job = Job(self, save)
  self.inventory = Inventory(save and save.items or data.items or {})
  self.statusList = StatusList(self, save)
  self.equipSet = EquipSet(self, save)
  self.skillList = SkillList(self, save)
  self.attackSkill = SkillAction:fromData(save.attackID or data.attackID)
  -- Elements
  self.elementBase = save and save.elements and copyArray(save.elements)
  if not self.elementBase then
    local e = newArray(#Config.elements, 0)
    for i = 1, #data.elements do
      e[data.elements[i].id + 1] = data.elements[i].value / 100 - 1
    end
    self.elementBase = e
  end
  -- Attributes
  self.att = AttributeSet(self, save)
  self.jumpPoints = self.att[Config.battle.attJump]
  self.maxSteps = self.att[Config.battle.attStep]
  self.mhp = self.att[Config.battle.attHP]
  self.msp = self.att[Config.battle.attSP]
  -- State variables
  if save and save.state then
    self.state = copyTable(save.state)
  else
    self.state = {}
    self.state.hp = math.huge
    self.state.sp = math.huge
  end
  self:refreshState()
end

---------------------------------------------------------------------------------------------------
-- HP and SP damage
---------------------------------------------------------------------------------------------------

-- Damages HP.
-- @param(value : number) the number of the damage
-- @ret(boolean) true if reached 0, otherwise
function Battler:damageHP(value)
  value = self.state.hp - value
  if value <= 0 then
    self.state.hp = 0
    return true
  else
    self.state.hp = min(value, self.mhp())
    return false
  end
end
-- Damages SP.
-- @param(value : number) the number of the damage
-- @ret(boolean) true if reached 0, otherwise
function Battler:damageSP(value)
  value = self.state.sp - value
  if value <= 0 then
    self.state.sp = 0
    return true
  else
    self.state.sp = min(value, self.msp())
    return false
  end
end
-- Decreases the points given by the key.
-- @param(key : string) HP, SP or other designer-defined point type
-- @param(value : number) value to be decreased
function Battler:damage(key, value)
  if key == Config.battle.attHP then
    self:damageHP(value)
  elseif key == Config.battle.attSP then
    self:damageSP(value)
  else
    return false
  end
  return true
end
-- Applies results and creates a popup for each value.
-- @param(pos : Vector) the character's position
-- @param(results : table) the array of effect results
function Battler:popupResults(pos, results, character)
  local popupText = PopupText(pos.x, pos.y - 10, pos.z - 60)
  for i = 1, #results.points do
    local points = results.points[i]
    if points.heal then
      popupText:addHeal(points)
      self:damage(points.key, -points.value)
    else
      popupText:addDamage(points)
      self:damage(points.key, points.value)
    end
  end
  for i = 1, #results.status do
    local r = results.status[i]
    local popupName, text
    if r.add then
      local s = self.statusList:addStatus(r.id, nil, character, r.caster)
      popupText:addStatus(s)
    else
      local s = self.statusList:removeAllStatus(r.id, character)
      popupText:removeStatus(s)
    end
  end
  popupText:popup()
end
-- Applies the result of a skill.
function Battler:applyResults(results, character)
  for i = 1, #results.points do
    local points = results.points[i]
    if points.heal then
      self:damage(points.key, -points.value)
    else
      self:damage(points.key, points.value)
    end
  end
  for i = 1, #results.status do
    local r = results.status[i]
    if r.add then
      self.statusList:addStatus(r.id, nil, character)
    else
      self.statusList:removeAllStatus(r.id, character)
    end
  end
end
-- Applies a list of costs (HP, SP or other state variable).
-- @param(costs : table) array of tables with the variable key and the cost functions
function Battler:damageCosts(costs)
  for i = 1, #costs do
    local value = costs[i].cost(self.att)
    self:damage(costs[i].key, value)
  end
end
-- Limits each state variable to its maximum.
function Battler:refreshState()
  self.state.hp = min(self.mhp(), self.state.hp)
  self.state.sp = min(self.msp(), self.state.sp)
end

---------------------------------------------------------------------------------------------------
-- State
---------------------------------------------------------------------------------------------------

-- Checks if battler is seen as defeated, either by no remaining HP or by a KO-like status effect.
-- @ret(boolean) True if battler is considered alive, false otherwise.
function Battler:isAlive()
  return self.state.hp > 0 and not self.statusList:isDead()
end
-- Checks if battler can execute an action in the current turn.
-- @ret(boolean) True if battler is considered active in the battle, false otherwise.
function Battler:isActive()
  return self:isAlive() and not self.statusList:isDeactive()
end
-- Gets the attack element. This is an additive factor (0 is neutral).
-- @param(id : number) The element's ID (position in the elements database).
function Battler:elementAtk(id)
  return self.statusList:elementAtk(id) + self.equipSet:elementAtk(id)
end
-- Gets the element immunity. This is an additive factor (0 is neutral).
-- @param(id : number) The element's ID (position in the elements database).
function Battler:elementDef(id)
  return self.elementBase[id] + self.statusList:elementDef(id) + self.equipSet:elementDef(id)
end
-- Gets the element damage bonus. This is an additive factor (0 is neutral).
-- @param(id : number) The element's ID (position in the elements database).
function Battler:elementBuff(id)
  return self.statusList:elementBuff(id) + self.equipSet:elementBuff(id)
end
-- Gets the battler's AI, if any.
-- @ret(BattlerAI) Battler's AI. Nil if controlled by player.
function Battler:getAI()
  return self.statusList:getAI() or self.AI
end

---------------------------------------------------------------------------------------------------
-- Battle Callbacks
---------------------------------------------------------------------------------------------------

-- Callback for when the battle ends.
function Battler:onBattleStart(char)
  if self.AI and self.AI.onBattleStart then
    self.AI:onBattleStart(self, char)
  end
  self.equipSet:addBattleStatus(char)
  self.statusList:callback('BattleStart', char)
end
-- Callback for when the battle ends.
function Battler:onBattleEnd(char)
  if self.AI and self.AI.onBattleEnd then
    self.AI:onBattleEnd(self, char)
  end
  self.statusList:callback('BattleEnd', char)
  if Config.battle.battleEndRevive then
    self.state.hp = max(1, self.state.hp)
  end
end

---------------------------------------------------------------------------------------------------
-- Skill callbacks
---------------------------------------------------------------------------------------------------

-- Callback for when the character finished using a skill.
function Battler:onSkillUse(input, character)
  self.statusList:callback('SkillUse', input, character)
end
-- Callback for when the character is about to receive a skill effect.
function Battler:onSkillEffect(input, results, character)
  self.statusList:callback('SkillEffect', input, results, character)
end
-- Callback for when the character received a skill effect.
function Battler:onSkillResult(input, results, character)
  self.statusList:callback('SkillResult', input, results, character)
end

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Converting to string.
-- @ret(string) A string representation.
function Battler:__tostring()
  return 'Battler ' .. self.data.id .. ': ' .. self.key .. ' (' .. self.name .. ')' 
end
-- Creates the save table. It also works as an extended troop unit data table.
-- @param(list : number) List type. 0 is current, 1 is backup, 2 is hidden.
-- @param(x : number) X position in the grid (optional).
-- @param(y : number) Y position in the grid (optional). 
-- @ret(table) Table that stores the battler's current state to be saved.
function Battler:getState(list, x, y)
  return {
    key = self.key,
    x = x,
    y = y,
    list = list,
    name = self.name,
    charID = self.charID,
    battlerID = self.data.id,
    state = copyTable(self.state),
    elements = copyTable(self.elementBase),
    att = self.att:getState(),
    job = self.job:getState(),
    equips = self.equipSet:getState(),
    status = self.statusList:getState(),
    skills = self.skillList:getState()
  }
end

return Battler
