
--[[===============================================================================================

KillCheat
---------------------------------------------------------------------------------------------------
Adds a key to kill all enemies in the nuxt turn during battle.
Used to skip battles during game test.

-- Plugin parameters:
When player presses the button key <win>, all enemy characters die.
When player presses the button key <lose>, all ally characters die.

=================================================================================================]]

-- Imports
local TurnManager = require('core/battle/TurnManager')

-- Parameters
KeyMap.main['win'] = args.win
KeyMap.main['lose'] = args.lose

---------------------------------------------------------------------------------------------------
-- TurnManager
---------------------------------------------------------------------------------------------------

-- Kills all enemies of the given party.
-- @param(party : number)
local function killAll(party)
  for char in TroopManager.characterList:iterator() do
    if char.party ~= party then
      char.battler.state.hp = 0
    end
  end
end
-- Override. Check lose and win keys.
local TurnManager_runTurn = TurnManager.runTurn
function TurnManager:runTurn()
  if InputManager.keys['win']:isPressing() then
    killAll(TroopManager.playerParty)
    return 1, TroopManager.playerParty
  elseif InputManager.keys['lose']:isPressing() then
    local party = #TroopManager.troops - TroopManager.playerParty
    killAll(party)
    return -1, party
  else
   return TurnManager_runTurn(self)
  end
end
