
--[[===============================================================================================

Troop
---------------------------------------------------------------------------------------------------
Manipulates the matrix of battler IDs to the instatiated in the beginning of the battle.

=================================================================================================]]

-- Imports
local List = require('core/datastruct/List')
local Matrix2 = require('core/math/Matrix2')
local Battler = require('core/battle/Battler')
local TroopBase = require('core/battle/TroopBase')

-- Alias
local mod = math.mod

-- Constants
local sizeX = Config.troop.width
local sizeY = Config.troop.height
local baseDirection = 315 -- characters' direction at rotation 0

local Troop = class(TroopBase)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor. 
-- @param(data : table) troop's data from database
-- @param(party : number) the number of the field party spot this troops was spawned in
function Troop:init(data, party)
  TroopBase.init(self, data)
  self.party = party
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
-- Characters
---------------------------------------------------------------------------------------------------

-- Adds a character to the field that represents the member with the given key.
-- @param(key : string) member's key
-- @param(tile : ObjectTile) the tile the character will be put in
-- @ret(Character) the newly created character for the member
function Troop:callMember(key, tile)
  local i = self:findMember(key, self.backup)
  assert(i, 'Could not call member ' .. key .. ': not in backup list.')
  local member = self.backup:remove(i)
  self.current:add(member)
  local dir = self:getCharacterDirection()
  local character = TroopManager:createCharacter(tile, dir, member, self.party)
  TroopManager:createBattler(character)
  return character
end
-- Removes a member character.
-- @param(char : Character)
function Troop:removeMember(char)
  local i = self:findMember(char.key, self.current)
  assert(i, 'Could not remove member ' .. char.key .. ': not in current list.')
  local member = self.current:remove(i)
  self.backup:add(member)
  self:setMemberData(char.key, char.battler:createPersistentData())
  TroopManager:removeCharacter(char)
end
-- Gets the characters in the field that are in this troop.
-- @param(alive) true to include only alive character, false to only dead, nil to both
-- @ret(List)
function Troop:currentCharacters(alive)
  local characters = List(TroopManager.characterList)
  characters:conditionalRemove(
    function(c)
      return c.battler.party ~= self.party or c.battler:isAlive() == not alive
    end)
  return characters
end

---------------------------------------------------------------------------------------------------
-- Rewards
---------------------------------------------------------------------------------------------------

-- Adds the rewards from the defeated enemies.
function Troop:addRewards()
  -- List of living party members
  local characters = self:currentCharacters(true)
  -- List of dead enemies
  local enemies = List(TroopManager.characterList)
  enemies:conditionalRemove(
    function(e)
      return e.battler.party == self.party or e.battler:isAlive() 
    end)
  for enemy in enemies:iterator() do
    self:addTroopRewards(enemy)
    self:addMembersRewards(enemy, characters)
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
function Troop:addMembersRewards(enemy, characters)
  characters = characters or self:currentCharacters(true)
  for char in characters:iterator() do
    char.battler.exp = char.battler.exp + enemy.battler.data.exp
    -- TODO: check level up
  end
end

return Troop