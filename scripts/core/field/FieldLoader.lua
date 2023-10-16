
--[[===============================================================================================

@module FieldLoader
---------------------------------------------------------------------------------------------------
Loads and prepares field from file data.

=================================================================================================]]

-- Imports
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
-- @tparam table characters Array of character instances.
-- @tparam table save Field's save data.
function FieldLoader.loadCharacters(field, characters, save)
  local persistentData = save or FieldManager:getFieldSave(field.id)
  for i, char in ipairs(characters) do
    local save = persistentData.chars[char.key]
    if not (save and save.deleted) then
      if (save and save.charID or char.charID) >= 0 then
        Character(char, save)
      else
        char.passable = true
        Interactable(char, save)
      end
    end
  end
end

-- ------------------------------------------------------------------------------------------------
-- Field Transitions
-- ------------------------------------------------------------------------------------------------

--- Creates interactables for field's transitions.
-- @tparam Field field Current field.
-- @tparam table transitions Array of field's transitions.
function FieldLoader.createTransitions(field, transitions)
  field.transitions = {}
  for i, t in ipairs(transitions) do
    local args = { fieldID = t.destination.fieldID,
      x = t.destination.x,
      y = t.destination.y,
      h = t.destination.h,
      direction = t.destination.direction,
      fade = t.fade }
    field.transitions[i] = args
    if not t.noSource then
      local func = function(script)
        if script.char.collider == 'player' then
          script:moveToField(args)
        end
      end
      local scripts = { { func = func, 
        block = true, 
        global = true,
        wait = true,
        onCollide = true,
        transition = args } }
      for _, tile in ipairs(t.origin) do
        local instData = { key = 'Transition',
          scripts = scripts,
          x = tile.dx, y = tile.dy, h = tile.height }
        Interactable(instData)
      end
    end
  end
end

return FieldLoader
