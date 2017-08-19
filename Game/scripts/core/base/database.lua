
Database = {}
local db = {'attributes', 'items', 'skills', 'skillDags', 'battlers', 'status', 
  'animCharacter', 'animBattle', 'animOther', 'terrains', 'obstacles', 'ramps', 
  'troops', 'charBattle', 'charField', 'charOther', 'variables'}
for i = 1, #db do
  local file = db[i]
  local datajson = love.filesystem.read('data/' .. file .. '.json')
  Database[file] = JSON.decode(datajson)
end