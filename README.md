# pimatic-floorplan
Pimatic plugin for floorplans in the Pimatic gui

## background
Pimatic's standard gui is pimatic-mobile-frontend. This standard gui gives a good and functional interface towards the Pimatic functions.
The interface is based on jQueryMobile and gives a structured page oriented layout to manage and control devices, rules, etc.
some home-automation users want a more graphical representation of the gui. This plugin is build for that purpose.

## description

This plugin adds a gui option to create 1 or more floorplan devices, for viewing and controlling existing pimatic devices. The concept is as follows:
- Scalable Vector Graphics (svg) as graphical base for a floorplan.
- Manual adding of devices that must be shown on the floorplan.
- Free choice of shapes for background and the pimatic devices, as long as they are linked to pimatic (see Linking the floorplan svg and pimatic).
- The supported devices are: switch, presence, contact, light, button and sensor (text/value display).
- The states of an on/off switch, open/close contact, light, push/release button and present/absent presence sensor are all presented via colors. The colors are configurable. The light  will color depending on the color of the device its connected to.
- Attribute values can be shown via the sensor field. Optional you can add the acronym and unit of the used device.

## preparation
Install the plugin the normal way via the pimatic plugins page or config.json.


## creating a floorplan

Create a svg floorplan with a background of the room(s) your want to 'floorplan' and add graphics for the devices you want to use. A good and free program for this is [inkscape](https://inkscape.org). The ID tag of a sgv device object need to match the device-attribute in pimatic (see Linking the floorplan svg and pimatic).

Save the created svg file in the public folder of pimatic-mobile-frontend (pimatic-app/node_modules/pimatic-mobile-frontend/public. The filename (incl .svg) is use in the device config.

Create a floorplan device with the following configuration:
```
floorplan: "the sgv filename of the floorplan"
devices: "list of devices used in the floorplan"
  name: "The device name"
  type: "The gui type of device
     ["switch","button","presence","contact","light","sensor"]
  pimatic_device_id: "The pimatic device Id"
  pimatic_attribute_name:" The attribute name of the Pimatic device like state, presence or temperature"
colors: "Array with Colors for the states in the floorplan device"
  name: "Name of device state"
    ["switchOff", "switchOn", "contactOn", "contactOff",
    "presenceOff", "presenceOn", "buttonOff", "buttonOn",
    "lightOff", "lightOn"]
  color: "The hex color number for the the state, for example: #12DA0F"
```
Add pimatic devices by there device-id, give them a logical type and optional color the states.

Make sure that floorplan devices are the last devices in the device list (the gui devices page).
After adding a floorplan please refresh the gui (incl clearing the cache)

## Linking the floorplan svg and pimatic

In the svg file you need to name a device object with the following ID (the label is not used)
```
name: <pimatic device id>_<attribute name>

examples:
  switch 'my-switch', the ID is my-switch_state.
  presence sensor 'my-sensor', the ID is my-sensor_presence
  temperature attribute of device 'whats-the-temp', the ID is whats-the-temp_temperature
```
The underscore between device id and attribute is important! Underscores in the devicename are no problem.

The device object that you create must have the option to fill it with a color. Otherwise the states colering will obviously not work.
The color, font size, etc of a text field (sensor values) must be set in the editor.



---
The plugin is in development. You could backup Pimatic before you are using this plugin!
