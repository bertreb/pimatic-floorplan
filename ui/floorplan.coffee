$(document).on 'templateinit', (event) ->

  # define the item class
  class FloorplanItem extends pimatic.DeviceItem
    constructor: (templData, @device) ->
      super(templData, @device)

      @id = templData.deviceId
      @td = templData
      @floorplan = @device.config.floorplan

      @switchOff = 'fill:#cccccc'
      @switchOn = "fill:#00ff00"
      @presenceOff = 'fill:#cccccc'
      @presenceOn = 'fill:#ff0000'
      @contactOff = 'fill:#cccccc'
      @contactOn = 'fill:#88ffff'
      @buttonOff = 'fill:#cccccc'
      @buttonOn = 'fill:#0000dd'
      @lightOff = 'fill:#cccccc'
      @lightOn = 'fill:#ffff00'
      for _stateColor in @device.config.colors
        if @[_stateColor.name]?
          @[_stateColor.name] = "fill:" + _stateColor.color


      @floorplanDevices = {}
      for _dev, i in @device.config.devices
        @floorplanDevices[_dev.pimatic_device_id+'_'+_dev.pimatic_attribute_name] = @device.config.devices[i]

    afterRender: (elements) =>
      super(elements)
      ### Apply UI elements ###
      
      a = document.getElementById(@id)
      a.addEventListener("load",() =>
        svgDoc = a.contentDocument #get the inner DOM of alpha.svg
        @svgRoot = svgDoc.documentElement

        for i, _device of @floorplanDevices
          _id = _device.pimatic_device_id + "_" + _device.pimatic_attribute_name
          attribute = @getAttribute(_id)
          if attribute?
            _tId = "#" + _id
            switch _device.type
              when 'switch'
                @_switchOnOff($(_tId, @svgRoot),attribute.value())
                $(_tId, @svgRoot).on("click", (e)=>
                  _tId = "#" + e.target.id
                  _clickedElement = $(_tId, @svgRoot)
                  if _clickedElement.attr("style") == @switchOn
                    @_switchOnOff(_clickedElement,false)
                    @_setState(e.target.id, false)
                  else            
                    @_switchOnOff(_clickedElement,true)
                    @_setState(e.target.id, true)
                )
                @_onRemoteStateChange _id

              when 'button'
                @_buttonOnOff($(_tId, @svgRoot), false)
                $(_tId, @svgRoot).on("mousedown", (e)=>
                  _tId = "#" + e.target.id
                  _clickedElement = $(_tId, @svgRoot)
                  @_buttonOnOff(_clickedElement, true)
                  @_setButton(e.target.id)
                )
                @_onRemoteStateChange _id

              when 'light'
                attributeColor = @getAttribute(_id+"_color")
                @lightOn = "fill:" + attributeColor.value()
                @_lightOnOff($(_tId, @svgRoot),attribute.value())
                #alert(@lightOn + ' - ' + attribute.value())
                $(_tId, @svgRoot).on("click", (e)=>
                  _tId = "#" + e.target.id
                  _clickedElement = $(_tId, @svgRoot)
                  if _clickedElement.attr("style") == @lightOn
                    @_lightOnOff(_clickedElement,false)
                    @_setLight(e.target.id,false)
                  else            
                    @_lightOnOff(_clickedElement,true)
                    @_setLight(e.target.id,true)

                )
                @_onRemoteStateChange _id
                @_onRemoteColorChange _id

              when 'presence'
                @_presenceOnOff($(_tId, @svgRoot),attribute.value())
                @_onRemoteStateChange _id

              when 'contact'
                @_contactOnOff($(_tId, @svgRoot),attribute.value())
                @_onRemoteStateChange _id

              when 'sensor' 
                $(_tId, @svgRoot).text(attribute.value())
                @_onRemoteStateChange _id
      )

    _switchOnOff: (_id, onoff) =>
      if onoff
        $(_id, @svgRoot).attr('style',@switchOn)
      else
        $(_id, @svgRoot).attr('style',@switchOff)

    _presenceOnOff: (_id, onoff) =>
      if onoff
        $(_id, @svgRoot).attr('style',@presenceOn)
      else
        $(_id, @svgRoot).attr('style',@presenceOff)

    _contactOnOff: (_id, onoff) =>
      if onoff
        $(_id, @svgRoot).attr('style',@contactOn)
      else
        $(_id, @svgRoot).attr('style',@contactOff)

    _lightOnOff: (_id, onoff) =>
      if onoff
        $(_id, @svgRoot).attr('style',@lightOn)
      else
        $(_id, @svgRoot).attr('style',@lightOff)

    _buttonOnOff: (_id, onoff) =>
      if onoff
        $(_id, @svgRoot).attr('style',@buttonOn)
        setTimeout(=>
          $(_id, @svgRoot).attr('style',@buttonOff)
        ,1000)        
      else
        $(_id, @svgRoot).attr('style',@buttonOff)


    _onRemoteStateChange: (attributeString) =>
      attribute = @getAttribute(attributeString)
      unless attributeString?
        throw new Error("The floorplan device needs an #{attributeString} attribute!")

      @[attributeString] = ko.observable attribute.value()
      attribute.value.subscribe (newValue) =>
        _tId = "#" + attributeString
        switch @floorplanDevices[attributeString].type
          when 'switch'    
            @_switchOnOff($(_tId, @svgRoot),newValue)    
          when 'button'
            @_buttonOnOff($(_tId, @svgRoot), true)    
          when 'presence'
            @_presenceOnOff($(_tId, @svgRoot),newValue)    
          when 'contact'
            @_contactOnOff($(_tId, @svgRoot),newValue)
          when 'light'
            @_lightOnOff($(_tId, @svgRoot),newValue)   
          when 'sensor'
            $(_tId, @svgRoot).text(newValue)

    _onRemoteColorChange: (attributeString) =>
      attributeStringColor = attributeString + '_color'
      attribute = @getAttribute(attributeStringColor)
      unless attributeString?
        throw new Error("The floorplan device needs an #{attributeString} attribute!")

      @[attributeStringColor] = ko.observable attribute.value()
      attribute.value.subscribe (newColor) =>
        _tId = "#" + attributeString
        _oldColor = @lightOn
        @lightOn = 'fill:' + newColor
        if $(_tId, @svgRoot).attr('style') is _oldColor
          @_lightOnOff($(_tId, @svgRoot), true)

    _setState: (_id, _state) ->
      @device.rest.setState {id:_id, state:_state}, global: no

    _setButton: (_id) ->
      @device.rest.buttonPressed {buttonId:_id}, global: no

    _setLight: (_id, _lightState) ->
      @device.rest.setLight {id: _id, state: _lightState}, global: no

  # register the item-class
  pimatic.templateClasses['floorplan'] = FloorplanItem
