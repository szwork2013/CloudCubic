angular.module('budweiserApp').controller 'StudentQuickNavCtrl', (
  $scope
  $modalInstance
  notify
  otherCourses
  $rootScope
) ->
  angular.extend $scope,
    close: ->
      $modalInstance.dismiss('close')

    viewState: {}

    otherCourses: otherCourses

  # Fix bug: the popup does not dismiss when change state
  # http://stackoverflow.com/questions/14898296/how-to-unsubscribe-to-a-broadcast-event-in-angularjs-how-to-remove-function-reg
  offCloseHandle = $rootScope.$on '$stateChangeSuccess', $scope.close

  $scope.$on '$destroy', ()->
    console.log 'destroy'
    offCloseHandle()



