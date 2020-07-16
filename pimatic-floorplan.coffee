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
          mobileFrontend.registerAssetFile 'js', 'pimatic-floorplan/ui/vendor/spectrum.js'
          mobileFrontend.registerAssetFile 'css', 'pimatic-floorplan/ui/vendor/spectrum.css'
          mobileFrontend.registerAssetFile 'js', 'pimatic-floorplan/ui/vendor/async.js'
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

      @lightAttributes = ["color","ct","dimlevel"]
      


      @framework.on "deviceChanged", (device) =>
        _floorplanDevice = _.find(@attributeValues, (d)=> d.remoteDevice.config.id is device.config.id)
        if _floorplanDevice?
          _attrName = _floorplanDevice.attrName
          @attributeValues[_attrName]["remoteDevice"] = device


      @framework.variableManager.waitForInit()
      .then(()=>
        # get and set all initial values
        for i, _device of @attributeValues
          _getter = _device.remoteGetAction
          env.logger.info "_getter after init: " + _getter
          if _device.remoteDevice.config.class isnt "ButtonsDevice" and _getter?
            _device.remoteDevice[_getter]()
            .then((value)=>
              env.logger.info "iii: " + i + ", value: " + value
              @setLocalState(i, value)
            )
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
      )
      
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
                  @addAttribute(_attrName,
                    description: "remote device " + _attrName ? ""
                    type: _deviceAttrType
                  )
                when "string"
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
            remoteValue: @lastState?[attrName]?.value ? false
            remoteGetAction: 'getState'
            remoteSetAction: 'changeStateTo'
        when "presence"
          @attributeValues[attrName] =
            remoteValue: @lastState?[attrName]?.value ? false
            remoteGetAction: 'getPresence'
            remoteSetAction: 'changePresenceTo'
        when "light"
          @attributeValues[attrName] =
            remoteValue: 
              state: true
              dimlevel: 100
              color: @lastState?[attrName]?.value ? '#000'
              ct: 50
            remoteGetAction: 'getColor'
            remoteSetAction: 'changeStateTo'
          #env.logger.info "attrName: " + attrName + ", @attributeValues[attrName].remoteValue " + JSON.stringify(@attributeValues[attrName].remoteValue,null,2)
        when "button"
          @attributeValues[attrName] =
            remoteValue: @lastState?[attrName]?.value ? null
            remoteGetAction: 'getButton'
            remoteSetAction: 'buttonPressed'
        when "string"
          @attributeValues[attrName] =
            remoteValue: @lastState?[attrName]?.value ? ""
            remoteGetAction: 'get'+upperCaseFirst(remoteAttrName)
            remoteSetAction: ''
        else
          @attributeValues[attrName] =
            remoteValue: lastState?[attrName]?.value ? ""
            remoteGetAction: 'get'+upperCaseFirst(remoteAttrName)
            remoteSetAction: ''

      @attributeValues[attrName]["attrName"] = attrName
      @attributeValues[attrName]["remoteAttrName"] = remoteAttrName
      @attributeValues[attrName]["remoteDevice"] = remoteDevice

      @_createGetter attrName, () => 
        return Promise.resolve @attributeValues[attrName].remoteValue.color

    getTemplateName: -> "floorplan"

    setLocalState: (_attr, _value) =>
      env.logger.info "SetLocalState _attr: " + _attr + ", value: " + _value
      #env.logger.info "SetLocalState @attributeValues[_attr].val " + @attributeValues[_attr].val + ", _state: " + _state 
      #if @attributeValues[_attr].val is _state then return
      @attributeValues[_attr]["remoteValue"] = _value
      @emit _attr, _value

    setLocalButton: (_attr, _value) =>
      env.logger.info "SetLocalState _attr: " + _attr + ", value: " + _value
      #env.logger.info "SetLocalState @attributeValues[_attr].val " + @attributeValues[_attr].val + ", _state: " + _state 
      #if @attributeValues[_attr].val is _state then return
      @attributeValues[_attr]["remoteValue"] = _value
      @emit _attr, _value
      setTimeout(=>
        @emit _attr, null
      ,1000 )
    setLocalLight: (_attr, _type, _receivedValue) =>
      env.logger.info "SetLocalLight _attr: " + _attr + ", _type: " + _type + ", value: " + _receivedValue + ", @attributeValues[_attr].remoteValue: " + JSON.stringify(@attributeValues[_attr].remoteValue,null,2)
      switch _type
        when "color"
          _value = "#" + _receivedValue unless _receivedValue.startsWith('#')
          @attributeValues[_attr].remoteValue.color = _value
          @emit _attr, _value

        when "dimlevel"
          _newDimlevelColor = chroma(@attributeValues[_attr].remoteValue.color).luminance(_receivedValue/200).hex()
          #env.logger.info "_attr: " + _attr + ", Dimlevel _newColor: " + _newDimlevelColor

          @attributeValues[_attr].remoteValue.dimlevel = _receivedValue
          @emit _attr, _newDimlevelColor

        when "ct"
          kelvin=Math.round(1500 + (100-_receivedValue) / 100 * (15000-1500))
          _newCtColor = chroma.temperature(kelvin).hex()
          #env.logger.info "_attr: " + _attr + ", CT _newColor: " + _newCtColor

          @attributeValues[_attr].remoteValue.ct = _receivedValue
          @emit _attr, _newCtColor


    setState: (_attr, _value) =>
      #env.logger.info "SetState _attr: " + _attr + ", _value: " + _value
      #env.logger.info "SetState @attributeValues[_attr].remoteValue " + @attributeValues[_attr].remoteValue
      #if @attributeValues[_attr].remoteValue is _value then return
      @attributeValues[_attr].remoteValue.state = _value
      #_setter = "change" + upperCaseFirst(@attributeValues[_attr].remoteAttrName) + "To"
      #_setter2 = "set" + upperCaseFirst(@attributeValues[_attr].remoteAttrName)
      _setter = @attributeValues[_attr].remoteSetAction
      #env.logger.info "_setter " + _setter
      @attributeValues[_attr].remoteDevice[_setter](_value)

    setLight:(_attr, _lightState) =>
      #env.logger.info "setLight: " + _attr + ", _lightState: " + _lightState
      _setter = @attributeValues[_attr].remoteSetAction
      # toggle remote device state
      @attributeValues[_attr].remoteValue.state = !@attributeValues[_attr].remoteValue.state
      # switch remote light device on/off
      @attributeValues[_attr].remoteDevice[_setter](@attributeValues[_attr].remoteValue.state)
      # set local light attribute to right color
      @emit _attr, @attributeValues[_attr].remoteValue.color

      ###
        _newValue = @attributeValues[_attr]["remoteValue"]
      else
        @attributeValues[_attr].remoteDevice[_setter](off)
        _newValue = '#000'
      ###
      #@emit _attr, _newValue

    buttonPressed: (_id) =>
      @attributeValues[_id]["remoteValue"] = _id
      _setter = "buttonPressed"
      env.logger.info "_setter " + _setter
      @attributeValues[_id].remoteDevice[_setter](@attributeValues[_id].remoteAttrName)

    upperCaseFirst = (string) ->
      unless string.length is 0
        string[0].toUpperCase() + string.slice(1)
      else ""

    destroy: ->
      @framework.removeListener('deviceAttributeChanged', @attrHandler)
      super()


  return new FloorplanPlugin()
