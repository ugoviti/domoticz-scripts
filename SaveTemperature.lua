-- Script per la lettura ed il salvataggio in una variabile globale della temperatura di un device
-- utile quando è necessario utilizzare questo valore all'interno di altri automatismi, tipo gli eventi a blockly, etc...
-- NB. questo script gira ogni minuto
commandArray = {}

local domoticzURL    = 'http://localhost:8080' -- domoticz Json API URL

-- Read the temperature from this device
devSensorTemp = 'Esterno / Temperatura'

-- round the temperature value to the nearest integer
function round(n) return math.floor((math.floor(n*2)+1)/2) end

-- Read the temperature
local newTemp = round(tonumber(otherdevices_svalues[devSensorTemp]))
--local newTemp = round(tonumber('-9.2'))

-- Read the previuous temeperature from this domoticz variable
local oldTemp = tonumber(uservariables["temperatura_esterna"])

-- Calc the difference time from device updates
 function timedifference(s)
   year = string.sub(s, 1, 4)
   month = string.sub(s, 6, 7)
   day = string.sub(s, 9, 10)
   hour = string.sub(s, 12, 13)
   minutes = string.sub(s, 15, 16)
   seconds = string.sub(s, 18, 19)
   t1 = os.time()
   t2 = os.time{year=year, month=month, day=day, hour=hour, min=minutes, sec=seconds}
   difference = os.difftime (t1, t2)
   return difference
 end

--print ("updated: " .. otherdevices_lastupdate[devSensorTemp].. " difference time: " .. timedifference(otherdevices_lastupdate[devSensorTemp]))

if (timedifference(otherdevices_lastupdate[devSensorTemp]) > 300) then
    -- commandArray['SendNotification'] = 'ATTENZIONE: Il sensore di temperatura: ' .. devSensorTemp .. ' non invia aggiornamenti dalla data: ' .. otherdevices_lastupdate[devSensorTemp]
    commandArray['Variable:temperatura_esterna_tts'] = 'ATTENZIONE: la temperatura esterna non è aggiornata da ' .. difference .. ' secondi'
    commandArray['Variable:temperatura_esterna'] = '0'
elseif (newTemp ~= oldTemp) then
    print ("Rilevata modifica temperatura esterna. Vecchia: " .. oldTemp .. " gradi. Nuova: " .. newTemp .. " gradi. Ultimo aggiornamento ricevuto dal device: " .. otherdevices_lastupdate[devSensorTemp])
    -- os.execute('scripts/izsynth -t "Rilevata nuova temperatura esterna di ' .. newTemp .. 'gradi. La vecchia temperatura era di' .. oldTemp .. 'gradi"')
    -- Imposto la temperatura su questa variabile
    commandArray['Variable:temperatura_esterna'] = tostring(newTemp)
    commandArray['Variable:temperatura_esterna_tts'] = 'La temperatura esterna è di ' .. newTemp .. ' gradi'
    -- Send Kodi Notification
    commandArray['SendNotification'] = 'Temperatura Esterna: '..newTemp..'°#Attuale: '..newTemp..'°\nPrecedente: '..oldTemp..'°#0###kodi'
    --else
    --  print ("Nuova Temperatura uguale alla vecchia: " .. newTemp .. " gradi" )
end

return commandArray
