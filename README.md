# Domoticz Personal Scripts
Domoticz (Home Automation System) personal Bash/LUA scripts <br/>
Author: Ugo Viti <ugo.viti@initzero.it>

## Description
This is my personal collection of self made scripts and customization for Domoticz (Open Source Home Automation System) http://www.domoticz.com

## Scripts

### izDomoSecuritySystem.lua

#### Description
A full featured Home Security System for Domoticz Home Automation System (http://www.domoticz.com)

#### Features
  * Full featured Home Security System like commercial ones
  * Born to be Easy and Fast for everyone (you can configure your full feature Home Security System within 5 minutes)
  * Arm Home (using only perimetral contact sensors to triggers alarms)
  * Arm Away (using perimetral and motion sensors to trigger alarms)
  * Support Siren devices when a security violation is confirmed
  * Countdown timer when Arming (so you can close the main door and exit the home before the Home Security System is Armed)
  * Countdown timer when entering home and the contact sensor get triggered (so you can Disarm the Home Security System before the Siren is turned On)
  * Different actions when ArmHome or ArmAway. example: Turn off all house lights only when ArmAway
  * Various vocal messages using a speakers connected to Domoticz Box or an Tablet with ImperiHome and TTS engine API enabled
    * Vocal messages when arming, disarming, security breach, siren confirmation, etc...
    * Vocal messages confirming armed state after countdown
  * Multiple and concurrent TTS engine support (ex. ArmingHome go to izsynth, ArmingAway go to ImperiHome tablet)
  * Translation System for Notifications, Logs and Vocal messages (right now is supported English and Italian languages only... please make your translation and share with me)
  * Holidays Mode (used when you don't came back to home for some days and don't want activate auto arming timers)
  * Validation if all system devices exists before using that script (so you can't make mistakes defining sensors names)
  * Notify the user during arming countdown if any of security sensor is already breached (you can exclude some devices from this check)
  * You can switch between security statuses without waiting arming timer countdown is over

#### Requirements
  * Domoticz (of course ;))
  * Some Contact Sensors (I use a mix of Xiaomi MiHome devices and ZWave Sensors)
  * Some Motion Sensors (I use a mix of Xiaomi MiHome devices and ZWave Sensors)
  * One or more Sirens (I use ZWave Siren of AeonLab)
  * Suggested: an Android Tablet with ImperiHome Professional (and the TTS engine enabled for voice annuncements)
  * Otherwise izsynth installed (http://www.domoticz.com/wiki/IzSynth) and a Sound Speaker connected to the (Domoticz Box) RaspberryPi 2,5 Audio Jack

#### Installation
  * Open your Domoticz Home Page URL address
  * From Domoticz Home Page go into: **Setup --> Hardware** tab
    * Create the followings new **Dummy** Hardware devices (if Dummy Hardware is not configured add it before continue):
    * Click **Create Virtual Sensors** and insert:
      * Name: **Alarm / Status**
      * Sensor Type: **Selector**
    * Click **Create Virtual Sensors** and insert:
      * Name: **Alarm / Violated**
      * Sensor Type: **Switch**
    * Click **Create Virtual Sensors** and insert:
      * Name: **Alarm / Confirmed**
      * Sensor Type: **Switch**
    * Click **Create Virtual Sensors** and insert:
      * Name: **Holidays Mode**
      * Sensor Type: **Switch**
    * Go into **Switches** tab and EDIT the **Alarm / Status** selector switch:
      * Selector Level 0: **Off**
      * Selector Level 10: **ArmHome**
      * Selector Level 20: **ArmAway**
  * If you like, I suggest to customize the switches icons
  * From Domoticz Home Page go into: **Setup --> More Options --> Events** tab
    * Create the following LUA script:
      * Event name: **izDomoSecuritySystem**
      * Method: **LUA**
      * Type: **Device**
    * Copy&Paste the **izDomoSecuritySystem.lua** code
  * Now the most important part: customize the examples and localized variables and your sensors devices (in the example you'll find italian strings)
    * NB. I suggest to rename your sensors devices using the following naming convention (important is to differentiate **Contact** and **Motion** sensors using a standard naming):
      * Kitchen / Motion
      * Kitchen / Contact Window
      * Livin Room / Motion
      * Livin Room / Contact Main Door
      * Livin Room / Contact Window 1
      * Livin Room / Contact Window 2
      * Bathroom / Motion
      * Bathroom / Contact Window
      * so on...
  * When done, save the edited file and go into **Setup --> Log** tab and look for errors
  * Try to **Disarm / Arm Home / Arm Away** the Home Security System clicking in the variuos states of **Alarm / Status** switch

#### ImperiHome Configuration
  * From Layout editor, create a new Switch selecting the "Alarm / Status" switch... this will be configured as "Selector" switch, with the 3 Labels you used when configured Level 0, Level 10 and Level 20

#### Open Problems
  * commandArray['SecPanel'] doesn't work as release 3.7392 (20170501) because that, this script doesn't use domoticz Security status
  * globalvariables['Security'] get triggered instantly instead at end of countdown timer, so we must use a intermediate variable to detect states changes
  * 2 OpenURL inside the same "if" statment doesn't works
  * ImperiHome support Domoticz Selector Switches, but doesn't works if the names contais spaces, so we must create selector name values without spaces (IMPORTANT)

### izDomoSecurityTimer.lua

#### Description
Timer script for auto activating izDomoSecuritySystem on given day/time   

#### Features
  * Holidays mode (when activated this virtual switch, the Auto timer get disabled)
