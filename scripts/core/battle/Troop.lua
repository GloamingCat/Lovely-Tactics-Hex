
--[[===============================================================================================

Troop
---------------------------------------------------------------------------------------------------
Manipulates the matrix of battler IDs to the instatiated in the beginning of the battle.

=================================================================================================]]

-- Imports
local Battler = require('core/battle/battler/Battler')
local Inventory = require('core/battle/Inventory')
local List = require('core/datastruct/List')

-- Alias
local mod = math.mod
local copyTable = util.table.deepCopy

local Troop = class()

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor. 
-- @param(data : table) Troop's data from database.
-- @param(party : number) The number of the field party spot this troops was spawned in.
function Troop:init(data, party)
  data = data or Database.troops[TroopManager.playerTroopID]
  self.data = data
  self.party = party
  self.tags = Database.loadTags(data.tags)
  local save = TroopManager.troopData[data.id .. ''] or data
  self.save = save
  self.inventory = Inventory(save.items)
  self.money = save.money
  self.sizeX = Config.troop.width
  self.sizeY = Config.troop.height
  -- Members
  self:initBattlers(save.members)
  -- Rotation
  self.rotation = 0
  -- AI
  if data.ai ~= '' then
    self.AI = require('custom/' .. data.ai)
  end
end
-- Creates battler for each member data in the given list that is not hidden.
-- @param(members : table) An array of member data.
function Troop:initBattlers(members)
  self.members = List(copyTable(members))
  self.battlers = {}
  for member in self.members:iterator() do
    if member.list < 2 then
      -- For when in battle
      local battler = Battler(self, member)
      self.battlers[member.key] = battler
    end
    self.members[member.key] = member
  end
end

---------------------------------------------------------------------------------------------------
-- Member Lists
---------------------------------------------------------------------------------------------------

-- Checks if a member with the given key exists and is not hidden.
-- @param(string) Member's key.
-- @ret(boolean) True if the current or backup list has a member with given key.
function Troop:hasMember(key)
  local list = List()
  for member in self.members:iterator() do
    if member.list ~= 2 and member.key == key then
      return true
    end
  end
  return false
end
-- @ret(List) List of all members in the current party grid.
function Troop:currentMembers()
  local list = List()
  for member in self.members:iterator() do
    if member.list == 0 then
      list:add(member)
    end
  end
  return list
end
-- @ret(List) List of backup members.
function Troop:backupMembers()
  local list = List()
  for member in self.members:iterator() do
    if member.list == 1 then
      list:add(member)
    end
  end
  return list
end
-- @ret(List) List of all hidden members.
function Troop:hiddenMembers()
  local list = List()
  for member in self.members:iterator() do
    if member.list == 2 then
      list:add(member)
    end
  end
  return list
end
-- @ret(List) List of all visible (current and backup) members.
function Troop:visibleMembers()
  local list = List(self.members)
  list:removeAll(self:hiddenMembers())
  return list
end
-- @ret(List) List of all battlers in the current party grid.
function Troop:currentBattlers()
  local list = self:currentMembers()
  for i = 1, #list do
    list[i] = self.battlers[list[i].key]
  end
  return list
end
-- @ret(List) List of all backup battlers.
function Troop:backupBattlers()
  local list = self:backupMembers()
  for i = 1, #list do
    list[i] = self.battlers[list[i].key]
  end
  return list
end
-- @ret(List) List of all visible (current and backup) battlers.
function Troop:visibleBattlers()
  local list = self:visibleMembers()
  for i = 1, #list do
    list[i] = self.battlers[list[i].key]
  end
  return list
end
-- Moves a member to another list.
-- @param(key : string) Member's key.
-- @param(list : number) List type. 0 is current, 1 is backup, 2 is hidden.
-- @param(x : number) Grid-x position of the member (optional).
-- @param(y : number) Grid-y position of the member (optional).
-- @ret(Battle) The called member.
function Troop:moveMember(key, list, x, y)
  assert(self.members[key], 'Member ' .. tostring(key) .. ' not in ' .. tostring(self))
  local member = self.members[key]
  member.list = list
  member.x = x or member.x
  member.y = y or member.y
  return member
end

---------------------------------------------------------------------------------------------------
-- Rotation
---------------------------------------------------------------------------------------------------

-- Sets the troop rotation (and adapts the ID matrix).
-- @param(r : number) New rotation.
function Troop:setRotation(r)
  for i = mod(r - self.rotation, 4), 1, -1 do
    self:rotate()
  end
end
-- Rotates by 90.
function Troop:rotate()
  for member in self.members:iterator() do
    local i, j = member.x, member.y
    member.x, member.y = j, self.sizeX - i + 1
  end
  self.rotation = mod(self.rotation + 1, 4)
  self.sizeX, self.sizeY = self.sizeY, self.sizeX
end
-- @ret(number) Character direction in degrees.
function Troop:getCharacterDirection()
  local baseDirection = math.field.baseDirection() -- Characters' direction at rotation 0.
  return mod(baseDirection + self.rotation * 90, 360)
end

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Converting to string.
-- @ret(string) A string representation.
function Troop:__tostring()
  local party = self.party and ' (party ' .. self.party .. ')' or ''
  return 'Troop ' .. self.data.id .. ': ' .. self.data.name .. party
end
-- Creates the table to represent troop's persistent data.
-- @param(saveFormation : boolean) True to save modified grid formation (optional).
-- @ret(table) Table with persistent data.
function Troop:getState(saveFormation)
  if not self.data.persistent then
    return nil
  end
  local data = {}
  data.money = self.money
  data.items = self.inventory:getState()
  data.members = {}
  data.rotation = saveFormation and self.rotation or self.save.rotation
  local members = saveFormation and self.members or self.save.members
  for i = 1, #members do
    local member = members[i]
    if self.battlers[member.key] then
      -- For when in battle
      data.members[i] = self.battlers[member.key]:getState(member.list, member.x, member.y)
    else
      data.members[i] = member
    end
  end
  return data
end

return Troop
