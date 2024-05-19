
-- ================================================================================================

--- Contains information about the units and their respective `Battler`s.
-- It manipulates the matrix of units to be instatiated in the beginning of the battle.
---------------------------------------------------------------------------------------------------
-- @battlemod Troop

-- ================================================================================================

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
-- Tables
-- ------------------------------------------------------------------------------------------------

--- The different group types the unit can be in.
-- @enum Group
-- @field CURRENT Group of current active battlers. Equals to 0.
-- @field BACKUP Group of backup battlers, not active in battle. Equals to 1.
-- @field HIDDEN Group of currently unaccessible battlers. Equals to 2.
Troop.Group = {
  CURRENT = 0,
  BACKUP = 1,
  HIDDEN = 2
}

--- A troop unit entry.
-- @table Unit
-- @tfield string key The unit's identified. It must be unique within the troop.
-- @tfield number|string battlerID The ID or key of the unit's battler data.
-- @tfield number|string charID The ID or key of the unit's character data.
-- @tfield Group list The identifier of the group this unit is currently in.
-- @tfield[opt] number x The unit's x position in the troop grid (if unit is active).
-- @tfield[opt] number y The unit's y position in the troop grid (if unit is active.
-- @tfield[opt] table state The unit's persistent data (if the battler is persistent).
Troop.emptyUnit = {
  key = "",
  battlerID = -1,
  charID = -1,
  list = 0,
  x = 1,
  y = 1,
  state = nil,
}

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
-- @tparam table members An array of `Unit` entries.
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
--- Creates a list with all members in the current party grid.
-- @treturn List List of `Unit` entries.
function Troop:currentMembers()
  local list = List()
  for member in self.members:iterator() do
    if member.list == self.Group.CURRENT then
      list:add(member)
    end
  end
  return list
end
--- Creates a list with all backup members.
-- @treturn List List of `Unit` entries.
function Troop:backupMembers()
  local list = List()
  for member in self.members:iterator() do
    if member.list == self.Group.BACKUP then
      list:add(member)
    end
  end
  return list
end
--- Creates a list with all hidden members.
-- @treturn List List of `Unit` entries.
function Troop:hiddenMembers()
  local list = List()
  for member in self.members:iterator() do
    if member.list == self.Group.HIDDEN then
      list:add(member)
    end
  end
  return list
end
--- Creates a list with all visible (current and backup) members.
-- @treturn List List of `Unit` entries.
function Troop:visibleMembers()
  local list = List(self.members)
  list:removeAll(self:hiddenMembers())
  return list
end
--- Creates a list with all battlers in the current party grid
-- @treturn List List of `Battler`.
function Troop:currentBattlers()
  local list = self:currentMembers()
  for i = 1, #list do
    list[i] = self.battlers[list[i].key]
  end
  return list
end
--- Creates a list with all backup battlers.
-- @treturn List List of `Battler`.
function Troop:backupBattlers()
  local list = self:backupMembers()
  for i = 1, #list do
    list[i] = self.battlers[list[i].key]
  end
  return list
end
--- Creates a list with all visible (current and backup) battlers.
-- @treturn List List of `Battler`.
function Troop:visibleBattlers()
  local list = self:visibleMembers()
  for i = 1, #list do
    list[i] = self.battlers[list[i].key]
  end
  return list
end
--- Counts the number of units that have Battlers of the given ID.
-- @tparam string id The battler's key or ID in the database.
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
--- Adds a new member to the troop. It is put initially in the backup group.
-- @tparam table member The troop unit data of the character.
-- @tparam[opt] Battler battler Member's battler.
function Troop:addMember(member, battler)
  self.members[member.key] = member
  self.members:add(member)
  self.battlers[member.key] = battler
  member.list = self.Group.BACKUP
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
-- @tparam Group list Group in which to put this unit in.
-- @tparam[opt] number x Grid-x position of the member.
-- @tparam[opt] number y Grid-y position of the member.
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
-- @tparam number r New rotation, from 0 (default rotation) to 3 (270-degree turn).
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
--- Gets the direction the characters are facing when the troop is not rotated.
-- @treturn number Character direction in degrees.
function Troop:getCharacterDirection()
  local baseDirection = math.field.baseDirection() -- Characters' direction at rotation 0.
  return mod(baseDirection + self.rotation * 90, 360)
end

-- ------------------------------------------------------------------------------------------------
-- Level
-- ------------------------------------------------------------------------------------------------

--- Computes the average level among visible members.
-- @treturn number Troop's average level.
function Troop:getLevel()
  local level = 0
  local list = self:visibleBattlers()
  for i = 1, #list do
    level = level + list[i].job.level
  end
  return level / #list
end
--- Computes the higher level among visible members.
-- @treturn number Troop's highest level.
function Troop:getMaxLevel()
  local level = 0
  local list = self:visibleBattlers()
  for i = 1, #list do
    level = math.max(level, list[i].job.level)
  end
  return level
end
--- Computes the minimum level among visible members.
-- @treturn number Troop's lowest level.
function Troop:getMinLevel()
  local level = math.huge
  local list = self:visibleBattlers()
  for i = 1, #list do
    level = math.min(level, list[i].job.level)
  end
  return level
end

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

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
-- For debugging.
function Troop:__tostring()
  local party = self.party and ' (party ' .. self.party .. ')' or ''
  return 'Troop ' .. self.data.id .. ': ' .. self.data.name .. party
end

return Troop
