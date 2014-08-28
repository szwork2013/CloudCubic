'use strict'

angular.module('budweiserApp').directive 'qiniuKey', ($http)->
  restrict: 'A'
  scope:
    qiniuKey:'='
    suffix:'@'
    sourceAttr:'@'

  link: ($scope, $element, $attrs) ->
    setSource = (url)->
      switch $scope.sourceAttr
        when 'background-image'
          $element.css('background-image','url(' + url + ')')
        when 'data'
          $element[0].data = url
        else
          $element[0].src = url

    $scope.$watch 'qiniuKey',(key) ->
      if !key
        return
      else if /\/\//.test(key)
        setSource(key)
      else
        suffix = $scope.suffix ? ''
        $http.get('/api/qiniu/signed_url/' + encodeURIComponent(key + suffix))
        .success setSource

