
--[[===============================================================================================

KeyMapWindow
---------------------------------------------------------------------------------------------------
Window with resolution options.

=================================================================================================]]

-- Imports
local Button = require('core/gui/widget/control/Button')
local GridWindow = require('core/gui/GridWindow')

-- Alias
local copyTable = util.table.deepCopy

-- Constants
local keys = { 'confirm', 'cancel', 'dash', 'pause', 'prev', 'next' }

local KeyMapWindow = class(GridWindow)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Implements GridWindow:createWidgets.
function KeyMapWindow:createWidgets()
  for i = 1, #keys do
    self:createKeyButtons(keys[i])
  end
  Button:fromKey(self, 'apply').text:setAlign('center')
  Button:fromKey(self, 'default').text:setAlign('center')
end
-- Creates main and alt buttons for the given key.
-- @param(key : string) Key type code.
function KeyMapWindow:createKeyButtons(key)
  local button1 = Button(self)
  button1:createText((Vocab[key] or key))
  button1.key = key
  button1.map = 'main'
  local button2 = Button(self)
  button2:createText((Vocab[key] or key) .. ' (' .. Vocab.alt .. ')')
  button2.key = key
  button2.map = 'alt'
end

---------------------------------------------------------------------------------------------------
-- Keys
---------------------------------------------------------------------------------------------------

-- Overrides Window:show.
function KeyMapWindow:show(...)
  if not self.open then
    self.map = { main = copyTable(InputManager.mainMap),
      alt = copyTable(InputManager.altMap) }
    self:refreshKeys()
    self:hideContent()
    GridWindow.show(self, ...)
  end
end
-- Refreshes key codes.
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

---------------------------------------------------------------------------------------------------
-- Input
---------------------------------------------------------------------------------------------------

-- Chooses new resolution.
function KeyMapWindow:onButtonConfirm(button)
  self.cursor.paused = true
  button:createInfoText('')
  repeat
    coroutine.yield()
  until InputManager.lastKey
  local code = InputManager.lastKey
  local map = self.map[button.map]
  if InputManager.arrowMap[code] or InputManager.keyMap[code] then
    code = map[button.key]
  end
  button:createInfoText(code)
  button:updatePosition(self.position)
  map[button.key] = code
  self.cursor.paused = false
end
-- Applies changes.
function KeyMapWindow:applyConfirm()
  InputManager:setKeyMap(copyTable(self.map))
  self.result = 1
end
-- Sets default key map.
function KeyMapWindow:defaultConfirm()
  self.map = copyTable(KeyMap)
  self:refreshKeys()
end

---------------------------------------------------------------------------------------------------
-- Properties
---------------------------------------------------------------------------------------------------

-- Overrides GridWindow:colCount.
function KeyMapWindow:colCount()
  return 2
end
-- Overrides GridWindow:rowCount.
function KeyMapWindow:rowCount()
  return 7
end
-- Overrides GridWindow:cellWidth()
function KeyMapWindow:cellWidth()
  return 140
end
-- @ret(string) String representation (for debugging).
function KeyMapWindow:__tostring()
  return 'Resolution Window'
end

return KeyMapWindow