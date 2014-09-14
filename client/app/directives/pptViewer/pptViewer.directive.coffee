'use strict'

angular.module('budweiserApp').directive 'pptViewer', ->
  templateUrl: 'app/directives/pptViewer/pptViewer.html'
  restrict: 'AE'
  replace: true
  scope: { slides: '=' }
  link: (scope, element, attrs) ->
    scope.currentIndex = 0 # Initially the index is at the first silde
    scope.canPrev = false
    scope.next = ($event) ->
      $event.stopPropagation()
      if not scope.slides
        return
      if scope.currentIndex is scope.slides.length - 1
        return
      else
        scope.currentIndex++

    scope.prev = ($event) ->
      $event.stopPropagation()
      if not scope.slides
        return
      if scope.currentIndex is 0
        return
      else
        scope.currentIndex--

    scope.$watch 'slides', (newValue, oldValue)->
      if newValue? and newValue.length isnt 0
        scope.currentIndex = 0