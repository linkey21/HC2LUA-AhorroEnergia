--[[ ahorroEnergia
	Dispositivo virtual
	selecDevButton.lua
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

-- averiguar dispositivo seleccioando actualmete
local selectedId = 1
local label = fibaro:get(_selfId,"ui.selectedDevices.value")
for key, value in pairs(powerSavingDevs) do
  if value.id..'-'..value.name == label then selectedId = key end
end
-- seleccionar el siguiente dispositivo
if selectedId < #powerSavingDevs then
  selectedId = selectedId + 1
elseif #powerSavingDevs == 0 then
  selectedId = 0
else
  selectedId = 1
end

-- anotar las etiquetas
if selectedId ~= 0 then
  fibaro:call(_selfId,"setProperty","ui.selectedDevices.value",
  powerSavingDevs[selectedId].id..'-'..powerSavingDevs[selectedId].name)
  local type = 'NC'
  if powerSavingDevs[selectedId].NO then type = 'NO' end
  local switchON = 'OFF'
  if powerSavingDevs[selectedId].switchON then switchON = 'ON' end
  fibaro:call(_selfId, "setProperty", "ui.optionsLabel.value",
   'pwS='..powerSavingDevs[selectedId].pwSafe..'W  swT='..
   type..'  wUp='..switchON)
else
  fibaro:call(_selfId,"setProperty","ui.selectedDevices.value", '-')
  fibaro:call(_selfId, "setProperty", "ui.optionsLabel.value",
   'pwS=  swT=  wUp= ')
end

--  💡♻️
