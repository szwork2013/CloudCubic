"use strict"

express = require("express")
controller = require("./lecture.controller")
auth = require("../../auth/auth.service")

router = express.Router()

router.get '/', controller.index
router.get '/:id', auth.isAuthenticated(false), controller.show
router.post '/', auth.hasRole('teacher'), controller.create
router.put '/:id', auth.hasRole('teacher'), controller.update
router.patch '/:id', auth.hasRole('teacher'), controller.update
router.delete '/:id', auth.hasRole('teacher'), controller.destroy

module.exports = router
