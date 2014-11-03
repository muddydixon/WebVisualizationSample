'use strict'
# 描画エリアの情報
margin = new Margin(50)
[width, height] = [900, 700]

#------------------------------------------------------------
#
# ## appendPartition
#
# パーティションをsvgに追加する関数
#
# * @param  svg          d3.selection メインとなるsvg要素
# * @param  data         配列   データの配列
# * @param  attrOrder    配列          要素の順序
# * @return d3.selection パーティションのsvg要素
#
appendPartition = (svg, data, attrOrder)->
  # パーティションを描くsvg要素を作成
  main = svg
    .append("g").attr(
      width: width, height: height
      transform: "translate(" + margin.left + "," + margin.top + ")")

  # 色指定
  color = d3.scale.category10()

  # データを入れ子構造に変換。その際に支払額の集計も行う(rollup)
  nest = d3.nest()
  for attr in attrOrder
    do (attr)->
      nest.key((d)-> d[attr])
  data = nest.rollup((values)-> d3.sum(values, (d)-> d.payment)).entries(users)

  # x/y位置のスケールを作成
  x = d3.scale.linear().range([0, width])
  y = d3.scale.linear().range([0, height])

  # パーティションのlayoutを作成
  # あわせてchildren要素とvalue要素を指定
  partition = d3.layout.partition()
    .children((d)-> d.values)
    .value((d)-> 0|d.values) # 整数化

  # 入れ子のトップを子要素と同じ形式に変形
  root = {key: "全体", values: data}

  # ノードの位置情報を計算
  nodes = partition.nodes(root)

  # ノードの描画
  g = main.selectAll('g').data(nodes).enter().append('g')
    .classed((d)-> "depth#{d.depth}")
    .attr('transform', (d)-> "translate(#{x(d.y)},#{y(d.x)})")
  g.append('rect')
    .attr(
      width: (d)-> d.dy * width
      height: (d)-> d.dx * height
      fill: (d, idx)-> color(d.depth)
      stroke: 'grey'
      'data-val': (d)-> d.value
    )
    .style(
      opacity: (d)-> if d.parent then d.value / d.parent.value else 0.8
      cursor: 'pointer'
    )

  # 桁区切りのフォーマットを作成
  currency = d3.format(",")
  # 属性名と総額を描画
  g.append('text').text((d)-> if d.key then "#{d.key} (#{currency(d.value)}円)" else "" )
    .attr('dy', 12)
    .style('opacity', (d)-> if d.dx * height > 12 then 1 else 0)

  main

#------------------------------------------------------------
#
# ## appendController
#
# コントローラーを追加する
#
# * @param  svg          d3.selection メインとなるsvg要素
# * @param  attrOrder    配列          要素の順序
# * @return d3.selection コントローラのsvg要素
#
appendController = (svg, attrOrder)->
  # 色指定
  color = d3.scale.category10()

  # 「全体」を表す要素を追加
  attrOrderWithTotal = ["全体"].concat(attrOrder)
  # 幅を計算
  w = width / attrOrderWithTotal.length
  # 三角形のpathを生成
  triangle = d3.svg.symbol().type('triangle-up')

  # コントローラのsvg要素を追加
  ctrl = svg
    .append("g").attr(
      width: width, height: margin.top
      transform: "translate(#{margin.left},0)")
  ctrlCell = ctrl.selectAll('g').data(attrOrderWithTotal).enter().append('g')
    .attr('transform', (d, idx)-> "translate(#{idx * w},0)")
  ctrlCell.append('rect')
    .attr(
      width: w
      height: margin.top - 10
      fill: (d, idx)-> color(idx)
      stroke: 'none'
    )
    .style('opacity', 0.5)
  # コントローラの各要素(セル)に左三角と右三角を追加
  ctrlCell.append('path').classed('toLeft', true)
    .attr(
      d: triangle
      transform: "translate(20, 20) rotate(-90)")
    .style(
      cursor: 'pointer'
      opacity: (d, idx)-> if idx <= 1 then 0 else 1)
  ctrlCell.append('path').classed('toRight', true)
    .attr(
      d: triangle
      transform: "translate(#{w - 20}, 20) rotate(90)")
    .style(
      cursor: 'pointer'
      opacity: (d, idx)-> if idx is 0 or idx is attrOrder.length then 0 else 1)

  ctrl

#------------------------------------------------------------
#
# ## パーティション可視化を作成する
#
# * @param  target     文字列 svgを追加するDOM要素
# * @param  data       配列   データの配列
# * @param  attrOrder  配列   要素の順序
# * @return null
#
createExploratoryPartition = (target, data = {}, attrOrder)->
  # svg要素を作成
  svg = d3.select(target).append("svg")
    .attr(
      width: width + margin.width, height: height + margin.height)

  # パーティションを作成する
  main = appendPartition(svg, data, attrOrder)
  # コントローラを作成する
  ctrl = appendController(svg, attrOrder)

  # コントローラからパーティションの順序を入れ替えられるようにする(左要素と入れ替え)
  ctrl.selectAll('path.toLeft').on 'click', (d, idx)->
    attrOrder[idx - 2..idx - 1] = [attrOrder[idx - 1], attrOrder[idx - 2]]
    main.remove()
    main = appendPartition(svg, data, attrOrder)

  # コントローラからパーティションの順序を入れ替えられるようにする(右要素と入れ替え)
  ctrl.selectAll('path.toRight').on 'click', (d, idx)->
    attrOrder[idx - 1..idx] = [attrOrder[idx], attrOrder[idx - 1]]
    main.remove()
    main = appendPartition(svg, data, attrOrder)

#------------------------------------------------------------
#
# # user のデータを作成して、指定した順番に探索的ツリーマップを作成する
#
userNum = 3000
users = [0..userNum - 1].map (d)-> new User()
createExploratoryPartition('body', users, ['campaign', 'gender', 'age', 'job'])
