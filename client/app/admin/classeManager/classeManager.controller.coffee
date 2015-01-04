'use strict'

angular.module('budweiserApp')

.controller 'ClasseManagerCtrl', (
  $state
  $scope
  $modal
  Courses
  Restangular
) ->

  angular.extend $scope,
    classes: null
    other:
      _id: ''
      name: '未分班的学生'

    selectedClasse: null

    search:
      keyword: $state.params.keyword

    pageConf:
      maxSize      : 5
      currentPage  : $state.params.page ? 1
      itemsPerPage : 9

    createNewClasse: ->
      $modal.open
        templateUrl: 'app/admin/classeManager/editClasseModal.html'
        controller: 'EditClasseModalCtrl'
        resolve:
          Courses: -> Courses
          Classe: ->
            name: ''
            price: 0
            enrollment: {}
            duration: {}
      .result.then (newClasse) ->
        $scope.classes.splice 0, 0, newClasse

    deleteClasse: (classe) ->
      $modal.open
        templateUrl: 'components/modal/messageModal.html'
        controller: 'MessageModalCtrl'
        size: 'sm'
        resolve:
          title: -> "删除班级"
          message: ->
            """确认要删除班级"#{classe.name}"吗？"""
      .result.then ->
        Restangular
        .one('classes', classe._id)
        .remove()
        .then ->
          index = $scope.classes.indexOf(classe)
          $scope.classes.splice(index, 1)

    editClasse: (classe) ->
      $modal.open
        templateUrl: 'app/admin/classeManager/editClasseModal.html'
        controller: 'EditClasseModalCtrl'
        resolve:
          Courses: -> Courses
          Classe: -> angular.copy(classe)
      .result.then (dbClasse) ->
        angular.extend classe, dbClasse

    setKeyword: ($event) ->
      if $event.keyCode isnt 13 then return
      $state.go('admin.classeManager', {keyword:$scope.search.keyword, page:$scope.pageConf.currentPage})

    viewClasse: (classe) ->
      $state.go('admin.classeManager.detail', classeId:classe._id) if classe?

  reloadStandAloneStudents = ->
    Restangular.all('users').getList(role:'student', standalone:true)
    .then (students) ->
      $scope.other.students = _.pluck students, '_id'
      $scope.other.$students = students

  reloadStandAloneStudents()
  $scope.$on 'reloadStandAloneStudents', reloadStandAloneStudents

  updateClassesStudents = (event, updateClasses) ->
    _.forEach updateClasses, (c) ->
      currentClasse = _.find Classes, _id:c._id
      currentClasse?.students = c.students

  $scope.$on 'removeUsersFromSystem', updateClassesStudents

  Restangular
  .all('classes')
  .getList(
    from    : ($scope.pageConf.currentPage - 1) * $scope.pageConf.itemsPerPage
    limit   : $scope.pageConf.itemsPerPage
    keyword : $scope.search.keyword
  )
  .then (classes) ->
    $scope.classes = classes

  $scope.$watch 'pageConf.currentPage', (newPage) ->
    $state.go('admin.classeManager', {keyword:$scope.search.keyword, page:newPage})
