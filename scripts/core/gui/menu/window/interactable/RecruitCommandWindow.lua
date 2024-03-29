
--[[===============================================================================================

RecruitCommandWindow
---------------------------------------------------------------------------------------------------
Window with the initial commands of the shop GUI (hire, dismiss, cancel).

=================================================================================================]]

-- Imports
local Button = require('core/gui/widget/control/Button')
local GridWindow = require('core/gui/GridWindow')

local RecruitCommandWindow = class(GridWindow)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(GUI : GUI) Parent GUI.
-- @param(hire : boolean) True if "hire" option if enabled.
-- @param(dismiss : boolean) True if "dismiss" option if enabled.
function RecruitCommandWindow:init(GUI, hire, dismiss)
  self.hire = hire
  self.dismiss = dismiss
  GridWindow.init(self, GUI)
end
-- Overrides GridWindow:setProperties.
function RecruitCommandWindow:setProperties()
  GridWindow.setProperties(self)
  self.tooltipTerm = ''
  self.buttonAlign = 'center'
end
-- Implements GridWindow:createWidgets.
function RecruitCommandWindow:createWidgets()
  Button:fromKey(self, 'hire').text:setAlign('center', 'center')
  Button:fromKey(self, 'dismiss').text:setAlign('center', 'center')
  Button:fromKey(self, 'return').text:setAlign('center', 'center')
end

---------------------------------------------------------------------------------------------------
-- Confirm Callbacks
---------------------------------------------------------------------------------------------------

-- Shows the windows to hire.
function RecruitCommandWindow:hireConfirm()
  self.GUI.countWindow:setHireMode()
  self.GUI.listWindow:setHireMode()
  self.GUI:showRecruitGUI()
end
-- Shows the windows to dismiss.
function RecruitCommandWindow:dismissConfirm()
  self.GUI.countWindow:setDismissMode()
  self.GUI.listWindow:setDismissMode()
  self.GUI:showRecruitGUI()
end
-- Closes shop GUI.
function RecruitCommandWindow:cancelConfirm()
  self.result = 0
end

---------------------------------------------------------------------------------------------------
-- Enable Conditions
---------------------------------------------------------------------------------------------------

-- Enable condition of "hire" button.
function RecruitCommandWindow:hireEnabled()
  return self.hire
end
-- Enable condition of "dismiss" button.
function RecruitCommandWindow:dismissEnabled()
  return self.dismiss
end

---------------------------------------------------------------------------------------------------
-- Properties
---------------------------------------------------------------------------------------------------

-- Overrides GridWindow:colCount.
function RecruitCommandWindow:colCount()
  return 3
end
-- Overrides GridWindow:rowCount.
function RecruitCommandWindow:rowCount()
  return 1
end
-- Overrides GridWindow:rowCount.
function RecruitCommandWindow:cellWidth()
  return 60
end
-- @ret(string) String representation (for debugging).
function RecruitCommandWindow:__tostring()
  return 'Recruit Command Window'
end

return RecruitCommandWindow
