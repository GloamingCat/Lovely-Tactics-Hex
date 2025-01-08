
-- ================================================================================================

--- Accessor for game variables.
---------------------------------------------------------------------------------------------------
-- @module Variables

-- ================================================================================================

-- Alias
local pathAccess = util.table.access

local meta = {}
local Variables = {}

-- ------------------------------------------------------------------------------------------------
-- Global Variables
-- ------------------------------------------------------------------------------------------------

Variables.vars = {}
function meta:__index(key)
  return self.vars[key]
end
function meta:__newindex(key, v)
  self.vars[key] = v
end

-- ------------------------------------------------------------------------------------------------
-- Scoped Variables
-- ------------------------------------------------------------------------------------------------

--- Gets the value of a variable considering the scope of execution.
-- The scope of the variable is searched in order:
-- Vocab, script (local, character, args, tags), field, game (global).
-- @tparam string key The name of the variable.
-- @tparam[opt] Fiber script The current executing script.
-- @tparam[opt] Field field The current loaded field.
-- @return The value of the variable.
function meta:__call(key, script, field)
  script = script or _G.Fiber
  field = field or FieldManager.currentField
  local value = pathAccess(Vocab, key)
  if value == nil and script then
    -- Local
    value = script.vars and script.vars[key]
    if value == nil and script.char and script.char.vars then
      -- Object
      value = script.char.vars[key]
    end
    if value == nil and script.args then
      -- Args
      value = script.args[key]
    end
    if value == nil and script.tags then
      -- Default args
      value = script.tags[key]
    end
  end
  if value == nil and field and field.vars then
    -- Field
    value = field.vars[key]
  end
  if value == nil and Variables.vars then
    -- Global
    value = Variables.vars[key]
  end
  return value
end

setmetatable(Variables, meta) 
return Variables
