$(document).on 'templateinit', (event) ->

  # define the item class
  class FloorplanItem extends pimatic.DeviceItem
    constructor: (templData, @device) ->
      super(templData, @device)

      @id = templData.deviceId
      @td = templData
      @floorplan = @device.config.floorplan

      @switchOff = 'fill:#dddddd'
      #@switchOn = "fill:#00ff00"
      @presenceOff = 'fill:#dddddd'
      #@presenceOn = 'fill:#ff0000'
      @contactOff = 'fill:#dddddd'
      #@contactOn = 'fill:#88ffff'
      @buttonOff = 'fill:#dddddd'
      #@buttonOn = 'fill:#0000dd'
      @lightOff = 'fill:#dddddd'
      #@lightOn = 'fill:#ffff00'
      for _stateColor in @device.config.colors
        if @[_stateColor.name]?
          @[_stateColor.name] = "fill:" + _stateColor.color

      @floorplanDevices = {}
      for _dev, i in @device.config.devices
        @floorplanDevices[_dev.pimatic_device_id+'_'+_dev.pimatic_attribute_name] = @device.config.devices[i]

    getItemTemplate: => 'floorplan'

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
            _selector = $(_tId, @svgRoot)
            # save the designed 'on' color
            _onColor = _selector.attr("style")
            @floorplanDevices[_id]["colorOn"] = _onColor
            switch _device.type
              when 'switch'
                @_switchOnOff(_id,attribute.value())
                _selector.on("click", (e)=>
                  _tId = "#" + e.target.id
                  _clickedElement = $(_tId, @svgRoot)
                  if _clickedElement.attr("style") == @floorplanDevices[e.target.id]["colorOn"]
                    @_switchOnOff(e.target.id,false)
                    @_setState(e.target.id, false)
                  else
                    @_switchOnOff(e.target.id,true)
                    @_setState(e.target.id, true)
                )
                @_onRemoteStateChange _id

              when 'button'
                @_buttonOnOff(_id, false)
                _selector.on("click", (e)=>
                  _tId = "#" + e.target.id
                  _clickedElement = $(_tId, @svgRoot)
                  @_buttonOnOff(e.target.id, true)
                  @_setButton(e.target.id)
                )
                @_onRemoteStateChange _id

              when 'light'
                attributeColor = @getAttribute(_id+"_color")
                @lightOn = "fill:" + attributeColor.value()
                @_lightOnOff(_id,attribute.value())
                #alert(@lightOn + ' - ' + attribute.value())
                _selector.on("click", (e)=>
                  _tId = "#" + e.target.id
                  _clickedElement = $(_tId, @svgRoot)
                  if _clickedElement.attr("style") == @floorplanDevices[e.target.id]["colorOn"]
                    @_lightOnOff(e.target.id,false)
                    @_setLight(e.target.id,false)
                  else
                    @_lightOnOff(e.target.id,true)
                    @_setLight(e.target.id,true)

                )
                @_onRemoteStateChange _id
                @_onRemoteColorChange _id

              when 'presence'
                @_presenceOnOff(_id,attribute.value())
                @_onRemoteStateChange _id

              when 'contact'
                @_contactOnOff(_id,attribute.value())
                @_onRemoteStateChange _id

              when 'sensor'
                _color = $(_tId, @svgRoot).css('fill')
                if _selector.text() isnt ""
                  #alert("text")
                  _selector.text(attribute.value())
                _selector.css('fill',_color)
                @_onRemoteStateChange _id

                #check if extra charts are on the floorplan
                _bar = _id + "_bar"
                _tBar = "#" + _bar
                if $(_tBar, @svgRoot)?
                  if Number.isNaN(Number attribute.value())
                    @floorplanDevices[_id]["bar"] = false
                  else
                    @floorplanDevices[_id]["height"] = Number $(_tBar, @svgRoot).attr('height')
                    @floorplanDevices[_id]["y"] = Number $(_tBar, @svgRoot).attr('y')
                    @floorplanDevices[_id]["bar"] = true
                    @_setBar(_id, attribute.value())

      )

    _switchOnOff: (_id, onoff) =>
      _tId = "#" + _id
      if onoff
        _onColor = @floorplanDevices[_id]["colorOn"]
        $(_tId, @svgRoot).attr('style',_onColor)
      else
        $(_tId, @svgRoot).attr('style',@switchOff)

    _presenceOnOff: (_id, onoff) =>
      _tId = "#" + _id
      if onoff
        _onColor = @floorplanDevices[_id]["colorOn"]
        $(_tId, @svgRoot).attr('style',_onColor)
      else
        $(_tId, @svgRoot).attr('style',@presenceOff)

    _contactOnOff: (_id, onoff) =>
      _tId = "#" + _id
      if onoff
        _onColor = @floorplanDevices[_id]["colorOn"]
        $(_tId, @svgRoot).attr('style',_onColor)
      else
        $(_tId, @svgRoot).attr('style',@contactOff)

    _lightOnOff: (_id, onoff) =>
      _tId = "#" + _id
      if onoff
        _onColor = @floorplanDevices[_id]["colorOn"]
        $(_tId, @svgRoot).attr('style',_onColor)
      else
        $(_tId, @svgRoot).attr('style',@lightOff)

    _buttonOnOff: (_id, onoff) =>
      _tId = "#" + _id
      if onoff
        #alert(_onColor)
        _onColor = @floorplanDevices[_id]["colorOn"]
        $(_tId, @svgRoot).clearQueue()
        $(_tId, @svgRoot).attr('style',_onColor)
        setTimeout( =>
          $(_tId, @svgRoot).attr('style',@buttonOff)
        , 1500)
      else
        $(_tId, @svgRoot).attr('style',@buttonOff)


    _onRemoteStateChange: (attributeString) =>
      attribute = @getAttribute(attributeString)
      unless attributeString?
        throw new Error("The floorplan device needs an #{attributeString} attribute!")

      @[attributeString] = ko.observable attribute.value()
      attribute.value.subscribe (newValue) =>
        _id = attributeString
        _tId = "#" + _id
        switch @floorplanDevices[_id].type
          when 'switch'
            @_switchOnOff(_id,newValue)
          when 'button'
            @_buttonOnOff(_id, true)
          when 'presence'
            @_presenceOnOff(_id,newValue)
          when 'contact'
            @_contactOnOff(_id,newValue)
          when 'light'
            @_lightOnOff(_id, newValue)
          when 'sensor'
            _color = $(_tId, @svgRoot).css('fill')
            if $(_tId, @svgRoot).text() isnt ""
              #alert("text")
              $(_tId, @svgRoot).text(newValue)
            $(_tId, @svgRoot).css('fill',_color)

            #check if extra charts are attached to _tId
            if @floorplanDevices[_id]["bar"]? and @floorplanDevices[_id]["bar"]
              @_setBar(_id, newValue)

    _setBar: (_id, value) =>
      _tBar = '#' + _id + "_bar"
      _height = @floorplanDevices[_id]["height"] # Number($(_tId, @svgRoot).attr('height'))
      _y = @floorplanDevices[_id]["y"] # Number($(_tId, @svgRoot).attr('y'))
      _y0 = _y + _height
      _newY = _y0 - _height * Number(value)/100
      _newHeight = _height * Number(value)/100
      $(_tBar, @svgRoot).attr('y', _newY)
      $(_tBar, @svgRoot).attr('height', _newHeight)


    _onRemoteColorChange: (attributeString) =>
      attributeStringColor = attributeString + '_color'
      attribute = @getAttribute(attributeStringColor)
      unless attributeString?
        throw new Error("The floorplan device needs an #{attributeString} attribute!")

      @[attributeStringColor] = ko.observable attribute.value()
      attribute.value.subscribe (newColor) =>
        _id = attributeString
        _tId = "#" + _id
        _oldColor = @floorplanDevices[_id]["colorOn"]
        @floorplanDevices[_id]["colorOn"] = "fill:" + newColor
        if $(_tId, @svgRoot).attr('style') is _oldColor
          @_lightOnOff(_id, true)

    _setState: (_id, _state) ->
      @device.rest.setState {id:_id, state:_state}, global: no

    _setButton: (_id) ->
      @device.rest.buttonPressed {buttonId:_id}, global: no

    _setLight: (_id, _lightState) ->
      @device.rest.setLight {id: _id, state: _lightState}, global: no

  # register the item-class
  pimatic.templateClasses['floorplan'] = FloorplanItem
