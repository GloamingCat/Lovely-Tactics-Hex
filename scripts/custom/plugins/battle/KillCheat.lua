
-- ================================================================================================

--- Adds a key to kill all enemies in the nuxt turn during battle.
-- Used to skip battles during game test.
---------------------------------------------------------------------------------------------------
-- @plugin KillCheat

--- Plugin parameters.
-- @tags Plugin
-- @tfield string win Button key to stay pressed to make all enemy characters die in the next turn.
-- @tfield string lose Button key to stay pressed to make all ally characters die in the next turn.

-- ================================================================================================

-- Imports
local GameKey = require('core/input/GameKey')
local InputManager = require('core/input/InputManager')
local TurnManager = require('core/battle/TurnManager')

-- Rewrites
local InputManager_init = InputManager.init
local TurnManager_runTurn = TurnManager.runTurn

-- Parameters
local winKey = args.win
local loseKey = args.lose

-- ------------------------------------------------------------------------------------------------
-- TurnManager
-- ------------------------------------------------------------------------------------------------

--- Kills all enemies of the given party.
-- @tparam number party
local function killAll(party)
  for char in TroopManager.characterList:iterator() do
    if char.party ~= party then
      char.battler.state.hp = 0
    end
  end
end
--- Rewrites `TurnManager:runTurn`.
-- @rewrite
function TurnManager:runTurn(...)
  local enemyParty = #TroopManager.troops - TroopManager.playerParty
  if _G.InputManager.keys['win']:isPressing() and _G.InputManager.keys['lose']:isPressing() then
    killAll(TroopManager.playerParty)
    killAll(enemyParty)
    return 0, -1
  elseif _G.InputManager.keys['win']:isPressing() then
    killAll(TroopManager.playerParty)
    return 1, TroopManager.playerParty
  elseif _G.InputManager.keys['lose']:isPressing() then
    killAll(enemyParty)
    return -1, enemyParty
  else
   return TurnManager_runTurn(self, ...)
  end
end

-- ------------------------------------------------------------------------------------------------
-- Input
-- ------------------------------------------------------------------------------------------------

--- Rewrites `InputManager:init`.
-- Add win / lose keys.
-- @rewrite
function InputManager:init(...)
  InputManager_init(self, ...)
  self.keyMaps.main.win = winKey
  self.keyMaps.main.lose = loseKey
  self.keys.win = GameKey()
  self.keys.lose = GameKey()
end
