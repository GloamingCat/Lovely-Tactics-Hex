
local function toArray(arr, children)
  for i = 1, #children do
    local node = children[i]
    if node.data then
      arr[node.data.id] = node.data
      node.data.name = node.name
    else
      toArray(arr, node.children)
    end
  end
  return arr
end

-- Database files
Database = {}
local db = {'animations', 'battlers', 'characters', 'classes', 'items', 'obstacles', 
  'skills', 'status', 'terrains', 'troops'}
for i = 1, #db do
  local file = db[i]
  local data = JSON.load('data/' .. file)
  Database[file] = toArray({}, data)
end
-- System files
local sys = {'attributes', 'elements', 'regions', 'variables'}
for i = 1, #sys do
  local file = sys[i]
  local data = JSON.load('data/system/' .. file)
  Config[file] = data
end
for i = 1, #Config.attributes do
  local att = Config.attributes[i]
  Config.attributes[att.key] = att
end