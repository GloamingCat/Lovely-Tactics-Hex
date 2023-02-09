
--[[===============================================================================================

Party Events
---------------------------------------------------------------------------------------------------
Functions that are loaded from the EventSheet.

=================================================================================================]]

-- Imports
local Battler = require('core/battle/battler/Battler')
local Troop = require('core/battle/Troop')

local EventSheet = {}

---------------------------------------------------------------------------------------------------
-- Party
---------------------------------------------------------------------------------------------------

-- @param(args.value : number) Value to be added to each battler's exp.
-- @param(args.onlyCurrent : boolean) True to ignore backup and members (false by default).
function EventSheet:increaseExp(args)
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
-- @param(args.value : number) Value to be added to the party's money.
function EventSheet:increaseMoney(args)
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
-- @param(args.id : number) ID of the item to be added.
-- @param(args.value : number) Quantity to be added.
function EventSheet:increaseItem(args)
  local troop = Troop()
  troop.inventory:addItem(args.id, args.value)
  TroopManager:saveTroop(troop)
  if FieldManager.hud then
    FieldManager.hud:refreshSave(true)
  end
end
-- Heal all members' HP and SP.
-- @param(args.onlyCurrent : boolean) True to ignore backup members (false by default).
function EventSheet:healAll(args)
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

---------------------------------------------------------------------------------------------------
-- Formation
---------------------------------------------------------------------------------------------------

-- @param(args.key : string) New member's key.
-- @param(args.x : number) Member's grid X (if nil, it's added to backup list).
-- @param(args.y : number) Member's grid Y (if nil, it's added to backup list).
-- @param(args.backup : number) If true, add member to the backup list.
function EventSheet:addMember(args)
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
-- @param(args.key : string) Member's key.
function EventSheet:hideMember(args)
  local troop = Troop()
  troop:moveMember(args.key, 2)
  TroopManager:saveTroop(troop, true)
  if FieldManager.hud then
    FieldManager.hud:refreshSave(true)
  end
end

---------------------------------------------------------------------------------------------------
-- Battler
---------------------------------------------------------------------------------------------------

-- General parameters:
-- @param(args.key : string) The key of the member to be modified.

-- Makes a member learn a new skill.
-- @param(args.id : number) Skill's ID.
function EventSheet:learnSkill(args)
  local troop = Troop()
  local battler = troop.battlers[args.key]
  assert(battler, "No battler with key: " .. tostring(args.key))
  battler.skillList:learn(args.id)
  TroopManager:saveTroop(troop)
  if FieldManager.hud then
    FieldManager.hud:refreshSave(true)
  end
end
-- Sets a member's level. 
-- Learns new skills if level increased, but keeps old skills if decreased.
-- @param(args.level : number) Member's new level.
function EventSheet:setLevel(args)
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
-- Sets that item equiped in the specified slot.
-- @param(args.id : number) Item ID.
-- @param(args.slot : string) Slot key.
-- @oaram(args.store : boolean) Flag to store previous equipped item in party's inventory.
function EventSheet:setEquip(args)
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

return EventSheet
