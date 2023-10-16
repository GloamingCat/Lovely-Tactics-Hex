
--[[===============================================================================================

@classmod Troop
---------------------------------------------------------------------------------------------------
-- Manipulates the matrix of battler IDs to the instatiated in the beginning of the battle.

=================================================================================================]]

-- Imports
local Battler = require('core/battle/battler/Battler')
local Inventory = require('core/battle/Inventory')
local List = require('core/datastruct/List')

-- Alias
local mod = math.mod
local copyTable = util.table.deepCopy

-- Class table.
local Troop = class()

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor. 
-- @tparam table data Troop's data from database.
-- @tparam number party The number of the field party spot this troops was spawned in.
-- @tparam table save Troop's save data.
function Troop:init(data, party, save)
  data = data or Database.troops[TroopManager.playerTroopID]
  self.data = data
  self.party = party
  self.tags = Database.loadTags(data.tags)
  self.save = TroopManager.troopData[data.id .. ''] or data
  save = save or self.save
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
--- Creates battler for each member data in the given list that is not hidden.
-- @tparam table members An array of member data.
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

-- ------------------------------------------------------------------------------------------------
-- Member Lists
-- ------------------------------------------------------------------------------------------------

--- Checks if a member with the given key exists and is not hidden.
-- @tparam string key Member's key.
-- @treturn boolean True if the current or backup list has a member with given key.
function Troop:hasMember(key)
  local list = List()
  for member in self.members:iterator() do
    if member.list ~= 2 and member.key == key then
      return true
    end
  end
  return false
end
-- @treturn List List of all members in the current party grid.
function Troop:currentMembers()
  local list = List()
  for member in self.members:iterator() do
    if member.list == 0 then
      list:add(member)
    end
  end
  return list
end
-- @treturn List List of backup members.
function Troop:backupMembers()
  local list = List()
  for member in self.members:iterator() do
    if member.list == 1 then
      list:add(member)
    end
  end
  return list
end
-- @treturn List List of all hidden members.
function Troop:hiddenMembers()
  local list = List()
  for member in self.members:iterator() do
    if member.list == 2 then
      list:add(member)
    end
  end
  return list
end
-- @treturn List List of all visible (current and backup) members.
function Troop:visibleMembers()
  local list = List(self.members)
  list:removeAll(self:hiddenMembers())
  return list
end
-- @treturn List List of all battlers in the current party grid.
function Troop:currentBattlers()
  local list = self:currentMembers()
  for i = 1, #list do
    list[i] = self.battlers[list[i].key]
  end
  return list
end
-- @treturn List List of all backup battlers.
function Troop:backupBattlers()
  local list = self:backupMembers()
  for i = 1, #list do
    list[i] = self.battlers[list[i].key]
  end
  return list
end
-- @treturn List List of all visible (current and backup) battlers.
function Troop:visibleBattlers()
  local list = self:visibleMembers()
  for i = 1, #list do
    list[i] = self.battlers[list[i].key]
  end
  return list
end
-- @tparam string number The battler's key or ID in the database.
-- @treturn number The number of members in the party with the given battler ID.
function Troop:battlerCount(id)
  local count = 0
  local battler = Database.battlers[id]
  for member in self.members:iterator() do
    if member.list < 2 and member.battlerID == battler.id then
      count = count + 1
    end
  end
  return count
end
--- Adds a new member to the troop.
-- @tparam table member Member data.
-- @tparam Battler battler Member's battler (optional).
function Troop:addMember(member, battler)
  self.members[member.key] = member
  self.members:add(member)
  self.battlers[member.key] = battler
  member.list = 1
  member.x = 1
  member.y = 1
end
--- Deletes a member completely.
-- @tparam string key Member's key.
function Troop:removeMember(key)
  util.array.remove(self.members, self.members[key])
  self.members[key] = nil
  self.battlers[key] = nil
end
--- Moves a member to another list.
-- @tparam string key Member's key.
-- @tparam number list List type. 0 is current, 1 is backup, 2 is hidden.
-- @tparam number x Grid-x position of the member (optional).
-- @tparam number y Grid-y position of the member (optional).
-- @treturn Battle The called member.
function Troop:moveMember(key, list, x, y)
  assert(self.members[key], 'Member ' .. tostring(key) .. ' not in ' .. tostring(self))
  local member = self.members[key]
  member.list = list
  member.x = x or member.x
  member.y = y or member.y
  return member
end

-- ------------------------------------------------------------------------------------------------
-- Rotation
-- ------------------------------------------------------------------------------------------------

--- Sets the troop rotation (and adapts the ID matrix).
-- @tparam number r New rotation.
function Troop:setRotation(r)
  for i = mod(r - self.rotation, 4), 1, -1 do
    self:rotate()
  end
end
--- Rotates by 90.
function Troop:rotate()
  for member in self.members:iterator() do
    local i, j = member.x, member.y
    member.x, member.y = j, self.sizeX - i + 1
  end
  self.rotation = mod(self.rotation + 1, 4)
  self.sizeX, self.sizeY = self.sizeY, self.sizeX
end
-- @treturn number Character direction in degrees.
function Troop:getCharacterDirection()
  local baseDirection = math.field.baseDirection() -- Characters' direction at rotation 0.
  return mod(baseDirection + self.rotation * 90, 360)
end

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Converting to string.
-- @treturn string A string representation.
function Troop:__tostring()
  local party = self.party and ' (party ' .. self.party .. ')' or ''
  return 'Troop ' .. self.data.id .. ': ' .. self.data.name .. party
end
--- Creates the table to represent troop's persistent data.
-- @tparam boolean saveFormation Flag to include current formation in the persistent data.
-- @treturn table Table with persistent data.
function Troop:getState(saveFormation)
  local data = {}
  data.money = self.money
  data.items = self.inventory:getState()
  data.members = {}
  for i, member in ipairs(saveFormation and self.members or self.save.members) do
    if self.battlers[member.key] then
      -- For when in battle
      data.members[i] = self.battlers[member.key]:getState(member.list, member.x, member.y)
    else
      data.members[i] = copyTable(member)
    end
  end
  return data
end
-- @treturn number The higher level among visible members.
function Troop:getLevel()
  local level = 0
  local list = self:visibleBattlers()
  for i = 1, #list do
    level = math.max(level, list[i].job.level)
  end
  return level
end

return Troop
