
-- ================================================================================================

--- Window with resolution options.
---------------------------------------------------------------------------------------------------
-- @classmod KeyMapWindow
-- @extend GridWindow

-- ================================================================================================

-- Imports
local Button = require('core/gui/widget/control/Button')
local GridWindow = require('core/gui/GridWindow')

-- Alias
local copyTable = util.table.deepCopy

-- Class table.
local KeyMapWindow = class(GridWindow)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Overrides `GridWindow:setProperties`. Sets tooltip.
-- @override
function KeyMapWindow:setProperties()
  self.keys = { 'confirm', 'cancel', 'dash', 'pause', 'prev', 'next' }
  GridWindow.setProperties(self)
  self.tooltipTerm = 'buttonChange'
end
--- Implements `GridWindow:createWidgets`.
-- @implement
function KeyMapWindow:createWidgets()
  for i = 1, #self.keys do
    self:createKeyButtons(self.keys[i])
  end
  Button:fromKey(self, 'apply').text:setAlign('center')
  Button:fromKey(self, 'default').text:setAlign('center')
end
--- Creates main and alt buttons for the given key.
-- @tparam string key Key type code.
function KeyMapWindow:createKeyButtons(key)
  local button1 = Button(self)
  button1:createText(key, key)
  button1.key = key
  button1.map = 'main'
  button1.tooltipTerm = self.tooltipTerm
  local button2 = Button(self)
  local term = '{%' .. key .. '} ({%alt})'
  local fb = key .. ' ({%alt})'
  button2:createText(term, fb)
  button2.key = key
  button2.map = 'alt'
  button2.tooltipTerm = self.tooltipTerm
end

-- ------------------------------------------------------------------------------------------------
-- Keys
-- ------------------------------------------------------------------------------------------------

--- Overrides `Window:show`. 
-- @override
function KeyMapWindow:show(...)
  if not self.open then
    self.map = { main = copyTable(InputManager.mainMap),
      alt = copyTable(InputManager.altMap),
      gamepad = copyTable(InputManager.gamepadMap) }
    self:refreshKeys()
    self:hideContent()
    GridWindow.show(self, ...)
  end
end
--- Refreshes key codes.
function KeyMapWindow:refreshKeys()
  for i = 1, #self.matrix do
    local b = self.matrix[i]
    if b.map then
      local map = self.map[b.map]
      b:createInfoText(map[b.key])
      b:updatePosition(self.position)
    end
  end
end

-- ------------------------------------------------------------------------------------------------
-- Input
-- ------------------------------------------------------------------------------------------------

--- Chooses new resolution.
function KeyMapWindow:onButtonConfirm(button)
  self:setWidgetTooltip('pressKey')
  self.cursor.paused = true
  InputManager.keys['pause']:block()
  button:createInfoText('')
  repeat
    Fiber:wait()
  until InputManager.lastKey
  local code = InputManager.lastKey
  local map = self.map[button.map]
  if InputManager.arrowMap[code] or InputManager.keyMap[code] then
    code = map[button.key]
  end
  InputManager.keys['pause']:unblock()
  button:createInfoText(code)
  button:updatePosition(self.position)
  map[button.key] = code
  self.cursor.paused = false
  self:setWidgetTooltip(button)
end
--- Applies changes.
function KeyMapWindow:applyConfirm()
  InputManager:setKeyMap(copyTable(self.map))
  self.result = 1
end
--- Sets default key map.
function KeyMapWindow:defaultConfirm()
  self.map = copyTable(KeyMap)
  self:refreshKeys()
end

-- ------------------------------------------------------------------------------------------------
-- Properties
-- ------------------------------------------------------------------------------------------------

--- Overrides `GridWindow:colCount`. 
-- @override
function KeyMapWindow:colCount()
  return 2
end
--- Overrides `GridWindow:rowCount`. 
-- @override
function KeyMapWindow:rowCount()
  return 7
end
-- Overrides `GridWindow:cellWidth`.
function KeyMapWindow:cellWidth()
  return 140
end
-- @treturn string String representation (for debugging).
function KeyMapWindow:__tostring()
  return 'Resolution Window'
end

return KeyMapWindow
