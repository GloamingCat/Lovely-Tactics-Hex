
---------------------------------------------------------------------------------------------------
-- Require
---------------------------------------------------------------------------------------------------

-- Overrides Lua's default require function to ignore ".lua" extension.
local old_require = require
require = function(path)
  return old_require(string.gsub(path, '.lua', ''))
end

---------------------------------------------------------------------------------------------------
-- Coroutine Error
---------------------------------------------------------------------------------------------------

-- Prints coroutine error.
-- @param(msg : string) error message
local function err(msg) 
  print(debug.traceback(msg, 2))  
end

-- Overrides Lua's native coroutine.create function to show errors inside the coroutine.
-- @param(func : function) the coroutine's function
-- @ret(coroutine) the newly created coroutine
local old_coroutine_create = coroutine.create
function coroutine.create(func)
  local pfunc = function() 
    xpcall(func, err)
  end
  return old_coroutine_create(pfunc)
end

---------------------------------------------------------------------------------------------------
-- Image Cache
---------------------------------------------------------------------------------------------------

local ImageCache = {}

-- Overrides LÖVE's newImage function to use cache.
-- @param(path : string) image's path relative to main path
-- @ret(Image) to image store in the path
local old_newImage = love.graphics.newImage
function love.graphics.newImage(path)
  if type(path) == 'string' then
    path = string.gsub(path, '\\', '/')
    local img = ImageCache[path]
    if img then
      return img
    else
      img = old_newImage(path)
      img:setFilter('linear', 'nearest')
      ImageCache[path] = img
    end
  end
  return old_newImage(path)
end

---------------------------------------------------------------------------------------------------
-- Font Cache
---------------------------------------------------------------------------------------------------

local FontCache = {}

-- Overrides LÖVE's newFont function to use cache.
-- @param(size : number) the font's size
-- @param(path : string) font's path relative to main path (optional)
-- @ret(Image) to image store in the path
local old_newFont = love.graphics.newFont
function love.graphics.newFont(path, size)
  local key = '' .. size
  if not path then
    key = key .. '.' .. path
  end
  local font = FontCache[key]
  if not font then
    font = old_newFont(path, size)
    FontCache[key] = font
  end
  return font
end

---------------------------------------------------------------------------------------------------
-- Function Cache
---------------------------------------------------------------------------------------------------

local FunctionCache = {}

-- Overrides Lua's native function to store string in cache if already compiled.
-- @param(str : string) the string chunk
-- @param(... : unknown) any other parameters to the original loadstring function
-- @ret(function) the function that executes the chunk in the string
local old_loadstring = loadstring
function loadstring(str, ...)
  local func = FunctionCache[str]
  if func then
    return func
  else
    func = old_loadstring(str, ...)
    FunctionCache[str] = func
    return func
  end
end

function loadfunction(body, param)
  if param and param ~= '' then
    local funcString = 
      'function(' .. param .. ') ' ..
        body ..
      ' end'
    return loadstring('return ' .. funcString)()
  else
    return loadstring(body)
  end
end

-- Generates a function from a formula in string.
-- @param(formula : string) the formula expression
-- @param(param : string) the param needed for the function (optional)
-- @ret(function) the function that evaluates the formulae
function loadformula(formula, param)
  return loadfunction('return ' .. formula, param)
end
