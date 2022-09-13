--[[===============================================================================================

Stalker
---------------------------------------------------------------------------------------------------
NPC that walks towards the player.

-- Arguments:
<id> ID of the item to be received.
<count> Quantity (1 by default).

=================================================================================================]]

-- Alias
local rand = love.math.random

return function(script)
  local id = tonumber(script.args.id) or script.args.id
  local item = Database.items[id]
  local count = tonumber(script.args.count) or 1
  Config.variables["loot"].value = item.name
  Config.variables["lootq"].value = count
  script:showDialogue { id = 1, message = Vocab.loot }
  script:increaseItem { id = item.id, value = count }
  script:closeDialogueWindow { id = 1 }
  script:deleteChar { key = "self", permanent = true }
end