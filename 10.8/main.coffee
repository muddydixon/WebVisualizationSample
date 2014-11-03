'use strict'
# 描画エリアの情報
margin = new Margin(50)
[width, height] = [1000, 500]

# アニメーション時間
duration = 500

#------------------------------------------------------------
#
# ## normalize
#
# 合計値が1.0になるように正規化した値をnValに追加する
#
# * @param  values  配列
#
normalize = (values)->
  max = d3.max values, (d)-> d.value
  for value in values
    value.nVal = value.value / max
  values

#------------------------------------------------------------
#
# ## drawOpenSpending
#
# 税金はどこに行った風の可視化を作成する関数
#
# * @param  target 文字列 可視化を追加する要素のXPath
# * @param  data   配列   データ配列
#
drawOpenSpending = (target, data)->
  x = d3.scale.ordinal().rangePoints([0, width], 0.3).domain(data.map (d)-> d.key)
  r = width / data.length / 2 * 0.9
  rscale = d3.scale.linear().range([0, r])
    .domain([0, Math.sqrt(d3.extent(data, (d)-> d["支出済額"])[1])])
  color = d3.scale.category20()
  currency = d3.format(',')

  svg = d3.select(target).append('svg')
    .attr('width', width + margin.width + 50).attr('height', height + margin.height)

  # スライダー領域
  slider = svg.append('g').attr
    height: 100
    width: width
    transform: "translate(#{margin.left + 50},#{margin.top})"
  # メイン領域
  main = svg.append('g').attr
    width: width, height: height
    transform: "translate(#{margin.left + 50},#{margin.top + 100})"
  # 詳細領域
  detailmain = svg.append('g').attr
    width: width, height: height
    transform: "translate(#{margin.left},#{margin.top + r * 5 + 100})"

  # メインとなる円を描画
  node = main.selectAll('g.node').data(data).enter().append('g').classed('node', true)
    .attr('transform', (d)-> "translate(#{x(d.key)},#{r})")
  node.append('circle').attr('r', r).attr('fill', 'white')
    .attr('stroke', 'grey').attr('stroke-dasharray', '4,3')
  node.append('circle').attr('r', (d)-> rscale(Math.sqrt(d["支出済額"] or 0)))
    .attr('fill', color(0))

  # 金額・使途のテキスト
  node.append('text').text((d)-> d.key)
    .style('text-anchor', 'middle').attr('dy', - r * 1.1)
  node.append('text').classed("spent", true).style('text-anchor', 'middle').attr('dy', r * 1.3)
    .text((d)-> "¥#{currency(d['支出済額'] or 0)}")

  # 予算との差
  main.append('text').text('支出済額').attr(dx: -r * 2, dy: r * 2.5 + 8, 'font-size': '0.7em')
  main.append('text').text('予算現額').attr(dx: -r * 2, dy: r * 2.5 + 18, 'font-size': '0.7em')
  gap = node.append('g').classed('gap', true)
    .attr('transform', "translate(#{-r},#{r * 1.5})")
  gapBar = gap.selectAll('g').data((d)-> normalize(d3.entries(
    "支出済額": d["支出済額"]
    "予算現額": d["予算現額"]
    ))).enter()
  gapBar.append('rect').attr(
      y: (d, idx)-> 10 * idx
      width: (d)-> d.nVal * 2 * r or 0
      height: 10
      fill: (d)-> color(d.key)
    )
  gapBar.append('text').text((d)-> "¥#{currency(0|(d.value or 0) / 1000)}千円") # 整数化
    .attr('dy', (d, idx)-> 10 * idx + 8).attr('font-size', '0.7em')

  # mouseoverイベントで詳細項目を見られるようにする
  detailx = d3.scale.ordinal().rangePoints([0, width], 0.3)
  node
    .on('mouseover', (d)->
      # 詳細情報の配置を取得
      detailx.domain(d.values.map (dd)-> dd["科目"])

      # circleのfillをリセット
      main.selectAll('.node circle.out').attr('fill', color(0))
      # 新たにクリックされたものに selected クラスをセットし、色みを変更
      d3.select(this).select('.out').attr('fill', 'white')

      # 新たに処理するデータ key として、科目を指定
      detail = detailmain.selectAll('g.detail').data(d.values, (dd)-> dd["科目"])

      # 削除される要素
      detailExit = detail.exit().transition().duration(duration)
        .attr('transform', (dd)-> "translate(#{x(dd['区分'])},#{-r * 3})")
        .style('opacity', 0).remove()

      # 追加される要素
      detailEnter = detail.enter().append('g').classed('detail', true)
        .attr('transform', "translate(#{x(d.key)},#{-r * 1.5})")
        .style('opacity', 0)
      detailEnter.append('circle').attr('r', r * 1.0)
        .attr('fill', 'none').attr('stroke', 'grey').attr('stroke-dasharray', '4,3')
      detailEnter.append('circle').attr('r', (d)-> rscale(Math.sqrt(d["支出済額"])))
        .attr('fill', color(0)).style('opacity', 0.8)
      detailEnter.append('text').text((dd)-> dd["科目"])
        .style('text-anchor', 'middle')
        .attr('dy', -r * 1.1)
      detailEnter.append('text').classed('spent', true).text((dd)-> "¥#{currency(dd['支出済額'])}")
        .style('text-anchor', 'middle')
        .attr('dy',　r * 1.3)
      detailEnter.transition().duration(duration)
        .attr('transform', (dd)-> "translate(#{detailx(dd['科目'])},0)")
        .style('opacity', 1)
    )

  # スライダー
  slider.append('text').classed('income', true).text("¥#{currency(1e6)}")
  slider.append('text').classed('spent', true).text("¥#{currency(0|1e6 * 0.06)}")
    .attr('transform', "translate(#{width * 0.9},0)")
  incomeRate = d3.scale.linear().domain([0, width * 0.6]).rangeRound([1e6, 2e7])
  drag = d3.behavior.drag()
    .on('drag', ()->
      point = d3.select(this)
      mv = +point.attr('cx') + d3.event.dx
      mv = Math.max(0, Math.min(mv, width * 0.6))
      point.attr('cx', mv)
      slider.select('.income').text("¥#{currency(incomeRate(mv))}")
      slider.select('.spent').text("¥#{currency(0|incomeRate(mv) * 0.06)}")
      main.selectAll('text.spent').text((d)->
        "¥#{currency(0|mv / (width * 0.6) * d['支出済額'])}")
      detailmain.selectAll('text.spent').text((d)-> "¥#{currency(0|mv / (width * 0.6) * d['支出済額'])}")
    )
  slideBar = slider.append('g')
    .attr('transform', "translate(#{width * 0.2},0)")
  slideBar.append('rect').attr(
    width: width * 0.6
    height: 10
    rx: 5
    fill: '#CCC'
  )
  slideBar.append('circle').attr(
    cx: 0
    cy: 5
    r: 10
    fill: '#CCC'
    stroke: 'black'
  ).style('cursor', 'move').call(drag)

#------------------------------------------------------------
#
# ## parseData
#
# 歳入歳出データをparseする関数
#
# * @param  text       文字列      歳入歳出のテキストデータ
# * @return オブジェクト 歳入歳出毎のJSONオブジェクト配列のオブジェクト
#
parseData = (text)->
  typeStrs = text.split /\n\n/
  data = {}
  for typeStr in typeStrs
    [typeLabelStr, dataStr...] = typeStr.replace(/\n$/, '').split /\n/
    [label, unit] = typeStr.split /\s+/
    ssv = d3.dsv(" ", "text/ssv")
    if dataStr[dataStr.length - 1].match /^合計/
      dataStr.pop()
    data[label] = d3.nest().key((d)-> d["区分"] or "全体")
      .entries(ssv.parse dataStr.join("\n"))

    # 桁区切りのカンマを除去
    for section in data[label]
      for item in section.values
        for k, v of item
          if v.match(/[\d\,]+/)
            item[k] = +v.replace(/,/g, '')
            section[k] = 0 unless section[k]
            section[k] += item[k]
            data[label][k] = 0 unless data[label][k]
            data[label][k] += item[k]
  data

#------------------------------------------------------------
#
# # 歳入歳出のデータを取得して、税金はどこに行った風の可視化を作成する
#
$.get("./kawasaki.dat").done (text)->
  data = parseData(text)
  drawOpenSpending "body", data["歳出"]
