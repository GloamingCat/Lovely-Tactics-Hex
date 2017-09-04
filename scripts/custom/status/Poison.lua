
--[[===============================================================================================

Poison
---------------------------------------------------------------------------------------------------
Life-draining status.

=================================================================================================]]

-- Imports
local PopupText = require('core/battle/PopupText')
local Status = require('core/battle/Status')

-- Alias
local floor = math.floor

-- Constants
local battlerVariables = Database.variables.battler
local lifeName = battlerVariables[Config.battle.attLifeID + 1].shortName

local Poison = class(Status)

---------------------------------------------------------------------------------------------------
-- Callbacks
---------------------------------------------------------------------------------------------------

function Poison:onTurnStart(char, partyTurn)
  if partyTurn then
    local pos = char.position
    local popupText = PopupText(pos.x, pos.y - 20, pos.z - 10)
    local value = floor(char.battler:maxLifePoints() / 10)
    local popupName = 'popup_dmg' .. lifeName
    popupText:addLine(value, Color[popupName], Font[popupName])
    char.battler:damage(lifeName, value)
    popupText:popup()
  end
  Status.onTurnStart(self, char, partyTurn)
end

return Poison
