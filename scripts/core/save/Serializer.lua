
-- ================================================================================================

--- A module that deals with string-object convertion using JSON.
---------------------------------------------------------------------------------------------------
-- @iomod Serializer

-- ================================================================================================

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
  Serializer.validate('', data)
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
    if type(data) ~= 'number' or data == tonumber(text) then
      return data
    end
  end
end
--- Verifies that the table can be json-encoded.
-- @tparam string path The path within the root table.
-- @tparam table data The table to verify.
function Serializer.validate(path, data)
  for k, v in pairs(data) do
    if type(v) == "function" then
      error("Functional value: " .. path .. '.' .. k)
    elseif type(k) ~= "string" and type(k) ~= "number" then
      error("Non-alphanumeric key: " .. path .. tostring(k))
    elseif type(v) == "table" then
      Serializer.validate(path .. "." .. tostring(k), v)
    end
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