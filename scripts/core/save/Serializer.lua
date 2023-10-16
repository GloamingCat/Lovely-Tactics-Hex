
--[[===============================================================================================

@module Serializer
---------------------------------------------------------------------------------------------------
A module that deals with string-object convertion using JSON.

=================================================================================================]]

-- Imports
local JSON = require('core/save/JsonParser')

-- Alias
local readFile = love.filesystem.read
local writeFile = love.filesystem.write

local Serializer = {}

-- ------------------------------------------------------------------------------------------------
-- Codification
-- ------------------------------------------------------------------------------------------------

--- Converts any object to a serialized string.
-- @tparam unknown data Any object to be encoded into a string.
-- @treturn string A string codification of the object.
function Serializer.encode(data)
  -- TODO: exceptions
  return JSON.encode(data)
end
--- Parses a serialized string to an object.
-- @tparam string text The string codification of the object.
-- @treturn The object that the string represents.
function Serializer.decode(text)
  if type(text) ~= 'string' then
    return text
  end
  local data, err, msg = JSON.decode(text)
  if err and msg then
    print(err, msg, "on: " .. tostring(text))
    return nil
  else
    return data
  end
end

-- ------------------------------------------------------------------------------------------------
-- File
-- ------------------------------------------------------------------------------------------------

--- Decodes the content of a given file.
-- @tparam string path The path to the file.
-- @treturn The decoded object stored in the file.
function Serializer.load(path)
  local text = readFile(path)
  assert(text, "Could not load " .. path)
  local data = Serializer.decode(text)
  assert(data, 'Could not parse ' .. path)
  return data
end
--- Encodes the content into a given file.
-- @tparam string path The path to the file.
-- @tparam unknown data Any object to be encoded and stored.
-- @treturn string A string codification of the object.
function Serializer.store(path, data)
  local text = Serializer.encode(data)
  writeFile(path, text)
  return text
end

return Serializer