
--[[===============================================================================================

QuitWindow
---------------------------------------------------------------------------------------------------
Window with options to close / restart game.

=================================================================================================]]

-- Imports
local Button = require('core/gui/widget/control/Button')
local GridWindow = require('core/gui/GridWindow')

local QuitWindow = class(GridWindow)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Implements GridWindow:createWidgets.
function QuitWindow:createWidgets()
  Button:fromKey(self, 'cancel').text.sprite:setAlignX('center')
  Button:fromKey(self, 'title').text.sprite:setAlignX('center')
  if GameManager:isDesktop() then
    Button:fromKey(self, 'close').text.sprite:setAlignX('center')
  end
end

---------------------------------------------------------------------------------------------------
-- Buttons
---------------------------------------------------------------------------------------------------

-- When player cancels the quit action.
function QuitWindow:cancelConfirm()
  self.result = 0
end
-- When players chooses to return to TitleGUI.
function QuitWindow:titleConfirm()
  self:hide()
  FieldManager.renderer:fadeout(nil, true)
  GameManager.restartRequested = true
end
-- When player chooses to shut the game down.
function QuitWindow:closeConfirm()
  GameManager:quit()
end

---------------------------------------------------------------------------------------------------
-- Properties
---------------------------------------------------------------------------------------------------

-- Overrides GridWindow:colCount.
function QuitWindow:colCount()
  return 1
end
-- Overrides GridWindow:rowCount.
function QuitWindow:rowCount()
  return GameManager:isDesktop() and 3 or 2
end
-- @ret(string) String representation (for debugging).
function QuitWindow:__tostring()
  return 'Field Command Window'
end

return QuitWindow