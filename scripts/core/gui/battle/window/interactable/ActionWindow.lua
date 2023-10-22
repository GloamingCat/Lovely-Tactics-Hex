
-- ================================================================================================

--- Parent window for the classes that execute some `BattleAction`.
-- It implements common methods for starting an action execution.
-- Its result is the result data returned by the action.
---------------------------------------------------------------------------------------------------
-- @uimod ActionWindow
-- @extend GridWindow

-- ================================================================================================

-- Imports
local ActionGUI = require('core/gui/battle/ActionGUI')
local ActionInput = require('core/battle/action/ActionInput')
local GridWindow = require('core/gui/GridWindow')
local SkillAction = require('core/battle/action/SkillAction')

-- Alias
local radiusIterator = math.field.radiusIterator

-- Class table.
local ActionWindow = class(GridWindow)

-- ------------------------------------------------------------------------------------------------
-- Confirm Action
-- ------------------------------------------------------------------------------------------------

--- Select an action.
-- @tparam BattleAction action The action to the executed on button selection.
--  (must inherit from BattleAction) 
-- @tparam ActionInput input User's input data (optional, creates new by default).
function ActionWindow:selectAction(action, input)
  -- Executes action grid selecting.
  input = input or ActionInput(nil, TurnManager:currentCharacter(), nil, self.GUI)
  input.action = action
  action:onSelect(input)
  self.GUI:hide()
  local result = GUIManager:showGUIForResult(ActionGUI(self.GUI, input))
  if result.endCharacterTurn or result.escaped then
    -- End of turn.
    self.result = result
  else
    if input.user then
      FieldManager.renderer:moveToObject(input.user)
    end
    self.GUI:show()
  end
end
--- Checks if a given skill action is enabled to use.
-- @tparam SkillAction skill
-- @treturn boolean
function ActionWindow:skillActionEnabled(skill)
  if skill.freeNavigation then
    return true
  end
  local user = TurnManager:currentCharacter()
  local input = ActionInput(skill, user)
  skill:resetTileProperties(input)
  if skill.autoPath and self:moveEnabled() then
    -- There's a selectable tile, and the character can move closer to it.
    for tile in FieldManager.currentField:gridIterator() do
      if tile.gui.selectable then
        return true
      end
    end
  else
    -- The character can't move, but there is a reachable selectable tile.
    for tile in FieldManager.currentField:gridIterator() do
      if tile.gui.selectable and tile.gui.reachable then
        return true
      end
    end
  end
  return false
end
--- Move condition. Enabled if there are any tiles for the character to move to.
function ActionWindow:moveEnabled()
  local user = TurnManager:currentCharacter()
  if user.battler.steps < 1 then
    return false
  end
  local userTile = user:getTile()
  for path in TurnManager:pathMatrix():iterator() do
    if path and path.lastStep ~= userTile and path.totalCost <= user.battler.steps + 0.001 then
      return true
    end
  end
  return false
end

-- ------------------------------------------------------------------------------------------------
-- Cancel Action
-- ------------------------------------------------------------------------------------------------

--- Closes this window to be replaced by another one.
-- @tparam GridWindow window The new active window.
-- @tparam boolean showDescription Flag to open the GUI's DescriptionWindow.
function ActionWindow:changeWindow(window, showDescription)
  self:hide()
  self:removeSelf()
  if showDescription then
    self.GUI:showDescriptionWindow(window)
  end
  window:insertSelf()
  window:show()
  window:activate()
end

return ActionWindow
