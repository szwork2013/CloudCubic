'use strict'

angular.module('budweiserApp')

.directive 'questionLibrary', ->
  restrict: 'EA'
  replace: true
  controller: 'QuestionLibraryCtrl'
  templateUrl: 'app/teacher/teacherLecture/questionLibrary.html'
  scope:
    lecture: '='
    keyPoints: '='
    categoryId: '='

.controller 'QuestionLibraryCtrl', (
  $scope
  $state
  $modal
  $rootScope
  Restangular
  messageModal
) ->

  angular.extend $scope,
    questions: null
    selectedKeyPoints: []
    pageSize: 10
    totalItems: 0
    currentPage: 1
    keyword: ''
    $state: $state

    getSelectedNum: ->
      _.reduce $scope.questions, (sum, q) ->
        sum + (if q.$selected then 1 else 0)
      , 0

    toggleSelectAll: (selected) ->
      angular.forEach $scope.questions, (q) -> q.$selected = selected if !q.$exists

    toggleKeyPoint: (keyPoint) ->
      keyPoint.$selected = !keyPoint.$selected
      $scope.selectedKeyPoints = _.filter $scope.keyPoints, (k) -> k.$selected
      $scope.searchQuestions()

    removeQuestion: (question = null) ->
      messageModal.open
        title: -> '删除题库中的问题'
        message: ->
          if question?
            """确认要删除题库中的问题？"""
          else
            """确认要删除题库中的这#{$scope.getSelectedNum()}个问题？"""
      .result.then ->
        questions = $scope.questions
        $scope.selectedAll = false if $scope.selectedAll
        deleteQuestions =
          if question?
            [question]
          else
            _.filter questions, (q) -> q.$selected == true
        $scope.deleting = true
        Restangular.all('questions').customPOST(ids: _.pluck(deleteQuestions, '_id'), 'multiDelete')
        .then ->
          $scope.deleting = false
          angular.forEach deleteQuestions, (q) ->
            questions.splice(questions.indexOf(q), 1)
          $scope.pageChange()

    addNewQuestion: ->
      $modal.open
        templateUrl: 'app/teacher/teacherLecture/newQuestion.html'
        controller: 'NewQuestionCtrl'
        windowClass: 'new-question-modal'
        backdrop: 'static'
        resolve:
          keyPoints: -> $scope.keyPoints
          categoryId: -> $scope.categoryId._id ? $scope.categoryId
      .result.then (question) ->
        Restangular
        .all('questions')
        .post(question)
        .then $scope.pageChange

    addToLecture: ->
      $scope.updating = true

      $rootScope.$broadcast 'add-library-question', $state.params.questionType,
        _.filter $scope.questions, (q) -> q.$selected

    pageChange: ->
      loadedItems = $scope.currentPage * $scope.pageSize
      $scope.searchQuestions(true) if $scope.questions.length < loadedItems

    searchQuestions: (loadMore = false) ->
      Restangular.all('questions').getList(
        from: (if loadMore then $scope.questions.length else 0)
        limit: ($scope.pageSize + if loadMore then 0 else 1)
        categoryId: $scope.categoryId._id ? $scope.categoryId
        keyword: $scope.keyword
        sort: JSON.stringify {created: 1}
        keyPointIds: JSON.stringify _.pluck($scope.selectedKeyPoints, '_id')
      ).then (questions) ->
        currentQuestions = _.pluck $scope.lecture?[$state.params.questionType], '_id'
        angular.forEach questions, (q) ->
          q.$exists = currentQuestions.indexOf(q._id) >= 0
        $scope.questions =
          if loadMore
            _.union $scope.questions, questions, '_id'
          else
            questions
        $scope.totalItems = questions.$count

  $scope.$watch 'categoryId', (value)->
    $scope.searchQuestions() if value
