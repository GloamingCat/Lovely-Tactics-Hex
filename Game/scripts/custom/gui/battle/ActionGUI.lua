
--[[===============================================================================================

ActionGUI
---------------------------------------------------------------------------------------------------
The GUI that is open when player selects an action.
It does not have windows, and instead it implements its own "waitForResult" 
and "checkInput" methods.
Its result is the action time that the character spent.

=================================================================================================]]

-- Imports
local GUI = require('core/gui/GUI')
local StepWindow = require('core/gui/battle/StepWindow')
local TargetWindow = require('core/gui/battle/TargetWindow')
local BattleCursor = require('core/battle/BattleCursor')

-- Alias
local yield = coroutine.yield

local ActionGUI = class(GUI)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Overrides GUI:init.
local old_init = ActionGUI.init
function ActionGUI:init(input)
  old_init(self)
  self.name = 'Action GUI'
  self.input = input
  input.GUI = self
end

---------------------------------------------------------------------------------------------------
-- Auxiliary Windows
---------------------------------------------------------------------------------------------------

-- Creates step window.
-- @ret(StepWindow) newly created window
function ActionGUI:createStepWindow()
  if not self.stepWindow then
    local window = StepWindow(self)
    self.stepWindow = window
    self.windowList:add(window)
    window:setVisible(false)
  end
  return self.stepWindow
end
-- Creates target window.
-- @ret(TargetWindow) newly created window
function ActionGUI:createTargetWindow()
  if not self.targetWindow then
    local window = TargetWindow(self)
    self.targetWindow = window
    self.windowList:add(window)
    window:setVisible(false)
  end
  return self.targetWindow
end

---------------------------------------------------------------------------------------------------
-- Input
---------------------------------------------------------------------------------------------------

-- [COROUTINE] Overrides GUI:waitForResult.
function ActionGUI:waitForResult()
  self.result = self.input.action:onActionGUI(self.input)
  while self.result == nil do
    if self.cursor then
      self.cursor:update()
    end
    coroutine.yield()
    self:checkInput()
  end
  if self.cursor then
    self.cursor:destroy()
  end
  return self.result
end
-- Verifies player's input. Stores result of action in self.result.
function ActionGUI:checkInput()
  if InputManager.keys['confirm']:isTriggered() then
    if self.input.target.gui.selectable then
      self.result = self.input.action:onConfirm(self.input)
    end
  elseif InputManager.keys['cancel']:isTriggered() then
    self.result = self.input.action:onCancel(self.input)
  else
    local dx, dy = InputManager:axis(0.5, 0.0625)
    if dx ~= 0 or dy ~= 0 then
      local target = self.input.action:nextTarget(self.input, dx, dy)
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
  self.input.action:onDeselectTarget(self.input)
  self.input.target = target
  self.input.action:onSelectTarget(self.input)
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

---------------------------------------------------------------------------------------------------
-- Grid selecting
---------------------------------------------------------------------------------------------------

-- Shows grid and cursor.
function ActionGUI:startGridSelecting(target)
  if self.stepWindow then
    GUIManager.fiberList:fork(self.stepWindow.show, self.stepWindow)
  end
  FieldManager:showGrid()
  self.cursor = self.cursor or BattleCursor()
  self:selectTarget(target or self.input.action.target)
  self.gridSelecting = true
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
  self.gridSelecting = false
end

return ActionGUI
