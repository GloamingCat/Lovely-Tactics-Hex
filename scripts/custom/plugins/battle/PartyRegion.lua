
--[[===============================================================================================

PartyRegion
---------------------------------------------------------------------------------------------------
Sets custom party tiles in a battle field.

-- Plugin parameters:
party1, party2 ... partyN: the region ID's associated with each field party.
Set <override> to completely override old method, instead of merging.

=================================================================================================]]

-- Parameters
local regionIDs = {}
do
  local i = 0
  while args['party' .. i] do
    regionIDs[i] = tonumber(args['party' .. i])
    i = i + 1
  end
end
local merge = not args.override

-- Imports
local FieldLoader = require('core/field/FieldLoader')

---------------------------------------------------------------------------------------------------
-- FieldLoader
---------------------------------------------------------------------------------------------------

-- Override. Checks for tile regions.
local FieldLoader_setPartyTiles = FieldLoader.setPartyTiles
function FieldLoader.setPartyTiles(field)
  if merge then
    FieldLoader_setPartyTiles(field)
  end
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
