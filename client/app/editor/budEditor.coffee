'use strict'

angular.module('budweiserApp').directive 'budEditor', ()->
  restrict: 'E'
  scope:
    metadata: '='
    content: '='
  replace: true
  templateUrl: 'app/editor/bud-editor.html'

  link: (scope, element, attrs) ->

  controller: ($scope,$timeout)->
    angular.extend $scope,
      onImgUploaded: (key)->
        $scope.metadata.images ?= []
        $scope.metadata.images.push
          url: "#{key}-blog"
          key: key

      removeImg: (image)->
        $scope.metadata.images.splice $scope.metadata.images.indexOf(image), 1

    $scope.$watch 'metadata', (value)->
      # should delay 2 seconds
      $scope.metadata ?= {}
      $scope.metadata.raw ?= ''
      $scope.content = $scope.metadata.raw.replace /\r?\n/g, '<br/>'
      if $scope.metadata.tags?.length
        $scope.tags = ''
        $scope.metadata.tags?.forEach (tag)->
          $scope.tags = "<div class=\"tag\" href=\"#{tag.type}\" src=\"#{tag.srcId}\">#{tag.name}</div>"  + $scope.tags
        $scope.content = '<div class="tags clearfix">' + $scope.tags + '</div>' + $scope.content
      $scope.metadata.images?.forEach (image)->
        $scope.content += "<img class=\"sm image-zoom\" src=\"#{image.url}\">"
    , true
