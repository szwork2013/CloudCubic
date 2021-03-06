'use strict'

path = require 'path'
_ = require 'lodash'

requiredProcessEnv = (name) ->
  if not process.env[name]
    throw new Error 'You must set the ' + name + ' environment variable'
  process.env[name]

# All configurations will extend these options
# ============================================
all =
  appName: 'budweiser'

  morgan:
    accessLog: '/data/log/budweiser.access.log'

  env: process.env.NODE_ENV

  # Root path of server
  root: path.normalize __dirname + '/../../..'

  # Server port
  port: process.env.PORT or 9000

  # Should we populate the DB with sample data?
  seedDB: false

  # Secret for session
  secrets:
    session: process.env.EXPRESS_SECRET or 'budweiser-secret'

  # List of user roles
  userRoles: ['student', 'teacher', 'admin', 'superuser']

  # MongoDB connection options
  mongo:
    options:
      db:
        safe: true

# Export the config object based on the NODE_ENV
# ==============================================
module.exports = _.merge all, require('./' + process.env.NODE_ENV + '.js') or {}
