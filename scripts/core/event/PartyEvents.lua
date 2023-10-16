
--[[===============================================================================================

@module PartyEvents
---------------------------------------------------------------------------------------------------
Party-related functions that are loaded from the EventSheet.

=================================================================================================]]

-- Imports
local Battler = require('core/battle/battler/Battler')
local Troop = require('core/battle/Troop')

local PartyEvents = {}

-- ------------------------------------------------------------------------------------------------
-- Party
-- ------------------------------------------------------------------------------------------------

--- Give EXP point to the members of the player's troop.
-- @tparam table args
--  args.value (number): Value to be added to each battler's exp.
--  args.onlyCurrent (boolean): True to ignore backup and members (false by default).
function PartyEvents:increaseExp(args)
  local troop = Troop()
  for battler in troop:currentBattlers():iterator() do
    battler.job:addExperience(args.value)
  end
  if not args.onlyCurrent then
    for battler in troop:backupBattlers():iterator() do
      battler.job:addExperience(args.value)
    end
  end
  TroopManager:saveTroop(troop)
  if FieldManager.hud then
    FieldManager.hud:refreshSave(true)
  end
end
--- Give money to the player's troop.
-- @tparam table args
--  args.value (number): Value to be added to the party's money.
function PartyEvents:increaseMoney(args)
  local save = TroopManager.troopData[TroopManager.playerTroopID .. '']
  if not save then
    TroopManager:saveTroop(Troop())
    save = TroopManager.troopData[TroopManager.playerTroopID .. '']
  end
  save.money = save.money + args.value
  if FieldManager.hud then
    FieldManager.hud:refreshSave(true)
  end
end
--- Add an item to the player's inventory.
-- @tparam table args
--  args.id (number) ID of the item to be added.
--  args.value (number): Quantity to be added.
function PartyEvents:increaseItem(args)
  local troop = Troop()
  troop.inventory:addItem(args.id, args.value)
  TroopManager:saveTroop(troop)
  if FieldManager.hud then
    FieldManager.hud:refreshSave(true)
  end
end
--- Heal all members' HP and SP.
-- @tparam table args
--  args.onlyCurrent (boolean): True to ignore backup members (false by default).
function PartyEvents:healAll(args)
  local troop = Troop()
  local list = args.onlyCurrent and troop:currentBattlers() or troop:visibleBattlers()
  for battler in list:iterator() do
    battler.state.hp = battler.mhp()
    battler.state.sp = battler.msp()
    if args.status then
      for _, id in ipairs(args.status) do
        battler.statusList:removeStatusAll(id)
      end
    end
  end
  TroopManager:saveTroop(troop)
  if FieldManager.hud then
    FieldManager.hud:refreshSave(true)
  end
end

-- ------------------------------------------------------------------------------------------------
-- Formation
-- ------------------------------------------------------------------------------------------------

--- Un-hide a hidden member in the player's troop.
-- @tparam table args
--  args.key (string): New member's key.
--  args.x (number): Member's grid X (if nil, it's added to backup list).
--  args.y (number): Member's grid Y (if nil, it's added to backup list).
--  args.backup (number): If true, add member to the backup list.
function PartyEvents:addMember(args)
  local troop = Troop()
  if args.backup then
    troop:moveMember(args.key, 1)
  else
    troop:moveMember(args.key, 0, args.x, args.y)
  end
  TroopManager:saveTroop(troop, true)
  if FieldManager.hud then
    FieldManager.hud:refreshSave(true)
  end
end
--- Remove (hide) a member from the player's troop.
-- @tparam table args
--  args.key (string): Member's key.
function PartyEvents:hideMember(args)
  local troop = Troop()
  troop:moveMember(args.key, 2)
  TroopManager:saveTroop(troop, true)
  if FieldManager.hud then
    FieldManager.hud:refreshSave(true)
  end
end

-- ------------------------------------------------------------------------------------------------
-- Battler
-- ------------------------------------------------------------------------------------------------

--- Makes a member learn a new skill.
-- @tparam table args
--  args.key (string): The key of the member to be modified.
--  args.id (number): Skill's ID.
function PartyEvents:learnSkill(args)
  local troop = Troop()
  local battler = troop.battlers[args.key]
  assert(battler, "No battler with key: " .. tostring(args.key))
  battler.skillList:learn(args.id)
  TroopManager:saveTroop(troop)
  if FieldManager.hud then
    FieldManager.hud:refreshSave(true)
  end
end
--- Sets a member's level. 
--- Learns new skills if level increased, but keeps old skills if decreased.
-- @tparam table args
--  args.key (string): The key of the member to be modified.
--  args.level (number): Member's new level.
function PartyEvents:setLevel(args)
  local troop = Troop()
  local battler = troop.battlers[args.key]
  assert(battler, "No battler with key: " .. tostring(args.key))
  if args.level < battler.job.level then
    battler.job.level = args.level
    battler.job.exp = battler.job.expCurve(args.level)
  else
    local exp = battler.job.expCurve(args.level) - battler.job.exp
    battler.job:addExperience(exp)
  end
  TroopManager:saveTroop(troop)
  if FieldManager.hud then
    FieldManager.hud:refreshSave(true)
  end
end
--- Sets that item equiped in the specified slot.
-- @tparam table args
--  args.key (string): The key of the member to be modified.
--  args.id (number): Item ID.
--  args.slot (string): Slot key.
--  args.store (boolean): Flag to store previous equipped item in party's inventory.
function PartyEvents:setEquip(args)
  local troop = Troop()
  local battler = troop.battlers[args.key]
  assert(battler, "No battler with key: " .. tostring(args.key))
  local item = Database.items[args.id]
  assert(item, "Item does not exist: " .. tostring(args.id))
  assert(item.slot ~= '', "Item " .. Database.toString(item) .. "is not an equipment.")
  assert(item.slot:contains(args.slot), "Item " .. Database.toString(item)
    .. " is not of slot type " .. args.slot)
  if args.store then
    battler.equipSet.setEquip(args.slot, item, troop.inventory)
  else
    battler.equipSet.setEquip(args.slot, item)
  end
  TroopManager:saveTroop(troop)
  if FieldManager.hud then
    FieldManager.hud:refreshSave(true)
  end
end

return PartyEvents
