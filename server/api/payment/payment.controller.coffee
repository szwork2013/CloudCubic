"use strict"

alipay = require('./alipay_config').alipay;

alipay
.on 'verify_fail', ()->
  console.log('emit verify_fail')
.on 'create_direct_pay_by_user_trade_finished', (out_trade_no, trade_no)->
  console.log('create_direct_pay_by_user_trade_finished')
.on 'create_direct_pay_by_user_trade_success', (out_trade_no, trade_no)->
  console.log('create_direct_pay_by_user_trade_success')


exports.create_direct_pay_by_user = (req, res, next)->
  data =
    out_trade_no:req.query.out_trade_no
    subject:req.query.subject
    total_fee:req.query.total_fee
    body: req.query.body
    show_url:req.query.show_url

  console.log data

  alipay.create_direct_pay_by_user(data, res);
  console.log 'create_direct_pay_by_user'
#  res.send "sucess"