
--[[===============================================================================================

KillCheat
---------------------------------------------------------------------------------------------------
Adds a key to kill all enemies in the nuxt turn during battle.
Used to skip battles during game test.

=================================================================================================]]

KeyMap[args.key] = 'kill'

-- Imports
local TurnManager = require('core/battle/TurnManager')

local function killAll(party)
  for char in TroopManager.characterList:iterator() do
    if char.battler.party ~= party then
      char.battler:kill()
    end
  end
end

local old_runTurn = TurnManager.runTurn
function TurnManager:runTurn()
  if InputManager.keys['kill']:isPressing() then
    killAll(TroopManager.playerParty)
    return 1, TroopManager.playerParty
  else
   return old_runTurn(self)
  end
end

