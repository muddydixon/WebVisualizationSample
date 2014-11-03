'use strict'
# 描画エリアの情報
margin = new Margin(50, 100)
[width, height] = [600, 400]

#------------------------------------------------------------
#
# ## drawBoxPlot
#
# データを読み込んで、両箱ひげ図を作成する
#
# * @param  svg          d3.selection メインとなるsvg要素
# * @param  data         配列   データの配列
#
drawBoxPlot = (target, data)->
  monthlyData = d3.nest().key((d)-> d.Month).entries(data)

  # svg要素を作成
  svg = d3.select(target).append("svg").attr(
    width: width + margin.width
    height: height + margin.height
  )
  main = svg.append("g").attr(
    width: width
    height: height
    transform: "translate(" + margin.left + "," + margin.top + ")"
  )

  labels = monthlyData.map (d)-> d.key

  # データのスケール・軸を作成
  x = d3.scale.ordinal().domain(labels).rangePoints([0, width], 1)
  yDomain = d3.extent data, (d)-> +d.Wind
  y = d3.scale.linear().domain([0, yDomain[1]]).range([height, 0])
  xaxis = d3.svg.axis().scale(x).tickFormat((d)-> "#{d}月")
  main.append('g').call(xaxis).classed('axis', true).attr(transform: "translate(0,#{height})")
  yaxis = d3.svg.axis().scale(y).orient('left').tickSize(- width)
  main.append('g').call(yaxis).classed('axis', true)
  main.append('text').text('Wind')
    .attr('transform', "rotate(-90) translate(#{- height / 2},#{- margin.top})")

  # 色スケール
  color = d3.scale.category20()

  # 箱ひげ図のsvgを作成
  boxSymbol = d3.svg.box().scale(y).value((d)-> +d.Wind).withHist(true)

  # 箱ひげ図のg要素
  box = main.selectAll('g.month').data(monthlyData).enter()
    .append('g').attr(
      class: 'month'
      stroke: (d)-> color(d.key)
      'stroke-width': 2
    )
  box.append('g')
    .attr('transform', (d, idx)-> "translate(#{x(d.key) - boxSymbol.width() / 2},0)")
    .datum((d)-> d.values).call(boxSymbol)

#------------------------------------------------------------
#
# ## drawBiBoxPlot
#
# データを読み込んで、両箱ひげ図を作成する
#
# * @param  svg          d3.selection メインとなるsvg要素
# * @param  data         配列   データの配列
#
drawBiBoxPlot = (target, data)->
  monthlyData = d3.nest().key((d)-> d.Month).entries(data)

  # 両箱ひげ図のsvg要素
  svg = d3.select(target).append("svg").attr(
    width: width + margin.width
    height: height + margin.height
  )
  main = svg.append("g").attr(
    width: width
    height: height
    transform: "translate(" + margin.left + "," + margin.top + ")"
  )

  # データのスケール・軸を作成
  xDomain = d3.extent data, (d)-> +d.Temp
  x = d3.scale.linear().domain(xDomain).range([0, width])
  xaxis = d3.svg.axis().scale(x)
  yDomain = d3.extent data, (d)-> +d.Wind
  y = d3.scale.linear().domain([0, yDomain[1]]).range([height, 0])
  yaxis = d3.svg.axis().scale(y).orient('left').tickSize(- width)

  # 軸を描画
  main.append('g').call(xaxis).classed('axis', true).attr('transform', "translate(0,#{height})")
  main.append('g').call(yaxis).classed('axis', true)
  main.append('text').text('Temp')
    .attr('transform', "translate(#{width / 2},#{height + margin.top - 12})")
  main.append('text').text('Wind')
    .attr('transform', "rotate(-90) translate(#{- height / 2},#{- margin.top})")

  # 色スケール
  color = d3.scale.category20()

  # 両箱ひげ図のsvgを作成
  biboxSymbol = d3.svg.bibox().x(x).y(y)
    .valueX((d)-> +d.Temp).valueY((d)-> +d.Wind)

  # 両箱ひげ図のg要素
  bibox = main.selectAll('g.month').data(monthlyData).enter()
    .append('g').attr(
      class: 'month'
      stroke: (d)-> color(d.key)
      'stroke-width': 2
    )
  bibox.append('g')
    .datum((d)-> d.values).call(biboxSymbol)

  # ラベル
  bibox.append('text').text((d)-> "#{d.key}月")
    .attr(
      dx: 10
      dy: (d, idx)-> 20 + 20 * idx
      fill: (d)-> color(d.key)
      stroke: 'none'
      'font-size': 20
    )

#------------------------------------------------------------
#
# 箱ひげ図・両箱ひげ図を作成
#
d3.csv './airquality.csv', (data)->
  drawBoxPlot('body', data)
  drawBiBoxPlot('body', data)
