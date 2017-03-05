
local Build = {}

function Build.STR(level)
  return 0.5 * level
end

function Build.MAG(level)
  return 6 * level
end

function Build.DEX(level)
  return 4 * level
end

function Build.RES(level)
  return 1 * level
end

function Build.AGI(level)
  return 3.5 * level
end

function Build.MOV(level)
  return 5
end

function Build.JMP(level)
  return 1.5
end

return Build
