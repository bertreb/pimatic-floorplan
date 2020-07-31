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
  svgId: "The object ID used in the svg floorplan"
  type: "The gui type of device
     ["switch","button","presence","contact","light","sensor","sensor_bar","sensor_gauge"]
  pimatic_device_id: "The pimatic device Id"
  pimatic_attribute_name:" The attribute name of the Pimatic device like state, presence or temperature"
  format: "Optional JSON formatted attribute values"
```
Add pimatic devices by there device-id, give them a logical type and optional color the off-states. The default off color for all devices is #dddddd (light gray). The on-state colors are defined by the svg color of the object.

Make sure that floorplan devices are the last devices in the device list (the gui devices page).
After adding a floorplan please refresh the gui (incl clearing the cache)

## Linking the floorplan svg and pimatic

The linking between the svg objects and the pimatic devices devices is done in the floorplan config.
The svgId in the floorplan config must be the object ID in the floorplan svg. The svg ID can be be freely choosen.

The device object that you create must have the option to fill it with a color. Otherwise the states colering will obviously not work.
The color, font size, etc of a text field (sensor values) must be set in the svg editor.

## Devices
#### switch, presence and contact
The switch can be used in any svg object that has a color that can be set via the 'fill' attribute. By clicking on the drawing the device will toggle (on<->off) and go from on color to off color.The on color is defined by the svg drawing, the off color is default 'gray' or can be set in the format.
Format option is: colorOff

#### light
The light can be used with any svg object that has a color and can be set via the 'fill' attribute. By clicking on the drawing the light will toggle (on<->off) and go from on color to off color. The on color is defined by the color of used pimatic light device. The off color is default 'gray' or can be set in the format.
Format option is: colorOff.

#### sensor
The sensor will show the value of the used Pimatic device+attribute. For this floorplan device the svg type must be a TEXT field.

#### sensor_bar
The sensor bar will show a Pimatic device+attribute value in a bar form. In the svg drawing a RECT type form must be used.
In the format you can set a minimum and a maximum value ({'min':'\<number>'},'max':'\<number>',"fill":"\<color>"}). If not set the defaults 0, 100 and 'red' will be used.
![](bar.png)

#### sensor_gauge
The sensor gauge will show a Pimatic device+attribute value in a gauge form. In the svg drawing a CIRCLE type form must be used.
In the format you can set a minimum and a maximum value ({'min':'\<number>'},'max':'\<number>'). If not set the defaults 0, 100 and 'red' will be used.
![](gauge.png)

---
The plugin is in development. You could backup Pimatic before you are using this plugin!
