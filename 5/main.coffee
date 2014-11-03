'use strict'
# 描画エリアの情報
margin = new Margin(50)
[width, height] = [400, 400]

# ヒト型のパス
path = "M200,369 L200,575 L139,575 L139,370 L124,370 L124,575 L63,575 L63,369 L63,194 L47,194 L47,345 L5,345 L5,192 C5,167 26,140 51,140 L212,140 C238,140 258,169 258,194 L258,345 L216,345 L216,194 L200,194 L200,369 zM131,5 C95,5 65,35 65,72 C65,109 95,139 131,139 C168,139 198,109 198,72 C198,35 168,5 131,5 z"

#------------------------------------------------------------
#
# ## drawPerson
#
# ヒト型のグラフを描く
#
# * @param  target  文字列 SVGを追加する要素
# * @param  data    配列   データ
#
drawPerson = (target, data)->
  # x軸スケール、y軸スケール
  x = d3.scale.ordinal().rangeBands([0, 400], .2).domain(data.map (d)-> d.name)
  y = d3.scale.linear().range([height, 0]).domain([0, d3.max(data, (d)-> d.value)])
  # 色スケール
  color = d3.scale.category10()

  # ヒト型のSVG要素を適用させる関数
  person = (g)->
    g.each ()->
      d3.select(this).append('path').attr('d', path)
        .attr('transform', (d)-> "scale(#{(height - y(d.value)) / 575})")

  # SVG要素を追加
  svg = d3.select(target).append('svg').attr(
    width: width + margin.width
    height: height + margin.height
  )
  main = svg.append('g').attr(
    width: width, height: height
    transform: "translate(#{margin.left},#{margin.top})"
  )

  # y軸 (目盛線)
  main.append('g').call(
    d3.svg.axis().scale(y).orient('left').tickSize(- width)
  ).selectAll('line,path').attr(fill: 'none', stroke: 'grey')

  # ラベル
  xLabel = main.append('text').text('ユーザタイプ')
    .attr('transform', "translate(#{width / 2},#{height + 20})")
    .style('text-anchor', 'middle')
  yLabel = main.append('text').text('人数')
    .attr('transform', "rotate(-90) translate(#{-height / 2},-30)")

  # ヒト型をプロット
  main.selectAll('g.person').data(data).enter().append('g').attr(class: 'person')
    .call(person).attr(
      transform: (d, idx)-> "translate(#{x(d.name)},#{y(d.value)})"
    )
    .attr('fill', (d, idx)-> color(idx))

#------------------------------------------------------------
#
# # データを渡してヒト型を描画
#
drawPerson('body', [{name: "A", value: 20}, {name: "B", value: 40}])
