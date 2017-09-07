
--[[===============================================================================================

TroopBase
---------------------------------------------------------------------------------------------------
Stores and manages the troop data and its members.

=================================================================================================]]

-- Imports
local List = require('core/datastruct/List')
local TagMap = require('core/datastruct/TagMap')
local Inventory = require('core/battle/Inventory')

local TroopBase = class()

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(data : table) troop's data from database
function TroopBase:init(data)
  self.data = data
  -- Members' persistent data
  if data.persistent then
    local save = SaveManager.current.troops[data.id]
    self:initState(save or data)
    -- Member data table
    self.memberData = {}
    self:setMembersData(self.current)
    self:setMembersData(self.backup)
    self:setMembersData(self.hidden)
  else
    self:initState(data)
  end
   -- Tags
  self.tags = TagMap(data.tags)
end
-- Sets troop's state given the initial state data.
-- @param(data : table) data from save file or database file
function TroopBase:initState(data)
  self.current = List(data.current)
  self.backup = List(data.backup)
  self.hidden = List(data.hidden)
  self.inventory = Inventory(data.inventory)
  self.gold = data.gold
end

---------------------------------------------------------------------------------------------------
-- Members
---------------------------------------------------------------------------------------------------

-- Searchs for a member with the given key.
-- @param(key : string) member's key
-- @ret(number) the index of the member in the member list (nil if not found)
-- @ret(List) the list the member is in (nil if not found)
function TroopBase:findMember(key, arr)
  if arr then
    for i = 1, #arr do
      if arr[i].key == key then
        return i, arr
      end
    end
  else
    local i = self:findMember(key, self.current)
    if i then
      return i, self.current
    end
    i = self:findMember(key, self.backup)
    if i then
      return i, self.backup
    end
    i = self:findMember(key, self.hidden)
    if i then
      return i, self.hidden
    end
  end
end

---------------------------------------------------------------------------------------------------
-- Persistent Data
---------------------------------------------------------------------------------------------------

-- Gets the data from the member with the given key.
-- @param(key : string) member's key
-- @ret(table)
function TroopBase:getMemberData(key)
  if self.data.persistent then
    return self.memberData[key].data
  end
end
-- Sets the data of the member with the given key.
-- @param(key : string) member's key
-- @param(data : table)
function TroopBase:setMemberData(key, data)
  if self.data.persistent then
    self.memberData[key].data = data
  end
end
-- Gets the list of members' data
-- param(arr : table) array of members
function TroopBase:getMembersData(arr)
  local data = {}
  for i = 1, #arr do
    local member = arr[i]
    data[i] = self.memberData[member.key] or member
  end
  return data
end
-- Stores members' data in the member's persistent data table.
-- @param(arr : table) array of members
function TroopBase:setMembersData(arr)
  for i = 1, #arr do
    local member = arr[i]
    self.memberData[member.key] = member
  end
end
-- Creates the table to represent troop's persistent data.
-- @param(saveFormation : boolean) true to saves modified grid formation (optional)
-- @ret(table)
function TroopBase:createPersistentData(saveFormation)
  if not self.data.persistent then
    return nil
  end
  local data = {}
  data.gold = self.gold
  data.items = self.inventory:getState()
  if saveFormation then
    data.current = self:getMembersData(self.current)
    data.backup = self:getMembersData(self.backup)
    data.hidden = self:getMembersData(self.hidden)
  else
    data.current = self:getMembersData(self.data.current)
    data.backup = self:getMembersData(self.data.backup)
    data.hidden = self:getMembersData(self.data.hidden)
  end
  return data
end

return TroopBase