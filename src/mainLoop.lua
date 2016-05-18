--[[ ahorroEnergia
	Dispositivo virtual
	mainLoop.lua
	por Manuel Pascual
------------------------------------------------------------------------------]]

--[[----- CONFIGURACION DE USUARIO -------------------------------------------]]
local iconId = 12
--[[----- FIN CONFIGURACION DE USUARIO ---------------------------------------]]

--[[----- NO CAMBIAR EL CODIGO A PARTIR DE AQUI ------------------------------]]

--[[----- CONFIGURACION AVANZADA ---------------------------------------------]]
local _selfId = fibaro:getSelfId()  -- ID de este dispositivo virtual
--[[----- FIN CONFIGURACION AVANZADA -----------------------------------------]]

--[[isVariable(varName)
    (string) varName: nombre de la variable global
  comprueba si existe una variable global dada(varName) --]]
function isVariable(varName)
  -- comprobar si existe
  local valor, timestamp = fibaro:getGlobal(varName)
  if (valor and timestamp > 0) then return valor end
  return false
end

--[[resetDevice(nodeId)
    (number) nodeId: número del dispositivo a almacenar en la variable global
  crea una varaible global para almacenar la tabla que representa el dispositivo
  y lo inicializa. --]]
function resetDevice(nodeId)
  -- si no exite la variable global
  if not isVariable('dev'..nodeId) then
    -- intentar crear la variableGlobal
    local json = '{"name":"'..'dev'..nodeId..'", "isEnum":0}'
    if not HC2 then HC2 = Net.FHttp("127.0.0.1", 11111) end
    HC2:POST("/api/globalVariables", json)
    fibaro:sleep(1000)
    -- comprobar que se ha creado la variableGlobal
    if not isVariable('dev'..nodeId) then
      fibaro:debug('No se pudo declarar variable global dev'..nodeId)
      fibaro:abort()
    end
  end
  -- crear tabla vacía para dispositivos
  local staleTimeoOut = 0
  local powerSavingDevs = {}
  --powerSavingDevs[#powerSavingDevs + 1] = {switchON = false, name = "🔧",
  -- id = 0, selected = false, pwOffPre = 0, NO = true}
  local ahorroEnergia = {powerSavingDevs = powerSavingDevs,
   staleTimeoOut = staleTimeoOut}

  -- guardar la tabla en la variable global
  fibaro:setGlobal('dev'..nodeId, json.encode(ahorroEnergia))
  return ahorroEnergia
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
  -- en cualquier otro caso iniciarlo y devolverlo
  return resetDevice(nodeId)
end

-- recuperar dispositivo
local powerSavingDevs = getDevice(_selfId)
powerSavingDevs = powerSavingDevs.powerSavingDevs


while true do
  -- actualizar etiqueta id de dispositivo
  fibaro:call(_selfId,"setProperty","ui.idLabel.value", 'id: '.._selfId)
  -- actualizar icono
  fibaro:call(_selfId, 'setProperty', "currentIcon", iconId)
  -- watchdog
  fibaro:debug('ahorroEnergia OK')
  fibaro:sleep(1000)
end
