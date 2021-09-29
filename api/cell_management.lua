require "api.helper"

pushabilitySheet = {}
moddedMovers = {}
moddedBombs = {}
moddedTrash = {}
cellsForIDManagement = {}
cellLabels = {}
cellWeights = {}
moddedDivergers = {}
local cellTypes = {}

function getCellType(id)
  return cellTypes[id] or "unknown"
end

function bindDivergerFunction(id, divergerFunction)
  if getCellType(id) ~= "diverger" then return end
  moddedDivergers[id] = divergerFunction
end

function setCell(x, y, id, rot, lastvars)
  local original = CopyCell(x, y)
  rot = rot or original.rot
  lastvars = lastvars or original.lastvars

  cells[y][x].ctype = id
  cells[y][x].rot = rot
  cells[y][x].lastvars = lastvars
  for _, mod in pairs(modcache) do
    if mod.onModSetCell ~= nil then
      mod.onModSetCell(id, x, y, rot, lastvars, original)
    end
  end
end

function addModdedWall(ctype)
  for i=1,#walls,1 do
    if walls[i] == ctype then
      return
    end
  end
  walls[#walls + 1] = ctype
end

function addCell(label, texture, push, ctype, invisible, index, weight)
  if label == "vanilla" or label == "unknown" then
    error("Invalid label for custom cell")
  end
  local cellID = #cellsForIDManagement+1
  tex[cellID] = love.graphics.newImage(texture)
  invisible = invisible or false
  if invisible == false then
    if not index then
      listorder[#listorder+1] = cellID
    elseif type(index) == "number" then
      table.insert(listorder, index, cellID)
    end
  end
  pushabilitySheet[cellID] = push
  cellLabels[cellID] = label
  cellsForIDManagement[#cellsForIDManagement+1] = cellID
  if weight ~= nil then
    cellWeights[cellID] = weight
  end
  ctype = ctype or "normal"
  if ctype == "mover" then
    moddedMovers[cellID] = true
  elseif ctype == "enemy" then
    moddedBombs[cellID] = true
  elseif ctype == "trash" then
    moddedTrash[cellID] = true
  elseif ctype == "diverger" then
    moddedDivergers[cellID] = function(x, y, rot) return rot end
  end
  cellTypes[cellID] = ctype
  texsize[cellID] = {}
  texsize[cellID].w = tex[cellID]:getWidth()
  texsize[cellID].h = tex[cellID]:getHeight()
  texsize[cellID].w2 = tex[cellID]:getWidth()/2
  texsize[cellID].h2 = tex[cellID]:getHeight()/2
  moddedIDs[#moddedIDs+1] = cellID
  return cellID
end

function canPushCell(cx, cy, px, py, pushing)
  if (not cx) or (not cy) then
    return false
  end
  if cx < 1 or cx > width-1 or cy < 1 or cy > height-1 then
    return false
  end
  local cdir = cells[cy][cx].rot
  local pdir = cells[py][px].rot
  local ctype = cells[cy][cx].ctype
  if pushabilitySheet[ctype] == nil then
    return false
  end
  return pushabilitySheet[ctype](cx, cy, cdir, px, py, pdir, pushing)
end