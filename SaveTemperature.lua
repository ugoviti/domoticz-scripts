-- Script per la lettura ed il salvataggio in una variabile globale della temperatura di un device
-- utile quando è necessario utilizzare questo valore all'interno di altri automatismi, tipo gli eventi a blockly, etc...
-- NB. questo script gira ogni minuto
commandArray = {}

-- Read the temperature from this device
devSesorTemp = 'Esterno / Temperatura'

-- round the temperature value to the nearest integer
function round(n) return math.floor((math.floor(n*2)+1)/2) end

-- Read the temperature
local newTemp = round(tonumber(otherdevices_svalues[devSesorTemp]))

-- Read the previuous temeperature from this domoticz variable
local oldTemp = tonumber(uservariables["temperatura_esterna"])

-- Calc then difference time from device updates
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

--print ("updated: " .. otherdevices_lastupdate[devSesorTemp].. " difference time: " .. timedifference(otherdevices_lastupdate[devSesorTemp]))

if (timedifference(otherdevices_lastupdate[devSesorTemp]) > 300) then
    commandArray['SendNotification'] = 'ATTENZIONE: Il sensore di temperatura: ' .. devSesorTemp .. ' non invia aggiornamenti dalla data: ' .. otherdevices_lastupdate[devSesorTemp]
elseif (newTemp ~= oldTemp) then
    print ("Rilevata nuova temperatura esterna: " .. newTemp .. " gradi. Data ultimo aggiornamento ricevuto dal device: " .. otherdevices_lastupdate[devSesorTemp])
    -- os.execute('scripts/izsynth -t "Rilevata nuova temperatura esterna di ' .. newTemp .. 'gradi. La vecchia temperatura era di' .. oldTemp .. 'gradi"')
    -- Imposto la temperatura su questa variabile
    commandArray['Variable:temperatura_esterna'] = tostring(newTemp)
    --else
    --  print ("Nuova Temperatura uguale alla vecchia: " .. newTemp .. " gradi" )
end

return commandArray

