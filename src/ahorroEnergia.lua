--[[
%% properties
86 value

%% globals
--]]

--[[ ahorroEnergia
	Escena
	ahoroEnergia.lua
	por Manuel Pascual
------------------------------------------------------------------------------]]

--[[----- CONFIGURACION DE USUARIO -------------------------------------------]]
idAhorroEnergia = 254
--[[----- FIN CONFIGURACION DE USUARIO ---------------------------------------]]

--[[----- NO CAMBIAR EL CODIGO A PARTIR DE AQUI ------------------------------]]

--[[----- CONFIGURACION AVANZADA ---------------------------------------------]]
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

--[[actuateDevices(devices, action)
  (table) devices:  tabla con los dispositivos
  (string)  action: nombre de la funcion a aplicar
  --]]
function actuateDevices(devices, action)
  -- comprobar que la acción es correcta
  if action ~= 'turnOn' and action ~= 'turnOff' then return false end
  -- recorrer dispositivos
  for key, value in pairs(devices) do
    -- si la accion es encende
    if action == 'turnOn' then
      -- comprobar si está marcado para encender y su caso encender
      if value.switchON then
        -- comprobar tipo, si es es NormallyClose cambiar la acción
        local myAction = action
        if not value.NO then myAction = 'turnOff' end
        -- encender el dispositivo
        fibaro:call(value.id, myAction)
        fibaro:debug('Encendido '..value.id..'-'..value.name)
      end
    else
      -- comprobar la protección de apagado por consumo mínimo
      local power = tonumber(fibaro:getValue(value.id, 'power'))
      if not power then power = 0 end
      if power <= value.pwSafe or value.pwSafe == 0 then
        -- comprobar tipo, si es es NormallyClose cambiar la acción
        local myAction = action
        if not value.NO then myAction = 'turnOn' end
        -- apagar el dispositivo
        fibaro:call(value.id, myAction)
        fibaro:debug('Apagado '..value.id..'-'..value.name)
      end
    end
  end
end

local sourceTrigger = fibaro:getSourceTrigger()

-- solo si la escena se inicia por cambio de estado del detector de presencia
if sourceTrigger.type == 'property' then
  -- detectar el estado
  local value = fibaro:getValue(sourceTrigger.deviceID,
   sourceTrigger.propertyName)

   -- recuperar dispositivo
   local ahorroEnergia = getDevice(idAhorroEnergia)
   local powerSavingDevs = ahorroEnergia.powerSavingDevs
   local staleTimeoOut = ahorroEnergia.staleTimeoOut

  -- esperar por otra instancia
  fibaro:sleep(1000)

  -- si el estado ha cambia a detección encender los dispositivos
  if value == '1' then
    fibaro:debug('Se ha detectado presencia')
    actuateDevices(powerSavingDevs, 'turnOn')
  else
    fibaro:debug('Se ha dejado de detectar presencia')
    -- esperar mientras pasa el tiempo de reinicio
    local setPoint = os.time() + staleTimeoOut
    while os.time() <= setPoint do
      -- comprobar si se ha iniciado otra instancia para detener la actual
      if fibaro:countScenes() > 1 then
        setPoint = os.time() + staleTimeoOut
        fibaro:abort()
      end
      -- watchdog
      fibaro:debug('ahorroEnergia esperando '..setPoint - os.time()..'s')
      -- esperar
      fibaro:sleep(1000)
    end
    -- pasado el tiempo apagar los dispositivos marcados
    actuateDevices(powerSavingDevs, 'turnOff')
  end
end
