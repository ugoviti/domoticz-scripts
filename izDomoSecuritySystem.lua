-- izDomoSecurity System
-- A full featured Home Security System for Domoticz Home Automation System (http://www.domoticz.com)
-- author: Ugo Viti <ugo.viti@initzero.it>
-- version: 20170506

--[[
KEY FEATURES:
  * Full featured Home Security System like commercial ones
  * Born to be Easy and Fast for everyone (you can configure your full feature Home Security System within 5 minutes)
  * Arm Home (using only perimetral contact sensors to triggers alarms)
  * Arm Away (using perimetral and motion sensors to trigger alarms)
  * Support Siren devices when an security violation is confirmed
  * Countdown timer when Arming (so you can close the main door and exit the home before the Home Security System is Armed)
  * Countdown timer when entering home and the contact sensor get triggered, so you can Disarm the Home Security System before the Siren is turned On)
  * Various vocal messages using a speaker connected to Domoticz Box or an Tablet with ImperiHome and TTS engine API enables
    * Vocal messages when arming, disarming, security breach, etc...
    * Vocal messages confirming armed state after countdown
  * Multiple and concurrent TTS engine support (ex. ArmingHome go to izsynth, ArmingAway go to ImperiHome tablet)
  * Translation system for Notifications, Logs and Vocal messages (right now is supported English and Italian only... please make you translation and share with me)
  * Holidays Mode (used when you don't came back to home for some days and don't want activate auto arming timers)
  * Validation if all system device exists before using that script
  * Notify the user during arming countdown, if any of security sensor is already breached
  * You can switch between security statuses without waiting arming timer countdown is over

OPEN PROBLEMS:
  * commandArray['SecPanel'] doesn't work as release 3.7392 (20170501) because that, this script doesn't use domoticz Security status
  * globalvariables['Security'] get triggered instantly instead at end of countdown timer, so we must use a intermediate variable to detect states changes
  * 2 OpenURL inside the same "if" statment doesn't works
  * ImperiHome support Domoticz Selector Switches, but doesn't works if the names contais spaces, so we must create selector name values without spaces (IMPORTANT)
--]]

-- ########################################################################################################
-- ########################## USER VARIABLES AND CONFIGURATION
local language       = 'it' -- translate all logs, notifications and vocal messages to this language
local alarmCountdown = 30   -- alarm activation countdown timer (in seconds)
local sirenTime      = 3    -- siren on time (in minutes)

local domoticzURL    = 'http://localhost:8080/json.htm?' -- domoticz Json API URL
local imperiHomeURLs = {    -- imperihome tablets addresses (used for TTS voices) you can add other URLs to get the same vocal message to all tablets together
    'http://domotablet:8080/api/rest/speech/tts?',
}

-- phisical security sensors (rename the following devices according to your domoticz sensors names)
local devSensors = {
    'Soggiorno / Contatto Porta Entrata',
    'Soggiorno / Contatto Finestrone 1',
    'Soggiorno / Contatto Finestrone 2',
    'Cucina / Contatto Finestra',
    'Studio / Contatto Finestrone',
    'Bagno / Contatto Finestra',
    'Camera / Contatto Finestrone',
    'Cameretta / Contatto Finestrone',
    'Cucina / Movimento',
    'Bagno / Movimento',
    'Studio / Movimento',
    'Cameretta / Movimento',
    'Contatto Test',
}

-- exclude these device to check Open state when Arming (example: Open the main entrance door, activate the Arm Away selector and close the door exiting the house)
local devSensorsVerifyClosedExclude = {
    'Soggiorno / Contatto Porta Entrata',
    'Contatto Test',
}

-- domoticz security devices (you must create these virtual hardware switches before saving izDomoSecurity LUA script)
local devAlarm = {
    -- hardware security switches
    Siren        = 'Ripostiglio / Sirena', -- Phisical Siren hardware device
    -- virtual security swithces (create these devices from Domoticz Hardware Page as Dummy Devices)
    Status       = 'Allarme / Stato',      -- Virtual Hardware Type: SELECTOR (0:Off, 10:ArmHome, 20:ArmAway)
    Violated     = 'Allarme / Violato',    -- Virtual Hardware Type: SWITCH
    Confirmed    = 'Allarme / Confermato', -- Virtual Hardware Type: SWITCH
    HolidaysMode = 'Modalità Vacanza',     -- Virtual Hardware Type: SWITCH
}

-- this is used to match the Selector Name configured into Virtual Device devAlarm['Status'] (IMPORTANT: don't use spaces for selector values, otherwise ImperiHome doesn't works)
local devAlarmStatus = {
    Disarm  = 'Off',            -- Level: 0
    ArmHome = 'Perimetrale',    -- Level: 10
    ArmAway = 'Totale'          -- Level: 20
}

-- default text to speech engine based on context (valid options: imperihome, izsynth)
local tts = {
    Default = 'imperihome',
    Disarm  = 'imperihome',
    ArmHome = 'izsynth',
    ArmAway = 'imperihome'
}

-- EDIT: use this local function to manage devices activated after Disarming
function usrDisarm()
	commandArray['Soggiorno / Applic'] = 'On FOR 3'
	commandArray['Scene:Soggiorno / LED / Allarme Disattivato'] = 'On'
end

-- EDIT: use this local function to manage devices activated after Arming Home
function usrArmHome()
    commandArray['Scene:Soggiorno / LED / Allarme Attivazione'] = 'On'
end

-- EDIT: use this local function to manage devices activated after Arming Away
function usrArmAway()
	commandArray['Group:Gruppo / Luci Casa'] = 'Off' -- turn off all home lights
    commandArray['Scene:Soggiorno / LED / Allarme Attivazione'] = 'On'
	commandArray['SetSetPoint:'..otherdevices_idx['Termostato Casa']] = '16' -- change home temperature
end

-- EDIT: use this local function to manage devices activated after security Violation is detected
function usrViolated()
    -- EDIT: turn on the following devices
    commandArray['Scene:Soggiorno / LED / Allarme Intrusione'] = 'On'

    -- EDIT: actions based on sensor name
    if      (devName == 'Soggiorno / Contatto Porta Entrata') then
                commandArray['Cucina / Scatta Foto'] = 'On AFTER 5' -- take a photo after 5 seconds
    elseif  (devName == 'Cucina / Movimento') then
            commandArray['Cucina / Scatta Foto'] = 'On'
            commandArray['SendNotification'] = msgtr('ALARM_VIOLATED_NFY',devName)
    else
            -- send notification about sensor violated
            commandArray['SendNotification'] = msgtr('ALARM_VIOLATED_NFY',devName)
    end
end        
            

-- ########################## END CONFIGURATION
-- ########################################################################################################
-- ########################## SYSTEM FUNCTIONS (script internals, don't edit anything bellow)
-- domoticz callback array
commandArray = {}

-- program name used for logging porpouse
local progName= "izDomoSecurity"

-- enable to log commands
local logging = true

-- this variable is more fast than commandArray['Variable:varAlarmStatus'] otherwise the talk function doesn't works correctly
local varAlarmStatus = uservariables['varAlarmStatus']

-- save to a variable the current time and date
local time = os.date("*t")
local date = (time.day..'/'..time.month..'/'..time.year..'/'..' '..time.hour..':'..time.min..':'..time.sec)

-- script messages tranlastion (add your translations here)
function msgtr(text,devName)
	-- english language
    if      language == 'en' then
		-- devices status
        if      text == 'Open'    then return ('Open')
        elseif  text == 'Closed'  then return ('Closed')
        elseif  text == 'On'      then return ('On')
        elseif  text == 'Off'     then return ('Off')
		-- other messages
        elseif  text == 'ALARM_ARMING_ERROR'  then return ('WARNING: Open sensor detected: '..string.gsub(devName, "/ Contact ", " "))
        elseif  text == 'ALARM_ARMING_EXCLUDE'then return ('WARNING: Open sensor detected but excluded from the arming check: '..string.gsub(devName, "/ Contact ", " "))
        elseif  text == 'ALARM_ARMING_HOME'   then return ('Arming Home in '..alarmCountdown..' seconds')
        elseif  text == 'ALARM_ARMING_AWAY'   then return ('Arming Away in '..alarmCountdown..' seconds')
        elseif  text == 'ALARM_ARMED_HOME'    then return ('Armed Home correctly. With a total of '..#devSensors.. ' monitored sensors')
        elseif  text == 'ALARM_ARMED_AWAY'    then return ('Armed Away correctly. With a total of '..#devSensors.. ' monitored sensors')
        elseif  text == 'ALARM_ARMING_STOP'   then return ('Cancelling Arming stage')
        elseif  text == 'ALARM_DISARMING'     then return ('Security system deactivated')
		elseif  text == 'ALARM_RESTORED'      then return ('Security restored')
        elseif  text == 'ALARM_VIOLATED'      then return ('Security violation detected: ' .. string.gsub(devName, "/ Contact ", " ") .. '. Deactivate security system within '..alarmCountdown..' seconds')
		elseif  text == 'ALARM_CONFIRMED'     then return ('Confirmed intrusion. Activating Siren for '..sirenTime..' minutes')
        elseif  text == 'ALARM_VIOLATED_NFY'  then return ('[ALARM] Violated sensor: ' .. devName .. ', Status: ' .. msgtr(devicechanged[devName]))
		elseif  text == 'ALARM_CONFIRMED_NFY' then return ('[ALARM] Confirmed intrusion#Activating Siren for '..sirenTime..' minutes#0') -- via notification system
        end

	-- italian language
    elseif  language == 'it' then
		-- devices status
        if      text == 'Open'    then return ('Aperto')
        elseif  text == 'Closed'  then return ('Chiuso')
        elseif  text == 'On'      then return ('Acceso')
        elseif  text == 'Off'     then return ('Spento')
		-- other messages
        elseif  text == 'ALARM_ARMING_ERROR'  then return ('ATTENZIONE: Rilevato sensore aperto: '..string.gsub(devName, "/ Contatto ", " "))
        elseif  text == 'ALARM_ARMING_EXCLUDE'then return ('ATTENZIONE: Rilevato sensore aperto ma escluso dal check: '..string.gsub(devName, "/ Contatto ", " "))
        elseif  text == 'ALARM_ARMING_HOME'   then return ('Attivazione allarme perimetrale in '..alarmCountdown..' secondi')
        elseif  text == 'ALARM_ARMING_AWAY'   then return ('Attivazione allarme totale in '..alarmCountdown..' secondi')
        elseif  text == 'ALARM_ARMED_HOME'    then return ('Allarme perimetrale, attivato correttamente. Con un totale di '..#devSensors.. ' sensori monitorati')
        elseif  text == 'ALARM_ARMED_AWAY'    then return ('Allarme totale, attivato correttamente. Con un totale di '..#devSensors.. ' sensori monitorati')
        elseif  text == 'ALARM_ARMING_STOP'   then return ('Annullamento attivazione allarme')
        elseif  text == 'ALARM_DISARMING'     then return ('Allarme disattivato')
		elseif  text == 'ALARM_RESTORED'      then return ('Sicurezza Ripristinata')
        elseif  text == 'ALARM_VIOLATED'      then return ('Sicurezza Violata: ' .. string.gsub(devName, "/ Contatto ", " ") .. '. Disattivare allarme entro '..alarmCountdown..' secondi')
		elseif  text == 'ALARM_CONFIRMED'     then return ('Intrusione confermata. Attivazione sirena per '..sirenTime..' minuti')
        elseif  text == 'ALARM_VIOLATED_NFY'  then return ('[ALLARME] Sensore Violato: ' .. devName .. ', Stato: ' .. msgtr(devicechanged[devName]))
		elseif  text == 'ALARM_CONFIRMED_NFY' then return ('[ALLARME] Intrusione Confermata#Attivazione sirena per '..sirenTime..' minuti#0') -- via notification system
        end

    -- failback if no text to translate get identified
    else
        return text
    end
end

-- izDomoSecurity logger function
function log(log) 
    print ("[" .. progName .. "] " .. log)
end

-- encode url before passing to OpenURL functions
function url_encode(str)
  if (str) then
    str = string.gsub (str, "\n", "\r\n")
    str = string.gsub (str, "([^%w %-%_%.%~])",
    function (c) return string.format ("%%%02X", string.byte(c)) end)
    str = string.gsub (str, " ", "+")
  end
  return str
end

-- imperihome tablet talk via integrated TTS API
function tts.imperihome(text)
    for id, tablet in pairs(imperiHomeURLs) do
        commandArray['OpenURL'] = tablet..'text='..url_encode(text)
    end
end

-- direct sound card domoticz talk via izsynth script (https://www.domoticz.com/wiki/IzSynth)
function tts.izsynth(text)
    os.execute('scripts/izsynth -t "'..text..'"')
end

-- syntesize text using the specified TTS engine based of alarm context
function talk(text)
    if (tts['Default'] == nil ) then -- default failback synth engine
        log('Talking - context: Failbak - engine: izsynth - text: '..text)
        tts.izsynth(text)
    elseif (varAlarmStatus == 'Armed Home' or varAlarmStatus == 'Arming Home') then
        log('Talking - context: ArmHome - engine: '..tts['ArmHome']..' - text: '..text)
        tts[tts['ArmHome']](text)
    elseif (varAlarmStatus == 'Armed Away' or varAlarmStatus == 'Arming Away') then
        log('Talking - context: ArmAway - engine: '..tts['ArmAway']..' - text: '..text)
        tts[tts['ArmAway']](text)
    elseif (varAlarmStatus == 'Disarmed'   or varAlarmStatus == 'Disarming')   then
        log('Talking - context: Disarm - engine: '..tts['Disarm']..' - text: '..text)
        tts[tts['Disarm']](text)
    else
        log('Talking - context: Default - engine: '..tts['Default']..' - text: '..text)
        tts[tts['Default']](text)
    end
end

-- function used to verify if a value is contained into an array
local function containsVal(table, val)
   for i=1,#table do
      if table[i] == val then 
         return true
      end
   end
   return false
end

-- function to verify if any contact device is in an Open Status
function verifyDeviceClosed(devIncluded,devExcluded)
    
    for id, devName in pairs(devIncluded) do
        if (otherdevices[devName] == 'Open') then
            if containsVal(devExcluded,devName) then
                log(msgtr('ALARM_ARMING_EXCLUDE',devName))
            else
                log(msgtr('ALARM_ARMING_ERROR',devName))
                talk(msgtr('ALARM_ARMING_ERROR',devName))
                return false -- stop the for loop to don't generate too many messages if other sensors are opened    
            end
        end
    end
    return true
end

-- function to verify if all Security Virtual Devices exist in the system
function verifyDeviceExist(array,type)
 for id, devName in pairs(array) do
    --log('PRE devName: '..devName)
    if (otherdevices[devName] == nil) then 
        log('WARNING: The '..type..' device \''..devName..'\' doesn\'t exist. Please create it as Dummy Device from Hardware configuration and retry. exiting...')
        return
    end
 end
end

-- function to create a domoticz variable
function createVar(var,val)
	log("Creating variable: '" .. var .. "' with value: '" .. val .. "'");
	commandArray['OpenURL'] = domoticzURL..'type=command&param=saveuservariable&vname='..url_encode(var)..'&vtype=2&vvalue='..val
end

-- create domoticz variables if missing
if     (uservariables['varAlarmStatus'] == nil) then createVar("varAlarmStatus","Disarmed")
elseif (uservariables['varAlarmAction'] == nil) then createVar("varAlarmAction","Disarmed") -- this needed because we need a variable to use with AFTER clause
end

-- verify if virtual devices and the configured sensors exist, else exit from the script
verifyDeviceExist (devAlarm,'Virtual')
verifyDeviceExist (devSensors,'Sensor')


-- debug and tests go here
-- log('Debug Message')
-- log('devAlarmStatus = ' .. otherdevices[devAlarm['Status']])

--n=0 ; for i, v in pairs( devSensors ) do
--  n = n + 1
--end
-- log('totsens: '..#devSensors)


-- ########################################################################################################
-- ########################## ARMING / DISARMING
-- disarm during Arming State
if (devicechanged[devAlarm['Status']] == devAlarmStatus['Disarm'] and (uservariables["varAlarmStatus"] == "Arming Home" or uservariables["varAlarmStatus"] == "Arming Away")) then
    log(msgtr('ALARM_ARMING_STOP'))
	talk(msgtr('ALARM_ARMING_STOP'))
    varAlarmStatus = 'Disarmed' -- put after talking, if you want use the same tts engine used for arming
	commandArray['Variable:varAlarmStatus'] = varAlarmStatus
	commandArray['Variable:varAlarmAction'] = 'Standby AFTER '..alarmCountdown
	commandArray[devAlarm['Violated']] = 'Off'
	commandArray[devAlarm['Confirmed']] = 'Off'
	commandArray[devAlarm['Siren']] = 'Off'
	--commandArray['Security Panel'] = 'Disarm'

-- disarm from Armed State
elseif (devicechanged[devAlarm['Status']] == devAlarmStatus['Disarm']) then
    log(msgtr('ALARM_DISARMING'))
    talk(msgtr('ALARM_DISARMING'))
    varAlarmStatus = 'Disarmed' -- put after talking, if you want use the same tts engine used for arming
    commandArray['Variable:varAlarmStatus'] = varAlarmStatus
    commandArray['Variable:varAlarmAction'] = 'Standby'
	commandArray[devAlarm['Violated']] = 'Off'
	commandArray[devAlarm['Confirmed']] = 'Off'
	commandArray[devAlarm['Siren']] = 'Off'
	--commandArray['Security Panel'] = 'Disarm'
    usrDisarm()

-- arm home (ex. when activated by timer)
elseif (devicechanged[devAlarm['Status']] == devAlarmStatus['ArmHome']) then
	varAlarmStatus = 'Arming Home' -- before talking is important to use the right tts engine
    log(msgtr('ALARM_ARMING_HOME'))
	if verifyDeviceClosed(devSensors,devSensorsVerifyClosedExclude) then talk(msgtr('ALARM_ARMING_HOME')) end
	commandArray['Variable:varAlarmStatus'] = varAlarmStatus
	commandArray['Variable:varAlarmAction'] = 'Armed Home AFTER '..alarmCountdown
	commandArray[devAlarm['Violated']] = 'Off'
	commandArray[devAlarm['Confirmed']] = 'Off'
	--commandArray['Security Panel'] = 'Arm Home'
    usrArmHome()

-- arm away (ex. when activated manually)	
elseif (devicechanged[devAlarm['Status']] == devAlarmStatus['ArmAway']) then
	local varAlarmStatus = 'Arming Away' -- before talking is important to use the right tts engine
    log(msgtr('ALARM_ARMING_AWAY'))
    if verifyDeviceClosed(devSensors,devSensorsVerifyClosedExclude) then talk(msgtr('ALARM_ARMING_AWAY')) end
	commandArray['Variable:varAlarmStatus'] = varAlarmStatus
	commandArray['Variable:varAlarmAction'] = 'Armed Away AFTER '..alarmCountdown
	commandArray[devAlarm['Violated']] = 'Off'
	commandArray[devAlarm['Confirmed']] = 'Off'
	--commandArray['Security Panel'] = 'Arm Away'
    usrArmAway()
end

-- ########################## ARMED / DISARMED CONFIRMATION
if (otherdevices[devAlarm['Status']] == devAlarmStatus['ArmHome'] and uservariables['varAlarmAction'] == 'Armed Home') then
    log('Attivato Allarme: Armed Home')
    commandArray['Variable:varAlarmStatus'] = 'Armed Home'
    commandArray['Variable:varAlarmAction'] = 'Standby'
    talk(msgtr('ALARM_ARMED_HOME'))

elseif (otherdevices[devAlarm['Status']] == devAlarmStatus['ArmAway'] and uservariables['varAlarmAction'] == 'Armed Away') then
    log('Attivato Allarme: Armed Away')
    commandArray['Variable:varAlarmStatus'] = 'Armed Away'
    commandArray['Variable:varAlarmAction'] = 'Standby'
    talk(msgtr('ALARM_ARMED_AWAY'))
end


-- ########################## ALARM VIOLATION DETECTION
--if (globalvariables["Security"] ~= "Disarmed" and (uservariables["varAlarmStatus"] ~= "Arming Home" or uservariables["varAlarmStatus"] ~= "Arming Away")) then
if (uservariables["varAlarmStatus"] == "Armed Home" or uservariables["varAlarmStatus"] == "Armed Away") then    
    for id, devName in pairs(devSensors) do
        if ((devicechanged[devName] == 'Open' and uservariables["varAlarmStatus"] ~= "Disarmed") -- violation when armed home (trigger only contact sensors)
            or 
            (devicechanged[devName] == 'On' and uservariables["varAlarmStatus"] == "Armed Away")) -- violation when armed away (trigger motion sensors too)
        then
            if (logging) then print (msgtr('ALARM_VIOLATED_NFY',devName)) end
            commandArray['Variable:varAlarmAction'] = 'Violated'
            commandArray[devAlarm['Violated']] = 'On'

            -- talk about security violation
			talk(msgtr('ALARM_VIOLATED',devName))
            
            -- run user custom action when security violation occour
            usrViolated()
        elseif (devicechanged[devName] ~= nil) then
            if (logging) then print (msgtr('ALARM_VIOLATED_NFY',devName)) end
--          commandArray['SendNotification'] = msgtr('ALARM_VIOLATED',devName)
--          commandArray[devAlarm['Violated']] = 'Off'
--          talk(msgtr('ALARM_RESTORED'))
        end
    end

 -- ########################## ALARM CONFIRMATION AND SIREN ACTIVATION
 -- log('Debug Message')

 if     (devicechanged[devAlarm['Violated']] == 'On' and uservariables["varAlarmAction"] == "Violated") then
	commandArray['Variable:varAlarmAction'] = 'Confirmed AFTER '..alarmCountdown-1 -- if the variable get valorized after device activation the siren doens't turn on
	commandArray[devAlarm['Confirmed']] = 'On AFTER '..alarmCountdown -- this needed to permit disabling siren countdown during warm up timer
 elseif (devicechanged[devAlarm['Confirmed']] == 'Off' and uservariables["varAlarmAction"] == "Confirmed") then -- get triggered when want disarm during violation time
    commandArray['Variable:varAlarmAction'] = 'Standby' -- reset varAlarmAction to Standby
 elseif (devicechanged[devAlarm['Confirmed']] == 'On' and uservariables["varAlarmAction"] == "Confirmed") then
	commandArray['Variable:varAlarmAction'] = 'Siren'
	talk(msgtr('ALARM_CONFIRMED'))
	commandArray[devAlarm['Siren']] = 'On FOR '..sirenTime
 elseif (devicechanged[devAlarm['Siren']] == 'On' and uservariables["varAlarmAction"] == "Siren") then
    commandArray['Variable:varAlarmAction'] = 'Siren for '..sirenTime..' minutes'
	commandArray['SendNotification'] = msgtr('ALARM_CONFIRMED_NFY')
	-- reset security virtual devices
	commandArray[devAlarm['Violated']] = 'Off'
    commandArray[devAlarm['Confirmed']] = 'Off'
 end
end

return commandArray

