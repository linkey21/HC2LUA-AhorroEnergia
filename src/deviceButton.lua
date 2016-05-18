--[[ ahorroEnergia
	Dispositivo virtual
	deviceButton.lua
	por Manuel Pascual
------------------------------------------------------------------------------]]

--[[----- CONFIGURACION DE USUARIO -------------------------------------------]]
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
local powerSavingDevs = getDevice(_selfId)
powerSavingDevs = powerSavingDevs.powerSavingDevs

-- obtener conexión con el controlador
if not HC2 then
  HC2 = Net.FHttp("127.0.0.1", 11111)
end

-- obtener sensores interruptores
response ,status, errorCode = HC2:GET("/api/devices?roomID="..
 fibaro:getRoomID(_selfId))
local devices = json.decode(response)
local binarySwitches = {}
for key, value in pairs(devices) do
  for actionsKey, actionsValue in pairs(value['actions']) do
    if actionsKey == 'turnOn' and not inTable(powerSavingDevs, value) then
      local binarySwitch = {id = value.id, name = value.name}
      table.insert(binarySwitches, binarySwitch)
      break
    end
  end
end

-- averiguar dispositivo seleccioando actualmete
local selectedId = 1
local label = fibaro:get(_selfId,"ui.devicesLabel.value")
for key, value in pairs(binarySwitches) do
  if value.id..'-'..value.name == label then selectedId = key end
end
-- seleccionar el siguiente dispositivo
if selectedId < #binarySwitches then
  selectedId = selectedId + 1
elseif #binarySwitches == 0 then
  selectedId = 0
else
  selectedId = 1
end

-- anotar las etiquetas
if selectedId ~= 0 then
  fibaro:call(_selfId,"setProperty","ui.devicesLabel.value",
  binarySwitches[selectedId].id..'-'..binarySwitches[selectedId].name)
else
  fibaro:call(_selfId,"setProperty","ui.devicesLabel.value", '-')
end

--  💡♻️
