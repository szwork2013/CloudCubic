'use strict'

angular.module('budweiserApp')

.controller 'ClasseManagerDetailCtrl', (
  $scope
  $state
  notify
  $modal
  $rootScope
) ->

  angular.extend $scope,

    eidtingInfo: null

    reloadStudents: (users) ->
      $scope.selectedClasse?.all?('students').getList()
      .then (students) ->
        $scope.selectedClasse.students = _.pluck students, '_id'
        $scope.selectedClasse.$students = students

    viewStudent: (student) ->
      $state.go('classeManager.detail.student', classeId:$scope.selectedClasse._id, studentId:student._id)

  $scope.$watch 'classes', ->
    return if !$scope.classes
    $scope.$parent.selectedClasse = _.find($scope.classes, _id:$state.params.classeId) ? $scope.other
    $scope.reloadStudents()
