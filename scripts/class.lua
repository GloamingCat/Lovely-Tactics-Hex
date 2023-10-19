
-- ================================================================================================

--- The base class.
-- Reference: Kevin Clancy's Game Kitchen project.
---------------------------------------------------------------------------------------------------
-- @classmod class

-- ================================================================================================

function class(...)
  local parents = {...}
  
  -- Create class metatable from parents.
  local c_meta = {}
  
  for i = 1, #parents do
    for k, v in pairs(getmetatable(parents[i])) do
      c_meta[k] = v
    end
  end
  
  -- Access inherited fields if not overriden.
  if #parents > 1 then
    function c_meta:__index(key)
      local k
      for i = #parents, 1, -1 do
        k = parents[i][key]
        if k then return k end
      end
    end
  elseif #parents == 1 then
    local p = parents[1]
    function c_meta:__index(key)
      return p[key]
    end
  end

  -- When a new field is set.
  function c_meta:__newindex(k,v)
    if type(k) == 'string' and k:sub(1,2) == '__' then
      rawset(getmetatable(self), k, v)
    else
      rawset(self,k,v)
    end
  end
  
  -- The new class.
  local c = {}
  
  -- Constructor.
  function c_meta:__call(...)
    local inst = {}
    inst.__class = c
    local inst_meta = {}
    for k,v in pairs(c_meta) do
      inst_meta[k] = v
    end
    function inst_meta:__index(key)
      return c[key]
    end
    setmetatable(inst,inst_meta)
    if inst.init then
      inst:init(...)
    end
    return inst
  end

  setmetatable(c,c_meta) 
  return c
end
