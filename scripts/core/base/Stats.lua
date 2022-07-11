
--[[===============================================================================================

Stats
---------------------------------------------------------------------------------------------------
Module that reads and counts the files and lines from the projects.

=================================================================================================]]

-- Alias
local listItems = love.filesystem.getDirectoryItems
local readFile = love.filesystem.read
local fileInfo = love.filesystem.getInfo

local stats = {}

---------------------------------------------------------------------------------------------------
-- Stats
---------------------------------------------------------------------------------------------------

-- Prints number of files and lines of code and data.
function stats.printStats()
  local codefiles, codelines = stats.count('scripts', stats.countCodeLines)
  print('Number of code files:', codefiles)
  print('Number of code lines:', codelines)
  local datafiles, datalines = stats.count('data', stats.countDataLines)
  print('Number of data files:', datafiles)
  print('Number of data lines:', datalines)
end
-- Counts number of files and lines of code.
-- @param(path : string) Code files folder.
-- @ret(number) Number of code files.
-- @ret(number) Number of code lines.
function stats.count(path, countLines)
  local files, lines = 0, 0
  local fileList = listItems(path)
  for i = 1, #fileList do
    local file = fileList[i]
    local path2 = path .. '/' .. file
    if fileInfo(path2).type == 'file' then 
      files = files + 1
      lines = lines + countLines(path2)
    else
      local files2, lines2 = stats.count(path2, countLines)
      files = files + files2
      lines = lines + lines2
    end
  end
  return files, lines
end

---------------------------------------------------------------------------------------------------
-- Lines
---------------------------------------------------------------------------------------------------

-- Counts the number of code lines in a file, ignoring comments.
-- The file is assumed to be a compilable Lua file.
-- @ret(number) Number of code lines.
function stats.countCodeLines(path)
  local content = readFile(path)
  local blockComments = "(%-%-%[%[)(.-)*?(%]%])"
  local lineComments = "(%-%-)(.-)*?\n"
  content = content:gsub(blockComments, '')
  content = content:gsub(lineComments, '')
  content = content:gsub('(\n%s+\n)', '\n')
  local _, count = content:gsub('\n', '\n')
  return count
end
-- Counts the number of data lines in a (assumed valid) file, ignoring comment.
-- The file is assumed to be a parsable JSON file.
-- @ret(number) Number of data lines.
function stats.countDataLines(path)
  local content = readFile(path)
  local comments = "//.*?\n"
  content = content:gsub(comments, '')
  content = content:gsub('(\n%s+\n)', '\n')
  local _, count = content:gsub('\n', '\n')
  return count
end

return stats
