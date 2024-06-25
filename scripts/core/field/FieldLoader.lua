
-- ================================================================================================

--- Loads and prepares field from file data.
---------------------------------------------------------------------------------------------------
-- @module FieldLoader

-- ================================================================================================

-- Imports
local AnimatedInteractable = require('core/objects/AnimatedInteractable')
local Character = require('core/objects/Character')
local Field = require('core/field/Field')
local Interactable = require('core/objects/Interactable')
local Serializer = require('core/save/Serializer')
local TagMap = require('core/datastruct/TagMap')
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
function FieldLoader.loadField(id, save)
  local data = Serializer.load(Project.dataPath .. 'fields/' .. id .. '.json')
  local prefs = save and save.prefs or data.prefs.persistent and FieldManager:getFieldSave(id).prefs or data.prefs
  local maxH = data.prefs.maxHeight
  local field = Field(data.id, data.prefs.name, data.sizeX, data.sizeY, maxH)
  field.key = data.prefs.key
  field.persistent = data.prefs.persistent
  field.vars = prefs.vars or {}
  field.images = prefs.images or data.prefs.images
  field.tags = TagMap(data.prefs.tags)
  field.loadScript = prefs.loadScript or data.prefs.loadScript
  if field.loadScript then
    field.loadScript = util.table.deepCopy(field.loadScript)
    field.loadScript.vars = field.loadScript.vars or {}
  end
  field.exitScript = prefs.exitScript or data.prefs.exitScript
  if field.exitScript then
    field.exitScript = util.table.deepCopy(field.exitScript)
    field.exitScript.vars = field.exitScript.vars or {}
  end
  field.bgm = prefs.bgm
  -- Battle info
  field.playerParty = prefs.playerParty or data.playerParty
  field.parties = prefs.parties or data.parties
  -- Default region
  local defaultRegion = prefs.defaultRegion or data.prefs.defaultRegion
  if defaultRegion and defaultRegion >= 0 then
    for tile in field:gridIterator() do
      tile.regionList:add(defaultRegion)
    end
  end
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
-- @tparam table save Field's save data.
function FieldLoader.loadCharacters(field, instances, save)
  local persistentData = save or FieldManager:getFieldSave(field.id)
  for i, inst in ipairs(instances) do
    local save = persistentData.chars[inst.key]
    if not (save and save.deleted) then
      if (save and save.charID or inst.charID) >= 0 then
        Character(inst, save)
      elseif inst.animation and inst.animation ~= '' then
        AnimatedInteractable(inst, save)
      else
        Interactable(inst, save)
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
      FieldLoader.createTransitionTile(tile, t.destination, id)
      id = id + 1
    end
  end
end
--- Creates the interactable for a transition tile.
-- @tparam table origin The coordinates of the origin tile (x, y, h).
-- @tparam table destination The destination with coordinates, direction and field ID.
-- @return Interactable The transition object.
function FieldLoader.createTransitionTile(origin, destination, i)
  local key = "Transition" .. tostring(i)
  local args = { fieldID = destination.fieldID,
    x = destination.x,
    y = destination.y,
    h = destination.h,
    direction = destination.direction,
    exit = key }
  local func = function(script)
    if script:collidedWith('player') then
      script:moveToField(args)
    end
  end
  local script = { func = func,
    block = true, 
    global = true,
    wait = true,
    onCollide = true,
    vars = {} }
  local instData = { key = key,
    passable = false,
    active = true,
    x = origin.dx, y = origin.dy, h = origin.height,
    scripts = { script } }
  return Interactable(instData)
end

return FieldLoader
