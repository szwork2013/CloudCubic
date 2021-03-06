angular.module('budweiserApp')

.directive 'searchInput', ->
  restrict: 'E'
  replace: true
  templateUrl: 'app/directives/searchInput/searchInput.html'
  scope:
    keyword: '='
    onSubmit: '&'
    placeholder: '@'
  controller: ($scope) ->

    angular.extend $scope,

      onSearch: ->
        $scope.onSubmit?($keyword:$scope.keyword)

      onKeyup: ($event) ->
        $scope.onSearch() if $event.keyCode is 13
