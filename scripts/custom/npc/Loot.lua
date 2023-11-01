-- ================================================================================================

--- NPC that walks towards the player.
---------------------------------------------------------------------------------------------------
-- @event Loot

--- Parameters Script tags.
-- @tags Script
-- @tfield number id The ID of the item to be received.
-- @tfield[opt=1] number count The quantity of the item rewarded.

-- ================================================================================================

-- Alias
local rand = love.math.random

return function(script)

  local id = tonumber(script.args.id) or script.args.id
  local item = Database.items[id]
  local count = tonumber(script.args.count) or 1
  local name = "{%data.item." .. item.key .. "}"
  Config.variables["loot"].value = name
  Config.variables["lootq"].value = count
  -- Translate
  if not pcall(script.showDialogue, script, { id = 1, message = Vocab.loot }) then   
    Config.variables["loot"].value = item.name
    script:showDialogue { id = 1, message = Vocab.loot }
  end
  script:increaseItem { id = item.id, value = count }
  script:closeDialogueWindow { id = 1 }
  script:deleteChar { key = "self", permanent = true }
end