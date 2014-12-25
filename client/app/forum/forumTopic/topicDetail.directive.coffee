'use strict'

angular.module('budweiserApp')

.directive 'topicDetail', ->
  restrict: 'E'
  replace: true
  controller: 'TopicDetailCtrl'
  templateUrl: 'app/forum/forumTopic/topicDetail.template.html'
  scope:
    topic: '='
    activeReply: '@'

.controller 'TopicDetailCtrl', ($scope, Auth, Restangular, $timeout, $document, $state, $modal)->
  angular.extend $scope,

    me: Auth.getCurrentUser()

    newReply: {}
    replying: false

    replyTo: (topic, reply)->
      # validate
      @replying = true
      reply.type = Const.CommentType.DisTopic
      reply.belongTo = topic._id
      Restangular.all('comments').post reply
      .then (comment)->
        topic.$comments.splice 0, 0, comment
        $scope.initMyReply()
        $scope.replying = false
        $scope.activeReply = comment._id

    initMyReply: ()->
      @newReply = {} if !@newReply
      @newReply.content = ''
      @newReply.metadata = {}

    toggleLike: (topic)->
      topic.one('vote').post()
      .then (res)->
        topic.voteUpUsers = res.voteUpUsers

    toggleVote: (reply)->
      reply.one('vote').post()
      .then (res)->
        reply.voteUpUsers = res.voteUpUsers

    deleteReply: (topic, reply)->
      $modal.open
        templateUrl: 'components/modal/messageModal.html'
        controller: 'MessageModalCtrl'
        resolve:
          title: -> '删除回复？'
          message: -> "删除后将无法恢复！"
      .result.then ->
        reply.remove()
        .then ()->
          topic.$comments.splice topic.$comments.indexOf(reply), 1

    repliesFilter: (item)->
      switch $scope.viewState.filterMethod
        when 'all'
          return true
        when 'createdByMe'
          return item.postBy._id is $scope.me._id
      return true

    scrollToEditor: ()->
      $document.scrollToElement(angular.element('.new-reply-right'), 200, 200)

  $scope.$on 'message.notice', (event, raw)->
    switch raw.type
      when Const.NoticeType.TopicVoteUp
        if raw.data.disTopic._id is $scope.topic._id
          $scope.topic.voteUpUsers = raw.data.disTopic.voteUpUsers
      when Const.NoticeType.ReplyVoteUp
        myReplie = $scope.topic.$comments.filter (item)->
          item._id is raw.data.disReply._id
        if myReplie?.length
          myReplie[0].voteUpUsers = raw.data.disReply.voteUpUsers

  $scope.$watch 'activeReply', (value)->
    if value
      $timeout ->
        targetElement = angular.element(document.getElementById value)
        targetElement.addClass('active')
        windowHeight = $(window).height();
        $document.scrollToElement(targetElement, windowHeight/2, 500)
        $timeout ->
          targetElement.removeClass('active')
        , 1000
      , 100

