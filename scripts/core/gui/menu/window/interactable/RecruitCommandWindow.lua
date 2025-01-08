
-- ================================================================================================

--- Window with the initial commands of the shop Menu (hire, dismiss, cancel).
---------------------------------------------------------------------------------------------------
-- @windowmod RecruitCommandWindow
-- @extend GridWindow

-- ================================================================================================

-- Imports
local Button = require('core/gui/widget/control/Button')
local GridWindow = require('core/gui/GridWindow')

-- Class table.
local RecruitCommandWindow = class(GridWindow)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam Menu menu Parent Menu.
-- @tparam boolean hire True if "hire" option if enabled.
-- @tparam boolean dismiss True if "dismiss" option if enabled.
function RecruitCommandWindow:init(menu, hire, dismiss)
  self.hire = hire
  self.dismiss = dismiss
  GridWindow.init(self, menu)
end
--- Overrides `GridWindow:setProperties`. 
-- @override
function RecruitCommandWindow:setProperties()
  GridWindow.setProperties(self)
  self.tooltipTerm = ''
  self.buttonAlign = 'center'
end
--- Implements `GridWindow:createWidgets`.
-- @implement
function RecruitCommandWindow:createWidgets()
  Button:fromKey(self, 'hire').text:setAlign('center', 'center')
  Button:fromKey(self, 'dismiss').text:setAlign('center', 'center')
  Button:fromKey(self, 'return').text:setAlign('center', 'center')
end

-- ------------------------------------------------------------------------------------------------
-- Confirm Callbacks
-- ------------------------------------------------------------------------------------------------

--- Shows the windows to hire.
function RecruitCommandWindow:hireConfirm()
  self.menu.countWindow:setHireMode()
  self.menu.listWindow:setHireMode()
  self.menu:showRecruitMenu()
end
--- Shows the windows to dismiss.
function RecruitCommandWindow:dismissConfirm()
  self.menu.countWindow:setDismissMode()
  self.menu.listWindow:setDismissMode()
  self.menu:showRecruitMenu()
end
--- Closes shop Menu.
function RecruitCommandWindow:cancelConfirm()
  self.result = 0
end

-- ------------------------------------------------------------------------------------------------
-- Enable Conditions
-- ------------------------------------------------------------------------------------------------

--- Enable condition of "hire" button.
function RecruitCommandWindow:hireEnabled()
  return self.hire
end
--- Enable condition of "dismiss" button.
function RecruitCommandWindow:dismissEnabled()
  return self.dismiss
end

-- ------------------------------------------------------------------------------------------------
-- Properties
-- ------------------------------------------------------------------------------------------------

--- Overrides `GridWindow:colCount`. 
-- @override
function RecruitCommandWindow:colCount()
  return 3
end
--- Overrides `GridWindow:rowCount`. 
-- @override
function RecruitCommandWindow:rowCount()
  return 1
end
--- Overrides `GridWindow:rowCount`. 
-- @override
function RecruitCommandWindow:cellWidth()
  return 60
end
-- For debugging.
function RecruitCommandWindow:__tostring()
  return 'Recruit Command Window'
end

return RecruitCommandWindow
