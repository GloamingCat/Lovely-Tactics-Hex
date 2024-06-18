
-- ================================================================================================

--- Party-related functions that are loaded from the EventSheet.
---------------------------------------------------------------------------------------------------
-- @module PartyEvents

-- ================================================================================================

-- Imports
local ActionInput = require('core/battle/action/ActionInput')
local Battler = require('core/battle/battler/Battler')
local SkillAction = require('core/battle/action/SkillAction')
local TargetMenu = require('core/gui/common/TargetMenu')
local Troop = require('core/battle/Troop')

local PartyEvents = {}

-- ------------------------------------------------------------------------------------------------
-- Arguments
-- ------------------------------------------------------------------------------------------------

--- Common arguments.
-- @table PartyArguments
-- @tfield number value Value to be added/subtracted.
-- @tfield number|string id ID or key of the item to be added, for `increaseItem`, or the skill to
--  be used, for `useSkill`.
-- @tfield boolean onlyCurrent True to ignore backup and members, for `increaseExp`
--  or `healAll`.

--- Common formation arguments.
-- @table FormationArguments
-- @tfield string key The key of the member to be moved.
-- @tfield number x Member's grid X (if nil, it's added to backup list).
-- @tfield number y Member's grid Y (if nil, it's added to backup list).
-- @tfield boolean backup Flag to add member to the backup list.

--- Member arguments.
-- @table MemberArguments
-- @tfield string key The key of the member to be modified.
-- @tfield number|string id ID or key of the skill/item.
-- @tfield number level Member's new level, for `setLevel`.
-- @tfield string slot The key of the equip slot, for `setEquip`.
-- @tfield boolean store Flag to store previous equipped item in party's inventory.

-- ------------------------------------------------------------------------------------------------
-- Party
-- ------------------------------------------------------------------------------------------------

--- Give EXP point to the members of the player's troop.
-- @tparam PartyArguments args
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
-- @tparam PartyArguments args
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
-- @tparam PartyArguments args
function PartyEvents:increaseItem(args)
  local troop = Troop()
  troop.inventory:addItem(args.id, args.value)
  TroopManager:saveTroop(troop)
  if FieldManager.hud then
    FieldManager.hud:refreshSave(true)
  end
end
--- Apply a skill on a party. If the party is not defined, apply it on the player troop.
-- @tparam PartyArguments args
function PartyEvents:useSkill(args)
  local troop = TroopManager:getTroop(args.party)
  local input = ActionInput(SkillAction(arg.id))
  input.user = args.user and troop.battlers[args.user]
  input.target = args.target and troop.battlers[args.target]
  if not input.target then
    if input.action:isArea() then
      -- All members
      input.targets = args.backup and troop:visibleBattlers() or troop:currentBattlers()
      input.action:menuUse(input)
    elseif input.action:isRanged() or not input.user then
      local menu = TargetMenu(self.menu, troop, input, args.backup)
      MenuManager:showMenuForResult(menu)
    else
      input.target = input.user
      input.action:menuUse(input)
    end
  end
  TroopManager:saveTroop(troop)
  if FieldManager.hud then
    FieldManager.hud:refreshSave(true)
  end
end
--- Heal all members' HP and SP.
-- @tparam PartyArguments args
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
-- @tparam FormationArguments args
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
-- @tparam FormationArguments args
function PartyEvents:hideMember(args)
  local troop = Troop()
  troop:moveMember(args.key, 2)
  TroopManager:saveTroop(troop, true)
  if FieldManager.hud then
    FieldManager.hud:refreshSave(true)
  end
end

-- ------------------------------------------------------------------------------------------------
-- Member
-- ------------------------------------------------------------------------------------------------

--- Makes a member learn a new skill.
-- @tparam MemberArguments args
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
-- Learns new skills if level increased, but keeps old skills if decreased.
-- @tparam MemberArguments args
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
-- @tparam MemberArguments args
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
    battler.equipSet:setEquip(args.slot, item, troop.inventory)
  else
    battler.equipSet:setEquip(args.slot, item)
  end
  TroopManager:saveTroop(troop)
  if FieldManager.hud then
    FieldManager.hud:refreshSave(true)
  end
end
--- Adds or remove a status effect to the given member.
-- @tparam MemberArguments args
function PartyEvents:setStatus(args)
  local troop = Troop()
  local battler = troop.battlers[args.key]
  assert(battler, "No battler with key: " .. tostring(args.key))
  local status = Database.status[args.id]
  assert(status, "Status does not exist: " .. tostring(args.id))
  if args.remove then
    battler.statusList:removeStatus(status)
  else
    battler.statusList:addStatus(status)
  end
  TroopManager:saveTroop(troop)
  if FieldManager.hud then
    FieldManager.hud:refreshSave(true)
  end
end

return PartyEvents
