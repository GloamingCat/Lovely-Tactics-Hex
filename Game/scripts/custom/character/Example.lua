
--[[===========================================================================

An example of usage of an eventsheet for a Field.

=============================================================================]]

-- Imports
local Window = require('core/gui/Window')
local Callback = require('core/callback/Callback')

local Example = Callback:inherit()

-------------------------------------------------------------------------------
-- Main function
-------------------------------------------------------------------------------

function Example:exec(event, ...)
  --FieldManager.player.blockingCharacters = FieldManager.player.blockingCharacters + 1
  print('Just started.')
  local list = FieldManager:search('Template')
  print(list.size)
  local char1 = list[2]
  local char2 = list[1]
  char1:turnToTile(char1.tile.x + 1, char1.tile.y)
  self:fork(function()
    print('Walk start')
    char2:walkTiles(0, 6, 0)
    print('Walk end.')
  end)
  self:wait(60)
  print('1 second.')
  self:fork(function()
    self:wait(60)
    print('2 seconds.')
  end)
  self:wait(120)
  print('3 seconds.')
  --FieldManager.player.blockingCharacters = FieldManager.player.blockingCharacters - 1
end

return Example
