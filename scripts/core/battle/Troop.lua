
--[[===============================================================================================

Troop
---------------------------------------------------------------------------------------------------
Manipulates the matrix of battler IDs to the instatiated in the beginning of the battle.

=================================================================================================]]

-- Imports
local List = require('core/datastruct/List')
local Matrix2 = require('core/math/Matrix2')
local TagMap = require('core/datastruct/TagMap')
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
  -- Grid and members
  self.grid = Matrix2(sizeX, sizeY)
  self.backup = List(data.backup)
  self.hidden = List(data.hidden)
  self.battlers = List()
  for i = 1, #data.current do
    local battler = data.current[i]
    self.grid:set(battler, battler.x + 1, battler.y + 1)
    self.battlers:add(battler)
  end
  -- Inventory and money
  self.inventory = Inventory(data.items)
  self.gold = data.gold
  -- Rotation
  self.rotation = 0
  -- AI
  local ai = data.scriptAI
  if ai.path ~= '' then
    self.AI = require('custom/' .. ai.path)(self)
  end
  -- Tags
  self.tags = TagMap(data.tags or {})
  -- TODO: load persistent data from data's ID
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
      local id = self.grid:get(i, j)
      grid:set(id, sizeY - j + 1, i)
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
  local enemies = List(TroopManager.characterList)
  enemies:conditionalRemove(
    function(e) 
      return e.battler.party == self.party or e.battler:isAlive() 
    end)
  for enemy in enemies:iterator() do
    self:addTroopRewards(enemy)
    self:addMemberRewards(enemy)
  end
end
-- Adds the troop's rewards (money).
-- @param(enemy : Character)
function Troop:addTroopRewards(enemy)
  self.gold = self.gold + enemy.battler.gold
end
-- Adds each troop member's rewards (experience).
-- @param(enemy : Character)
function Troop:addMemberRewards(enemy)
  for battler in self.battlers:iterator() do
    battler.exp = battler.exp + enemy.battler.exp
  end
end

return Troop
  