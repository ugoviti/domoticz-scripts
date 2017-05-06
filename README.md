# Domoticz Personal Scripts
Domoticz (Home Automation System) personal Bash/LUA scripts

## Description
This is my personal collection of self made scripts and customization for Domoticz (Open Source Home Automation System) http://www.domoticz.com

## Scripts

### izDomoSecuritySystem.lua

#### Description
A complete security system for Domoticz Home Automation System (http://www.domoticz.com)

#### Features
  * Standalone Home Security System like commercial ones
  * Born to be Easy and Fast for everyone (you can configure your full feature Home Security System within 5 minutes)
  * Arm Away (using only perimetral contact sensors to triggers alarms)
  * Arm Home (using perimetral and motion sensors to trigger alarms)
  * Support Siren devices when an security violation is confirmed
  * Countdown timer when Arming (so you can close the main door and exit the home before the Home Security System is Armed)
  * Countdown timer when entering home and the contact sensor get triggered, so you can Disarm the Home Security System before the Siren is turned On)
  * Various vocal messages using a speaker connected to Domoticz Box or an Tablet with ImperiHome and TTS engine API enables
    * Vocal messages when arming, disarming, security breach, siren confirmation, etc...
    * Vocal messages confirming armed state after countdown
  * Multiple and concurrent TTS engine support (ex. ArmingHome go to izsynth, ArmingAway go to ImperiHome tablet)
  * Translation system for Notifications, Logs and Vocal messages (right now is supported English and Italian only... please make you translation and share with me)
  * Holidays Mode (used when you don't came back to home for some days and don't want activate auto arming timers)
  * Validation if all system device exists before using that script
  * Notify the user during arming countdown, if any of security sensor is already breached
  * You can switch between security statuses without waiting arming timer countdown is over

### izDomoSecurityTimer.lua

#### Description
Timer script for auto activating izDomoSecuritySystem on given day/time   

#### Features
  * Holidays mode (when activated this a virtual switch, the Auto timer get disabled)
