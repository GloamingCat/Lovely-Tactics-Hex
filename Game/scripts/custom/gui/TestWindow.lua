
local ButtonWindow = require('core/gui/ButtonWindow')

--[[===========================================================================

Just an example window.

===========================================================================]]

local TestWindow = ButtonWindow:inherit()

local function buttonConfirm(button)
  print(button.index)
end

function TestWindow:createButtons()
  for i = 1, 10 do
    self:addButton('Button' .. i, nil, buttonConfirm)
  end
end

return TestWindow
