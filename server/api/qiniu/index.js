(function() {
  'use strict';
  var auth, config, controller, express, qiniu, router;

  qiniu = require('qiniu');

  express = require('express');

  controller = require('./qiniu_controller');

  config = require('../../config/environment');

  auth = require('../../auth/auth.service');

  router = express.Router();

  router.get('/uptoken', auth.isAuthenticated(), controller.uptoken);

  router.get('/signedUrl/:id', auth.isAuthenticated(), controller.signedUrl);

  module.exports = router;

}).call(this);

//# sourceMappingURL=index.js.map