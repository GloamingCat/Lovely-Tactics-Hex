
-- ================================================================================================

--- Window that shows the list of save slots.
---------------------------------------------------------------------------------------------------
-- @uimod SaveWindow
-- @extend GridWindow

-- ================================================================================================

-- Imports
local Button = require('core/gui/widget/control/Button')
local ConfirmWindow = require('core/gui/common/window/interactable/ConfirmWindow')
local GridWindow = require('core/gui/GridWindow')
local SaveInfo = require('core/gui/widget/data/SaveInfo')
local Vector = require('core/math/Vector')

-- Class table.
local SaveWindow = class(GridWindow)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Overrides `Window:init`.
-- @override
function SaveWindow:init(...)
  GridWindow.init(self, ...)
  self.confirmWindow = ConfirmWindow(self.GUI, 'overwrite')
  self.confirmWindow:setXYZ(0, 0, -50)
  self.confirmWindow:setVisible(false)
  local button = self.confirmWindow.matrix[1]
  button.confirmSound = Config.sounds.save or button.confirmSound
  button.clickSound = button.confirmSound
end
--- Overrides `GridWindow:setProperties`. 
-- @override
function SaveWindow:setProperties()
  GridWindow.setProperties(self)
  self.tooltipTerm = 'saveSlot'
end
--- Implements `GridWindow:createWidgets`. 
-- @implement
function SaveWindow:createWidgets()
  for i = 1, SaveManager.maxSaves do
    self:createSaveButton(i .. '', Vocab.saveName .. ' ' .. i)
  end
end
--- Creates a button for the given save file.
-- @tparam string file Name of the file (without .save extension).
-- @tparam string name Name of the button that will be shown.
-- @treturn Button Newly created button.
function SaveWindow:createSaveButton(file, name)
  local button = Button(self)
  local w, h = self:cellWidth(), self:cellHeight()
  button.saveInfo = SaveInfo(nil, w - self:paddingX(), h)
  button.content:add(button.saveInfo)
  button.file = file
  if SaveManager:getHeader(file) == nil then
    button.confirmSound = Config.sounds.save or button.confirmSound
    button.clickSound = button.confirmSound
  end
  return button
end

-- ------------------------------------------------------------------------------------------------
-- Saves
-- ------------------------------------------------------------------------------------------------

--- Refresh each member info.
function SaveWindow:refreshSave(button)
  button.saveInfo:refreshInfo(SaveManager:getHeader(button.file))
  button:updatePosition(self.position)
  button:refreshEnabled()
end
--- Overrides `Window:show`. 
-- @override
function SaveWindow:show(...)
  if not self.open then
    for button in self.matrix:iterator() do
      self:refreshSave(button)
    end
    self:hideContent()
  end
  GridWindow.show(self, ...)
end

-- ------------------------------------------------------------------------------------------------
-- Input
-- ------------------------------------------------------------------------------------------------

--- When player chooses a file to load.
function SaveWindow:onButtonConfirm(button)
  if SaveManager:getHeader(button.file) then
    local result = self.GUI:showWindowForResult(self.confirmWindow)
    if result == 0 then
      return
    end
  end
  self:refreshSave(button)
  SaveManager:storeSave(button.file)
  self.result = button.file
end
--- When player cancels the load action.
function SaveWindow:onButtonCancel()
  self.result = ''
end

-- ------------------------------------------------------------------------------------------------
-- Properties
-- ------------------------------------------------------------------------------------------------

--- Overrides `GridWindow:colCount`. 
-- @override
function SaveWindow:colCount()
  return 1
end
--- Overrides `GridWindow:rowCount`. 
-- @override
function SaveWindow:rowCount()
  return math.min(SaveManager.maxSaves, GameManager:isMobile() and 3 or 4)
end
--- Overrides `ListWindow:cellWidth`. 
-- @override
function SaveWindow:cellWidth()
  return GridWindow.cellWidth(self) * 2
end
--- Overrides `GridWindow:cellHeight`. 
-- @override
function SaveWindow:cellHeight()
  return (GridWindow.cellHeight(self) * 2 + self:rowMargin() * 2) - 4
end
-- For debugging.
function SaveWindow:__tostring()
  return 'Save Window'
end

return SaveWindow
