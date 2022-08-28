
--[[===============================================================================================

FieldCommandWindow
---------------------------------------------------------------------------------------------------
Main GUI's selectable window.

=================================================================================================]]

-- Imports
local Button = require('core/gui/widget/control/Button')
local GridWindow = require('core/gui/GridWindow')

local FieldCommandWindow = class(GridWindow)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Implements GridWindow:createWidgets.
function FieldCommandWindow:createWidgets()
  Button:fromKey(self, 'cancel')
  Button:fromKey(self, 'title')
  if GameManager:isDesktop() then
    Button:fromKey(self, 'close')
  end
end

---------------------------------------------------------------------------------------------------
-- Buttons
---------------------------------------------------------------------------------------------------

-- When player cancels the quit action.
function FieldCommandWindow:cancelConfirm()
  self.result = 0
end
-- When players chooses to return to TitleGUI.
function FieldCommandWindow:titleConfirm()
  self:hide()
  FieldManager.renderer:fadeout(nil, true)
  GameManager.restartRequested = true
end
-- When player chooses to shut the game down.
function FieldCommandWindow:closeConfirm()
  GameManager:quit()
end

---------------------------------------------------------------------------------------------------
-- Properties
---------------------------------------------------------------------------------------------------

-- Overrides GridWindow:colCount.
function FieldCommandWindow:colCount()
  return 1
end
-- Overrides GridWindow:rowCount.
function FieldCommandWindow:rowCount()
  return GameManager:isDesktop() and 3 or 2
end
-- @ret(string) String representation (for debugging).
function FieldCommandWindow:__tostring()
  return 'Field Command Window'
end

return FieldCommandWindow