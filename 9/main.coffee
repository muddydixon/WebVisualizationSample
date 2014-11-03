'use strict'
# 描画エリアの情報
[width, height] = [800, 400]

#------------------------------------------------------------
#
# ## drawSVGCoordinate
#
# Web(SVG)における座標系について
#
# * @param  svg          d3.selection メインとなるsvg要素
# * @param  size         オブジェクト   SVG要素のサイズ
#
drawSVGCoordinate = (target, size)->
  d3.select(target).append('h2').text("Web(SVG)における座標系について")
  # SVG要素を追加
  svg = d3.select(target).append('svg').attr(
    width: size.width
    height: size.height
  )
  # 枠線
  svg.append('rect').attr(
    width: size.width, height: size.height,
    rx: 5, ry: 5, fill: 'none', stroke: 'grey')

  # x軸のスケール作成→SVGの軸を作成→g要素に作用させる
  xScale   = d3.scale.identity().domain([0, width])
  xAxisSvg = d3.svg.axis().scale(xScale).ticks(20).tickFormat((d)-> "#{d}px")
  xAxis    = svg.append('g').attr(transform: "translate(0,50)")
    .call(xAxisSvg)
  xAxis.selectAll('path,line').attr(stroke: 'grey', fill: 'none')

  # y軸のスケール作成→SVGの軸を作成→g要素に作用させる
  yScale   = d3.scale.identity().range([0, height])
  yAxisSvg = d3.svg.axis().orient('right').scale(yScale).tickFormat((d)-> "#{d}px")
  yAxis    = svg.append('g').attr(transform: "translate(50,0)")
    .call(yAxisSvg)
  yAxis.selectAll('path,line').attr(stroke: 'grey', fill: 'none')

  # selectで軸のラベル(text)の最初の要素だけ取得し、少し内側に移動させる
  xAxis.select('text').attr(dx: 20)
  yAxis.select('text').attr(dy: 20)

  # 円を描く
  svg.append('circle').attr(
    cx: 50, cy: 50, r: 15, fill: 'green', stroke: 'orange', 'stroke-width': 5
    cursor: 'pointer', opacity: 0.7
  )

#------------------------------------------------------------
#
# ## drawSVGCoordinate
#
# 代表的なSVG要素を描画
#
# * @param  svg          d3.selection メインとなるsvg要素
# * @param  size         オブジェクト   SVG要素のサイズ
#
drawSVGElement = (target, size)->
  d3.select(target).append('h2').text("代表的なSVG要素を描画")
  # SVG要素を追加
  svg = d3.select(target).append('svg').attr(
    width: size.width
    height: size.height
  )
  # 枠線
  svg.append('rect').attr(
    width: size.width, height: size.height,
    rx: 5, ry: 5, fill: 'none', stroke: 'grey')
  # x軸のスケール作成→SVGの軸を作成→g要素に作用させる
  xScale   = d3.scale.identity().domain([0, width])
  xAxisSvg = d3.svg.axis().scale(xScale).ticks(20).tickSize(-size.height).tickFormat(null)
  xAxis    = svg.append('g').attr(transform: "translate(0,#{height})")
    .call(xAxisSvg)
  xAxis.selectAll('path,line').attr(stroke: '#DDDDDD', fill: 'none')

  # y軸のスケール作成→SVGの軸を作成→g要素に作用させる
  yScale   = d3.scale.identity().range([0, height])
  yAxisSvg = d3.svg.axis().orient('right').scale(yScale).tickSize(-size.width).tickFormat(null)
  yAxis    = svg.append('g').attr(transform: "translate(#{width},0)")
    .call(yAxisSvg)
  yAxis.selectAll('path,line').attr(stroke: '#DDDDDD', fill: 'none')

    # カラーパレット(定性的な軸の一種)
  color = d3.scale.category20()

  circle = svg.append('g')
  circleAttr =
    cx: 50, cy: 50, r: 20
    fill: color('circle-fill'), stroke: color('circle-stroke'), 'stroke-width': 10
  circle.append('circle').attr(circleAttr)
  circle.append('text').text(JSON.stringify(circleAttr)).attr(dx: 50, dy: 50)

  rect = svg.append('g')
  rectAttr =
    x: 50, y: 100, width: 50, height: 100
    fill: color('rect-fill'), stroke: color('rect-stroke'), 'stroke-width': 0
  rect.append('rect').attr(rectAttr)
  rect.append('text').text(JSON.stringify(rectAttr)).attr(dx: 50, dy: 100)

  rect2 = svg.append('g')
  rect2Attr =
    x: 250, y: 150, width: 100, height: 50
    fill: color('rect-fill'), stroke: color('rect-stroke'), 'stroke-width': 10
  rect2.append('rect').attr(rect2Attr)
  rect2.append('text').text(JSON.stringify(rect2Attr)).attr(dx: 250, dy: 150)

  ellipse = svg.append('g')
  ellipseAttr =
    cx: 150, cy: 250, rx: 25, ry: 50
    fill: color('ellipse-fill'), stroke: color('ellipse-stroke'), 'stroke-width': 10
  ellipse.append('ellipse').attr(ellipseAttr)
  ellipse.append('text').text(JSON.stringify(ellipseAttr)).attr(dx: 150, dy: 250)

#------------------------------------------------------------
#
# ## drawBubbleChart
#
drawBubbleChart = (target, size)->
  d3.select(target).append('h2').text("バブルチャートを通して学ぶD3の基礎")
  # 円の半径
  r = 15

  # 配色リスト
  colors = ["green", "red", "orange", "blue", "yellow", "cyan", "grey", "magenta", "purple", "brown", "black"];

  # データ作成
  data = d3.range(0, 10).map (d)->
    cx: 0|Math.random() * width
    cy: 0|Math.random() * height
    r: 0|(Math.random() * r + r)

  # svg要素を追加するターゲットとなる要素を取得
  div = d3.select('body')
  # svg要素の追加
  svg = div.append('svg')
  # svg要素の属性(width, height)をセット
  svg.attr('width', size.width)
    .attr('height', size.height)

  # circleのセレクションを取得
  circleSelection = svg.selectAll('circle')
  # セレクションにデータをセット
  circleSelectionWithData = circleSelection.data(data)
  # セレクションのうち、新規に追加されたセレクションを取得
  circleWithNewData = circleSelectionWithData.enter()
  circle = circleWithNewData.append('circle')
  circle
    .attr('r', (d)-> d.r)  # 半径を指定
    .attr(                 # オブジェクトを渡して一括でセットも可能
      cx: (d)-> d.cx
      cy: (d)-> d.cy
    )
    .attr('fill', (d, idx)-> colors[idx % colors.length])


#------------------------------------------------------------
#
# # 可視化作成
#
drawSVGCoordinate('body', {width: width, height: height})
drawSVGElement('body', {width: width, height: height})
drawBubbleChart('body', {width: width, height: height})
