
-- ================================================================================================

--- General event functions that are loaded from the EventSheet.
---------------------------------------------------------------------------------------------------
-- @module GeneralEvents

-- ================================================================================================

local GeneralEvents = {}

-- ------------------------------------------------------------------------------------------------
-- Tables
-- ------------------------------------------------------------------------------------------------

--- Arguments for variable controlling.
-- @table VariableAguments
-- @tfield string name The key of the variable.
-- @tfield number VarScope The scope of the variable (global/local/object).
-- @field value The new value of the variable.

--- Arguments for field transition.
-- @table TransitionArguments
-- @tfield[opt] number fieldID Field to loaded's ID. When nil, stays in the same field.
-- @tfield number fade Duration of the fading in frames.
-- @tfield number x Player's destination x.
-- @tfield number y Player's destination y.
-- @tfield number h Player's destination height.
-- @tfield number direction Player's destination direction (in degrees).
-- @tfield boolean wait Flag to wait for all exit scripts to run before continuing.

--- Arguments for battle commands.
-- @table BattleArguments
-- @tfield[opt] boolean fieldID Battle field ID. If nil, the battle takes place in the current field.
-- @tfield[opt] number fade Duration of the fade out/in effect when exiting/returning to previous field.
-- @tfield[opt] boolean skipIntro Flag to skip the intro animation showing the parties.
-- @tfield[opt] boolean disableEscape Flag to disable the escape action for the player.
-- @tfield[opt=NONE] GameOverCondition|VictoryCondition gameOverCondition The condition to block the
--  "Continue" option from the Game Over screen. Either a number value from
--  `BattleManager.GameOverCondition` or a string value from `VictoryCondition`.

--- The conditions to enable the "Continue" button on the `GameOverWindow`.
-- @enum VictoryCondition
-- @field none Always enabled regardless of who wins.
-- @field survive Enabled as long as the player is still alive.
-- @field kill Never enabled.
GeneralEvents.VictoryCondition = {
  NONE = 'none',
  SURVIVE = 'survive',
  KILL = 'kill'
}

--- Types of scope for script variables.
-- @enum VarScope
-- @field global Global variables.
-- @field script Variables that are only accessible within the same script.
-- @field object Variables associated with the script's object/character.
GeneralEvents.VarScope = {
  global = 0,
  script = 1,
  object = 2,
  field = 3,
  params = 4
}

-- ------------------------------------------------------------------------------------------------
-- Variable
-- ------------------------------------------------------------------------------------------------

--- Sets the value of a variable.
-- @tparam VariableArguments args
-- @return The value of the variable (nil if not found).
function GeneralEvents:getVariable(args)
  local scope = self.VarScope[args.scope] or args.scope
  if scope == self.VarScope.global then
    scope = Variables.vars
  elseif scope == self.VarScope.script then
    scope = self.vars
  elseif scope == self.VarScope.field then
    scope = FieldManager.currentField.vars
  elseif scope == self.VarScope.params then
    if self.args and self.args[args.key] then
      scope = self.args
    else
      scope = self.tags
    end
  elseif scope == self.VarScope.object then
    assert(self.char, "Script was not called from a character")
    scope = self.char.vars
  else
    return nil
  end
  return scope[args.key]
end
--- Sets the value of a variable.
-- @tparam VariableArguments args
function GeneralEvents:setVariable(args)
  local scope = self.VarScope[args.scope] or args.scope
  if scope == self.VarScope.global then
    scope = Variables.vars
  elseif scope == self.VarScope.script then
    scope = self.vars
  elseif scope == self.VarScope.field then
    scope = FieldManager.currentField.vars
  elseif scope == self.VarScope.object then
    assert(self.char, "Script was not called from a character")
    scope = self.char.vars
  elseif scope == self.VarScope.params then
    error('Cannot modify script parameters')
  else
    return
  end
  scope[args.key] = self:evaluate(args.value)
end
--- Sets the value of a local (script) variable.
-- @tparam VariableArguments args
function GeneralEvents:setLocalVar(args)
  self.vars[args.key] = self:evaluate(args.value)
end
--- Sets the value of a global variable.
-- @tparam VariableArguments args
function GeneralEvents:setGlobalVar(args)
  Variables.vars[args.key] = self:evaluate(args.value)
end
--- Sets the value of a global variable.
-- @tparam VariableArguments args
function GeneralEvents:setFieldVar(args)
  FieldManager.currentField.vars[args.key] = self:evaluate(args.value)
end
--- Sets the value of a global variable.
-- @tparam VariableArguments args
function GeneralEvents:setCharVar(args)
  assert(self.char, "Script was not called from a character")
  self.char.vars[args.key] = self:evaluate(args.value)
end

-- ------------------------------------------------------------------------------------------------
-- Field
-- ------------------------------------------------------------------------------------------------

--- Teleports player to other field.
-- @coroutine
-- @tparam TransitionArguments args
function GeneralEvents:moveToField(args)
  local fiber = FieldManager.fiberList:forkMethod(FieldManager, 'loadTransition', args, nil, args.exit)
  if args.wait then
    fiber:waitForEnd()
  end
end
--- Loads battle field.
-- @coroutine
-- @tparam BattleArguments args
function GeneralEvents:runBattle(args)
  args.gameOverCondition = args.gameOverCondition or 1
  if type(args.gameOverCondition) == 'string' then
    local conditionName = args.gameOverCondition:trim():lower()
    if conditionName == self.VictoryCondition.SURVIVE then
      args.gameOverCondition = BattleManager.GameOverCondition.NOWIN -- Must win.
    elseif conditionName == self.VictoryCondition.KILL then
      args.gameOverCondition = 1 -- Must win or draw.
    elseif conditionName == self.VictoryCondition.NONE then
      args.gameOverCondition = 0 -- Never gets a game over.
    else
      args.gameOverCondition = 1 -- Default.
    end
  end
  FieldManager.currentField.vars.onBattle = true
  BattleManager.params = args
  FieldManager:storePlayerState()
  -- Openning
  local fiber = FieldManager.fiberList:fork(function()
    BattleManager:loadBattle()
    FieldManager.currentField.vars.onBattle = false
  end)
  fiber:waitForEnd()
end

return GeneralEvents
