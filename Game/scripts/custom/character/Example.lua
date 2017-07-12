
--[[===============================================================================================

An example of usage of a fiber for a Field.

=================================================================================================]]

-- Imports
local Window = require('core/gui/Window')

---------------------------------------------------------------------------------------------------
-- Main function
---------------------------------------------------------------------------------------------------

return function (event, ...)
  print('Just started.')
  local list = FieldManager:search('Template')
  print(list.size)
  local char1 = list[2]
  local char2 = list[1]
  char1:turnToTile(char1.tile.x + 1, char1.tile.y)
  _G.Fiber:fork(function()
    print('Walk start')
    char2:walkTiles(0, 6, 0)
    print('Walk end.')
  end)
  _G.Fiber:wait(60)
  print('1 second.')
  _G.Fiber:fork(function()
    self:wait(60)
    print('2 seconds.')
  end)
  _G.Fiber:wait(120)
  print('3 seconds.')
end
