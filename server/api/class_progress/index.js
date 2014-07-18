(function() {
  'use strict';
  var controller, express, router;

  express = require('express');

  controller = require('./class_progress.controller');

  router = express.Router();

  router.get('/', controller.index);

  router.get('/:id', controller.show);

  router.post('/', controller.create);

  router.put('/:id', controller.update);

  router.patch('/:id', controller.update);

  router["delete"]('/:id', controller.destroy);

  module.exports = router;

}).call(this);

//# sourceMappingURL=index.js.map