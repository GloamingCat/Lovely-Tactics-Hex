
--[[===============================================================================================

Just an example window.

=================================================================================================]]

-- Imports
local ButtonWindow = require('core/gui/ButtonWindow')

local TestWindow = class(ButtonWindow)

local function buttonConfirm(window, button)
  print(button.index)
end

function TestWindow:createButtons()
  for i = 1, 10 do
    self:addButton('Button' .. i, nil, buttonConfirm)
  end
end

return TestWindow
