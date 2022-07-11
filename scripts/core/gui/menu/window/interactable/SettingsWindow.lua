
--[[===============================================================================================

SettingsWindow
---------------------------------------------------------------------------------------------------
Window to change basic system settings.

=================================================================================================]]

-- Imports
local Button = require('core/gui/widget/control/Button')
local GridWindow = require('core/gui/GridWindow')
local HSpinnerButton = require('core/gui/widget/control/HSpinnerButton')
local SwitchButton = require('core/gui/widget/control/SwitchButton')

local SettingsWindow = class(GridWindow)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Implements GridWindow:createWidgets.
function SettingsWindow:createWidgets()
  HSpinnerButton:fromKey(self, 'volumeBGM', 0, 100, AudioManager.volumeBGM).bigIncrement = 10
  HSpinnerButton:fromKey(self, 'volumeSFX', 0, 100, AudioManager.volumeSFX).bigIncrement = 10
  HSpinnerButton:fromKey(self, 'windowScroll', 10, 100, GUIManager.windowScroll).bigIncrement = 10
  HSpinnerButton:fromKey(self, 'fieldScroll', 10, 100, GUIManager.fieldScroll).bigIncrement = 10
  SwitchButton:fromKey(self, 'autoDash', InputManager.autoDash)
  SwitchButton:fromKey(self, 'useMouse', InputManager.mouseEnabled)
  SwitchButton:fromKey(self, 'wasd', InputManager.wasd)
  Button:fromKey(self, 'keys').text:setAlign('center')
  Button:fromKey(self, 'resolution').text:setAlign('center')
end

---------------------------------------------------------------------------------------------------
-- Spinners
---------------------------------------------------------------------------------------------------

-- Change the BGM volume.
function SettingsWindow:volumeBGMChange(spinner)
  AudioManager:setBGMVolume(spinner.value)
end
-- Change the SFX volume.
function SettingsWindow:volumeSFXChange(spinner)
  AudioManager:setSFXVolume(spinner.value)
end
-- Change window scroll speed.
function SettingsWindow:windowScrollChange(spinner)
  GUIManager.windowScroll = spinner.value
end
-- Change field scroll speed.
function SettingsWindow:fieldScrollChange(spinner)
  GUIManager.fieldScroll = spinner.value
end

---------------------------------------------------------------------------------------------------
-- Switches
---------------------------------------------------------------------------------------------------

-- Change auto dash option.
function SettingsWindow:autoDashChange(button)
  InputManager.autoDash = button.value
end
-- Change mouse enabled option.
function SettingsWindow:useMouseChange(button)
  InputManager.mouseEnabled = button.value
  if not button.value then
    InputManager.mouse:hide()
    for i = 1, 3 do
      InputManager.keys['mouse' .. i]:onRelease()
    end
  end
end
-- Change WASD enabled.
function SettingsWindow:wasdChange(button)
  InputManager:setArrowMap(button.value)
end
-- Checks if any direction key is already in use.
function SettingsWindow:wasdEnabled(button)
  InputManager:setArrowMap(not button.value)
  for k, v in pairs(InputManager.keyMap) do
    if InputManager.arrowMap[k] then
      InputManager:setArrowMap(button.value)
      return false
    end
  end
  InputManager:setArrowMap(button.value)
  return true
end

---------------------------------------------------------------------------------------------------
-- Buttons
---------------------------------------------------------------------------------------------------

-- Resolution settings.
function SettingsWindow:resolutionConfirm()
  self:hide()
  self.GUI:showWindowForResult(self.GUI.resolutionWindow)
  self:show()
end
-- Key map settings.
function SettingsWindow:keysConfirm()
  self:hide()
  self.GUI:showWindowForResult(self.GUI.keyMapWindow)
  self:show()
end

---------------------------------------------------------------------------------------------------
-- Properties
---------------------------------------------------------------------------------------------------

-- Save and close.
function SettingsWindow:onCancel()
  SaveManager:storeConfig()
  GridWindow.onCancel(self)
end

---------------------------------------------------------------------------------------------------
-- Properties
---------------------------------------------------------------------------------------------------

-- Overrides GridWindow:colCount.
function SettingsWindow:colCount()
  return 1
end
-- Overrides GridWindow:rowCount.
function SettingsWindow:rowCount()
  return 9
end
-- Overrides GridWindow:cellWidth.
function SettingsWindow:cellWidth()
  return 200
end
-- @ret(string) String representation (for debugging).
function SettingsWindow:__tostring()
  return 'Settings Window'
end

return SettingsWindow