
-- ================================================================================================

--- Loads and prepares field from file data.
---------------------------------------------------------------------------------------------------
-- @module FieldLoader

-- ================================================================================================

-- Imports
local AnimatedInteractable = require('core/objects/AnimatedInteractable')
local BattleCharacter = require('core/objects/BattleCharacter')
local Character = require('core/objects/Character')
local Fiber = require('core/fiber/Fiber')
local Field = require('core/field/Field')
local InteractableObject = require('core/objects/InteractableObject')
local Serializer = require('core/save/Serializer')
local TerrainLayer = require('core/field/TerrainLayer')

local FieldLoader = {}

-- ------------------------------------------------------------------------------------------------
-- File
-- ------------------------------------------------------------------------------------------------

--- Loads the field of the given ID.
-- @tparam number id Field's ID.
-- @tparam table save The field's save data.
-- @treturn Field New empty field.
-- @treturn table Field file data.
function FieldLoader.getField(id, save)
  local data = Serializer.load(Project.dataPath .. 'fields/' .. tostring(id) .. '.json')
  local field = Field(id, data.prefs, data.sizeX, data.sizeY, save)
  -- Default region
  local defaultRegion = data.prefs.defaultRegion
  if defaultRegion and defaultRegion >= 0 then
    for tile in field:gridIterator() do
      tile.regionList:add(defaultRegion)
    end
  end
  field.playerParty = data.playerParty
  field.parties = data.parties
  field.transitions = data.prefs.transitions
  return field, data
end

-- ------------------------------------------------------------------------------------------------
-- Layers
-- ------------------------------------------------------------------------------------------------

--- Merges layers' data.
-- @tparam Field field Current field.
-- @tparam table layers Terrain, obstacle and region layer sets.
function FieldLoader.mergeLayers(field, layers)
  for i, layerData in ipairs(layers.terrain) do
    local list = field.terrainLayers[layerData.info.height]
    assert(list, "Terrain layers out of height limits: " .. layerData.info.height)
    local order = #list
    local layer = TerrainLayer(layerData, field.sizeX, field.sizeY, -order)
    list[order + 1] = layer
  end
  for i, layerData in ipairs(layers.obstacle) do
    field.objectLayers[layerData.info.height]:mergeObstacles(layerData)
  end
  for i, layerData in ipairs(layers.region) do
    field.objectLayers[layerData.info.height]:mergeRegions(layerData)
  end
  for tile in field:gridIterator() do
    tile:createNeighborList()
  end
end

-- ------------------------------------------------------------------------------------------------
-- Character
-- ------------------------------------------------------------------------------------------------

--- Creates field's characters.
-- @tparam Field field Current field.
-- @tparam table instances Array of character instances.
-- @tparam table fieldSave Field's save data.
function FieldLoader.loadCharacters(field, instances, fieldSave)
  local persistentData = fieldSave or FieldManager:getFieldSave(field.id)
  for _, inst in pairs(instances) do
    local save = persistentData.chars[inst.key]
    if not ((save and save.deleted) or (fieldSave and not save)) then
      if (save and save.charID or inst.charID) >= 0 then
        if inst.party and inst.party >= 0 then
          BattleCharacter(inst, save)
        else
          Character(inst, save)
        end
      elseif inst.animation and inst.animation ~= '' then
        AnimatedInteractable(inst, save)
      else
        InteractableObject(inst, save)
      end
    end
  end
end

-- ------------------------------------------------------------------------------------------------
-- Field Transitions
-- ------------------------------------------------------------------------------------------------

--- Creates interactables for field's transitions.
-- @tparam table transitions Array of field's transitions.
function FieldLoader.createTransitions(transitions)
  local id = 0
  for _, t in ipairs(transitions) do
    for _, tile in ipairs(t.origin) do
      FieldLoader.createTransitionTile(tile, t.destination, "Transition" .. tostring(id), t.condition)
      id = id + 1
    end
  end
end
--- Creates the interactable for a transition tile.
-- @tparam table origin The coordinates of the origin tile (x, y, h).
-- @tparam table destination The destination with coordinates, direction and field ID.
-- @tparam string key The key of the new object.
-- @return InteractableObject The newly created transition object.
function FieldLoader.createTransitionTile(origin, destination, key, condition)
  local args = { 
    { key = "fieldID", value = destination.fieldID },
    { key = "x", value = destination.x },
    { key = "y", value = destination.y },
    { key = "h", value = destination.h },
    { key = "direction", value = destination.direction },
    { key = "exit", value = '"' .. key .. '"' }
  }
  if condition and condition ~= '' then
    condition = " and (" .. condition .. ")"
  else
    condition = ''
  end
  local event = {
    name = "moveToField",
    tags = args,
    condition = "script:collidedWith('player') and not FieldManager.transitioning" .. condition
  }
  local script = { sheet = { events = { event } },
    name = "Move To Field",
    block = true, 
    scope = Fiber.Scope.OBJECT,
    wait = true,
    onCollide = true,
    vars = {} }
  local instData = { key = key,
    passable = false,
    active = true,
    x = origin.dx,
    y = origin.dy,
    h = origin.height,
    scripts = { script } }
  return InteractableObject(instData)
end

return FieldLoader
