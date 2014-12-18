'use strict'

express = require 'express'
controller = require './order.controller'
auth = require("../../auth/auth.service")

router = express.Router()

router.post '/', auth.isAuthenticated(), controller.create
router.get '/:id', auth.isAuthenticated(), controller.show
router.get '/:id/pay', auth.isAuthenticated(), controller.pay

# TODO: add auth.isAuthenticated()
router.get '/create_direct_pay_by_user', controller.create_direct_pay_by_user

alipay = require('./alipay_config').alipay;
alipay.route(router);

module.exports = router
