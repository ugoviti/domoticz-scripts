# Domoticz Personal Scripts
Domoticz (Home Automation System) personal Bash/LUA scripts <br/>
Author: Ugo Viti <ugo.viti@initzero.it>

## Description
This is my personal collection of self made scripts and customization for Domoticz (Open Source Home Automation System) http://www.domoticz.com

## Scripts

### izDomoSecuritySystem.lua

#### Description
A complete security system for Domoticz Home Automation System (http://www.domoticz.com)

#### Features
  * Standalone Home Security System like commercial ones
  * Born to be Easy and Fast for everyone (you can configure your full feature Home Security System within 5 minutes)
  * Arm Home (using only perimetral contact sensors to triggers alarms)
  * Arm Away (using perimetral and motion sensors to trigger alarms)
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

#### Requirements
  * Domoticz (of course ;))
  * Some Contact Sensors (I use a mix of Xiaomi MiHome devices and ZWave Sensors)
  * Some Motion Sensors
  * One or more Sirens (I use ZWave Siren)
  * Suggested: an Android Tablet with ImperiHome Professional (and the TTS engine enabled for voice annuncements)
  * Otherwise izsynth installed (http://www.domoticz.com/wiki/IzSynth) and a Sound Speaker connected to the RaspberryPi domoticz 2,5 Audio Jack

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
  * NB. I suggest to rename your sensors devices using the following naming convention:
    * Kitchen / Motion
    * Kitchen / Contact Window
    * Livin Room / Motion
    * Livin Room / Contact Main Door
    * Livin Room / Contact Window 1
    * Livin Room / Contact Window 2
    * Bathroom / Motion
    * Bathroom / Contact Window
    so on...
* When done, save the edited file and go into **Setup --> Log** tab and look for errors
* Try to **Disarm / Arm Home / Arm Away** the Home Security System clicking in the variuos states of **Alarm / Status** switch

### izDomoSecurityTimer.lua

#### Description
Timer script for auto activating izDomoSecuritySystem on given day/time   

#### Features
  * Holidays mode (when activated this a virtual switch, the Auto timer get disabled)
