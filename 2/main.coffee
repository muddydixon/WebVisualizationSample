'use strict'
# 描画エリアの情報
margin = new Margin(50)
[width, height] = [400, 300]

#------------------------------------------------------------
#
# ## drawBarchart
#
# 棒グラフを描く
#
# * @param  target   文字列/selection  SVGを追加する要素
# * @param  data     配列              データ配列
#
drawBarchart = (target, data)->
  d3.select(target).append('h2').text("複数の棒グラフ")
  # SVG要素を追加
  svg = d3.select(target).append('svg').attr(
    width: width + margin.width,
    height: height + margin.height
  )
  main = svg.append('g').attr(
    width: width
    height: height
    transform: "translate(#{margin.left},#{margin.top})"
  )
  # 年ごとの配列を作成
  years = d3.range(1940, 1965, 5)

  # 最大値を取得
  max = d3.max data, (d)-> d3.max(years, (dd)-> +d[dd])
  # y軸のスケールを作成
  y = d3.scale.linear().domain([0, max]).range([height, 0])
  # 年ごとのx座標のスケール
  yearx = d3.scale.ordinal().domain(years).rangeBands([0, width], 0.1)
  # 年ごとの幅
  yearW = yearx.rangeBand()
  # ジャンルごとの同一年におけるx座標
  genrex = d3.scale.ordinal().domain(data.map (d)-> d.Genre).rangeBands([0, yearW], 0.1)
  # ジャンルの幅
  barW = genrex.rangeBand()
  # 色
  color = d3.scale.category20()

  # ジャンルごとのグループ要素を作成
  genre = main.selectAll('g.genre').data(data).enter()
    .append('g').classed('genre', true)
    .attr('transform', (d)-> "translate(#{genrex(d.Genre)},0)")
    .attr('fill', (d)-> color(d.Genre))
  # 年のグループ要素を作成
  bar = genre.selectAll('g.bar').data((d)-> delete d.Genre; d3.entries(d)).enter()
    .append('g').classed('bar', true)
    .attr('transform', (d)-> "translate(#{yearx(d.key)},0)")
  # 棒を描画
  rect = bar.append('rect').attr(
    width: barW
    height: (d)-> height - y(+d.value)
    y: (d)-> y(+d.value)
  )

  # 軸を描画
  yaxis = d3.svg.axis().orient('left').scale(y)
  yAxis = main.append('g').call(yaxis).classed('axis', true)
  yearaxis = d3.svg.axis().scale(yearx)
  yearAxis = main.append('g').call(yearaxis).classed('axis', true)
    .attr('transform', "translate(0,#{height})")
  genreaxis = d3.svg.axis().scale(genrex).tickSize(0)
  genreAxis = yearAxis.select('.tick').append('g').call(genreaxis)
    .classed('axis genre', true)

  # 凡例を記載
  genreAxis.selectAll('text')
    .attr('transform', "rotate(-90) translate(5,-44)")
    .style('font-size', '0.9em')
    .style('text-anchor', 'start')


#------------------------------------------------------------
#
# ## drawStackChart
#
# 積み上げグラフを描く
#
# * @param  target   文字列/selection  SVGを追加する要素
# * @param  data     配列              データ配列
#
drawStackChart = (target, data)->
  d3.select(target).append('h2').text("積上(帯)グラフ")
  # SVG要素を追加
  svg = d3.select(target).append('svg').attr(
    width: width + margin.width,
    height: height + margin.height
  )
  main = svg.append('g').attr(
    width: width
    height: height
    transform: "translate(#{margin.left},#{margin.top})"
  )

  # 都市・郊外 / 男性・女性のtypeのラベルわけ
  typeLabels = Object.keys(data[0]).filter((d)-> d isnt "Age")

  # 都市・郊外 / 男性・女性のデータ整理
  type = typeLabels.map (label)->
    label: label
    ages: data.map (d)-> age: d.Age, value: +d[label]

  # stackレイアウト
  stack = d3.layout.stack()
    .values((d)-> d.ages)
    .x((d)-> d.age)
    .y((d)-> d.value)
    .offset('expand')

  # x座標スケール
  x = d3.scale.ordinal().rangeBands([0, width], 0.2).domain(type[0].ages.map (d)-> d.age)
  w = x.rangeBand()
  color = d3.scale.category20()

  # タイプのg要素を作成
  type = main.selectAll('g').data(stack(type)).enter()
    .append('g')
    .attr('fill', (d)-> color(d.label))
  # 個々の要素を描画
  type.selectAll('rect').data((d)-> d.ages).enter()
    .append('rect').attr(
      width: w
      y: (d)-> d.y0 * height
      x: (d)-> x(d.age)
      height: (d)-> d.y * height
    )

  # 軸を描画
  xaxis = d3.svg.axis().scale(x).tickSize(0)
  xAxis = main.append('g').call(xaxis).classed('axis', true)
    .attr('transform', "translate(0,#{height})")
  # ラベルを描画
  type.append('text').text((d)-> d.label).attr(
    dx: 20
    dy: (d)-> d.ages[0].y0 * height + 12
    fill: 'black'
  )

#------------------------------------------------------------
#
# ## drawRadarChart
#
# 弁護士の評価をパラレルチャートで可視化
#
# * @param  target   文字列/selection SVGを追加する要素
# * @param  dataurl  文字列           データのURL
# * @param  opt      オブジェクト      サイズ/マージン
#
drawRadarChart = (target, data, opt = {})->
  d3.select(target).append('h2').text("レーダーチャート")
  opt.margin = opt.margin or new Margin(50)
  opt.width = opt.width or 800
  opt.height = opt.height or 400
  radius = Math.min(opt.width, opt.height) / 2

  # SVG要素を追加
  svg = d3.select(target).append('svg').attr(
    width: opt.width + opt.margin.width,
    height: opt.height + opt.margin.height
  )
  main = svg.append('g').attr(
    width: opt.width
    height: opt.height
    transform: "translate(#{opt.margin.left},#{opt.margin.top})"
  )
  color = d3.scale.category20()

  # 弁護士の評価項目
  labels = Object.keys(data[0].value)

  # 評価項目の偏角座標スケール
  angle = d3.scale.ordinal().rangeBands([-180, 180]).domain(labels)

  # 評価項目ごとの半径座標スケール
  rs = {}
  for label in labels
    rs[label] = d3.scale.linear().range([0, radius])
      .domain(d3.extent(data, (dd)-> dd.value[label]))

  # Lineのデータパスを作成する関数
  line = d3.svg.line.radial().angle((d)-> angle(d.angle) * Math.PI / 180 + Math.PI).radius((d)-> d.r)

  # 評価軸を描画
  for label in labels
    parallel = main.append('g').call(d3.svg.axis().scale(rs[label]).orient('left'))
      .attr(transform: "translate(#{radius}, #{radius}) rotate(#{angle(label)})")
    parallel.selectAll('path,line').attr(
        fill: 'none'
        stroke: 'grey'
      )
    parallel.append('text').text(label).attr(
      transform: "translate(0,#{radius + 16})"
    ).style('text-anchor': 'middle')

  # 弁護士毎の線を描画
  person = main.selectAll('g.person').data(data).enter().append('g').attr(
    class: 'person'
    transform: "translate(#{radius},#{radius})"
  )
  person.append('path').attr(
    d: (d)->
      dat = labels.map (label)-> angle: label, r: rs[label](d.value[label])
      line(dat) + "z"
    stroke: (d)-> color(d.name)
    fill: 'none'
    'data-name': (d)-> d.name
  )

  # 凡例を描画
  people = main.append('g').attr(
    transform: "translate(#{opt.width},0)"
  )
  people.selectAll('text').data(data).enter().append('text').text((d)-> d.name).attr(
    dy: (d, idx)-> 10 * idx
    fill: (d)-> color(d.name)
  ).style('font-size': 8)

#------------------------------------------------------------
#
# ## drawParallelChart
#
# 弁護士の評価をパラレルチャートで可視化
#
# * @param  target   文字列/selection SVGを追加する要素
# * @param  dataurl  文字列           データのURL
# * @param  opt      オブジェクト      サイズ/マージン
#
drawParallelChart = (target, data, opt = {})->
  d3.select(target).append('h2').text("パラレルチャート")
  opt.margin = opt.margin or new Margin(50)
  opt.width = opt.width or 800
  opt.height = opt.height or 400

  # SVG要素を追加
  svg = d3.select(target).append('svg').attr(
    width: opt.width + opt.margin.width,
    height: opt.height + opt.margin.height
  )
  main = svg.append('g').attr(
    width: opt.width
    height: opt.height
    transform: "translate(#{opt.margin.left},#{opt.margin.top})"
  )
  color = d3.scale.category20()

  # 弁護士の評価項目
  labels = Object.keys(data[0].value)

  # 評価項目のx座標スケール
  x = d3.scale.ordinal().rangePoints([0, opt.width], .1).domain(labels)
  # 評価項目ごとのy座標スケール
  ys = {}
  for label in labels
    ys[label] = d3.scale.linear().range([opt.height, 0])
      .domain(d3.extent(data, (dd)-> dd.value[label]))

  # Lineのデータパスを作成する関数
  line = d3.svg.line().x((d)-> x(d.x)).y((d)-> d.y)

  # 評価軸を描画
  for label in labels
    parallel = main.append('g').call(d3.svg.axis().scale(ys[label]).orient('left'))
      .attr(transform: "translate(#{x(label)}, 0)")
    parallel.selectAll('path,line').attr(
        fill: 'none'
        stroke: 'grey'
      )
    parallel.append('text').text(label).attr(
      transform: "translate(0,#{opt.height + 16})"
    ).style('text-anchor': 'middle')

  # 弁護士毎の線を描画
  main.selectAll('path.person').data(data).enter().append('path').attr(
    class: 'person'
    d: (d)->
      dat = labels.map (label)-> x: label, y: ys[label](d.value[label])
      line(dat)
    stroke: (d)-> color(d.name)
    fill: 'none'
    'data-name': (d)-> d.name
  )

  # 凡例を描画
  people = main.append('g').attr(
    transform: "translate(#{opt.width},0)"
  )
  people.selectAll('text').data(data).enter().append('text').text((d)-> d.name).attr(
    dy: (d, idx)->
      lastLabel = "RTEN"
      ys[lastLabel](d.value[lastLabel])
    fill: (d)-> color(d.name)
  ).style('font-size': 8)

#------------------------------------------------------------
#
# # 可視化作成
#
# 棒グラフ
d3.csv "./USPersonalExpenditure2.csv", (data)->
  drawBarchart 'body', data

# 積上グラフ
d3.csv "./VADeaths.csv", (data)->
  drawStackChart 'body', data

# 散布図
d3.csv "./attitude.csv", (data)->

# 米国弁護士評価のレコードを整形する関数
USJudgeRatingsFormat = (d)->
  NAME = d.NAME
  delete d.NAME
  for k, v of d
    d[k] = +v
  {
    name: NAME
    value: d
  }

# レーダーチャート
d3.csv "./USJudgeRatings.csv", USJudgeRatingsFormat, (data)->
  drawRadarChart "body", data, {width: 400, margin: new Margin(50, 300, 50, 50)}

# パラレルチャート
d3.csv "./USJudgeRatings.csv", USJudgeRatingsFormat, (data)->
  drawParallelChart "body", data, {margin: new Margin(50, 300, 50, 50)}
