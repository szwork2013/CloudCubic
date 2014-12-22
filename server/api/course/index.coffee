"use strict"

express = require("express")
controller = require("./course.controller")
auth = require("../../auth/auth.service")
router = express.Router()

# course
router.get "/", controller.index
router.get "/:id", auth.isAuthenticated(), controller.show
router.get "/:id/public", controller.publicShow
router.post "/", auth.hasRole("teacher"), controller.create
router.put "/:id", auth.hasRole("teacher"), controller.update
router.patch "/:id", auth.hasRole("teacher"), controller.update
router.delete '/:id', auth.hasRole('teacher'), controller.destroy

module.exports = router
