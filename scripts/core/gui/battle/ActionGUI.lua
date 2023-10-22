
-- ================================================================================================

--- The GUI that is open when player selects an action.
-- It does not have windows, and instead it implements its own "waitForResult" 
-- and "checkInput" methods.
-- Its result is the action time that the character spent.
---------------------------------------------------------------------------------------------------
-- @uimod ActionGUI
-- @extend GUI

-- ================================================================================================

-- Imports
local BattleCursor = require('core/battle/BattleCursor')
local GUI = require('core/gui/GUI')
local ButtonWindow = require('core/gui/common/window/interactable/ButtonWindow')
local ConfirmButtonWindow = require('core/gui/common/window/interactable/ConfirmButtonWindow')
local PropertyWindow = require('core/gui/battle/window/PropertyWindow')
local TargetWindow = require('core/gui/battle/window/TargetWindow')

-- Class table.
local ActionGUI = class(GUI)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Overrides `GUI:init`. 
-- @override
function ActionGUI:init(parent, input)
  self.name = 'Action GUI'
  self.slideMargin = 16
  self.slideSpeed = 3
  GUI.init(self, parent)
  self.confirmSound = Config.sounds.buttonConfirm
  self.cancelSound = Config.sounds.buttonCancel
  self.selectSound = Config.sounds.buttonSelect
  self.errorSound = Config.sounds.buttonError
  self.input = input
  input.GUI = self
  self:createScrollArrows()
end
--- Creates the scroll arrows, one for each direction.
function ActionGUI:createScrollArrows()
  self.scrollArrows = {}
  local icon = {id = Config.animations.arrow}
  icon.col, icon.row = 0, 1
  for i = 1, 4 do
    icon.col = (i - 1) % 2
    icon.row = (i - 1 - icon.col) / 2
    self.scrollArrows[i] = ResourceManager:loadIcon(icon, GUIManager.renderer)
    self.scrollArrows[i]:setVisible(false)
  end
  self.scrollArrows[1]:setXYZ((ScreenManager.width - self.slideMargin) / 2, 0)
  self.scrollArrows[2]:setXYZ(0, (ScreenManager.height - self.slideMargin) / 2)
  self.scrollArrows[4]:setXYZ(-(ScreenManager.width - self.slideMargin) / 2, 0)
  self.scrollArrows[3]:setXYZ(0, -(ScreenManager.height - self.slideMargin) / 2)
end
--- Overrides `GUI:destroy`. Destroys scroll arrows.
-- @override
function ActionGUI:destroy(...)
  GUI.destroy(self, ...)
  if self.scrollArrows then
    for i = 1, #self.scrollArrows do
      self.scrollArrows[i]:destroy()
    end
  end
end

-- ------------------------------------------------------------------------------------------------
-- Auxiliary Windows
-- ------------------------------------------------------------------------------------------------

--- Creates the GUI's windows and sets the first active window.
function ActionGUI:createConfirmWindow()
  if not self.buttonWindow then
    local window = ConfirmButtonWindow(self, 'confirmTile', 'cancelTile')
    self.buttonWindow = window
    local x = -ScreenManager.width / 2 + window.width / 2 + self.slideMargin
    local y = -ScreenManager.height / 2 + window.height / 2 + self.slideMargin
    window:setXYZ(x, y)
    window.offBoundsCancel = false
    window:setVisible(false)
    if not InputManager:hasKeyboard() then
      window:show()
    end
  end
  return self.buttonWindow
end
--- Creates the GUI's windows and sets the first active window.
function ActionGUI:createCancelWindow()
  if not self.buttonWindow then
    local window = ButtonWindow(self, 'cancelTile')
    self.buttonWindow = window
    local x = -ScreenManager.width / 2 + window.width / 2 + self.slideMargin
    local y = -ScreenManager.height / 2 + window.height / 2 + self.slideMargin
    window:setXYZ(x, y)
    window.matrix[1].clickSound = Config.sounds.buttonCancel
    window:setVisible(false)
  end
  return self.buttonWindow
end
--- Creates step window if not created yet.
-- @treturn PropertyWindow This GUI's step window.
function ActionGUI:createPropertyWindow(label, value)
  if not self.propertyWindow then
    local window = PropertyWindow(self)
    window:setProperty(label, value)
    self.propertyWindow = window
    window:setVisible(false)
  end
  return self.propertyWindow
end
--- Creates target window if not created yet.
-- @treturn TargetWindow This GUI's target window.
function ActionGUI:createTargetWindow()
  if not self.targetWindow then
    local window = TargetWindow(self)
    self.targetWindow = window
    window:setVisible(false)
  end
  return self.targetWindow
end
--- Updates the battler shown in the target window.
function ActionGUI:updateTargetWindow(char)
  self.targetWindow:setBattler(char.battler)
  self.targetWindow:setVisible(false)
  self.targetWindow:show()
end

-- ------------------------------------------------------------------------------------------------
-- Input
-- ------------------------------------------------------------------------------------------------

--- Overrides `GUI:waitForResult`. 
-- @override
function ActionGUI:waitForResult()
  self.result = self.input.action:onActionGUI(self.input)
  while self.result == nil do
    if self.cursor then
      self.cursor:update(GameManager:frameTime())
    end
    if self.scrollArrows then
      local visible = self.buttonWindow and not self.buttonWindow.closed
      for i = 1, #self.scrollArrows do
        self.scrollArrows[i]:setVisible(visible and not self.scrollArrows[i].offBounds)
      end
    end
    Fiber:wait()
    self:checkInput()
  end
  if self.cursor then
    self.cursor:destroy()
  end
  return self.result
end
--- Verifies player's input. Stores result of action in self.result.
function ActionGUI:checkInput()
  if self.buttonWindow then
    self.buttonWindow:checkInput()
    if self.buttonWindow.result then
      if self.buttonWindow.result + #self.buttonWindow.matrix == 3 then
        self:confirmAction()
      else
        self:cancelAction()
      end
      self.buttonWindow.result = nil
      return
    end
  end
  return self:mouseInput() or self:keyboardInput()
end
--- Sets given tile as current target.
-- @tparam ObjectTile target
function ActionGUI:selectTarget(target)
  target = target or self.input.target
  if self.cursor then
    self.cursor:setTile(target)
  end
  if self.input.target then
    self.input.action:onDeselectTarget(self.input)
  end
  self.input.target = target
  self.input.action:onSelectTarget(self.input)
  if self.targetWindow then
    local char = target:getFirstBattleCharacter()
    if char then
      GUIManager.fiberList:fork(self.updateTargetWindow, self, char)
    else
      GUIManager.fiberList:fork(self.targetWindow.hide, self.targetWindow)
    end
  end
  if self.buttonWindow and #self.buttonWindow.matrix >= 2 then
    self.buttonWindow.matrix[1]:setEnabled(self.input.target.gui.selectable)
  end
end
--- Executes the given input.
function ActionGUI:confirmAction()
  self.result = self.input:execute()
  Fiber:wait()
end
--- Cancels the selected action.
function ActionGUI:cancelAction()
  self.result = self.input.action:onCancel(self.input)
  Fiber:wait()
end

-- ------------------------------------------------------------------------------------------------
-- Keyboard
-- ------------------------------------------------------------------------------------------------

--- Checks the keyboard input.
function ActionGUI:keyboardInput()
  if InputManager.keys['confirm']:isTriggered() then
    if self.input.target.gui.selectable then
      self:playConfirmSound()
      self:confirmAction()
    else
      self:playErrorSound()
    end
  elseif InputManager.keys['cancel']:isTriggered() then
    self:playCancelSound()
    self:cancelAction()
  elseif InputManager.keys['next']:isTriggered() then
    local target = self.input.action:nextLayer(self.input, 1)
    if target and target ~= self.input.target then
      FieldManager.renderer:moveToTile(target)
      self:playSelectSound()
      self:selectTarget(target)
    end
  elseif InputManager.keys['prev']:isTriggered() then
    local target = self.input.action:nextLayer(self.input, -1)
    if target and target ~= self.input.target then
      FieldManager.renderer:moveToTile(target)
      self:playSelectSound()
      self:selectTarget(target)
    end
  else
    local dx, dy = InputManager:axis(0.5, 0.0625)
    if dx ~= 0 or dy ~= 0 then
      local target = self.input.action:nextTarget(self.input, dx, dy)
      if target and target ~= self.input.target then
        FieldManager.renderer:moveToTile(target)
        self:playSelectSound()
        self:selectTarget(target)
      end
    else
      return false
    end
  end
  return true
end

-- ------------------------------------------------------------------------------------------------
-- Mouse Input
-- ------------------------------------------------------------------------------------------------

--- Check the mouse input.
function ActionGUI:mouseInput()
  self:checkSlide()
  if InputManager.mouse.moved then
    local target = FieldManager.currentField:getHoveredTile()
    if target and target ~= self.input.target then
      self:selectTarget(target)
    end
  elseif InputManager.keys['touch']:isTriggered() then
    self.waitingForTouch = true
  elseif InputManager.keys['touch']:isReleased() and self.waitingForTouch then
    self.waitingForTouch = false
    local target = FieldManager.currentField:getHoveredTile()
    if target and target ~= self.input.target then
      self:selectTarget(target)
      FieldManager.renderer:moveToTile(target)
    end
  elseif InputManager.keys['mouse1']:isTriggered() then
    local target = FieldManager.currentField:getHoveredTile()
    if target then
      if target ~= self.input.target then
        self:selectTarget(target)
      end
      if self.input.target.gui.selectable then
        self:playConfirmSound()
        self:confirmAction()
      else
        self:playErrorSound()
      end
    else
      self:playErrorSound()
    end
  elseif InputManager.keys['mouse2']:isTriggered() then
    self:playCancelSound()
    self:cancelAction()
  else
    return false
  end
  return true
end

-- ------------------------------------------------------------------------------------------------
-- Screen Slide
-- ------------------------------------------------------------------------------------------------

--- Checks if the mouse pointer in the slide area.
function ActionGUI:checkSlide()
  if not self.buttonWindow or not self.buttonWindow.lastOpen or not self.scrollArrows then
    return
  end
  if GameManager:isMobile() and not InputManager.keys.touch:isPressing() then
    return
  end
  local w = ScreenManager.width / 2 - self.slideMargin
  local h = ScreenManager.height / 2 - self.slideMargin
  local x, y = InputManager.mouse:guiCoord()
  if x > w or x < -w then
    self:slideX(math.sign(x))
  end
  if y > h or y < -h then
    self:slideY(math.sign(y))
  end
end
--- Slides the screen horizontally.
-- @tparam number d Direction (1 or -1).
function ActionGUI:slideX(d)
  local camera = FieldManager.renderer
  local speed = self.slideSpeed * GUIManager.fieldScroll * 2 / 100
  local x = camera.position.x + d * speed * GameManager:frameTime() * 60
  local field = FieldManager.currentField 
  self.scrollArrows[1].offBounds = false
  self.scrollArrows[4].offBounds = false
  if x < field.minx then
    self.scrollArrows[4].offBounds = true
    return
  end
  if x > field.maxx then
    self.scrollArrows[1].offBounds = true
    return
  end
  camera:setXYZ(x, nil)
  InputManager.mouse:show()
end
--- Slides the screen vertically.
-- @tparam number d Direction (1 or -1).
function ActionGUI:slideY(d)
  local camera = FieldManager.renderer
  local speed = self.slideSpeed * GUIManager.fieldScroll * 2 / 100
  local y = camera.position.y + d * speed * GameManager:frameTime() * 60
  local field = FieldManager.currentField 
  self.scrollArrows[2].offBounds = false
  self.scrollArrows[3].offBounds = false
  if y < field.miny then
    self.scrollArrows[3].offBounds = true
    return
  end
  if y > field.maxy then
    self.scrollArrows[2].offBounds = true
    return
  end
  camera:setXYZ(nil, y)
  InputManager.mouse:show()
end

-- ------------------------------------------------------------------------------------------------
-- Grid selecting
-- ------------------------------------------------------------------------------------------------

--- Shows grid and cursor.
function ActionGUI:startGridSelecting(target)
  if self.propertyWindow then
    GUIManager.fiberList:fork(self.propertyWindow.show, self.propertyWindow)
  end
  if self.buttonWindow then
    self.buttonWindow.active = true
    self.buttonWindow.result = nil
    GUIManager.fiberList:fork(self.buttonWindow.show, self.buttonWindow)
  end
  FieldManager:showGrid()
  FieldManager.renderer:moveToTile(target)
  self.cursor = self.cursor or BattleCursor()
  self:selectTarget(target)
  self.gridSelecting = true
end
--- Hides grid and cursor.
function ActionGUI:endGridSelecting()
  if self.buttonWindow then
    self.buttonWindow.active = false
    GUIManager.fiberList:fork(self.buttonWindow.hide, self.buttonWindow)
  end
  if self.propertyWindow then
    GUIManager.fiberList:fork(self.propertyWindow.hide, self.propertyWindow)
  end
  if self.targetWindow then
    GUIManager.fiberList:fork(self.targetWindow.hide, self.targetWindow)
  end
  if self.scrollArrows then
    for i = 1, #self.scrollArrows do
      self.scrollArrows[i]:setVisible(false)
    end
  end
  while (self.targetWindow and not self.targetWindow.closed 
      or self.buttonWindow and not self.buttonWindow.closed
      or self.propertyWindow and not self.propertyWindow.closed) do
    Fiber:wait()
  end
  FieldManager:hideGrid()
  if self.cursor then
    self.cursor:hide()
  end
  self.gridSelecting = false
end

-- ------------------------------------------------------------------------------------------------
-- Sound
-- ------------------------------------------------------------------------------------------------

--- Confirm a tile.
function ActionGUI:playConfirmSound()
  if self.confirmSound then
    AudioManager:playSFX(self.confirmSound)
  end
end
--- Cancel action.
function ActionGUI:playCancelSound()
  if self.cancelSound then
    AudioManager:playSFX(self.cancelSound)
  end
end
--- Select a tile.
function ActionGUI:playSelectSound()
  if self.selectSound then
    AudioManager:playSFX(self.selectSound)
  end
end
--- Confirm a non-selectable tile.
function ActionGUI:playErrorSound()
  if self.errorSound then
    AudioManager:playSFX(self.errorSound)
  end
end

return ActionGUI
