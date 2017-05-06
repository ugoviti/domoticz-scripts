-- Script per la lettura ed il salvataggio in una variabile globale della temperatura di un device
-- utile quando è necessario utilizzare questo valore all'interno di altri automatismi, tipo gli eventi a blockly, etc...
-- NB. questo script gira ogni minuto
commandArray = {}
 
-- arrotonda il valore ad un intero più vicino
function round(n) return math.floor((math.floor(n*2)+1)/2) end
 
-- Leggo la temperatura da questo device
local newTemp = round(tonumber(otherdevices_svalues['Esterno / Temperatura']))
 
-- Leggo la temperatura precedente da questa variabile globale
local oldTemp = tonumber(uservariables["temperatura_esterna"])
 
 
if (newTemp ~= oldTemp) then
  print ("Rilevata nuova temperatura esterna: " .. newTemp .. " gradi" )
  -- os.execute('scripts/izsynth -t "Rilevata nuova temperatura esterna di ' .. newTemp .. 'gradi. La vecchia temperatura era di' .. oldTemp .. 'gradi"')
  -- Imposto la temperatura su questa variabile
  commandArray['Variable:temperatura_esterna'] = tostring(newTemp)
--else
--  print ("Nuova Temperatura uguale alla vecchia: " .. newTemp .. " gradi" )
end
 
return commandArray
