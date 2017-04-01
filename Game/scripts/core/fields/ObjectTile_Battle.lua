
--[[===========================================================================

ObjectTile - Battle
-------------------------------------------------------------------------------
Implements functions that are only used in battle.

=============================================================================]]

-- Imports
local List = require('core/algorithm/List')
local Animation = require('core/graphics/Animation')

-- Alias
local tile2Pixel = math.field.tile2Pixel
local max = math.max

-- Constants
local tileW = Config.grid.tileW
local tileH = Config.grid.tileH

local ObjectTile_Battle = require('core/class'):new()

-------------------------------------------------------------------------------
-- General
-------------------------------------------------------------------------------

-- Gets the terrain move cost in this tile.
-- @ret(number) the move cost
function ObjectTile_Battle:getMoveCost()
  return FieldManager.currentField:getMoveCost(self.x, self.y, 
    self.layer.height)
end

-------------------------------------------------------------------------------
-- Grid GUI
-------------------------------------------------------------------------------

-- Creates the graphical elements for battle grid navigation.
function ObjectTile_Battle:createGridGUI()
  local renderer = FieldManager.renderer
  local x, y, z = tile2Pixel(self:coordinates())
  x = x - tileW / 2
  y = y - tileH / 2
  if Config.gui.tileAnimID >= 0 then
    local baseAnim = Database.animOther[Config.gui.tileAnimID + 1]
    self.baseAnim = Animation.fromData(baseAnim, renderer)
    self.baseAnim.sprite:setXYZ(x, y, z)
  end
  if Config.gui.tileHLAnimID >= 0 then
    local hlAnim = Database.animOther[Config.gui.tileHLAnimID + 1]
    self.highlightAnim = Animation.fromData(hlAnim, renderer)
    self.highlightAnim.sprite:setXYZ(x, y, z)
  end
  self:hide()
end

-- Updates graphics animation.
function ObjectTile_Battle:update()
  if self.highlightAnim then
    self.highlightAnim:update()
  end
  if self.baseAnim then
    self.baseAnim:update()
  end
end

-- Updates graphics pixel depth according to the terrains' 
--  depth in this tile's coordinates.
function ObjectTile_Battle:updateDepth()
  local tiles = FieldManager.currentField.terrainLayers[self.layer.height]
  local maxDepth = tiles[1].grid[self.x][self.y].depth
  for i = #tiles, 2, -1 do
    maxDepth = max(maxDepth, tiles[i].grid[self.x][self.y].depth)
  end
  if self.baseAnim then
    self.baseAnim.sprite:setOffset(nil, nil, maxDepth / 2)
  end
  if self.highlightAnim then
    self.highlightAnim.sprite:setOffset(nil, nil, maxDepth / 2 - 1)
  end
end

-------------------------------------------------------------------------------
-- Troop
-------------------------------------------------------------------------------

-- Returns the list of battlers that are suitable for this tile.
-- @ret(List) the list of battlers
function ObjectTile_Battle:getBattlerList()
  local battlers = nil
  if self.party == 0 then
    battlers = PartyManager:backupBattlers()
  else
    battlers = List()
    for regionID in self.regionList:iterator() do
      local data = Config.regions[regionID + 1]
      for i = 1, #data.battlers do
        local id = data.battlers[i]
        local battlerData = Database.battlers[id + 1]
        battlers:add(battlerData)
      end
    end
  end
  battlers:conditionalRemove(function(battler) 
      return not self.battlerTypeList:contains(battler.typeID)
    end)
  return battlers
end

-- Checks if any of types in a table are in this tile.
-- @ret(boolean) true if contains one or more types, falsa otherwise
function ObjectTile_Battle:containsBattleType(types)
  for i = 1, #types do
    local typeID = types[i]
    if self.battlerTypeList:contains(typeID) then
      return true
    end
  end
  return false
end

-------------------------------------------------------------------------------
-- Parties
-------------------------------------------------------------------------------

-- Checks if this tile os in control zone for given party.
-- @param(you : Battler) the battler of the current character
-- @ret(boolean) true if it's control zone, false otherwise
function ObjectTile_Battle:isControlZone(you)
  local containsAlly, containsEnemy = false, false
  for char in self.characterList:iterator() do
    if char.battler then
      if char.battler.party == you.party then
        containsAlly = true
      else
        containsEnemy = true
      end
    end
  end
  if containsEnemy then
    return true
  elseif containsAlly then
    return false
  end
  for n in self.neighborList:iterator() do
    for char in n.characterList:iterator() do
      if char.battler and char.battler.party ~= you.party then
        return true
      end
    end
  end
  return false
end

-- Gets the party of the current character in the tile.
-- @ret(number) the party number (nil if more than one character with different parties)
function ObjectTile_Battle:getCurrentParty()
  local party = nil
  for c in self.characterList:iterator() do
    if c.battler then
      if party == nil then
        party = c.battler.party
      elseif c.battler.party ~= party then
        return nil
      end
    end
  end
  return party
end

-- Checks if there are any enemies in this tile (character with a different party number)
-- @param(yourPaty : number) the party number to check
-- @ret(boolean) true if there's at least one enemy, false otherwise
function ObjectTile_Battle:hasEnemy(yourParty)
  for c in self.characterList:iterator() do
    if c.battler and c.battler.party ~= yourParty then
      return true
    end
  end
end

-- Checks if there are any allies in this tile (character with the same party number)
-- @param(yourPaty : number) the party number to check
-- @ret(boolean) true if there's at least one ally, false otherwise
function ObjectTile_Battle:hasAlly(yourParty)
  for c in self.characterList:iterator() do
    if c.party == yourParty then
      return true
    end
  end
end

-------------------------------------------------------------------------------
-- Grid GUI
-------------------------------------------------------------------------------

-- Selects / deselects this tile.
-- @param(value : boolean) true to select, false to deselect
function ObjectTile_Battle:setSelected(value)
  if self.highlightAnim then
    self.highlightAnim.sprite:setVisible(value)
  end
end

-- Sets color to the color with the given label.
-- @param(name : string) color label
function ObjectTile_Battle:setColor(name)
  self.colorName = name
  if name == nil or name == '' then
    name = 'nothing'
  end
  name = 'tile_' .. name
  if not self.selectable then
    name = name .. '_off'
  end
  local c = Color[name]
  self.baseAnim.sprite:setColor(c)
end

-- Shows tile edges.
function ObjectTile_Battle:show()
  if self.baseAnim then
    self.baseAnim.sprite:setVisible(true)
  end
end

-- Hides tile edges.
function ObjectTile_Battle:hide()
  if self.baseAnim then
    self.baseAnim.sprite:setVisible(false)
  end
  self:setSelected(false)
end

return ObjectTile_Battle