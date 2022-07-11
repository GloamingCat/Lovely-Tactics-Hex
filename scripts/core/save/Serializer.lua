
--[[===============================================================================================

Serializer
---------------------------------------------------------------------------------------------------
A module that deals with string-object convertion using JSON.

=================================================================================================]]

-- Imports
local JSON = require('core/save/JsonParser')

-- Alias
local readFile = love.filesystem.read
local writeFile = love.filesystem.write

local Serializer = {}

---------------------------------------------------------------------------------------------------
-- Codification
---------------------------------------------------------------------------------------------------

-- Converts any object to a serialized string.
-- @param(data) Any object to be encoded into a string.
-- @ret(string) A string codification of the object.
function Serializer.encode(data)
  -- TODO: exceptions
  return JSON.encode(data)
end
-- Parses a serialized string to an object.
-- @param(text : string) The string codification of the object.
-- @ret The object that the string represents.
function Serializer.decode(text)
  local data, err, msg = JSON.decode(text)
  if err and msg then
    print (err, msg)
  else
    return data
  end
end

---------------------------------------------------------------------------------------------------
-- File
---------------------------------------------------------------------------------------------------

-- Decodes the content of a given file.
-- @param(path : string) The path to the file.
-- @ret The object stored in the file.
function Serializer.load(path)
  local text = readFile(path)
  assert(text, "Could not load " .. path)
  local data = Serializer.decode(text)
  assert(data, 'Could not parse ' .. path)
  return data
end
-- Encodes the content into a given file.
-- @param(path : string) The path to the file.
-- @ret(string) A string codification of the object.
function Serializer.store(path, data)
  local text = Serializer.encode(data)
  writeFile(path, text)
  return text
end

return Serializer