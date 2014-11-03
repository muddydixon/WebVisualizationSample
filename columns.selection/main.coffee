margin = new Margin(50)
[width, height] = [300, 200]

addExitEnterUpdate = ()->
  color = d3.scale.category20()
  svg = d3.select('body').append('svg').attr(
    width: width + margin.width
    height: height + margin.height)
  main = svg.append('g').attr(
    width: width
    height: height
    transform: "translate(#{margin.left},#{margin.top})"
  )

  dom = main.append('g').attr transform: "translate(100, 100)"
  dom.append('circle').attr(
    r: 100
    stroke: color(0)
    fill: color(1)
    ).style('opacity', 0.5)
  dom.append('text').text('selectionのDOM').style('text-anchor', 'middle').attr(
    dy: -100
    stroke: color(0)
  )

  data = main.append('g').attr(transform: "translate(200, 100)")
  data.append('circle').attr(
    r: 100
    stroke: color(2)
    fill: color(3)
  ).style('opacity', 0.5)
  data.append('text').text('データ').style('text-anchor', 'middle').attr(
    dy: -100
    stroke: color(2))

  main.append('text').text('update').style('text-anchor', 'middle').attr(
    dx: width / 2
    dy: height / 2
    stroke: color(4)
  )
  main.append('text').text('exit').style('text-anchor', 'middle').attr(
    dx: 100 - 50
    dy: height / 2
    stroke: color(0)
  )
  main.append('text').text('enter').style('text-anchor', 'middle').attr(
    dx: 200 + 50
    dy: height / 2
    stroke: color(2)
  )

addExitEnterUpdate()
