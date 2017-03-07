
local List = require('core/algorithm/List')

--[[

A tree of callbacks. 
Must be updated every frame to run its callback children.

]]

local CallbackTree = require('core/class'):new()

function CallbackTree:init()
  self.children = List()
end

-- Adds a new callback to child list.
-- @param(callback : Callback) the callback object to add
function CallbackTree:addChild(callback)
  callback.parent = self
  callback.tree = self.tree or self
  self.children:add(callback)
end

-- Creates a new callback from the function and adds to child list.
-- @param(func : Function) the callback's function
-- @param(... : unknown) the function's parameters
function CallbackTree:fork(func, ...)
  local arg = {...}
  local Callback = require('core/callback/Callback')
  local callback = Callback(func, unpack(arg))
  self:addChild(callback)
  return callback
end

-- Creates a new callback from the function and adds to child list.
-- @param(func : Function) the callback's function
-- @param(... : unknown) the function's parameters
function CallbackTree:lockingFork(func, ...)
  local arg = {...}
  local Callback = require('core/callback/LockingCallback')
  local callback = Callback(func, unpack(arg))
  self:addChild(callback)
  return callback
end

-- Calls a listener from path and adds callback to child list.
-- @param(path : string) path to the script
-- @param(... : unknown) any extra arguments
function CallbackTree:forkFromPath(path, ...)
  if (path ~= '') then
    local Callback = require('custom/' .. path)
    local callback = Callback(nil, ...)
    self:addChild(callback)
    return callback
  end
end

-- Updates all children and removes to concluded ones.
function CallbackTree:update()
  self.children:conditionalRemove(function(child)
    return not child:update()
  end)
end

return CallbackTree
