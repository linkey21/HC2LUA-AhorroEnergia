--[[ ahorroEnergia
	Dispositivo virtual
	addButton.lua
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

-- escoger dispositivo seleccioando actualmete
local label = fibaro:get(_selfId,"ui.devicesLabel.value")
local p2 = string.find(label, '-')
local id = tonumber(string.sub(label, 1, p2 - 1))
local name = string.sub(label, p2 + 1, #label)
fibaro:debug(id..'-'..name)

-- invocar al botón para seleccionar el siguiente dispositivo
fibaro:call(_selfId, 'pressButton', '2')

-- recuperar dispositivo
local ahorroEnergia = getDevice(_selfId)

-- añadir dispositivo seleccionado
local powerSavingDev = {switchON = false, name = name, id = id, pwSafe = 0,
 NO = true}
table.insert(ahorroEnergia.powerSavingDevs, powerSavingDev)

-- guardar la tabla en la variable global
fibaro:setGlobal('dev'.._selfId, json.encode(ahorroEnergia))

-- actualizar etiqueta de dispositivos seleccionados
fibaro:call(_selfId, "setProperty", "ui.selectedDevices.value",
  powerSavingDev.id..'-'..powerSavingDev.name)
-- actualizar etiqueta de propiedades
fibaro:call(_selfId, "setProperty", "ui.optionsLabel.value",
 'pwS=0W  swT=NO  wUp=OFF ')
--  💡♻️
