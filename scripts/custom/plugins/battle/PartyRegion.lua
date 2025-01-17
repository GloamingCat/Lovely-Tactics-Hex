
-- ================================================================================================

--- Sets custom party tiles in a battle field.
---------------------------------------------------------------------------------------------------
-- @plugin PartyRegion

--- Plugin parameters.
-- @tags Plugin
-- @tfield number partyX The parameters `party1`, `party2` ... `partyN` are the region ID's
--  associated with each field party `X`. 
-- @tfield boolean override Flag to completely override old method for setting player tiles,
--  instead of merging.

-- ================================================================================================

-- Imports
local TroopManager = require('core/battle/TroopManager')

-- Rewrites
local TroopManager_setPartyTiles = TroopManager.setPartyTiles

-- Parameters
local regionIDs = {}
do
  local i = 0
  while args['party' .. i] do
    regionIDs[i] = args['party' .. i]
    i = i + 1
  end
end
local merge = args.override ~= true

-- ------------------------------------------------------------------------------------------------
-- TroopManager
-- ------------------------------------------------------------------------------------------------

--- Rewrites `TroopManager:setPartyTiles`.
-- @rewrite
function TroopManager:setPartyTiles()
  if merge then
    TroopManager_setPartyTiles(self)
  end
  local field = FieldManager.currentField
  for i, partyInfo in ipairs(field.parties) do
    local id = i - 1
    local regionID = regionIDs[id]
    if regionID then
      for tile in field:gridIterator() do
        if tile.regionList:contains(regionID) then
          tile.party = id
        end
      end
    end
  end
end
