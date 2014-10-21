'use strict'

angular.module('budweiserApp')

.controller 'ClasseManagerDetailCtrl', (
  Auth
  $scope
  $state
  notify
  $modal
  fileUtils
  Restangular
) ->

  angular.extend $scope,

    editingClasseName: ''

    saveClasseName: (form) ->
      if !form.$valid then return
      if $scope.editingClasseName != $scope.selectedClasse.name
        $scope.selectedClasse.patch name:$scope.editingClasseName
        .then (classe)->
          angular.extend $scope.selectedClasse, classe
          notify
            message: """"#{classe.name}"信息已保存"""
            classes: 'alert-success'

    addNewStudent: ->
      $modal.open
        templateUrl: 'app/admin/classeManager/newUserModal.html'
        controller: 'NewUserModalCtrl'
        resolve:
          userType: -> 'student'
          orgUniqueName: -> Auth.getCurrentUser().orgId.uniqueName
      .result.then (newStudent) ->
        newStudents = _.union $scope.selectedClasse.students, [newStudent._id]
        $scope.selectedClasse.patch students:newStudents
        .then ->
          $scope.loadStudents()
          notify
            message: '新学生添加成功'
            classes: 'alert-success'

    loadStudents: ->
      $scope.selectedClasse?.all('students').getList().then (students) ->
        $scope.selectedClasse.$students = students

  $scope.selectedClasse = _.find($scope.classes, _id: $state.params.classeId)
  $scope.editingClasseName = $scope.selectedClasse?.name
  $scope.loadStudents() if $scope.selectedClasse?._id

  #TODO refactor
  $scope.isExcelProcessing = false

  $scope.onFileSelect = (files)->
    $scope.isExcelProcessing = true
    fileUtils.uploadFile
      files: files
      validation:
        max: 50 * 1024 * 1024
        accept: 'excel'
      success: (key)->
        Restangular.one('users').post 'bulk',
          key: key
          orgId: Auth.getCurrentUser().orgId
          type: 'student'
          classeId: $scope.selectedClasse._id
        .then ->
          $scope.loadStudents()
          $scope.isExcelProcessing = false
        , (error)->
          console.log error
          $scope.isExcelProcessing = false
      fail: (error)->
        notify
          message: error
          classes: 'alert-danger'
        $scope.isExcelProcessing = false
      progress: ->
        console.debug 'uploading...'
