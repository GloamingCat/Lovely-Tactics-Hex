
--[[===============================================================================================

AttributeSet
---------------------------------------------------------------------------------------------------
Represents a set of battler attributes, stored by key.

=================================================================================================]]

-- Alias
local copyTable = util.table.shallowCopy

local AttributeSet = class()

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(battler : Battler) the battler with this attribute set
function AttributeSet:init(battler, save)
  self.battler = battler
  self.jobBase = {}
  self.battlerBase = {}
  self.formula = {}
  local attBase = save and save.att or self:toMap(battler.data.attributes)
  local build = battler.job.build
  for i, att in ipairs(Config.attributes) do
    local key = att.key
    local script = att.script
    -- Base values
    self.jobBase[key] = build and build[key] and build[key](battler.job.level) or 0
    self.battlerBase[key] = attBase[key] or 0
    self.formula[key] = script ~= '' and loadformula(script, 'att')
    -- Total
    self[key] = function()
      local base = self:getBase(key)
      if self.bonus then
        base = self:getBonus(key, base, battler)
      end
      return base
    end
  end
  self.bonus = true
end
-- Converts array of attributes to a map.
-- @param(att : table) Array of attributes, in the order defined by system configurations.
-- @ret(table) A map of attribute values by their keys.
function AttributeSet:toMap(atts)
  local t = {}
  for i, att in ipairs(Config.attributes) do
    t[att.key] = atts[i]
  end
  return t
end

---------------------------------------------------------------------------------------------------
-- Attribute Values
---------------------------------------------------------------------------------------------------

-- @param(key : string) attribute's key
-- @ret(number) the basic attribute value, without volatile bonus
function AttributeSet:getBase(key)
  local base = self.jobBase[key] + self.battlerBase[key]
  if self.formula[key] then
    base = base + self.formula[key](self)
  end
  return base
end
-- @param(key : string) attribute's key
-- @param(base : number) attribute's basic value
-- @param(battler : Battler) battler that contains the bonus information
-- @ret(number) the basic + the bonus value
function AttributeSet:getBonus(key, base, battler)
  local add, mul = 0, 1
  if battler.statusList then
    local add1, mul1 = battler.statusList:attBonus(key)
    add = add + add1
    mul = mul + mul1
  end
  if battler.equipSet then
    local add2, mul2 = battler.equipSet:attBonus(key)
    add = add + add2
    mul = mul + mul2
  end
  return add + base * mul
end

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Converting to string.
-- @ret(string) A string representation.
function AttributeSet:__tostring()
  return 'AttributeSet: ' .. tostring(self.battler)
end
-- @ret(table) persistent state of the battler's attributes
function AttributeSet:getState()
  return copyTable(self.battlerBase)
end

return AttributeSet
