
-- ================================================================================================

--- A class the holds character's information for battle formula.
---------------------------------------------------------------------------------------------------
-- @battlemod Battler

-- ================================================================================================

-- Imports
local AttributeSet = require('core/battle/battler/AttributeSet')
local BattlerAI = require('core/battle/ai/BattlerAI')
local Job = require('core/battle/battler/Job')
local EquipSet = require('core/battle/battler/EquipSet')
local Inventory = require('core/battle/Inventory')
local PopText = require('core/graphics/PopText')
local SkillList = require('core/battle/battler/SkillList')
local StatusList = require('core/battle/battler/StatusList')

-- Alias
local copyArray = util.array.shallowCopy
local copyTable = util.table.deepCopy
local max = math.max
local min = math.min
local newArray = util.array.new

-- Class table.
local Battler = class()

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam Troop troop
-- @tparam table save
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
--- Initializes general battler information.
-- @tparam table data The battler's data from database.
-- @tparam table save The data from save.
function Battler:initProperties(data, save)
  self.key = save.key
  self.charID = save.charID
  self.data = data
  self.name = save and save.name or data.name
  self.tags = Database.loadTags(data.tags)
end
--- Initializes battle state.
-- @tparam table data The battler's data from database.
-- @tparam table save The state data from save.
function Battler:initState(data, save)
  self.skillList = SkillList(self, save and save.skills)
  self.job = Job(self, save and save.job)
  self.inventory = Inventory(save and save.items or data.items or {})
  self.statusList = StatusList(self, save)
  self.equipSet = EquipSet(self, save)
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
  self.steps = save and save.steps or self.maxSteps()
end

-- ------------------------------------------------------------------------------------------------
-- Skills
-- ------------------------------------------------------------------------------------------------

--- Gets all skills available for this character.
-- @treturn SkillList
function Battler:getSkillList()
  local list = self.skillList:clone()
  list:learnAll(self.job.skillList)
  return list
end
--- Gets current default attack skill.
-- @treturn SkillAction
function Battler:getAttackSkill()
  return self.job.attackSkill
end

-- ------------------------------------------------------------------------------------------------
-- HP and SP damage
-- ------------------------------------------------------------------------------------------------

--- Damages HP.
-- @tparam number value The number of the damage.
-- @treturn boolean True if reached 0, otherwise.
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
--- Damages SP.
-- @tparam number value The number of the damage.
-- @treturn boolean True if reached 0, otherwise.
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
--- Decreases the points given by the key.
-- @tparam string key HP, SP or other designer-defined point type.
-- @tparam number value Value to be decreased.
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
--- Applies results and creates a text for each value.
-- @tparam PopText popText The pop text to which new lines will be added.
-- @tparam table results The array of effect results.
-- @tparam[opt] Character char The Character associated with this Battler.
function Battler:popResults(popText, results, char)
  for i = 1, #results.points do
    local points = results.points[i]
    if points.heal then
      popText:addHeal(points)
      self:damage(points.key, -points.value)
    else
      popText:addDamage(points)
      self:damage(points.key, points.value)
    end
  end
  for i = 1, #results.status do
    local r = results.status[i]
    local popupName, text
    if r.add then
      local s = self.statusList:addStatus(r.id, nil, char, r.caster)
      popText:addStatus(s)
    else
      local s = self.statusList:removeStatusAll(r.id, char)
      popText:removeStatus(s)
    end
  end
  popText:popUp()
end
--- Applies the result of a skill.
-- @tparam table results The array of effect results.
-- @tparam[opt] Character char The Character associated with this Battler.
function Battler:applyResults(results, char)
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
      self.statusList:addStatus(r.id, nil, char)
    else
      self.statusList:removeStatusAll(r.id, char)
    end
  end
end
--- Applies a list of costs (HP, SP or other state variable).
-- @tparam table costs Array of tables with the variable key and the cost functions.
function Battler:damageCosts(costs)
  for i = 1, #costs do
    local value = costs[i].cost(self.att)
    self:damage(costs[i].key, value)
  end
end
--- Limits each state variable to its maximum.
function Battler:refreshState()
  self.state.hp = min(self.mhp(), self.state.hp)
  self.state.sp = min(self.msp(), self.state.sp)
end

-- ------------------------------------------------------------------------------------------------
-- State
-- ------------------------------------------------------------------------------------------------

--- Checks if battler is seen as defeated, either by no remaining HP or by a KO-like status effect.
-- @treturn boolean True if battler is considered alive, false otherwise.
function Battler:isAlive()
  return self.state.hp > 0 and not self.statusList:isDead()
end
--- Checks if battler can execute an action in the current turn.
-- @treturn boolean True if battler is considered active in the battle, false otherwise.
function Battler:isActive()
  return self:isAlive() and not self.statusList:isDeactive()
end
--- Gets the attack element. This is an additive factor (0 is neutral).
-- @tparam number id The element's ID (position in the elements database).
function Battler:elementAtk(id)
  return self.statusList:elementAtk(id) + self.equipSet:elementAtk(id)
end
--- Gets the element immunity. This is an additive factor (0 is neutral).
-- @tparam number id The element's ID (position in the elements database).
function Battler:elementDef(id)
  return self.elementBase[id] + self.statusList:elementDef(id) + self.equipSet:elementDef(id)
end
--- Gets the element damage bonus. This is an additive factor (0 is neutral).
-- @tparam number id The element's ID (position in the elements database).
function Battler:elementBuff(id)
  return self.statusList:elementBuff(id) + self.equipSet:elementBuff(id)
end
--- Gets the status immunity. This is a multiplicative factor (1 is neutral).
-- @tparam number id The status ID.
function Battler:statusDef(id)
  return self.statusList:statusDef(id)
end
--- Gets the status cast chance bonus. This is a multiplicative factor (1 is neutral).
-- @tparam number id The status ID.
function Battler:statusBuff(id)
  return self.statusList:statusBuff(id)
end
--- Gets the battler's AI, if any.
-- @treturn BattlerAI Battler's AI. Nil if controlled by player.
function Battler:getAI()
  return self.statusList:getAI() or self.AI
end

-- ------------------------------------------------------------------------------------------------
-- Battle Callbacks
-- ------------------------------------------------------------------------------------------------

--- Callback for when the battle ends.
-- @tparam Character char The Character associated with this Battler.
function Battler:onBattleStart(char)
  if self.AI and self.AI.onBattleStart then
    self.AI:onBattleStart(self, char)
  end
  self.equipSet:addBattleStatus(char)
  self.statusList:callback('BattleStart', char)
end
--- Callback for when the battle ends.
-- @tparam Character char The Character associated with this Battler.
function Battler:onBattleEnd(char)
  if self.AI and self.AI.onBattleEnd then
    self.AI:onBattleEnd(self, char)
  end
  self.statusList:callback('BattleEnd', char)
  if Config.battle.battleEndRevive then
    self.state.hp = max(1, self.state.hp)
  end
end

-- ------------------------------------------------------------------------------------------------
-- Turn callbacks
-- ------------------------------------------------------------------------------------------------

--- Callback for when a new turn begins.
-- @tparam Character char The Character associated with this Battler.
-- @tparam boolean skipStart Skip persistent turn start effects (when loaded from save).
function Battler:onTurnStart(char, skipStart)
  local AI = self:getAI()
  if AI and AI.onTurnStart then
    AI:onTurnStart(char, skipStart)
  end
  self.statusList:onTurnStart(char, skipStart)
  if not skipStart then
    if TurnManager.initialTurnCharacters[char.key] then
      self.steps = self.maxSteps()
    else
      self.steps = 0
    end
  end
end
--- Callback for when a turn ends.
-- @tparam Character char The Character associated with this Battler.
function Battler:onTurnEnd(char)
  local AI = self:getAI()
  if AI and AI.onTurnEnd then
    AI:onTurnEnd(char)
  end
  self.statusList:callback('TurnEnd', char)
end
--- Callback for when this battler's turn starts.
-- @tparam Character char The Character associated with this Battler.
function Battler:onSelfTurnStart(char)
  self.statusList:callback('SelfTurnStart', char)
end
--- Callback for when this battler's turn ends.
-- @tparam Character char The Character associated with this Battler.
-- @tparam table result The results of the lattest turn.
function Battler:onSelfTurnEnd(char, result)
  self.statusList:callback('SelfTurnEnd', char, result)
end

-- ------------------------------------------------------------------------------------------------
-- Skill callbacks
-- ------------------------------------------------------------------------------------------------

--- Callback for when the character finished using a skill.
-- @tparam ActionInput input User's input data.
-- @tparam Character char The Character associated with this Battler.
function Battler:onSkillUse(input, char)
  self.statusList:callback('SkillUse', input, char)
end
--- Callback for when the character is about to receive a skill effect.
-- @tparam ActionInput input User's input data.
-- @tparam table results The results of the lattest turn.
-- @tparam Character char The Character associated with this Battler.
function Battler:onSkillEffect(input, results, char)
  self.statusList:callback('SkillEffect', input, results, char)
end
--- Callback for when the character received a skill effect.
-- @tparam ActionInput input User's input data.
-- @tparam table results The results of the lattest turn.
-- @tparam Character char The Character associated with this Battler.
function Battler:onSkillResult(input, results, char)
  self.statusList:callback('SkillResult', input, results, char)
end

-- ------------------------------------------------------------------------------------------------
-- Move callbacks
-- ------------------------------------------------------------------------------------------------

--- Callback for when the character moves.
-- @tparam Character char The Character associated with this Battler.
-- @tparam Path path The path that the battler just walked.
function Battler:onMove(char, path)
  self.steps = math.floor(self.steps - path.totalCost)
  self.statusList:callback('Move', char, path)
end
--- Callback for when the character enters the given tiles.
-- Adds terrain statuses.
-- @tparam Character char The Character associated with this Battler.
-- @tparam table tiles Array of terrain tiles.
function Battler:onTerrainEnter(char, tiles)
  for t = 1, #tiles do
    local data = FieldManager.currentField:getTerrainStatus(tiles[t]:coordinates())
    for s = 1, #data do
      self.statusList:addStatus(data[s].statusID, nil, char)
    end
  end
end
--- Callback for when the character exits the given tiles.
-- Removes terrain statuses.
-- @tparam Character char The Character associated with this Battler.
-- @tparam table tiles Array of terrain tiles.
function Battler:onTerrainExit(char, tiles)
  for i = 1, #tiles do
    local data = FieldManager.currentField:getTerrainStatus(tiles[i]:coordinates())
    for s = 1, #data do
      if data[s].removeOnExit then
        self.statusList:removeStatus(data[s].statusID, char)
      end
    end
  end
end

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Creates the save table. It also works as an extended troop unit data table.
-- @tparam number list List type. 0 is current, 1 is backup, 2 is hidden.
-- @tparam[opt] number x X position in the grid.
-- @tparam[opt] number y Y position in the grid.
-- @treturn table Table that stores the battler's current state to be saved.
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
    skills = self.skillList:getState(),
    steps = self.steps
  }
end
--- Discards save changes.
function Battler:resetState()
  self:initState(self.data)
end
-- For debugging.
function Battler:__tostring()
  return 'Battler ' .. self.data.id .. ': ' .. self.key .. ' (' .. self.name .. ')' 
end

return Battler
