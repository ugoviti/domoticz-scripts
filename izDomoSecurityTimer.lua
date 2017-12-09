-- izDomoSecurityTimer
-- A security system for Domoticz Home Automation System (http://www.domoticz.com)
-- author: Ugo Viti <ugo.viti@initzero.it>
-- version: 20171209

-- domoticz security devices (you must create these virtual hardware switches before saving izDomoSecurity LUA script)
local devAlarm = {
    Status       = 'Allarme / Stato',      -- Virtual Hardware Type: SELECTOR (0:Off, 10:ArmHome, 20:ArmAway)
    HolidaysMode = 'Modalità Vacanza',     -- Virtual Hardware Type: SWITCH
}

-- devAlarm['Status'] valid Levels:
-- Level  0: Disarm
-- Level 10: ArmHome
-- Level 20: ArmAway

-- save to a variable the current time and date
local hour = os.date('%H')
local min  = os.date('%M')
local day  = tonumber(os.date('%w')) -- 0:Sunday 1:Monday 2:Tuesday 3:Wednesday 4:Thursday 5:Friday 6:Saturday 
local now = (hour..':'..min)

commandArray = {}
-- EDIT the following conditions
if     (otherdevices[devAlarm['HolidaysMode']] == 'Off' ) and (day >= 0 and day <= 6 ) and (now == '00:00') then
        print("TIMER: Attivo Allarme in Casa")
        commandArray[devAlarm['Status']]='Set Level 10' -- ArmHome
        
elseif (otherdevices[devAlarm['HolidaysMode']] == 'Off' ) and (day >= 0 and day <= 6 ) and (now == '06:30') then
        print("TIMER: Disattivo Allarme")
        commandArray[devAlarm['Status']]='Set Level 0' -- Disarm
        
elseif (otherdevices[devAlarm['HolidaysMode']] == 'Off' ) and (day >= 1 and day <= 5 ) and (now == '10:30') then
        print("TIMER: Attivo Allarme Fuori Casa mediante")
        commandArray[devAlarm['Status']]='Set Level 20' -- ArmAway
end

return commandArray
