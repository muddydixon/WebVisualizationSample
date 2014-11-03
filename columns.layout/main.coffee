'use strict'
# 描画エリアの情報
margin = new Margin(50)
[width, height] = [700, 300]

#============================================================
#
# ## 円グラフを描くための d3.layout.pie()
#
do ()->
  # marginと半径の指定
  margin = new Margin(50)
  radius = 100

  # サンプルデータ
  data = [
    { "sales": 30, "name": "label 0"},
    { "sales":  8, "name": "label 1"},
    { "sales": 68, "name": "label 2"},
    { "sales": 52, "name": "label 3"},
    { "sales": 43, "name": "label 4"},
  ]
  # 配色
  color = d3.scale.category10()

  # 円弧のパス作成のユーティリティ関数
  arc = d3.svg.arc().outerRadius(radius)

  # svg要素を作成
  svg = d3.select('body').append('svg')
    .attr('width', radius * 2 + margin.width)
    .attr('height', radius * 2 + margin.height)
    .append('g')
    .attr('width', radius)
    .attr('height', radius)
    .attr('transform', "translate(#{radius + margin.left},#{radius + margin.top})")

  # pie レイアウトの定義
  pie = d3.layout.pie().value((d)-> d.sales).sort(()->)

  # データに基づき円弧を描画
  svg.selectAll('path.pie').data(pie(data)).enter()
    .append('path').classed('pie', true).attr('d', (d)-> a = arc(d); a).attr('fill', (d, idx)-> color(idx))

  # 半円のためのsvg要素を作成
  svg2 = d3.select('body').append('svg')
    .attr('width', radius * 2 + margin.width)
    .attr('height', radius * 2 + margin.height)
    .append('g')
    .attr('width', radius)
    .attr('height', radius)
    .attr('transform', "translate(#{radius + margin.left},#{radius + margin.top})")

  # 半円の pie レイアウトの定義
  halfpie = d3.layout.pie().value((d)-> d.sales).sort(undefined)
    .startAngle(-Math.PI / 2).endAngle(Math.PI / 2)

  # データに基づき円弧を描画
  svg2.selectAll('path.halfpie').data(halfpie(data)).enter()
    .append('path').classed('halfpie', true).attr('d', (d)-> a = arc(d); a).attr('fill', (d, idx)-> color(idx))

#============================================================
#
# ## クラスターを描くための d3.layout.cluster()
#
do ()->
  # marginと半径の指定
  margin = new Margin(50)
  [width, height] = [300, 200]

  # サンプルデータ
  data = [
    { "sales": 30, "name": "label 0", "type": 1},
    { "sales":  8, "name": "label 1", "type": 2},
    { "sales": 68, "name": "label 2", "type": 1},
    { "sales": 52, "name": "label 3", "type": 2},
    { "sales": 43, "name": "label 4", "type": 2},
  ]
  # 入れ子に集計(代数処理)
  nestedData = d3.nest().key((d)-> d.type).entries(data)
  # 配色
  color = d3.scale.linear().domain(d3.extent(data, (d)-> d.sales)).range(['#333', '#CCC'])

  # svg要素を作成
  svg = d3.select('body').append('svg')
    .attr('width', width + margin.width)
    .attr('height', height + margin.height)
    .append('g')
    .attr('width', width)
    .attr('height', height)
    .attr('transform', "translate(#{margin.left},#{margin.top})")

  # cluster レイアウトの定義
  cluster = d3.layout.cluster().size([width, height])
    .value((d)-> d.sales).children((d)-> d.values)
  # nodes / links を計算
  nodes = cluster.nodes({name: "root", values: nestedData})
  links = cluster.links(nodes)

  # リンクのpath作成のユーティリティ
  diagonal = d3.svg.diagonal()

  # データに基づきリンクを描画
  link = svg.selectAll('g.link').data(links).enter().append('g').classed('link', true)
  link.append('path').attr('d', diagonal).attr('fill', 'none').attr('stroke', 'grey')

  # データに基づきノードを描画
  node = svg.selectAll('g.node').data(nodes).enter().append('g').classed('node', true)
  node.append('circle').attr('cx', (d)-> d.x).attr('cy', (d)-> d.y).attr('r', 10)

  # 転置した樹形図のためのsvgを作成
  svg2 = d3.select('body').append('svg')
    .attr('width', width + margin.width)
    .attr('height', height + margin.height)
    .append('g')
    .attr('width', width)
    .attr('height', height)
    .attr('transform', "translate(#{margin.left},#{margin.top})")

  # 転置するための cluster レイアウトを定義 (width, heightが入れ替わっている)
  clusterTranspose = d3.layout.cluster()
    .size([height, width])
    .value((d)-> d.sales).children((d)-> d.values)
  # nodes / links を計算
  nodes = clusterTranspose.nodes({name: "root", values: nestedData})
  links = clusterTranspose.links(nodes)

  # リンクのpath作成のユーティリティ
  diagonal = d3.svg.diagonal().projection((d)-> [d.y, d.x])

  # データに基づきリンクを描画
  link = svg2.selectAll('g.link').data(links).enter().append('g').classed('link', true)
  link.append('path').attr('d', diagonal).attr('fill', 'none').attr('stroke', 'grey')

  # データに基づきノードを描画　(cx, cyが入れ替わっている)
  node = svg2.selectAll('g.node').data(nodes).enter().append('g').classed('node', true)
  node.append('circle').attr('cx', (d)-> d.y).attr('cy', (d)-> d.x).attr('r', 10)
    .attr('fill', (d)-> color(d.value)).attr('stroke', 'black')
