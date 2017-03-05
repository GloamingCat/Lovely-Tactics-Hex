
local Build = {}

function Build.STR(level)
  return 5 * level
end

function Build.MAG(level)
  return 0.5 * level
end

function Build.DEX(level)
  return 3 * level
end

function Build.RES(level)
  return 4 * level
end

function Build.AGI(level)
  return 2.5 * level
end

function Build.MOV(level)
  return 6
end

function Build.JMP(level)
  return 2
end

return Build
