
--[[===============================================================================================

TradeSkill
---------------------------------------------------------------------------------------------------
The SkillAction that is executed when players chooses the Trade action.

=================================================================================================]]

-- Imports
local CharacterOnlySkill = require('core/battle/action/CharacterOnlySkill')

local TradeSkill = class(CharacterOnlySkill)

-- Overrides CharacterOnlyAction:isCharacterSelectable.
function TradeSkill:isCharacterSelectable(input, char)
  return (char.battler.party == input.user.battler.party or not char.battler:isAlive()) and 
    (input.user ~= char) and (#input.user.battler.inventory > 0 or #char.battler.inventory > 0)
end
-- Overrides SkillAction:applyAnimatedEffects.
function TradeSkill:applyAnimatedEffects(input)
  input.user:turnToTile(input.target.x, input.target.y)
  local char = input.target.characterList[1]
  GUIManager:showGUIForResult('battle/TradeGUI', input.user, char)
end

return TradeSkill