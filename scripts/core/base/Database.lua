
-- ================================================================================================

--- Loads data from the data folder and stores in the Database or Config global tables.
-- ------------------------------------------------------------------------------------------------
-- @module Database

-- ================================================================================================

-- Imports
local Serializer = require('core/save/Serializer')
local TagMap = require('core/datastruct/TagMap')

-- Alias
local copyTable = util.table.deepCopy

local Database = {}

-- ------------------------------------------------------------------------------------------------
-- Database files
-- ------------------------------------------------------------------------------------------------

-- @treturn string Folder containing all data files.
function Database.getDataDirectory()
  return Project.dataPath
end
-- @treturn table Array with the names of all data files.
function Database.getDataFileNames()
  return {'animations', 'battlers', 'characters', 'items', 'jobs', 'obstacles',
  'skills', 'status', 'terrains', 'troops', 'events' }
end
--- Loads all data files and store in the Database table.
function Database.loadDataFiles()
  local db = Database.getDataFileNames()
  for i = 1, #db do
    local file = db[i]
    local data = Database.getRootArray(Database.getDataDirectory(), file)
    Database[file] = Database.toArray(data)
  end
end
--- Unifies all data files in a single array.
-- @tparam string folder Project's data folder.
-- @tparam string file Database file name.
-- @treturn table Array of data.
function Database.getRootArray(folder, file)
  local root = {}
  local files = love.filesystem.getDirectoryItems(folder)
  local data = nil
  for i = 1, #files do
    if files[i]:find(file .. '%w*' .. '%.json') then
      data = Serializer.load(folder .. files[i])
      util.array.addAll(root, data)
    end
  end
  assert(#root > 0 or data, 'Could not load ' .. file)
  return root
end
--- Ignores folder nodes and insert data nodes in the array in the position given by data index.
-- @tparam table children Original array of nodes.
-- @tparam number parentID The ID of the parent node.
-- @tparam table arr Final array with the data nodes (creates an empty one if nil).
-- @treturn table The array with the data nodes.
function Database.toArray(children, parentID, arr)
  arr = arr or {}
  parentID = parentID or -1
  for i = 1, #children do
    local node = children[i]
    if node.data then
      arr[node.id] = node.data
      node.data.id = node.id
      node.data.parentID = parentID
      if node.data.key then
        arr[node.data.key] = node.data
      end
    end
    Database.toArray(node.children, node.id, arr)
  end
  return arr
end
--- Formats data name to string.
-- @tparam table data Some data table from database.
-- @treturn string
function Database.toString(data)
  if data then
    return '[' .. data.id .. '] "' .. data.name .. '"' 
  else
    return 'NIL'
  end
end
--- Converts from array format to tree (raw format).
function Database.toTree(arr)
  if type(arr) == 'string' then
    arr = Database[arr]
  end
  -- Create node for each data
  local nodes = {}
  for i, arrnode in pairs(arr) do
    local data = copyTable(arrnode)
    data.id = nil
    nodes[i] = { id = i, children = {}, data = data }
  end
  -- Create children lists
  local root = { id = -1, children = {} }
  for i, node in pairs(nodes) do
    local list = root.children
    if node.data.parentID ~= -1 then
      list = nodes[node.data.parentID].children
    end
    node.data.parentID = nil
    list[#list + 1] = node
  end
  return root
end

-- ------------------------------------------------------------------------------------------------
-- Config files
-- ------------------------------------------------------------------------------------------------

-- @treturn string Folder containing config files.
function Database.getConfigDirectory()
  return Database.getDataDirectory() .. 'system/'
end
-- @treturn table Array with the names of all config files.
function Database.getConfigFileNames()
  return {'attributes', 'variables', 'elements', 'regions', 'equipTypes', 'plugins'}
end
--- Loads config data and store in the Config table.
function Database.loadConfigFiles()
  local sys = Database.getConfigFileNames()
  for i = 1, #sys do
    local file = sys[i]
    local data = Serializer.load(Database.getConfigDirectory() .. file .. '.json')
    Config[file] = data
  end
  local anim = Config.animations
  Config.animations = {}
  for i = 1, #anim do
    Config.animations[anim[i].name] = anim[i].id
  end
  local icons = Config.icons
  Config.icons = {}
  for i = 1, #icons do
    Config.icons[icons[i].name] = icons[i]
  end
  Database.insertKeys(Config.sounds)
  Database.insertKeys(Config.variables)
  Database.insertKeys(Config.attributes)
  Database.insertKeys(Config.equipTypes)
end
--- Creates alternate keys for the data elements in the given array.
--- Each element must contain a string "key" field.
-- @tparam table arr Array with data element.
function Database.insertKeys(arr)
  for i = 1, #arr do
    local a = arr[i]
    arr[a.key] = a
  end
end

-- ------------------------------------------------------------------------------------------------
-- Vocab files
-- ------------------------------------------------------------------------------------------------

-- @treturn string Database subfolder containing vocab files.
function Database.getVocabDirectory()
  return Database.getDataDirectory() .. 'vocab/'
end
--- Loads config data and store in the Config table.
-- @tparam string lang Selected language (optional, uses first one by default).
function Database.loadVocabFiles(lang)
  lang = Project.languages[lang or 1]
  local dir = Database.getVocabDirectory()
  Vocab = Serializer.load(dir .. 'terms-' .. lang .. '.json')
  Vocab.dialogues = Serializer.load(dir .. 'dialogues-' .. lang.. '.json')
  Vocab.data = Serializer.load(dir .. 'data-' .. lang.. '.json')
  Vocab.manual = Serializer.load(dir .. 'manual-' .. lang.. '.json')
end

-- ------------------------------------------------------------------------------------------------
-- Cache
-- ------------------------------------------------------------------------------------------------

-- Cache tables
local PatternCache = {}
local TimingCache = {}
local BonusCache = {}
local TagMapCache = {}

--Constants
local emptyMap = TagMap()

--- Gets the array of indexes for a given string.
-- @tparam string pattern Numbers separated by spaces.
-- @tparam number cols Number of columns. Used if pattern is empty.
-- @treturn table Array of numbers.
function Database.loadPattern(pattern, cols)
  if pattern and pattern ~= '' then
    local arr = PatternCache[pattern]
    if not arr then
      arr = pattern:trim():split('%s')
      for i = 1, #arr do
        arr[i] = tonumber(arr[i])
      end
      PatternCache[pattern] = arr
    end
    return arr
  else
    local arr = PatternCache[cols]
    if not arr then
      arr = {}
      for i = 1, cols do
        arr[i] = i - 1
      end
      PatternCache[cols] = arr
    end
    return arr
  end
end
--- Gets the array of animation frame times for a given string and animation length.
-- @tparam string durationstr Total duration of animation or sequence of duration of each frame.
-- @tparam number size Number of frames (animation length).
-- @treturn table Array of numbers.
function Database.loadDuration(durationstr, size)
  if not durationstr or durationstr == '' then
    return nil
  end
  local key = durationstr .. '.' .. size
  local arr = TimingCache[key]
  if not arr then
    arr = durationstr:trim():split('%s')
    if #arr < size then
      local duration = tonumber(arr[1])
      duration = duration / size
      for i = 1, size do
        arr[i] = duration
      end
    else
      for i = 1, size do
        arr[i] = tonumber(arr[i])
      end
    end
    TimingCache[key] = arr
  end
  return arr
end
--- Gets the table of move costs per job ID.
-- @tparam table entries Array of map entries.
-- @treturn table Map table.
function Database.loadBonusTable(entries)
  if BonusCache[entries] then
    return BonusCache[entries]
  end
  local t = {}
  for i = 1, #entries do
    t[entries[i].id] = entries[i].value
  end
  BonusCache[entries] = t
  return t
end
--- Gets the map of tags of the given tag array.
-- @tparam table tags Array of {key, value} entries.
-- @treturn TagMap The map with the given entries.
function Database.loadTags(tags)
  if tags == nil or #tags == 0 then
    return emptyMap
  end
  local map = TagMapCache[tags]
  if not map then
    map = TagMap(tags)
    TagMapCache[tags] = map
  end
  return map
end
--- Clears data cache.
function Database.clearCache()
  for k in pairs(PatternCache) do
    PatternCache[k] = nil
  end
  for k in pairs(TimingCache) do
    TimingCache[k] = nil
  end
  for k in pairs(BonusCache) do
    BonusCache[k] = nil
  end
  for k in pairs(TagMapCache) do
    TagMapCache[k] = nil
  end
end

return Database
