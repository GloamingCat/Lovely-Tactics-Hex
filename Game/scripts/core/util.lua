
--[[===============================================================================================

This module provides a few general functions to be used in convenient situations.

=================================================================================================]]

util = {}

function util.newArray(size, value)
  local a = {}
  for i = 1, size do
    a[i] = value
  end
  return a
end

