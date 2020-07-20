module.exports = (env) ->

  Promise = env.require 'bluebird'

  t = env.require('decl-api').types
  _ = env.require('lodash')
  M = env.matcher
  chroma = require 'chroma-js'

  class FloorplanPlugin extends env.plugins.Plugin

    init: (app, @framework, @config) =>
      deviceConfigDef = require('./device-config-schema.coffee')
      @framework.deviceManager.registerDeviceClass 'Floorplan',
        configDef: deviceConfigDef.Floorplan
        createCallback: (config,lastState) => return new Floorplan(config,lastState, @framework)

      @framework.on "after init", =>
        # Check if the mobile-frontend was loaded and get a instance
        mobileFrontend = @framework.pluginManager.getPlugin 'mobile-frontend'
        if mobileFrontend?
          mobileFrontend.registerAssetFile 'js', 'pimatic-floorplan/ui/floorplan.coffee'
          mobileFrontend.registerAssetFile 'css', 'pimatic-floorplan/ui/floorplan.css'
          mobileFrontend.registerAssetFile 'html', 'pimatic-floorplan/ui/floorplan.jade'
        else
          env.logger.warn 'your plugin could not find the mobile-frontend. No gui will be available'

  class Floorplan extends env.devices.Device

    template: 'floorplan'

    actions:
      setState:
        description: 'set state'
        params:
          id:
            type: "string"
          state:
            type: "boolean"
      setLight:
        description: 'switch light'
        params:
          id:
            type: "string"
          state:
            type: "boolean"
      buttonPressed:
        description: "Press a button"
        params:
          buttonId:
            type: t.string

    constructor: (@config, @lastState, @framework) ->
      @name = @config.name
      @id = @config.id
      #@_state = false
      @floorplan = @config.floorplan

      checkMultipleDevices = []
      @configDevices = []
      @nrOfDevices = 0
      @attributes = {}
      @attributeValues = {}


      @lightAttributes = ["state","color","ct","dimlevel"]

      @framework.on "deviceChanged", (device) =>
        _floorplanDevice = _.find(@attributeValues, (d)=> d.remoteDevice.config.id is device.config.id)
        if _floorplanDevice?
          _attrName = _floorplanDevice.attrName
          @attributeValues[_attrName]["remoteDevice"] = device


      @framework.variableManager.waitForInit()
      .then(()=>
        # get and set all initial values
        _arrayAttributeValues = _.map(@attributeValues)
        Promise.all(_arrayAttributeValues.map (d) =>
          for _action in d.remoteGetAction
            _getter = 'get' + upperCaseFirst(_action)
            if _getter?
              switch d.type
                when 'light'
                  getRemoteLight(d.remoteDevice,_getter, d.attrName, d.remoteAttrName)
                when 'sensor'
                  getRemoteSensor(d.remoteDevice, d.attrName, d.remoteAttrName)
                else
                  getRemote(d.remoteDevice,_getter, d.attrName,_action)
        )
      )

      getRemoteLight = (_device, _getter, _attrName, _action) =>
        _device[_getter]()
        .then((value)=>
          @setLocalLight(_attrName, _action, value)
        )
      getRemote = (_device, _getter, _attrName, _action) =>
        _device[_getter]()
        .then((value)=>
          @setLocalState(_attrName, value)
        )
      getRemoteSensor = (_device, _attrName, _remoteAttrName) =>
        _name = _device.config.id + "." + _remoteAttrName
        env.logger.info "_name: " + _name
        _value = @framework.variableManager.getVariableValue(_name)
        @setLocalSensor(_attrName, _value)


      @framework.on 'deviceAttributeChanged', @attrHandler = (attrEvent) =>
        _attr = attrEvent.device.id + "_" + attrEvent.attributeName
        if @attributes[_attr]?
          @setLocalState(_attr, attrEvent.value)
          #check on button
          return
        _attrButton = attrEvent.device.id + "_" + attrEvent.value
        if @attributes[_attrButton]?
          @setLocalButton(_attrButton, attrEvent.value)
          return
        if attrEvent.attributeName in @lightAttributes
          _attr = attrEvent.device.id + "_light"
          if @attributes[_attr]?
            @setLocalLight(_attr, attrEvent.attributeName, attrEvent.value)

      
      for _device in @config.devices
        do(_device) =>
          if _.find(checkMultipleDevices, (d) => d.pimatic_device_id is _device.pimatic_device_id and d.pimatic_attribute_name is _device.pimatic_attribute_name)?
            throw new Error "Pimatic device '#{_device.pimatic_device_id}' is already used"
          else
            checkMultipleDevices.push _device
            _fullDevice = @framework.deviceManager.getDeviceById(_device.pimatic_device_id)
            if _fullDevice?
              if _fullDevice.config.class is @config.class
                throw new Error "You can't add floorplan devices"
              switch _device.type
                when "switch"
                  _deviceAttrType =_fullDevice.attributes[_device.pimatic_attribute_name].type
                  _attrName = _device.pimatic_device_id + '_' + _device.pimatic_attribute_name
                  @addAttribute(_attrName,
                    description: "remote device " + _attrName ? ""
                    type: if _deviceAttrType is "boolean" then "boolean" else "string"
                  )
                when "presence"
                  _deviceAttrType =_fullDevice.attributes[_device.pimatic_attribute_name].type
                  _attrName = _device.pimatic_device_id + '_' + _device.pimatic_attribute_name
                  @addAttribute(_attrName,
                    description: "remote device " + _attrName ? ""
                    type: if _deviceAttrType is "boolean" then "boolean" else "string"
                  )
                when "button"
                  _button = _.find(_fullDevice.config.buttons, (b) => _device.pimatic_attribute_name == b.id)
                  if _button?
                    _deviceAttrType = "boolean"
                    _attrName = _device.pimatic_device_id + '_' + _device.pimatic_attribute_name
                    @addAttribute(_attrName,
                      description: "remote device " + _attrName ? ""
                      type: _deviceAttrType
                    )
                  else
                    throw new Error "Button '#{_device.pimatic_attribute_name}' of device '#{_device.id}' not found" 
                when "light"
                  # use hex color for all light: switch on/off, dimlevel, ct and rgb
                  _attrName = _device.pimatic_device_id + '_light' # + _device.pimatic_attribute_name
                  _deviceAttrType = "string"
                  #light switch attribute
                  @addAttribute(_attrName,
                    description: "remote device " + _attrName ? ""
                    type: "boolean"
                  )
                  _colorAttrName = _attrName + '_color'
                  # light color attribute
                  @addAttribute(_colorAttrName,
                    description: "remote device color " + _colorAttrName ? ""
                    type: "string" #_deviceAttrType
                  )
                when "sensor"
                  _attrName = _device.pimatic_device_id + '_' + _device.pimatic_attribute_name
                  _deviceAttrType = "string"
                  @addAttribute(_attrName,
                    description: "remote device " + _attrName ? ""
                    type: _deviceAttrType
                  )
                else
                  throw new Error "Device type '#{_device.type}' of device '#{_device.id}' not supported" 

              @addDevice(_attrName, _device.type, _fullDevice, _device.pimatic_attribute_name)

            else
              env.logger.info "Pimatic device '#{_device.pimatic_device_id}' does not excist"
              
      @nrOfDevices = _.size(@configDevices)
  
      super()

    addDevice: (attrName, deviceAttrType, remoteDevice, remoteAttrName) =>
      #_attr = _device.config.id
      switch deviceAttrType
        #when "number"
        #  @attributeValues[attrName] =
        #    remoteValue: @lastState?[attrName]?.value ? 0
        when "switch"
          @attributeValues[attrName] =
            state: 
              on: @lastState?[attrName]?.value ? false
            remoteGetAction: ['state']
            remoteSetAction: 'changeStateTo'
          @_createGetter attrName, () => 
            return Promise.resolve @attributeValues[attrName].state.on
        when "presence"
          @attributeValues[attrName] =
            state: 
              on: @lastState?[attrName]?.value ? false
            remoteGetAction: ['presence']
            remoteSetAction: 'changePresenceTo'
          @_createGetter attrName, () => 
            return Promise.resolve @attributeValues[attrName].state.on
        when "light"
          @attributeValues[attrName] =
            state: 
              on: @lastState?[attrName]?.value ? false
              dimlevel: 100
              color: @lastState?[attrName+"_color"]?.value ? ''
              ct: 50
            remoteGetAction: ['state','color']
            remoteSetAction: 'changeStateTo'
          @_createGetter attrName + '_color', () => 
            return Promise.resolve @attributeValues[attrName].state.color
          @_createGetter attrName, () => 
            return Promise.resolve @attributeValues[attrName].state.on
        when "button"
          @attributeValues[attrName] =
            state: 
              button: @lastState?[attrName]?.value ? null
            remoteGetAction: ['button']
            remoteSetAction: 'buttonPressed'
          @_createGetter attrName, () => 
            return Promise.resolve @attributeValues[attrName].state.button
        when "sensor"
          @attributeValues[attrName] =
            state: 
              sensor: @lastState?[attrName]?.value ? ""
            remoteGetAction: [remoteAttrName]
            remoteSetAction: null
          @_createGetter attrName, () => 
            return Promise.resolve @attributeValues[attrName].state.sensor
        else
          @attributeValues[attrName] =
            state:
              sensor: lastState?[attrName]?.value ? ""
            remoteGetAction: [remoteAttrName]
            remoteSetAction: null
          @_createGetter attrName, () => 
            return Promise.resolve @attributeValues[attrName].state.sensor

      @attributeValues[attrName]["type"] = deviceAttrType
      @attributeValues[attrName]["attrName"] = attrName
      @attributeValues[attrName]["remoteAttrName"] = remoteAttrName
      @attributeValues[attrName]["remoteDevice"] = remoteDevice


    getTemplateName: -> "floorplan"

    setLocalState: (_attr, _value) =>
      #env.logger.info "SetLocalState _attr: " + _attr + ", value: " + _value
      if typeof _value is 'boolean'
        @attributeValues[_attr].state.on = _value
        @emit _attr, _value
      else
        @attributeValues[_attr].state.sensor = _value
        @emit _attr, _value        

    setLocalSensor: (_attr, _value) =>
      env.logger.info "SetLocalSensor _attr: " + _attr + ", value: " + _value
      @attributeValues[_attr].state.sensor = _value
      @emit _attr, _value

    setLocalButton: (_attr, _value) =>
      #env.logger.info "SetLocalState _attr: " + _attr + ", value: " + _value
      @attributeValues[_attr].state.button = _value
      @emit _attr, _value
      setTimeout(=>
        @emit _attr, null
      ,1000 )
    setLocalLight: (_attr, _type, _receivedValue) =>
      _attrColor = _attr + '_color'
      switch _type
        when "state"
          #_value = "#" + _receivedValue unless _receivedValue.startsWith('#')
          @attributeValues[_attr].state.on = _receivedValue
          @emit _attr, _receivedValue
        when "color"
          _value = "#" + _receivedValue unless _receivedValue.startsWith('#')
          @attributeValues[_attr].state.color = _value
          @emit _attrColor, _value
        when "dimlevel"          
          if _receivedValue > 0
            #@attributeValues[_attr].state.on = true
            #@emit _attr, true
            _newDimlevelColor = chroma(@attributeValues[_attr].state.color).luminance(_receivedValue/130).hex()
            @attributeValues[_attr].state.dimlevel = _receivedValue
            #@emit _attrColor, _newDimlevelColor
          else
            @attributeValues[_attr].state.on = false
            @emit _attr, false 
        when "ct"
          kelvin=Math.round(1500 + (100-_receivedValue) / 100 * (15000-1500))
          _newCtColor = chroma.temperature(kelvin).hex()
          @attributeValues[_attr].state.ct = _receivedValue
          #@emit _attrColor, _newCtColor

      #env.logger.info "SetLocalLight _attr: " + _attr + ", _type: " + _type + ", value: " + _receivedValue + ", @attributeValues[_attr].state: " + JSON.stringify(@attributeValues[_attr].state,null,2)

    setState: (_attr, _value) =>
      @attributeValues[_attr].state.on = _value
      _setter = @attributeValues[_attr].remoteSetAction
      @attributeValues[_attr].remoteDevice[_setter](_value)

    setLight:(_attr, _lightState) =>
      _setter = @attributeValues[_attr].remoteSetAction
      # toggle remote device state
      @attributeValues[_attr].state.on = _lightState # !@attributeValues[_attr].state.on
      # switch remote light device on/off
      @attributeValues[_attr].remoteDevice[_setter](@attributeValues[_attr].state.on)

      # set local light attribute to right color
      @emit _attr, @attributeValues[_attr].state.on
      
    buttonPressed: (_id) =>
      @attributeValues[_id]["remoteValue"] = _id
      _setter = "buttonPressed"
      #env.logger.info "_setter " + _setter
      @attributeValues[_id].remoteDevice[_setter](@attributeValues[_id].remoteAttrName)

    upperCaseFirst = (string) ->
      unless string.length is 0
        string[0].toUpperCase() + string.slice(1)
      else ""

    destroy: ->
      @framework.removeListener('deviceAttributeChanged', @attrHandler)
      super()


  return new FloorplanPlugin()
