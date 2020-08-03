module.exports = {
  title: "pimatic-floorplan config options"
  Floorplan: {
    type: "object"
    extensions: ["xAttributeOptions"]
    properties:{
      floorplan:
        description: "the sgv filename with the floorplan"
        type: "string"
      devices:
        description: "list of devices used in the floorplan"
        format: "table"
        type: "array"
        default: []
        required: ["name", "type", "pimatic_device_id"]
        items:
          type: "object"
          properties:
            name:
              description: "Name of pimatic divice on the floorplan"
              type: "string"
            svgId:
              description: "The svg ID of the pimatic device"
              type: "string"
            type:
              description: "The gui type of the pimatic device"
              enum: ["switch","button","presence","contact","light","shutter","sensor","sensor_bar","sensor_gauge"]
            pimatic_device_id:
              descpription: "The pimatic device Id"
              type: "string"
            pimatic_attribute_name:
              description: "The attribute name of the Pimatic device like state, presence or temperature"
              type: "string"
            acronym:
              description: "Add acronym before sensor value (if available)"
              type: "string"
              required: false
            unit:
              description: "Add unit after sensor value (if available)"
              type: "string"
              required: false
            format:
              description: "Json string with extra formatting of devices like colors for states, min and max value for gauge or bar"
              type: "string"
    }
  }
}
