"use strict"

express = require("express")
controller = require("./wechat.controller")
auth = require("../../auth/auth.service")
router = express.Router()

#扩展api
router.all "/", controller.save
router.get  "/list", controller.index

module.exports = router
