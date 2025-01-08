
-- ================================================================================================

--- Represents a set of battler attributes, stored by key.
---------------------------------------------------------------------------------------------------
-- @battlemod AttributeSet

-- ================================================================================================

-- Alias
local copyTable = util.table.shallowCopy

-- Class table.
local AttributeSet = class()

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam Battler battler The battler with this attribute set.
-- @tparam table save The attribute set's save data.
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
--- Converts array of attributes to a map.
-- @tparam table atts Array of attributes, in the order defined by system configurations.
-- @treturn table A map of attribute values by their keys.
function AttributeSet:toMap(atts)
  local t = {}
  for i, att in ipairs(Config.attributes) do
    t[att.key] = atts[i]
  end
  return t
end

-- ------------------------------------------------------------------------------------------------
-- Attribute Values
-- ------------------------------------------------------------------------------------------------

--- Computes the base value of attributes from its formula plus the base valus from the job and
-- battler data.
-- @tparam string key Attribute's key.
-- @treturn number The basic attribute value, without volatile bonus.
function AttributeSet:getBase(key)
  local base = self.jobBase[key] + self.battlerBase[key]
  if self.formula[key] then
    base = base + self.formula[key](self)
  end
  return base
end
--- Computes the new value of the attribute added by its bonuses.
-- @tparam string key Attribute's key.
-- @tparam number base Attribute's basic value.
-- @tparam Battler battler Battler that contains the bonus information.
-- @treturn number The basic + the bonus value.
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

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Persistent state of the battler's attributes.
-- @treturn table Array with the base values of each attribute.
function AttributeSet:getState()
  return copyTable(self.battlerBase)
end
-- For debugging.
function AttributeSet:__tostring()
  return 'AttributeSet: ' .. tostring(self.battler)
end

return AttributeSet
