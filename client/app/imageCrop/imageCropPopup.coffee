angular.module('budweiserApp').controller 'ImageCropPopupCtrl', (
  $scope
  $modalInstance
  fileUtils
  notify
  $timeout
  files
  options
  $sce
) ->
  angular.extend $scope,
    viewState: {}

    files: files

    cancel: ->
      $modalInstance.dismiss('cancel')

    onFileSelect: ($event, files)->
      if not files?.length
        notify('请选择文件')
        return
      if not /^image\//.test files[0].type
        notify('请选择正确文件')
        return
      $scope.files = files

    confirm: () ->
      if not $scope.files.length
        return
      $scope.viewState.uploading = true
      fileUtils.uploadFile
        files: $scope.files
        validation:
          max: 5*1024*1024
          accept: 'image'
        rename: 'index'
        success: (key) ->
          $scope.viewState.uploading = false
          suffix = '?imageMogr2/auto-orient'
          if $scope.viewState.start
            cropSize =
              width: $scope.viewState.originSize.width / $scope.viewState.size.width * ($scope.viewState.end.x - $scope.viewState.start.x)
              height: $scope.viewState.originSize.height / $scope.viewState.size.height * ($scope.viewState.end.y - $scope.viewState.start.y)
            cropOffset =
              x: $scope.viewState.originSize.width / $scope.viewState.size.width * $scope.viewState.start.x
              y: $scope.viewState.originSize.height / $scope.viewState.size.height * $scope.viewState.start.y
            suffix += "/crop/!" + ~~cropSize.width + 'x' + ~~cropSize.height + 'a' + ~~cropOffset.x + 'a' + ~~cropOffset.y
          if options.maxWidth and options.maxWidth < (cropSize?.width || $scope.viewState.originSize.width)
            suffix += '/thumbnail/' + ~~options.maxWidth + 'x'

          result = "#{key}" + suffix

          $modalInstance.close result,
            key: key
            cropSize: cropSize
            cropOffset: cropOffset
            originSize: $scope.viewState.originSize
        fail: (error)->
          $scope.viewState.uploading = false
          notify(error)
        progress: (speed, percentage, evt)->
          $scope.viewState.uploadProgress = parseInt(100.0 * evt.loaded / evt.total) + '%'

  showCoords = (c)->
    $scope.viewState.start =
      x: c.x
      y: c.y
    $scope.viewState.end =
      x: c.x2
      y: c.y2

  cancelSelect = ()->
    $scope.viewState.start = undefined
    $scope.viewState.end = undefined

  $scope.$watch 'files', (value, oldValue)->
    if value
      url = URL.createObjectURL(value[0])
      safeUrl = $sce.trustAsResourceUrl(url)
      $timeout ()->
        $scope.viewState.previewUrl = safeUrl
      angular.element('.img-preview').on 'load', (e)->
        if e.target.clientWidth < 250
          angular.element('.img-preview').css 'width', 250
          angular.element('.img-preview').css 'height', ~~(e.target.clientHeight * 250 / e.target.clientWidth)
          $scope.viewState.size =
            width: 250
            height: ~~(e.target.clientHeight * 250 / e.target.clientWidth)
        else
          $scope.viewState.size =
            width: e.target.clientWidth
            height: e.target.clientHeight
        $scope.viewState.originSize =
          width: e.target.naturalWidth
          height: e.target.naturalHeight
        if /(gif|svg)/i.test value[0].type
          $scope.message = 'gif或者svg不支持裁剪'
        else
          $scope.message = ''
        angular.element('.img-preview').Jcrop
          onSelect: showCoords
          onChange: showCoords
          onRelease: cancelSelect
          aspectRatio: options.ratio
          keySupport: false
          setSelect: [0,0, $scope.viewState.size.width/2, $scope.viewState.size.width/2/options.ratio] if options.ratio and !$scope.message



