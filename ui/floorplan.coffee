$(document).on 'templateinit', (event) ->

  # define the item class
  class FloorplanItem extends pimatic.DeviceItem
    constructor: (templData, @device) ->
      super(templData, @device)

      @id = templData.deviceId
      @td = templData
      @floorplan = @device.config.floorplan

      @switchOn = 'fill:green'
      @switchOff = 'fill:#ddd'
      @lightOn = 'fill:yellow'
      @lightOff = 'fill:#000'
      @presenceOn = 'fill:red'
      @presenceOff = 'fill:#ddd'

      @floorplanDevices = {}
      for _dev, i in @device.config.devices
        @floorplanDevices[_dev.pimatic_device_id+'_'+_dev.pimatic_attribute_name] = @device.config.devices[i]

      ###
      #@getAttribute("state").value.subscribe( =>
      #  alert("ok")
      #  @updateClass()
      #)
      ###
      ###
      $.ajax(
        url: @floorplan
        success: (data)=>
          $(@svgRoot).append($( ".result" ).html( data ))
          alert(JSON.stringify(data,null,2))
      )
      ###


    afterRender: (elements) =>
      super(elements)
      ### Apply UI elements ###
      
      a = document.getElementById(@id)
      a.addEventListener("load",() =>
        svgDoc = a.contentDocument #get the inner DOM of alpha.svg
        @svgRoot = svgDoc.documentElement

        for i, _device of @floorplanDevices
          #_idP = _device.pimatic_device_id + "_" + _device.pimatic_attribute_name
          _id = _device.pimatic_device_id + "_" + _device.pimatic_attribute_name
          #alert(_id)
          attribute = @getAttribute(_id)
          _tIdSwitch = "#" + _id
          #alert(_id)
          _selectedElement = $(_tIdSwitch, @svgRoot)
          switch _device.type
            when 'switch'
              if attribute.value()
                _selectedElement.attr('style', @switchOn)
              else            
                _selectedElement.attr('style', @switchOff)
              
              _selectedElement.on("click", (e)=>
                _tId = "#" + e.target.id
                _clickedElement = $(_tId,@svgRoot)
                if _clickedElement.attr("style") == @switchOn
                  _clickedElement.attr('style', @switchOff)
                  @_setState(e.target.id, false)
                else            
                  _clickedElement.attr('style', @switchOn)
                  @_setState(e.target.id, true)
              )
              @_onRemoteChange _id
            when 'button'
              _selectedElement.attr('style', @switchOff)
              #alert("button")
              _selectedElement.on("mousedown", (e)=>
                _tId = "#" + e.target.id
                _clickedElement = $(_tId,@svgRoot)
                _clickedElement.attr('style', @switchOn)
                @_setButton(e.target.id)
              )
              @_onRemoteChange _id
            when 'light'
              if attribute.value()
                _selectedElement.attr('style', @lightOn)
              else            
                _selectedElement.attr('style', @lightOff)
              _selectedElement.on("click", (e)=>
                _tId = "#" + e.target.id
                _clickedElement = $(e.target)
                #_clickedElement = $(_tId,@svgRoot)
                #if _clickedElement.attr("style") is @lightOff or _clickedElement.attr("style") is '#000000'
                #  #_clickedElement.attr('style', @lightOff)
                @_setLight(e.target.id, true)
                #  #else            
                #  #_clickedElement.attr('style', @lightOn)
                #  #@_setLight(e.target.id, false)
              )
              @_onRemoteChange _id
            when 'presence'
              if attribute.value()
                _selectedElement.attr('style',@presenceOn)
              else            
                _selectedElement.attr('style',@presenceOff)
              @_onRemoteChange _id
            when 'string' 
              @[_id] = ko.observable attribute.value()
              #_selectedElement.text("")
              attribute.value.subscribe (newValue) =>
                _selectedElement.text(newValue)
      )

    updateClass: ->
      alert("updateClass and return, no action")
      return
      value = @getAttribute('t').value()
      if @presenceEle?
        switch value
          when true
            @presenceEle.addClass('value-present')
            @presenceEle.removeClass('value-absent')
          when false
            @presenceEle.removeClass('value-present')
            @presenceEle.addClass('value-absent')
          else
            @presenceEle.removeClass('value-absent')
            @presenceEle.removeClass('value-present')
        return

      #jQuery.get("floorplan.svg", (data)=>
      #  $( ".result" ).html( data );
      #  alert(JSON.stringify(data,null,2))
      #)

      #@svgRoot  = @svgDoc.documentElement;

      #@circle = @fp.find("#path10").attr("id")
      #@test = @fp.contents().find("canvas").attr({"fill":"lime"})
      #svg = $(elements).find('floorplan')

      ###
      mySVG = $(elements).getElementById("floorplan")
      mySVG.addEventListener("load", ()=>
        svgDoc = mySVG.contentDocument
        if svgDoc?
          alert("SVG contentDocument Loaded! " + JSON.stringify(svgDoc,null,2))
          #alert("SVG contentDocument Loaded! " + JSON.stringify(elements,null,2))
      , false)
      ###
      #@floorplan.visible = false;
      #@floorplan = @floorplan0.find('.text4631-4');
      #@floorplan.text = "Hallo";
      #console.log("@floorplan "+JSON.stringify(@floorplan,null,2));


      ###
      @powerSlider.flipswitch()
      $(elements).find('.ui-flipswitch').addClass('no-carousel-slide')

      @brightnessSlider = $(elements).find('.light-brightness')
      @brightnessSlider.slider()
      $(elements).find('.ui-slider').addClass('no-carousel-slide')

      @colorPicker = $(elements).find('.light-color')
      @colorPicker.spectrum
        preferredFormat: 'hex'
        showButtons: false
        allowEmpty: true
        move: (color) =>
          return @colorPicker.val(null).change() unless color
          @colorPicker.val("##{color.toHex()}").change()

      @colorPicker.on 'change', (e, payload) =>
        return if payload?.origin unless 'remote'
        @colorPicker.spectrum 'set', $(e.target).val()

      @_onLocalChange 'power', @_setPower
      @_onLocalChange 'brightness', @_setBrightness
      @_onLocalChange 'color', @_setColor
      ###
      ### React on remote user input ###

      ###
      @_onRemoteChange 'power', @powerSlider
      @_onRemoteChange 'brightness', @brightnessSlider
      @_onRemoteChange 'color', @colorPicker

      @colorPicker.spectrum('set', @color())
      @brightnessSlider.val(@brightness()).trigger 'change', [origin: 'remote']
      @powerSlider.val(@power()).trigger 'change', [origin: 'remote']
      ###

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
            $(_tId, @svgRoot).attr('style',@switchOn)
            setTimeout(=>
              $(_tId, @svgRoot).attr('style',@switchOff)
            ,2000)
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

    _setColor: (_id, colorCode) ->
      unless colorCode
        @device.rest.setWhite {}, global: no
      else
        @device.rest.setColor {colorCode: colorCode},  global: no

    _setLight: (_id, _lightState) ->
      @device.rest.setLight {id: _id, state: _lightState}, global: no

  # register the item-class
  pimatic.templateClasses['floorplan'] = FloorplanItem
