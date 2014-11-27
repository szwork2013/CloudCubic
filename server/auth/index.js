'use strict';

var express = require('express');
var passport = require('passport');
var config = require('../config/environment');
var User = _u.getModel("user");

// Passport Configuration
require('./local/passport').setup(User, config);
require('./passport');

var router = express.Router();

router.use('/local', require('./local'));

var auth = require("./auth.service")
router.get('/weibo', passport.authenticate('weibo'));
router.get('/weibo/callback', auth.verifyTokenCookie(), function(req, res, next) {
  passport.authenticate('weibo', function(err, user, info) {
    if (err) return res.json(401, error);
    //如果有信息传出，则将信息以cookie的形式传给前端
    if (info) {
      res.cookie('weibo_profile', JSON.stringify(info));
      return res.redirect('/social');
    }

    req.user = user
    auth.setTokenCookie(req, res);
  })(req, res, next);
});

router.get('/qq', passport.authenticate('qq'));
router.get('/qq/callback', auth.verifyTokenCookie(), function(req, res, next) {
  passport.authenticate('qq', function(err, user, info) {
    var error = err || info;
    if (error) return res.json(401, error);
    if (!user) return res.json(404, {message: 'Something went wrong, please try again.'});

    var token = auth.signToken(user._id, user.role);
    res.json({token: token});
  })(req, res, next);
});

module.exports = router;
