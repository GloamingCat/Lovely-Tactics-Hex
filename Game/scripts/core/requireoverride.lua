
--[[
@module 

Creates new require function

]]

local old_require = require
require = function(path)
  return old_require(string.gsub(path, ".lua", ""))
end