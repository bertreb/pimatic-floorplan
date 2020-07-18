$(document).on 'templateinit', (event) ->

  # define the item class
  class FloorplanItem extends pimatic.DeviceItem
    constructor: (templData, @device) ->
      super(templData, @device)

      @id = templData.deviceId
      @td = templData
      @floorplan = @device.config.floorplan

      @switchOff = "fill:#000000"
      @switchOn = "fill:#00dd00"
      @presenceOff = 'fill:#000000'
      @presenceOn = 'fill:#dd0000'
      @buttonOff = 'fill:#000000'
      @buttonOn = 'fill:#0000dd'
      @lightOff = 'fill:#000000'
      @lightOn = 'fill:#dddd00'


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
          _tId = "#" + _id
          switch _device.type
            when 'switch'
              if attribute.value()
                $(_tId, @svgRoot).attr('style', @switchOn)
              else            
                $(_tId, @svgRoot).attr('style', @switchOff)
              
              $(_tId, @svgRoot).on("click", (e)=>
                _tId = "#" + e.target.id
                _clickedElement = $(_tId, @svgRoot)
                if _clickedElement.attr("style") == @switchOn
                  _clickedElement.attr('style', @switchOff)
                  @_setState(e.target.id, false)
                else            
                  _clickedElement.attr('style', @switchOn)
                  @_setState(e.target.id, true)
              )
              @_onRemoteChange _id

            when 'button'
              $(_tId, @svgRoot).attr('style', @buttonOff)
              $(_tId, @svgRoot).on("mousedown", (e)=>
                _tId = "#" + e.target.id
                _clickedElement = $(_tId, @svgRoot)
                _clickedElement.attr('style', @buttonOn)
                @_setButton(e.target.id)
              )
              @_onRemoteChange _id

            when 'light'
              $(_tId, @svgRoot).attr('style', 'fill:'+attribute.value())
              $(_tId, @svgRoot).on("click", (e)=>
                _tId = "#" + e.target.id
                _clickedElement = $(_tId, @svgRoot)
                @_setLight(e.target.id, true)
              )
              @_onRemoteChange _id

            when 'presence'
              if attribute.value()
                $(_tId, @svgRoot).attr('style',@presenceOn)
              else            
                $(_tId, @svgRoot).attr('style',@presenceOff)
              @_onRemoteChange _id

            when 'string' 
              @[_id] = ko.observable attribute.value()
              attribute.value.subscribe (newValue) =>
                $(_tId, @svgRoot).text(newValue)
      )


    _onLocalChange: (element, fn) ->
      timeout = 500 # ms

      # only execute one command at the time
      # delay the callback to protect the device against overflow
      queue = async.queue((arg, cb) =>
        fn.call(@, arg)
        .done( (data) ->
          ajaxShowToast(data)
          setTimeout cb, timeout
        )
        .fail( (data) ->
          ajaxAlertFail(data)
          setTimeout cb, timeout
        )
      , 1) # concurrency

      $("#"+element, @svgRoot).on("click", (e, payload) =>       
        #return if payload?.origin is 'remote'
        #return if @[element]?() is $(e.target).val()
        # flush queue to do not pile up commands
        # latest command has highest priority
        queue.kill() if queue.length() > 2
        queue.push $(e.target).val()
      
      )

    _onRemoteChange: (attributeString) =>
      attribute = @getAttribute(attributeString)

      unless attributeString?
        throw new Error("The floorplan device needs an #{attributeString} attribute!")

      @[attributeString] = ko.observable attribute.value()
      attribute.value.subscribe (newValue) =>
        _tId = "#" + attributeString
        switch @floorplanDevices[attributeString].type
          when 'switch'          
            if newValue
              $(_tId, @svgRoot).attr('style',@switchOn)
            else
              $(_tId, @svgRoot).attr('style',@switchOff)
          when 'button'
            $(_tId, @svgRoot).attr('style',@buttonOn)
            setTimeout(=>
              $(_tId, @svgRoot).attr('style',@buttonOff)
            ,1000)
          when 'presence'       
            if newValue
              $(_tId, @svgRoot).attr('style',@presenceOn)
            else
              $(_tId, @svgRoot).attr('style',@presenceOff)
          when 'light'
            @lightOn = 'fill:'+newValue
            $(_tId, @svgRoot).attr('style',@lightOn)

    _setState: (_id, _state) ->
      @device.rest.setState {id:_id, state:_state}, global: no

    _setButton: (_id) ->
      @device.rest.buttonPressed {buttonId:_id}, global: no

    _setLight: (_id, _lightState) ->
      @device.rest.setLight {id: _id, state: _lightState}, global: no

  # register the item-class
  pimatic.templateClasses['floorplan'] = FloorplanItem
