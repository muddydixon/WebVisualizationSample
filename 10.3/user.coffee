'use strict'
############################################################
#
# User情報を作成するclass
#
# サンプルデータ作成用のユーザクラス
window.User = class User
  # 支払いのベース額
  @basePayment: d3.random.normal(500)
  # 基本属性 ([rate, payFactor])
  @attributes:
    gender:
      "男性": [0.6, 0.2], "女性": [0.4, 0.4]
    age:
      "10代": [0.05, 0.3], "20代": [0.2, 0.2]
      "30代": [0.3, 0.3], "40代": [0.3, 0.5]
      "50代": [0.1, 0.7], "60代": [0.05, 0.7]
    job:
      "その他": [0.05, 0.1], "会社員": [0.4, 0.3]
      "専業主婦": [0.05, 0.6], "自営業": [0.1, 0.3]
      "学生": [0.15, 0.3], "無職": [0.1, 0.1]
      "フリーター": [0.15, 0.1]
  # キャンペーン
  @campaigns:
    "キャンペーン 1": [0.25, 0.2], "キャンペーン 2": [0.25, 0.4]
    "キャンペーン 3": [0.25, 0.1], "キャンペーン 4": [0.25, 0.5]

  constructor: ()->
    # キャンペーンを決定
    [campaign, payFactor] = @_selectAttr(User.campaigns)
    @campaign = campaign
    @payFactor = payFactor

    # 各種属性を決定
    for attrType, attrs of User.attributes
      [attr, payFactor] = @_selectAttr(attrs)
      this[attrType] = attr
      @payFactor += payFactor

    @payment = @payFactor * User.basePayment()

  # 選択肢からひとつ選ぶメソッド
  _selectAttr: (attrs)->
    r = Math.random()
    cumulate = 0
    for attr, [prob, payFactor] of attrs
      cumulate += prob
      if r < cumulate
        return [attr, payFactor]
