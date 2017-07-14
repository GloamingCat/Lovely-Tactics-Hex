
--[[===============================================================================================

EscapeAction
---------------------------------------------------------------------------------------------------
The BattleAction that is executed when players chooses the "Escape" button.

=================================================================================================]]

-- Imports
local BattleAction = require('core/battle/action/BattleAction')

-- Alias
local yield = coroutine.yield

-- Constants
local animSpeed = 10

local EscapeAction = class(BattleAction)

---------------------------------------------------------------------------------------------------
-- Initilization
---------------------------------------------------------------------------------------------------

-- Constructor.
function EscapeAction:init()
  BattleAction.init(self, 100, 0, 0, '')
end

---------------------------------------------------------------------------------------------------
-- Callback
---------------------------------------------------------------------------------------------------

-- Overrides BattoeAction:onActionGUI.
function EscapeAction:onActionGUI(input)
  local confirm = GUIManager:showGUIForResult('ConfirmGUI')
  if confirm == 1 then
    return self:onConfirm(input)
  else
    return self:onCancel(input)
  end
end
-- Executes the escape animation for the given character.
function EscapeAction:onConfirm(input)
  local char = input.user
  local party = char.battler.party
  while char.sprite.color.alpha > 0 do
    local a = char.sprite.color.alpha
    char.sprite:setRGBA(nil, nil, nil, a - animSpeed)
    yield()
  end
  char.sprite:setRGBA(nil, nil, nil, 0)
  TroopManager:removeCharacter(char)
  if TroopManager:getMemberCount(party) == 0 then
    return {
      executed = true,
      escaped = true
    }
  else
    return self:execute()
  end
end

return EscapeAction
