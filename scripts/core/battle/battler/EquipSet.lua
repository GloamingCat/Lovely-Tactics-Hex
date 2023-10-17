
-- ================================================================================================

--- Represents the equipment set of a battler.
-- ------------------------------------------------------------------------------------------------
-- @classmod EquipSet

-- ================================================================================================

-- Alias
local deepCopyTable = util.table.deepCopy
local findByKey = util.array.findByKey

-- Class table.
local EquipSet = class()

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam Battler battler This set's battler.
-- @tparam table save Battler's save data (optional).
function EquipSet:init(battler, save)
  self.battler = battler
  self.slots = {}
  self.types = {}
  self.bonus = {}
  local equips = save and save.equips
  if equips then
    self.slots = deepCopyTable(equips.slots)
    self.types = deepCopyTable(equips.types)
  else
    local equips = battler.data.equip
    for i, slot in ipairs(Config.equipTypes) do
      self.types[slot.key] = { state = slot.state, count = slot.count }
      for k = 1, slot.count do
        local key = slot.key .. k
        local slotData = equips and findByKey(equips, key) 
        if slotData then
          self.slots[key] = deepCopyTable(slotData)
        else 
          self.slots[key] = { id = -1 }
        end
      end
    end
  end
  for k, slot in pairs(self.slots) do
    if battler and slot.id >= 0 then
      self:addStatus(Database.items[slot.id])
    end
    self:updateSlotBonus(k)
  end
end

-- ------------------------------------------------------------------------------------------------
-- Equip / Unequip
-- ------------------------------------------------------------------------------------------------

--- Gets the state of the current slot.
-- @tparam table slotType Slot type data.
-- @tparam string key Specific slot key.
-- @treturn number
function EquipSet:slotState(slotType, key)
  if self.slots[key] and self.slots[key].state ~= nil and self.slots[key].state > 0 then
    return self.slots[key].state
  else
    return slotType.state
  end
end
--- Gets the ID of the current equip in the given slot.
-- @tparam string key Slot's key.
-- @treturn number The ID of the equip item (-1 if none).
function EquipSet:getEquip(key)
  assert(self.slots[key], 'Slot does not exist: ' .. tostring(key))
  return Database.items[self.slots[key].id]
end
--- Sets the equip item in the given slot.
-- @tparam string key Slot's key.
-- @tparam table item Item's data from database.
-- @tparam Inventory inventory Troop's inventory.
-- @tparam Character character Battler's character, in case it's during battle (optional).
function EquipSet:setEquip(key, item, inventory, character)
  if item then
    assert(item.slot ~= '', 'Item is not an equipment: ' .. Database.toString(item))
    self:equip(key, item, inventory, character)
  else
    self:unequip(key, inventory, character)
  end
  if self.battler then
    self.battler:refreshState()
  end
end
--- Inserts equipment item in the given slot.
-- @tparam string key Slot's key.
-- @tparam table item Item's data from database.
-- @tparam Inventory inventory Troop's inventory.
-- @tparam Character character Battler's character, in case it's during battle (optional).
function EquipSet:equip(key, item, inventory, character)
  local slot = self.slots[key]
  -- If slot is blocked
  if slot.block and self.slots[slot.block] then
    self:unequip(slot.block, inventory, character)
  end
  -- Unequip slots from the same slot type
  if item.allSlots then
    key = item.slot .. '1'
    slot = self.slots[key]
    self:unequip(item.slot, inventory, character)
  else
    self:unequip(key, inventory, character)
  end
  if self.types[item.slot] then
    for i = 1, self.types[item.slot].count do
      local key2 = item.slot .. i
      local equip = key2 ~= key and self:getEquip(key2)
      if equip and equip.allSlots then
        self:unequip(key2, inventory, character)
      end
    end
  end
  for i = 1, #item.blocked do
    self:unequip(item.blocked[i], inventory, character)
  end
  -- Block slots
  for i = 1, #item.blocked do
    self:setBlock(item.blocked[i], key)
  end
  if item.allSlots then
    self:setBlock(item.slot, item.slot)
  end
  slot = self.slots[key]
  if self.battler then
    self:addStatus(item, character)
  end
  if inventory then
    inventory:removeItem(item.id)
  end
  slot.id = item and item.id or -1
  self:updateSlotBonus(key)
end
--- Removes equipment item (if any) from the given slot.
-- @tparam string key Slot's key.
-- @tparam Inventory inventory Troop's inventory.
-- @tparam Character character Battler's character, in case it's during battle (optional).
function EquipSet:unequip(key, inventory, character)
  if self.types[key] then
    for i = 1, self.types[key].count do
      self:unequip(key .. i, inventory, character)
    end
  else
    local slot = self.slots[key]
    local previousEquip = slot.id
    if previousEquip >= 0 then
      local data = Database.items[previousEquip]
      if self.battler then
        self:removeStatus(data, character)
      end
      if inventory then
        inventory:addItem(previousEquip)
      end
      slot.id = -1
      -- Unblock slots
      for i = 1, #data.blocked do
        self:setBlock(data.blocked[i], nil)
      end
      -- Unblock slots from the same slot type
      if data.allSlots then
        self:setBlock(data.slot, nil)
      end
      self:updateSlotBonus(key)
    end
  end
end
--- Sets the block of all slots from the given type to the given value.
-- @tparam string key The type of slot (includes a number if it's a specific slot).
-- @tparam string block The name of the slot that it blocking, or nil to unblock.
function EquipSet:setBlock(key, block)
  if self.types[key] then
    for i = 1, self.types[key].count do
      local keyi = key .. i
      self.slots[keyi].block = block
    end
  else
    self.slots[key].block = block
  end
end
--- Checks if an item may be equiped in the given slot.
-- @tparam string key The key of the slot.
-- @tparam table item Item data.
-- @treturn boolean If the item may be equiped.
function EquipSet:canEquip(key, item)
  local slotType = self.types[item.slot]
  assert(slotType, 'Slot does not exist: ' .. tostring(item.slot))
  local state = self:slotState(slotType, key)
  if state >= 3 then
    return false
  end
  local currentItem = self:getEquip(key)
  if item == currentItem then
    return true
  end
  for i = 1, #item.blocked do
    if not self:canUnequip(item.blocked[i]) then
      return false
    end
  end
  if item.allSlots then
    if slotType.count > 1 and state == 2 then
      return false
    end
  end
  if self.types[item.slot] then
    for i = 1, self.types[item.slot].count do
      local key2 = item.slot .. i
      local equip = key2 ~= key and self:getEquip(key2)
      local block = self.slots[key2].block
      if equip and equip.allSlots and block and block ~= item.slot then
        return false
      end
    end
  end
  local block = self.slots[key].block
  if block and self.slots[block] then
    if not self:canUnequip(block) then
      return false
    end
  end
  return true
end
--- Checks if an slot can have its equipment item removed.
-- @tparam string key The key of the slot.
-- @treturn boolean True if already empty of if the item may be removed.
function EquipSet:canUnequip(key)
  if self.types[key] then
    for i = 1, self.types[key].count do
      if not self:canUnequip(key .. i) then
        return false
      end
    end
    return true
  end
  local currentItem = self:getEquip(key)
  if currentItem then
    local slot = self.types[currentItem.slot]
    local state = self:slotState(slot, key)
    if state == 2 then
      return false
    elseif state == 1 then
      for i = 1, slot.count do
        local key2 = currentItem.slot .. i
        if key2 ~= key and self:getEquip(key2) then
          return true
        end
      end
      return false
    end
  end
  return true
end

-- ------------------------------------------------------------------------------------------------
-- Status
-- ------------------------------------------------------------------------------------------------

--- Adds all equipments' battle status.
-- @tparam Character character Battler's character.
function EquipSet:addBattleStatus(character)
  for key, slot in pairs(self.slots) do
    if slot.id >= 0 then
      local item = Database.items[slot.id]
      self:addStatus(item, character, true)
    end
  end
end
--- Adds the equip's statuses, either persistent or battle-only.
-- @tparam table data Item's data.
-- @tparam Character character Battler's character, in case it's during battle (optional).
-- @tparam boolean battle True to add battle status, false to add persistent status (optional).
function EquipSet:addStatus(data, character, battle)
  battle = battle or false
  for i = 1, #data.equipStatus do
    local s = data.equipStatus[i]
    if s.battle == battle then
      self.battler.statusList:addStatus(s.id, nil, character)
    end
  end
end
--- Removes the equip's persistent statuses.
-- @tparam table data Item's equip data.
-- @tparam Character character Battler's character, in case it's during battle (optional).
function EquipSet:removeStatus(data, character)
  for i = 1, #data.equipStatus do
    local s = data.equipStatus[i]
    if not s.battle then
      self.battler.statusList:removeStatus(s.id, character)
    end
  end
end

-- ------------------------------------------------------------------------------------------------
-- Bonus
-- ------------------------------------------------------------------------------------------------

--- Gets an attribute's total bonus given by the equipment.
-- @tparam string key Attribute's key.
-- @treturn number The total additive bonus.
-- @treturn number The total multiplicative bonus.
function EquipSet:attBonus(key)
  local add, mul = 0, 0
  for k, slot in pairs(self.bonus) do
    add = add + (slot.attAdd[key] or 0)
    mul = mul + (slot.attMul[key] or 0)
  end
  return add, mul
end
--- Gets the attack element given by the equipment.
-- @tparam number id Element's ID.
-- @treturn number The total bonus.
function EquipSet:elementAtk(id)
  local e = 0
  for _, slot in pairs(self.bonus) do
    e = e + (slot.elementAtk[id] or 0)
  end
  return e
end
--- Gets the total element immunity given by the equipment.
-- @tparam number id Element's ID.
-- @treturn number The total bonus.
function EquipSet:elementDef(id)
  local e = 0
  for _, slot in pairs(self.bonus) do
    e = e + (slot.elementDef[id] or 0)
  end
  return e
end
--- Gets element damage bonus given by the equipment.
-- @tparam number id Element's ID.
-- @treturn number The total bonus.
function EquipSet:elementBuff(id)
  local e = 0
  for _, slot in pairs(self.bonus) do
    e = e + (slot.elementBuff[id] or 0)
  end
  return e
end

-- ------------------------------------------------------------------------------------------------
-- Equip Bonus
-- ------------------------------------------------------------------------------------------------

--- Updates the tables of equipment attribute and element bonus.
-- @tparam string key Slot's key.
function EquipSet:updateSlotBonus(key)
  local bonus = self.bonus[key]
  if not self.bonus[key] then
    bonus = {}
    self.bonus[key] = bonus
  end
  local slot = self.slots[key]
  local data = slot.id >= 0 and Database.items[slot.id]
  bonus.attAdd, bonus.attMul = self:equipAttributes(data)
  bonus.elementAtk, bonus.elementDef, bonus.elementBuff = self:equipElements(data)
end
--- Gets the table of equipment attribute bonus.
-- @tparam table equip Item's equip data.
-- @treturn table Additive bonus table.
-- @treturn table Multiplicative bonus table.
function EquipSet:equipAttributes(equip)
  local add, mul = {}, {}
  if equip then
    for i = 1, #equip.equipAttributes do
      local bonus = equip.equipAttributes[i]
      add[bonus.key] = (bonus.add or 0)
      mul[bonus.key] = (bonus.mul or 0) / 100
    end
  end
  return add, mul
end
--- Gets the table of equipment element bonus.
-- @tparam table equip Item's equip data.
-- @treturn table Array for attack elements.
-- @treturn table Array for element immunity.
-- @treturn table Array for element damage.
function EquipSet:equipElements(equip)
  local atk, def, buff = {}, {}, {}
  if equip then
    for i = 1, #equip.elements do
      local b = equip.elements[i]
      if b.type == 0 then
        def[b.id + 1] = b.value / 100 - 1
      elseif b.type == 1 then
        atk[b.id + 1] = b.value / 100
      else
        buff[b.id + 1] = b.value / 100 - 1
      end
    end
  end
  return atk, def, buff
end

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Converting to string.
-- @treturn string A string representation.
function EquipSet:__tostring()
  return 'EquipSet: ' .. tostring(self.battler)
end
-- @treturn table Persistent state.
function EquipSet:getState()
  return {
    slots = deepCopyTable(self.slots),
    types = deepCopyTable(self.types) }
end
--- Gets the number of items of the given ID equipped.
-- @tparam number id The ID of the equipment item.
-- @treturn number The number of items equipped.
function EquipSet:getCount(id)
  local count = 0
  for _, v in pairs(self.slots) do
    if v.id == id then
      count = count + 1
    end
  end
  return count
end

return EquipSet
