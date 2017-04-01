
--[[===========================================================================

BattlePortrait
-------------------------------------------------------------------------------
A window content with a battler's portrait.

=============================================================================]]

-- Imports
local Sprite = require('core/graphics/Sprite')
local SimpleImage = require('core/gui/SimpleImage')

local BattlePortrait = SimpleImage:inherit()

-------------------------------------------------------------------------------
-- Initialization
-------------------------------------------------------------------------------

-- Overrides SimpleImage:init.
-- @param(battler : Battler) the portrait's battler
-- @param(name : string) the name of the portrait
local old_init = BattlePortrait.init
function BattlePortrait:init(battler, name, ...)
  local quad = battler.portraits[name]
  local sprite
  if quad then
    sprite = Sprite.fromQuad(quad)
  else
    local character = TroopManager:getCharacter(battler)
    sprite = character.sprite:clone(GUIManager.renderer)
  end
  old_init(self, sprite, ...)
end

return BattlePortrait
