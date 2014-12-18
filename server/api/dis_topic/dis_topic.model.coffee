'use strict'

mongoose = require('mongoose')
Schema = mongoose.Schema
ObjectId = Schema.Types.ObjectId

BaseModel = (require '../../common/BaseModel').BaseModel

exports.DisTopic = BaseModel.subclass
  classname: 'DisTopic'
  populates:
    index: [
      path: 'postBy', select: 'name avatar'
    ]
    show: [
      path: 'postBy', select: 'name avatar'
    ]
    create: [
      path: 'postBy', select: 'name avatar'
    ]

  initialize: ($super) ->
    @schema = new Schema
      postBy:
        type: ObjectId
        ref: 'user'
        required: true
      forumId:
        type: ObjectId
        ref: 'forum'
        required: true
      title:
        type: String
        required: true
      content:
        type: String
        required: true
      metadata: Schema.Types.Mixed
#        images: [
#          type: String
#        ]
#        tags: [
#          type: String
#        ]
      repliesNum:
        type: Number
        default: 0
      viewersNum:
        type: Number
        default: 0
      voteUpUsers: [
        type: ObjectId
        ref: 'user'
      ]

    $super()
