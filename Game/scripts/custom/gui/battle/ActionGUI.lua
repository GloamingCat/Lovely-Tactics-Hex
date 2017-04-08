
--[[===========================================================================

ActionGUI
-------------------------------------------------------------------------------
The GUI that is open when player selects an action.
It does not have windows, and instead it implements its own "waitForResult" 
and "checkInput" methods.
Its result is the action time that the character spent.

=============================================================================]]

-- Imports
local GUI = require('core/gui/GUI')
local StepWindow = require('custom/gui/battle/StepWindow')
local TargetWindow = require('custom/gui/battle/TargetWindow')
local BattleCursor = require('core/battle/BattleCursor')

-- Alias
local yield = coroutine.yield

local ActionGUI = GUI:inherit()

-------------------------------------------------------------------------------
-- Initialization
-------------------------------------------------------------------------------

-- Overrides GUI:createWindows.
function ActionGUI:createWindows()
  self.name = 'Action GUI'
  self.cursor = BattleCursor()
  self.action = BattleManager.currentAction
end

-------------------------------------------------------------------------------
-- Auxiliary Windows
-------------------------------------------------------------------------------

-- Creates step window.
-- @ret(StepWindow) newly created window
function ActionGUI:createStepWindow()
  if not self.stepWindow then
    local w = StepWindow(self)
    self.stepWindow = w
    self.windowList:add(w)
    w:setVisible(false)
  end
  return self.stepWindow
end

-- Creates target window.
-- @ret(TargetWindow) newly created window
function ActionGUI:createTargetWindow()
  if not self.targetWindow then
    local w = TargetWindow(self)
    self.targetWindow = w
    self.windowList:add(w)
    w:setVisible(false)
  end
  return self.targetWindow
end

-------------------------------------------------------------------------------
-- Input
-------------------------------------------------------------------------------

-- [COROUTINE] Overrides GUI:waitForResult.
function ActionGUI:waitForResult()
  self.action:onActionGUI(self)
  self:checkInput()
  while self.result == nil do
    if self.cursor then
      self.cursor:update()
    end
    coroutine.yield()
    self:checkInput()
  end
  self.cursor:destroy()
  return self.result, false
end

-- Verifies player's input. Stores result of action in self.result.
function ActionGUI:checkInput()
  if InputManager.keys['confirm']:isTriggered() then
    if self.action.currentTarget.gui.selectable then
      self.result = self.action:onConfirm(self)
    end
  elseif InputManager.keys['cancel']:isTriggered() then
    self.action:onCancel(self)
    self.result = -1
  else
    local dx, dy = InputManager:axis(0.5, 0.0625)
    if dx ~= 0 or dy ~= 0 then
      local target = BattleManager.currentAction:nextTarget(dx, dy)
      if target then
        self:selectTarget(target)
      end
    end
  end
end

-- Sets given tile as current target.
-- @param(target : ObjectTile) the new target tile
function ActionGUI:selectTarget(target)
  self.cursor:setTile(target)
  BattleManager:selectTarget(target)
  if self.targetWindow then
    if target.characterList.size > 0 then
      local battler = target.characterList[1].battler
      self.targetWindow:setBattler(battler)
      GUIManager.fiberList:fork(self.targetWindow.show, self.targetWindow)
    else
      GUIManager.fiberList:fork(self.targetWindow.hide, self.targetWindow)
    end
  end
end

-- Shows grid and cursor.
function ActionGUI:startGridSelecting(target)
  if self.stepWindow then
    GUIManager.fiberList:fork(self.stepWindow.show, self.stepWindow)
  end
  FieldManager:showGrid()
  self:selectTarget(target or self.action.currentTarget)
end

-- Hides grid and cursor.
function ActionGUI:endGridSelecting()
  if self.stepWindow then
    GUIManager.fiberList:fork(self.stepWindow.hide, self.stepWindow)
  end
  if self.targetWindow then
    GUIManager.fiberList:fork(self.targetWindow.hide, self.targetWindow)
  end
  while (self.targetWindow and not self.targetWindow.closed 
      or self.stepWindow and not self.stepWindow.closed) do
    yield()
  end
  FieldManager:hideGrid()
  self.cursor:hide()
end

return ActionGUI
