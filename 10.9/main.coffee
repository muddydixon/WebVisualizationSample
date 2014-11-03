'use strict'
# 描画エリアの情報
margin = new Margin(50, 50, 100)
[width, height] = [500, 300]

#------------------------------------------------------------
#
# ## drawBarChart
#
# 棒グラフを作成する関数
#
# * @param  target        文字列 svgを追加する要素のXPath
# * @param  data          配列   データの配列
# * @param  opt           高さや幅、マージン、タイトルなどの情報
#
drawBarChart = (target, data, opt)->
  # データを降順にソート
  data.sort (a, b)-> b.count - a.count

  # svg要素を作成
  svg = d3.select(target).append('svg')
    .attr('width', opt.width + opt.margin.width)
    .attr('height', opt.height + opt.margin.height)
  main = svg.append('g')
    .attr('width', opt.width)
    .attr('height', opt.height)
    .attr('transform', "translate(#{opt.margin.left},#{opt.margin.top})")

  # 回数の最大値を計算
  countMax = d3.max data, (d)-> +d.count
  # x, y, colorのスケールを作成
  x = d3.scale.ordinal().rangeBands([0, width], 0.1).domain(data.map (d)-> d.word)
  y = d3.scale.linear().domain([0, countMax]).range([height, 0])
  color = d3.scale.category10()

  # 棒グラフの棒を描画
  bar = main.selectAll('g').data(data).enter().append('g')
    .attr('transform', (d)-> "translate(#{x(d.word)},0)")
  # rect要素を作成
  bar.append('rect')
    .attr('width', x.rangeBand())
    .attr('height', (d)-> height - y(d.count))
    .attr('y', (d)-> y(d.count))
    .attr('fill', color(0))

  # 軸を作成
  xaxis = d3.svg.axis().scale(x)
  yaxis = d3.svg.axis().scale(y).orient('left').ticks(4).tickSize(-width)
  xAxis = main.append('g').classed('axis', true).call(xaxis)
    .attr('transform', "translate(0,#{opt.height})")
  yAxis = main.append('g').classed('axis', true).call(yaxis)
  # x軸の文字の角度・位置を調整
  xAxis.selectAll('text').attr('transform', "rotate(-90) translate(-40,-14)")

#------------------------------------------------------------
#
# ## drawForce
#
# 力学グラフを作成する
#
# * @param  target        文字列 svgを追加する要素のXPath
# * @param  data          配列   データの配列
# * @param  opt           高さや幅、マージン、タイトルなどの情報
#
drawForce = (target, data, opt)->
  # svg要素を作成
  svg = d3.select(target).append('svg')
    .attr('width', opt.width + opt.margin.width)
    .attr('height', opt.height + opt.margin.height)
  main = svg.append('g')
    .attr('width', opt.width).attr('height', opt.height)
    .attr('transform', "translate(#{opt.margin.left},#{opt.margin.top})")

  # 力学グラフのlayoutを定義
  force = d3.layout.force()
    .size([opt.width, opt.height])
    .nodes(data.nodes)
    .links(data.links)
    .charge(-120)
    .linkDistance(60)

  # リンクを描画
  link = main.selectAll('.link')
    .data(data.links).enter()
    .append('g').classed('link', true)
  # line要素を作成
  link.append('line')
    .attr('stroke', 'grey').attr('stroke-width', (d)-> d.weight * 20)

  # リンクが結びついていないノードは表示しない
  existsNodeInLink = {}
  for _link in data.links
    existsNodeInLink[_link.target] = true
    existsNodeInLink[_link.source] = true
  existsNodes = data.nodes.filter((d, idx)-> existsNodeInLink[idx])
  # ノード(円・テキスト)を描画
  node = main.selectAll('.node')
    .data(existsNodes).enter()
    .append('g').classed('node', true)
  # circle要素を作成
  node.append('circle')
    .attr('cx', (d)-> d.x).attr('cy', (d)-> d.y)
    .attr('r', (d)-> Math.sqrt(d.cnt * 2))
    .attr('fill', (d)-> 'white').attr('stroke', 'grey')
    .call(force.drag)
  # text要素を作成
  node.append('text').text((d)-> d.name)
    .attr('dx', (d)-> d.x).attr('dy', (d)-> d.y)

  # 演算過程の関数を定義
  tick = ()->
    link.select('line')
      .attr('x1', (d)-> d.source.x).attr('x2', (d)-> d.target.x)
      .attr('y1', (d)-> d.source.y).attr('y2', (d)-> d.target.y)

    node.select('circle')
      .attr('cx', (d)-> d.x).attr('cy', (d)-> d.y)
    node.select('text')
      .attr('dx', (d)-> d.x).attr('dy', (d)-> d.y)

  # 演算過程の関数を指定
  force.on('tick', tick)
  # 演算開始
  force.start()

#------------------------------------------------------------
#
# 単語の回数を読み込んで棒グラフを作成
#
d3.tsv "./alice_word_count.tsv", (data)->
  drawBarChart('body', data, {
    width: width
    height: height
    margin: margin
  })

#------------------------------------------------------------
#
# 単語の共起関係をもとにしたデータから力学グラフを作成
#
d3.json "./alice_wordnet.json", (data)->
  drawForce('body', data, {
    width: width
    height: height
    margin: margin
  })
