'use strict'
# 描画エリアの情報
margin = new Margin(50)
[width,height] = [800, 800]

#------------------------------------------------------------
#
# ## HeatTable
#
# ヒートマップ(テーブル)を作成するクラス
#
class HeatTable
  #
  # ### constructor
  #
  # コンストラクタ
  #
  # * @param  target 文字列      ヒートマップを追加する要素のXPath
  # * @param  opt    オブジェクト オプション
  #
  constructor: (target, @opt = {})->
    @target = d3.select(target)
    @margin = @opt.margin or new Margin(50)
    @width  = @opt.width or width
    @height = @opt.height or height

    @table = @target.append('div')
      .attr(
        width: @width + @margin.width
        height: @height + @margin.height)
      .append('table').attr(
        width: @width
        height: @height).style('margin', "#{margin}")

  #
  # ### draw
  #
  # 描画を行うメソッド
  #
  # * @param 配列   データの配列(1レコード目がheader、2レコード目以降がデータ)
  #
  draw: ([headerData, data...])->
    # 行数、列数を取得
    [rnum, cnum] = [data.length + 1, d3.max data, (d)-> d.length]

    # セルの高さと幅を計算
    cellSize =
      height: @height / rnum
      width:  @width  / cnum

    # 割合を表示する場合
    if @opt.ratio
      rsum = data.map (d)-> d3.sum d[1...cnum], (dd)-> +dd
      color = d3.scale.linear().domain([0, 1]).range(['white', 'red'])
      percent = d3.format('.1%')
    else
    # 割合を表示しない場合
      max = d3.max(data, (d)-> d3.max(d[1...cnum], (dd)-> +dd))
      color = d3.scale.linear().domain([0, max]).range(['white', 'red'])

    # header行を追加
    headerRow = @table.append('tr')
    headerCell = headerRow.selectAll('th').data(headerData).enter()
      .append('th').text((d)-> d).attr('width', cellSize.width)
      .style('border', '1px solid grey')

    # データを追加
    data.forEach (rowDat, rid)=>
      row = @table.append('tr').attr('height', cellSize.height)
      cell = row.selectAll('td').data(rowDat).enter().append('td')
        .style('border', '1px solid grey').style('text-align', 'center')

      if @opt.ratio
        cell.style('background', (d, idx)-> if idx > 0 then color(d / rsum[rid]) else "#EFEFEF")
        cell.text((d, idx)-> if idx is 0 then d else percent(d / rsum[rid]))
      else
        cell.style('background', (d, idx)-> if idx > 0 then color(d) else "#EFEFEF")
        cell.text((d, idx)-> d)

#------------------------------------------------------------
#
# 各課金額のUU数のデータを読み込みヒートマップのデータを読み込み
# ヒートマップを作成する
#
$.get("./monthly_heatmap.tsv").done (data)->
  data = data.split(/\n/).map (d)-> d.split(/\s*\t\s*/)
  table = new HeatTable('body').draw(data)

  table = new HeatTable('body',
    ratio: true
  ).draw(data)
