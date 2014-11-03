'use strict'
# 描画エリアの情報
margin = new Margin(50, 100)
[width, height] = [600, 400]

#------------------------------------------------------------
#
# ## changeBubbleOpacityByDay
#
# ある日の折線グラフをマウスオーバー/マウスアウトした時のハンドラ
# 対応する日付のバブルチャートのバブルの透明度だけを1に、それ以外を0.1にする
#
# * @param  day         オブジェクト   折線グラフでマウスオーバーされた日付データ
# * @param  bubbleChart d3.selection バブルチャートのsvg要素
# * @return null
#
changeBubbleOpacityByDay = (day, bubbleChart = d3.select('#bounce_and_elapse'))->
  if day?
    bubbleChart.selectAll('g.day')
      .style('opacity', 0.1)
    bubbleChart.selectAll("g.day.d#{new Date(day.key).getTime()}")
      .style('opacity', (d)-> 1.0)
  else
    bubbleChart.selectAll('g.day')
      .style('opacity', 1.0)

#------------------------------------------------------------
#
# ## drawScatterPlot
#
# バブルチャート作成関数
#
# * @param  target       文字列 バブルチャートを追加する要素のXPah
# * @param  data         配列   データの配列
# * @return d3.selection バブルチャートのsvg要素
#
drawScatterPlot = (target, data)->
  # svg要素を作成
  svg = d3.select(target).append("svg")
    .attr(
      width: width + margin.width
      height: height + margin.height
    )
  main = svg
    .append("g").attr(
      width: width
      height: height
      transform: "translate(#{margin.left},#{margin.top})"
    )

  # x軸、y軸の最大値を取得
  xmax = d3.max(data.map((d)-> d3.max(d.values, (e)-> e.values.elapse)))
  ymax = d3.max(data.map((d)-> d3.max(d.values, (e)->
    if +e.key is 19 then 0 else e.values.bounce / e.values.visitor)))
  rmax = d3.max(data.map((d)-> d3.max(d.values, (e)->
    if +e.key is 19 then 0 else e.values.visitor)))

  # x軸、y軸、半径、色のスケール
  x = d3.scale.linear().range([0, width]).domain([0, xmax])
  y = d3.scale.linear().range([height, 0]).domain([0, ymax])
  r = d3.scale.linear().range([1, 100]).domain([0, rmax])
  color = d3.scale.category20()

  # 日毎のg要素を作成
  day = main.selectAll('g.day').data(data).enter().append('g')
    .attr('class', (d)-> "day d#{new Date(d.key).getTime()}")

  # バブルのg要素を作成
  bubble = day.selectAll('g.bubble').data((d)-> d.values).enter()
    .append('g').attr(
      class: 'bubble'
      transform: (d)-> "translate(#{x(d.values.elapse)},#{y(d.values.bounce / d.values.visitor)})"
    )
  bubble.append('circle')
    .attr(
      r: (d)-> Math.sqrt(r(d.values.visitor))
      fill: (d)-> if +d.key is 19 then 'none' else color(d.key)
      stroke: 'grey')
    .style('opacity', 0.8)
  bubble.append('text').text((d)-> d.key)
    .attr(dy: 3).style('text-anchor', 'middle')

  # x軸、y軸を作成
  xaxis = d3.svg.axis().scale(x).tickFormat((d)-> "#{d}秒")
  yaxis = d3.svg.axis().orient("left").scale(y).tickFormat(d3.format("%"))
  xAxis = main.append('g').attr('class', 'axis').call(xaxis)
    .attr('transform', "translate(0, #{height})")
  yAxis = main.append('g').attr('class', 'axis').call(yaxis)

  # x軸、y軸のタイトルを作成
  xtitle = main.append('text').text('ステージプレイ時間')
    .attr('transform', "translate(#{width / 2}, #{height + 40})")
  ytitle = main.append('text').text('離脱率')
    .attr('transform', "rotate(-90) translate(#{- height / 2}, #{-60})")

  # バブルの大きさの凡例を作成
  raxis = d3.svg.axis().scale(r)
  legend = main.append('g')
  legend.selectAll('circle').data(d3.range(0, 0|rmax, (0|rmax) / 3)).enter().append('circle')
    .attr(
      r: (d)-> Math.sqrt(r(d))
      cx: (d, idx)-> 30
      cy: (d, idx)-> 20 * idx
      fill: 'none'
      stroke: 'grey')
  legend.selectAll('text').data(d3.range(0, 0|rmax, (0|rmax) / 3)).enter().append('text')
    .text((d)-> (0|d)+"人")
    .attr(
      dx: 50
      dy: (d, idx)-> 20 * idx + 5
      fill: 'none'
      stroke: 'grey')

  main

#------------------------------------------------------------
#
# ## drawSurviveLineChart
#
# 日毎の残存率の折線グラフを作成する関数
#
# * @param  target        文字列        svgを追加する要素のXPath
# * @param  data          配列          データの配列
# * @param  bubbleChart   d3.selection バブルチャートのsvg要素
#
drawSurviveLineChart = (target, data, bubbleChart)->
  # svg要素を作成
  svg = d3.select(target).append("svg")
    .attr(
      width: width + margin.width
      height: height + margin.height)
    .append("g").attr(
      width: width
      height: height
      transform: "translate(" + margin.left + "," + margin.top + ")")

  # x軸、y軸の範囲を取得
  xExtent = d3.extent data[0].values, (d)-> +d.key
  yExtent = d3.extent data[0].values, (d)-> d.surviveRate
  # x軸、y軸のスケールを作成
  x = d3.scale.linear().domain(xExtent).range([0, width])
  y = d3.scale.linear().range([height, 0])

  # 線分群のpathを作成する関数
  line = d3.svg.line().x((d)-> x(+d.key))
  # 透明度のスケールを作成
  opacities = d3.time.scale().domain([new Date(data[0].key), new Date()]).range([0, 1])

  # 日毎に折線を描画
  data.forEach (day, idx)->
    initVisitor = day.values[0].values.visitor
    line.y((d)-> y(d.values.visitor / initVisitor))
    path = svg.datum(day.values)
      .append('path')
      .attr(
        d: line
        fill: 'none'
        stroke: 'grey'
        'stroke-width': 3)
      .style('opacity', opacities(new Date(day.key)))
    # 折線をマウスオーバー、マウスアウトした時にバブルチャートをハイライトするイベントを追加
    if bubbleChart
      path
        .on('mouseover', ()-> changeBubbleOpacityByDay(day, bubbleChart))
        .on('mouseout', ()-> changeBubbleOpacityByDay(null, bubbleChart))

  # x軸、y軸を作成
  xaxis = d3.svg.axis().scale(x)
  yaxis = d3.svg.axis().scale(y).orient('left').tickFormat(d3.format('%'))
  xAxis = svg.append('g').classed('axis', true).call(xaxis).attr('transform', "translate(0,#{height})")
  yAxis = svg.append('g').classed('axis', true).call(yaxis)

  # x軸、y軸のタイトルを作成
  xtitle = svg.append('text').text('ステージ番号').attr('transform', "translate(#{width / 2}, #{height + 40})")
  ytitle = svg.append('text').text('残存率').attr('transform', "rotate(-90) translate(#{- height / 2}, #{-60})")


#------------------------------------------------------------
#
# サンプルのチュートリアルのアクセスログデータを作成し、
# これの日毎の各ステージ突入ユーザ数を折線グラフで、
# 各ステージのクリアにかかった時間と離脱率をバブルチャートで
# 表現する可視化を作成
#

# ログデータ数
recordNum = 10000
# ゲームのサンプルログを生成
gameLog = getSampleData(recordNum)

# ユーザIdでまとめあげてセッションに変換(代数処理)
users = d3.nest()
  .key((d)-> d.userId)
  .map(gameLog)

# ユーザごとのセッションにステージ処理時間や離脱のフラグを追加
for userId, session of users
  for stage, sid in session
    if session[sid + 1]?
      stage.elapse = (new Date(session[sid + 1].time) - new Date(stage.time)) / 1000
      stage.bounce = 0
    else
      stage.bounce = 1
      stage.elapse = 0

# 日毎・ステージごとにまとめあげ(代数・統計処理)
data = d3.nest()
  .key((d)-> d3.time.day(d.time))
  .sortKeys((a, b)-> new Date(b).getTime() - new Date(a).getTime())
  .key((d)-> d.stageId)
  .rollup((vals)->
    {
      visitor: vals.length
      elapse: d3.mean(vals.filter((d)-> d.elapse > 0), (d)-> d.elapse) or 0
      bounce: d3.sum(vals, (d)-> d.bounce)
    }
    )
  .entries(gameLog)

# 散布図描画
bubbleChart = drawScatterPlot("#bounce_and_elapse", data)
# 生存曲線描画
drawSurviveLineChart("#bounce_by_data", data, bubbleChart)
