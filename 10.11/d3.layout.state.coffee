d3.layout.state = ()->
  state = {}
  event = d3.dispatch "start", "tick", "end"
  nodes = []
  nodeLabels = []
  links = []
  value = (d)-> d
  label = (d)-> d
  width = 0
  height = 0
  drag = undefined
  alpha = undefined


  state.tick = ()->

  state.alpha = (_alpha)->
    alpha unless _alpha
    _alpha = +_alpha
    if alpha
      if _alpha > 0
        alpha = _alpha
      else
        alpha = 0
    else if _alpha > 0
      event.start(type: 'start', alpha: alpha = _alpha)
      d3.timer(state.tick)
    state

  state.size = (_width, _height)->
    width = _width
    height = _height
    state

  state.nodes = (_nodes)->
    nodes unless _nodes
    throw new Error("nodes should be an array") unless _nodes instanceof Array
    nodes = _nodes
    state

  state.links = (_links)->
    links unless _links
    throw new Error("links should be an array") unless _links instanceof Array
    links = _links
    state

  state.value = (_value)->
    value unless _value
    throw new Error("value should be a function") if typeof _value isnt 'function'
    value = _value
    state

  state.label = (_label)->
    label unless _label
    throw new Error("label should be a function") if typeof _label isnt 'function'
    label = _label
    state

  state.start = ()->
    nodeLabels = nodes.map (d)-> label(d)
    for node, idx in nodes
      node.x = node.x or Math.random() * width
      # node.y = Math.random() * height
      node.y = node.y or idx * height / nodes.length
    for link in links
      link.source = nodes[link.source] if typeof link.source is 'number'
      link.source = nodes[nodeLabels.indexOf(link.source)] if typeof link.source is 'string'
      link.target = nodes[link.target] if typeof link.target is 'number'
      link.target = nodes[nodeLabels.indexOf(link.target)] if typeof link.target is 'string'

    state.resume()

  d3_layout_stateDragstart = (d)->
    d.fixed |= 2
  d3_layout_stateDragend = (d)->
    d.fixed &= ~6
  d3_layout_stateMouseover = (d)->
    d.fixed |= 4
    d.px = d.x
    d.py = d.y
  d3_layout_stateMouseout = (d)->
    d.fixed &= ~4
  dragmove = (d)->
    d.px = d3.event.x
    d.py = d3.event.y
    state.resume()

  state.drag = ()->
    unless drag
      drag = d3.behavior.drag()
        .origin((d)-> d)
        .on('dragstart.state', d3_layout_stateDragstart)
        .on('drag.state', dragmove)
        .on('dragend.state', d3_layout_stateDragend)

    drag unless arguments.length
    this
      .on('mouseover.state', d3_layout_stateMouseover)
      .on('mouseout.state', d3_layout_stateMouseout)
      .call(drag)

  state.resume = ()->
    state.alpha(.1)

  state.stop = ()->
    state.alpha(0)

  d3.rebind state, event, 'on'
