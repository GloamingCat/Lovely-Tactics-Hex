
-- ================================================================================================

--- Window to change basic system settings.
---------------------------------------------------------------------------------------------------
-- @windowmod SettingsWindow
-- @extend GridWindow

-- ================================================================================================

-- Imports
local Button = require('core/gui/widget/control/Button')
local GridWindow = require('core/gui/GridWindow')
local HSpinnerButton = require('core/gui/widget/control/HSpinnerButton')
local SwitchButton = require('core/gui/widget/control/SwitchButton')

-- Class table.
local SettingsWindow = class(GridWindow)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Overrides `GridWindow:setProperties`. 
-- @override
function SettingsWindow:setProperties()
  GridWindow.setProperties(self)
  self.tooltipTerm = ''
end
--- Implements `GridWindow:createWidgets`.
-- @implement
function SettingsWindow:createWidgets()
  if #Config.languages > 1 then
    local langs = {}
    for i, lang in ipairs(Config.languages) do
      langs[i] = lang.name
    end
    SwitchButton:fromKey(self, 'language', GameManager.language, nil, langs)
  end
  SwitchButton:fromKey(self, 'tooltips', not MenuManager.disableTooltips)
  HSpinnerButton:fromKey(self, 'windowColor', 0, 100, MenuManager.windowColor).bigIncrement = 10
  HSpinnerButton:fromKey(self, 'volumeBGM', 0, 100, AudioManager.volumeBGM).bigIncrement = 10
  HSpinnerButton:fromKey(self, 'volumeSFX', 0, 100, AudioManager.volumeSFX).bigIncrement = 10
  --HSpinnerButton:fromKey(self, 'windowScroll', 0, 100, MenuManager.windowScroll).bigIncrement = 10
  if not GameManager:isMobile() then
    HSpinnerButton:fromKey(self, 'fieldScroll', 0, 100, MenuManager.fieldScroll).bigIncrement = 10
  end
  SwitchButton:fromKey(self, 'autoDash', InputManager.autoDash)
  if not GameManager:isMobile() then
    SwitchButton:fromKey(self, 'useMouse', InputManager.mouseEnabled)
    SwitchButton:fromKey(self, 'wasd', InputManager.wasd)
    Button:fromKey(self, 'keys').text:setAlign('center')
  end
  if GameManager:isDesktop() then
    Button:fromKey(self, 'resolution').text:setAlign('center')
  end
end

-- ------------------------------------------------------------------------------------------------
-- Spinners
-- ------------------------------------------------------------------------------------------------

--- Change window color brightness.
function SettingsWindow:windowColorChange(spinner)
  MenuManager.windowColor = spinner.value
  MenuManager:refresh()
  if FieldManager.hud then
    FieldManager.hud:refresh()
  end
end
--- Change the BGM volume.
function SettingsWindow:volumeBGMChange(spinner)
  AudioManager:setBGMVolume(spinner.value)
end
--- Change the SFX volume.
function SettingsWindow:volumeSFXChange(spinner)
  AudioManager:setSFXVolume(spinner.value)
end
--- Change window scroll speed.
function SettingsWindow:windowScrollChange(spinner)
  MenuManager.windowScroll = spinner.value
end
--- Change field scroll speed.
function SettingsWindow:fieldScrollChange(spinner)
  MenuManager.fieldScroll = spinner.value
end

-- ------------------------------------------------------------------------------------------------
-- Switches
-- ------------------------------------------------------------------------------------------------

--- Change the language.
function SettingsWindow:languageChange(button)
  GameManager.language = button.value
  Database.loadVocabFiles(GameManager.language)
  MenuManager:refresh()
end
--- Change auto dash option.
function SettingsWindow:autoDashChange(button)
  InputManager.autoDash = button.value
end
--- Change tooltips option.
function SettingsWindow:tooltipsChange(button)
  MenuManager.disableTooltips = not button.value
  self.tooltip:setVisible(button.value)
end
--- Change mouse enabled option.
function SettingsWindow:useMouseChange(button)
  InputManager.mouseEnabled = button.value
  if not button.value then
    InputManager.mouse:hide()
    for i = 1, 3 do
      InputManager.keys['mouse' .. i]:onRelease()
    end
  end
end
--- Change WASD enabled.
function SettingsWindow:wasdChange(button)
  InputManager:setArrowMap(button.value)
end
--- Checks if any direction key is already in use.
function SettingsWindow:wasdEnabled(button)
  InputManager:setArrowMap(not button.value)
  for k, v in pairs(InputManager.keyMap) do
    if InputManager.arrowMap[k] then
      InputManager:setArrowMap(button.value)
      return true
    end
  end
  InputManager:setArrowMap(button.value)
  return true
end

-- ------------------------------------------------------------------------------------------------
-- Buttons
-- ------------------------------------------------------------------------------------------------

--- Resolution settings.
function SettingsWindow:resolutionConfirm()
  self:hide()
  self.menu:showWindowForResult(self.menu.resolutionWindow)
  self:show()
end
--- Key map settings.
function SettingsWindow:keysConfirm()
  self:hide()
  self.menu:showWindowForResult(self.menu.keyMapWindow)
  self:show()
end

-- ------------------------------------------------------------------------------------------------
-- Properties
-- ------------------------------------------------------------------------------------------------

--- Save and close.
function SettingsWindow:onCancel()
  SaveManager:storeConfig()
  GridWindow.onCancel(self)
end

-- ------------------------------------------------------------------------------------------------
-- Properties
-- ------------------------------------------------------------------------------------------------

--- Overrides `GridWindow:colCount`. 
-- @override
function SettingsWindow:colCount()
  return 1
end
--- Overrides `GridWindow:rowCount`. 
-- @override
function SettingsWindow:rowCount()
  --local n = GameManager:isMobile() and 5 or GameManager:isWeb() and 8 or 9
  local n = 5
  return #Config.languages > 1 and n + 1 or n 
end
--- Overrides `GridWindow:cellWidth`. 
-- @override
function SettingsWindow:cellWidth()
  return 240
end
-- For debugging.
function SettingsWindow:__tostring()
  return 'Settings Window'
end

return SettingsWindow
