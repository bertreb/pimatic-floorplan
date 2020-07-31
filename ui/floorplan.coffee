
$(document).on 'templateinit', (event) ->

  # define the item class
  class FloorplanItem extends pimatic.DeviceItem
    constructor: (templData, @device) ->
      super(templData, @device)

      @id = templData.deviceId
      @td = templData
      @floorplan = @device.config.floorplan

      @colorAttributeExtension = "_color"

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
        #alert(JSON.stringify(_dev,null,2))

        @floorplanDevices[_dev.svgId] = @device.config.devices[i]
        #@floorplanDevices[_dev.pimatic_device_id+'_'+_dev.pimatic_attribute_name] = @device.config.devices[i]



    getItemTemplate: => 'floorplan'

    afterRender: (elements) =>
      super(elements)
      ### Apply UI elements ###


      a = document.getElementById(@id)      
      a.addEventListener("load",() =>
        svgDoc = a.contentDocument #get the inner DOM of alpha.svg
        @svgRoot = svgDoc.documentElement

        #$(window).resize(()=>
        #  alert("resize" + $(@svgRoot).width() + ' - ' + $(@svgRoot).height())
        #  if @gauge?
        #    @gauge.update()
        #  )

        for i, _device of @floorplanDevices
          #_id = _device.pimatic_device_id + "_" + _device.pimatic_attribute_name
          _id = _device.svgId
          attribute = @getAttribute(_id)
          if attribute?
            _tId = "#" + _id
            _selector = $(_tId, @svgRoot)
            # save the designed 'on' color
            _onColor = _selector.attr("style")
            #alert(JSON.stringify(_id + ' - ' + @floorplanDevices[_id]))
            @floorplanDevices[_id]["colorOn"] = _onColor
            #@floorplanDevices[_id]["label"] = document.createElementNS('http://www.w3.org/2000/svg', 'text')
            try 
              _format = JSON.parse(_device.format)
              @floorplanDevices[_id]["format"] = _format
            catch err
              _format = {}

            #@floorplanDevices[_id]["meter"] = document.createElement('canvas')

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
                #@_createLabel(_id)
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
                attributeColor = @getAttribute(_id+@colorAttributeExtension)
                attributeState = @getAttribute(_id)
                @floorplanDevices[_id]["colorOn"] = "fill:" + attributeColor.value()
                @_lightOnOff(_id,attributeState.value())
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
                  _selector.text(@_sensorFullValue(_id, attribute.value()))
                _selector.css('fill',_color)
                @_onRemoteStateChange _id

              when 'sensor_gauge'
                #check if extra charts are on the floorplan
                _gauge = _id # + "_bar"
                _tGauge = "#" + _gauge
                if $(_tGauge, @svgRoot)?
                  _isNumber = not Number.isNaN(attribute.value())
                  if _isNumber
                    @_createGauge(_id)
                    @_setGauge(_id, attribute.value())
                    @_onRemoteStateChange _id

              when 'sensor_bar'
                #check if extra charts are on the floorplan
                _bar = _id # + "_bar"
                _tBar = "#" + _bar
                if $(_tBar, @svgRoot)?
                  _isNumber = not Number.isNaN(attribute.value())
                  if _isNumber
                    @floorplanDevices[_id]["height"] = Number $(_tBar, @svgRoot).attr('height')
                    @floorplanDevices[_id]["y"] = Number $(_tBar, @svgRoot).attr('y')
                    @_setBar(_id, attribute.value()) #attribute.value())
                    _x = Number $(_tBar, @svgRoot).attr('x')
                    _y = Number $(_tBar, @svgRoot).attr('y')
                    unless Number.isNaN(_x) or Number.isNaN(_x)
                      @_createLabel(_bar, 0, 0.2)
                      @_setBar(_id, Number attribute.value())
                      @_onRemoteStateChange _id
      )

    _createLabel: (_id, _x, _y) =>
      _xy = @_dom2Svg(_id, _x, _y)
      _text = @floorplanDevices[_id]['label']
      _text.setAttribute('x', _xy.x)
      _text.setAttribute('y', _xy.y)
      _text.style.fill = 'red'
      _text.style.fontFamily = 'Verdana'
      _text.style.fontSize = '3'
      @svgRoot.appendChild(_text)

    GaugeDefaults =
      centerX: 50
      centerY: 50

    getCartesian: (cx, cy, radius, angle) =>
      rad = angle * Math.PI / 180
      return {
        x: Math.round((cx + radius * Math.cos(rad)) * 1000) / 1000
        y: Math.round((cy + radius * Math.sin(rad)) * 1000) / 1000
      }

    getDialCoords: (radius, startAngle, endAngle) =>
      cx = GaugeDefaults.centerX
      cy = GaugeDefaults.centerY
      return {
        end: @getCartesian(cx, cy, radius, endAngle)
        start: @getCartesian(cx, cy, radius, startAngle)
      }
          
    pathString: (radius, startAngle, endAngle, largeArc, x, y) =>
      coords = @getDialCoords(radius, startAngle, endAngle)
      start = coords.start
      end = coords.end
      largeArcFlag = 1 #typeof(largeArc) is "undefined" ? 1 : largeArc
      _result = ["M", x+start.x, y+start.y, "A", radius, radius, 0, largeArcFlag, 1, x+end.x, y+end.y, "Z"].join(" ")
      alert(_result)
      return _result

    _dom2Svg: (_id, _x, _y) =>
      elem = @svgRoot.getElementById(_id)

      _dom = elem.getBoundingClientRect()
      pt = @svgRoot.createSVGPoint()
      pt["x"] = (_dom.x + _dom.width*_x)
      pt["y"] = (_dom.bottom + _dom.height*_y) #+_dom.height/2
      #alert(pt.x+' - '+pt.y)
      svgP = pt.matrixTransform(@svgRoot.getScreenCTM().inverse())
      pt["x"] = (_dom.x)
      pt["y"] = (_dom.y)
      svgP2 = pt.matrixTransform(@svgRoot.getScreenCTM().inverse())
      pt["x"] = (_dom.x+_dom.width)
      pt["y"] = (_dom.y+_dom.height)
      svgP3 = pt.matrixTransform(@svgRoot.getScreenCTM().inverse())

      #alert(svgP3.x+' - '+svgP2.x)

      return 
        x: svgP.x
        y: svgP.y
        width: Math.round(Number svgP3.x - Number svgP2.x)
        height: Math.round(Number svgP3.y - Number svgP2.y)


    _createBar: (_id) =>     
      _xy = @_dom2Svg(_id, 0.5, 0)
      _x = _xy.x
      _y = _xy.y

      _line = document.createElementNS('http://www.w3.org/2000/svg', 'line')
      _line.setAttribute('x1',_x)
      _line.setAttribute('y1',_y)
      _line.setAttribute('x2',_x)
      _line.setAttribute('y2',_y)
      _line.setAttribute('stroke',"red")
      @floorplanDevices[_id]["gauge"] = _line
      _dot = document.createElementNS('http://www.w3.org/2000/svg', 'circle')
      _dot.setAttribute('r',5)
      _dot.setAttribute('fill',"black")
      _dot.setAttribute('cx',_x)
      _dot.setAttribute('cy',_y)
   
      _txtMin = @_createText(_id, -0.1, 0)
      _min = @floorplanDevices[_id].format?.min ? null
      _txtMin.innerHTML = _min if _min?

      _txtMax = @_createText(_id, 1.02, 0)
      _max = @floorplanDevices[_id].format?.max ? null
      _txtMax.innerHTML = _max if _max?

      _txtMid = @_createText(_id, 0.45, -1)
      _maxM = Number _max ? 100
      _minM = Number _min ? 0
      _txtMid.innerHTML = Math.round ((_minM + _maxM) / 2)

      @svgRoot.appendChild(_txtMin)
      @svgRoot.appendChild(_txtMid)
      @svgRoot.appendChild(_txtMax)
      @svgRoot.appendChild(_line)
      @svgRoot.appendChild(_dot)


    _createGauge: (_id) =>     
      ###
      radius = 15
      startAngle = 180
      angle = 180
      flag = 0
      ###

      _xy = @_dom2Svg(_id, 0.5, 0)
      _x = _xy.x
      _y = _xy.y
      _width = _xy.width
      _height = _xy.height

      ###
      _container = document.createElementNS('http://www.w3.org/2000/svg', 'svg')
      _container.setAttribute('width',_xy.width)
      _container.setAttribute('height',_xy.height)
      _container.setAttribute('x',_xy.x)
      _container.setAttribute('y',_xy.y)
      ###

      _line = document.createElementNS('http://www.w3.org/2000/svg', 'line')
      _line.setAttribute('x1',_x)
      _line.setAttribute('y1',_y)
      _line.setAttribute('x2',_x)
      _line.setAttribute('y2',_y)
      _line.setAttribute('stroke',"red")
      @floorplanDevices[_id]["gauge"] = _line
      @floorplanDevices[_id]["radius"] = _height
      _dot = document.createElementNS('http://www.w3.org/2000/svg', 'circle')
      _dot.setAttribute('r',5)
      _dot.setAttribute('fill',"black")
      _dot.setAttribute('cx',_x)
      _dot.setAttribute('cy',_y)
   
      _txtMin = @_createText(_id, -0.1, 0.05, "blue")
      _min = @floorplanDevices[_id].format?.min ? null
      _txtMin.innerHTML = _min if _min?

      _txtMax = @_createText(_id, 1.02, 0.05, "red")
      _max = @floorplanDevices[_id].format?.max ? null
      _txtMax.innerHTML = _max if _max?

      _txtMid = @_createText(_id, 0.45, -1, "green")
      _maxM = Number _max ? 100
      _minM = Number _min ? 0
      _txtMid.innerHTML = Math.round ((_minM + _maxM) / 2)

      _valueLabel = @_createText(_id, 0.4, 0.05, "white")
      _valueLabel.innerHTML = "20"
      #alert(_valueLabel)
      @floorplanDevices[_id]["label"] = _valueLabel

      #@svgRoot.appendChild(_container)
      @svgRoot.appendChild(_line)
      @svgRoot.appendChild(_dot)
      @svgRoot.appendChild(_valueLabel)
      @svgRoot.appendChild(_txtMin)
      @svgRoot.appendChild(_txtMid)
      @svgRoot.appendChild(_txtMax)

    _createText: (_id, _x, _y, _color) =>
      _xy = @_dom2Svg(_id, _x, _y)
      _x = _xy.x
      _y = _xy.y
      _txtLbl = document.createElementNS('http://www.w3.org/2000/svg', 'text')
      _txtLbl.setAttribute('x',_xy.x)
      _txtLbl.setAttribute('y',_xy.y)
      _txtColor = if _color? then _color else "black"
      _txtLbl.style.fill = _txtColor
      _txtLbl.style.fontFamily = 'Verdana'
      _txtLbl.style.fontSize = '3'
      return _txtLbl

    _setGauge: (_id, value) =>
      # value 0=180 -> 40=360
      _format = @floorplanDevices[_id].format if @floorplanDevices[_id].format?
      _min = _format.min ? 0
      _max = _format.max ? 100
      _val = 180 + (value-_min)*180/(_max-_min)
      #alert(@floorplanDevices[_id]["radius"])
      _radius = _format.radius ? (@floorplanDevices[_id]["radius"] ? 15)
    
      _xy = @_dom2Svg(_id, 0.5, 0)
      _line = @floorplanDevices[_id]["gauge"]
      #_radius = @floorplanDevices[_id]["radius"]
      #alert(_radius)
      coords = @getCartesian(_xy.x, _xy.y, _radius, _val)
      _line.setAttribute('x2',coords.x)
      _line.setAttribute('y2',coords.y)
      @floorplanDevices[_id]['label'].innerHTML = @_sensorFullValue(_id,value)


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
        _onColor = @floorplanDevices[_id]["colorOn"]
        $(_tId, @svgRoot).clearQueue()
        $(_tId, @svgRoot).attr('style',_onColor)
        setTimeout( =>
          $(_tId, @svgRoot).attr('style',@buttonOff)
        , 1500)
      else
        $(_tId, @svgRoot).attr('style',@buttonOff)

    _sensorFullValue: (_id, value) =>
      _value = ''
      if @floorplanDevices[_id]['acronym']? then _value += (@floorplanDevices[_id]['acronym'] + " ")
      _value += value
      if @floorplanDevices[_id]['unit']? then _value += (" " + @floorplanDevices[_id]['unit'])
      return _value

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
              $(_tId, @svgRoot).text(@_sensorFullValue(_id, newValue))
            $(_tId, @svgRoot).css('fill',_color)
          when 'sensor_bar'
            #check if extra charts are attached to _tId
            #if @floorplanDevices[_id]["bar"]? and @floorplanDevices[_id]["bar"]
            @_setBar(_id, newValue)
          when 'sensor_gauge'
            t = "Sensor_gauge empty"
            @_setGauge(_id, Number newValue)


    _setBar: (_id, value) =>
      _isNumber = not Number.isNaN(value)
      if _isNumber?
        _tBar = '#' + _id # + "_bar"
        _height = @floorplanDevices[_id]["height"] # Number($(_tId, @svgRoot).attr('height'))
        _y = @floorplanDevices[_id]["y"] # Number($(_tId, @svgRoot).attr('y'))
        _y0 = _y + _height
        _newY = _y0 - _height * value/100
        _newHeight = _height * value/100
        $(_tBar, @svgRoot).attr('y', _newY)
        $(_tBar, @svgRoot).attr('height', _newHeight)
      @floorplanDevices[_id]['label'].innerHTML = @_sensorFullValue(_id,value)


    _onRemoteColorChange: (attributeString) =>
      attributeStringColor = attributeString + @colorAttributeExtension
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
