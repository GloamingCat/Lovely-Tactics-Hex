
--[[===============================================================================================

Troop
---------------------------------------------------------------------------------------------------
Manipulates the matrix of battler IDs to the instatiated in the beginning of the battle.

=================================================================================================]]

-- Imports
local List = require('core/datastruct/List')
local Matrix2 = require('core/math/Matrix2')
local TagMap = require('core/datastruct/TagMap')
local Battler = require('core/battle/Battler')
local Inventory = require('core/battle/Inventory')

-- Alias
local mod = math.mod

-- Constants
local sizeX = Config.troop.width
local sizeY = Config.troop.height
local baseDirection = 315 -- characters' direction at rotation 0

local Troop = class()

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor. 
-- @param(grid : Matrix2) the matrix of battler IDs (optiontal, empty by default)
-- @param(r : number) the rotation of the troop (optional, 0 by default)
function Troop:init(data, party)
  self.data = data
  self.party = party
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
  -- Grid
  self.grid = Matrix2(sizeX, sizeY)
  for i = 1, #data.current do
    local member = data.current[i]
    self.grid:set(member, member.x, member.y)
  end
  -- Rotation
  self.rotation = 0
  -- AI
  local ai = data.scriptAI
  if ai.path ~= '' then
    self.AI = require('custom/' .. ai.path)(self)
  end
  -- Tags
  self.tags = TagMap(data.tags)
end
-- Sets troop's state given the initial state data.
-- @param(data : table) data from save file or database file
function Troop:initState(data)
  self.current = List(data.current)
  self.backup = List(data.backup)
  self.hidden = List(data.hidden)
  self.members = List(data.current)
  self.members:addAll(data.backup)
  self.inventory = Inventory(data.inventory)
  self.gold = data.gold
end

---------------------------------------------------------------------------------------------------
-- Rotation
---------------------------------------------------------------------------------------------------

-- Sets the troop rotation (and adapts the ID matrix).
-- @param(r : number) new rotation
function Troop:setRotation(r)
  for i = mod(r - self.rotation, 4), 1, -1 do
    self:rotate()
  end
end
-- Rotates by 90.
function Troop:rotate()
  local sizeX, sizeY = self.grid.width, self.grid.height
  local grid = Matrix2(sizeY, sizeX)
  for i = 1, sizeX do
    for j = 1, sizeY do
      local battler = self.grid:get(i, j)
      grid:set(battler, sizeY - j + 1, i)
    end
  end
  self.grid = grid
  self.rotation = mod(self.rotation + 1, 4)
end
-- Gets the character direction in degrees.
-- @ret(number)
function Troop:getCharacterDirection()
  return mod(baseDirection + self.rotation * 90, 360)
end

---------------------------------------------------------------------------------------------------
-- Rewards
---------------------------------------------------------------------------------------------------

-- Adds the rewards from the defeated enemies.
function Troop:addRewards()
  -- List of living party members
  local characters = List(TroopManager.characterList)
  characters:conditionalRemove(
    function(c)
      return c.battler.party ~= self.party or not c.battler:isAlive() 
    end)
  -- List of backup party members
  local backup = List(self.members)
  characters:conditionalRemove(
    function(m)
      return m.battler.party ~= self.party or not m.battler:isAlive() 
    end)
  -- List of dead enemies
  local enemies = List(TroopManager.characterList)
  enemies:conditionalRemove(
    function(e)
      return e.battler.party == self.party or e.battler:isAlive() 
    end)
  for enemy in enemies:iterator() do
    self:addTroopRewards(enemy)
    self:addMemberRewards(enemy, characters)
  end
  self.gold = self.gold + 1000
end
-- Adds the troop's rewards (money).
-- @param(enemy : Character)
function Troop:addTroopRewards(enemy)
  self.gold = self.gold + enemy.battler.data.gold
end
-- Adds each troop member's rewards (experience).
-- @param(enemy : Character)
function Troop:addMemberRewards(enemy, characters)
  for char in characters:iterator() do
    char.battler.exp = char.battler.exp + enemy.battler.data.exp
  end
  for member in self.backup:iterator() do
    member.data.exp = (member.data.exp or 0) + enemy.battler.data.exp / 2
  end
end

---------------------------------------------------------------------------------------------------
-- Change members
---------------------------------------------------------------------------------------------------

function Troop:createMember(member)
end

function Troop:deleteMember(key)

end

---------------------------------------------------------------------------------------------------
-- Persistent Data
---------------------------------------------------------------------------------------------------

function Troop:getMemberData(key)
  if self.data.persistent then
    return self.memberData[key].data
  end
end

function  Troop:setMemberData(key, data)
  if self.data.persistent then
    self.memberData[key].data = data
  end
end

function Troop:getMembersData(arr)
  local data = {}
  for i = 1, #arr do
    local member = arr[i]
    data[i] = self.memberData[member.key] or member
  end
  return data
end

function Troop:setMembersData(arr)
  for i = 1, #arr do
    local member = arr[i]
    self.memberData[member.key] = member
  end
end

function Troop:createPersistentData()
  local data = {}
  data.gold = self.gold
  data.items = self.inventory:getState()
  data.current = self:getMembersData(self.current)
  data.backup = self:getMembersData(self.backup)
  data.hidden = self:getMembersData(self.hidden)
  return data
end

return Troop