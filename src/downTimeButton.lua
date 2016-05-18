--[[ ahorroEnergia
	Dispositivo virtual
	downTimeButton.lua
	por Manuel Pascual
------------------------------------------------------------------------------]]

--[[----- CONFIGURACION DE USUARIO -------------------------------------------]]
interval = 15 -- min.
maxTime = 12 -- h.
--[[----- FIN CONFIGURACION DE USUARIO ---------------------------------------]]

--[[----- NO CAMBIAR EL CODIGO A PARTIR DE AQUI ------------------------------]]

--[[----- CONFIGURACION AVANZADA ---------------------------------------------]]
local _selfId = fibaro:getSelfId()  -- ID de este dispositivo virtual
--[[----- FIN CONFIGURACION AVANZADA -----------------------------------------]]

--[[inTable(tbl, item)
    (array) tbl:  tabla a comparar
    (table) item: tabla con el item a buscar, deve conterner un elemente "id"
  averiguar si un dispositivo forma parte de una tabla --]]
function inTable(tbl, item)
  if tbl ~= nil then
    for key, value in pairs(tbl) do
      if value.id == item.id then
        return true
      end
    end
  end
  return false
end

--[[isVariable(varName)
    (string) varName: nombre de la variable global
  comprueba si existe una variable global dada(varName) --]]
function isVariable(varName)
  -- comprobar si existe
  local valor, timestamp = fibaro:getGlobal(varName)
  if (valor and timestamp > 0) then return valor end
  return false
end

--[[getDevice(nodeId)
    (number) nodeId: número del dispositivo a recuperar de la variable global
  recupera el dispositivo virtual desde la variable global --]]
function getDevice(nodeId)
  -- si  existe la variable global recuperar dispositivo
  local device = isVariable('dev'..nodeId)
  if device and device ~= 'NaN' and device ~= 0 and device ~= '' then
    return json.decode(device)
  end
  -- en cualquier otro caso error
  return false
end

-- recuperar dispositivo
local ahorroEnergia = getDevice(_selfId)
local staleTimeoOut = ahorroEnergia.staleTimeoOut

--[[ disminuir el tiempo
if staleTimeoOut >= interval * 60 then
  -- disminuir intervalo
  staleTimeoOut = staleTimeoOut - interval * 60
else
  -- situar el tiempo máximo
  staleTimeoOut = maxTime * 60 * 60
end
--]]

-- aumentar el tiempo
if staleTimeoOut  < maxTime * 60 * 60 then
  -- aumentar el tiempo
  staleTimeoOut = staleTimeoOut + interval * 60
else
  -- situal ri tiempo mínimo
  staleTimeoOut = 0
end

-- guardar la tabla en la variable global
ahorroEnergia.staleTimeoOut = staleTimeoOut
fibaro:setGlobal('dev'.._selfId, json.encode(ahorroEnergia))

local formatTime = os.date("*t", os.time())
formatTime.hour = 0; formatTime.sec = 0; formatTime.min = 0
formatTime = os.time(formatTime)
formatTime = formatTime + staleTimeoOut
fibaro:debug(formatTime)
formatTime = os.date('%H:%M', formatTime)
-- actualizar etiqueta de propiedades
fibaro:call(_selfId, "setProperty", "ui.staleTimeoOutButton.value", formatTime)
