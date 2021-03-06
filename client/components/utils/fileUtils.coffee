angular.module 'budweiserApp'

.factory 'fileUtils', (
  $q
  $http
  $upload
  configs
  Restangular
  $timeout
  org
) ->

  rexDict =
    slides: /^application\/(pdf|msword|vnd.openxmlformats-officedocument.wordprocessingml.document|vnd.ms-powerpoint|vnd.openxmlformats-officedocument.presentationml.slideshow|vnd.openxmlformats-officedocument.presentationml.presentation)$/
    video: /^video\//
    image: /^image\//
    excel: /^application\//
    all: /.*/

  validate = (validation, files) ->
    if files?.length != 1
      return '请选择一个要上传的文件'
    file = files[0]
    if file.size > (validation?.max or Infinity)
      return '文件 ' + file.name + ' 大小超过上传限制'
    accept = validation?.accept or 'all'
    if !rexDict[accept]?.test(file.type)
      return '文件 ' + file.name + ' 格式不允许'

  doUploadFile = (opts, file) ->
    # get upload token
    Restangular.one('assets/upload/images','').get(fileName: file.name)
    .then (strategy)->
      start = moment()
      $upload.upload
        url: strategy.url
        method: 'POST'
        data: strategy.formData
        withCredentials: false
        file: file
        fileFormDataName: 'file'
      .progress (evt)->
        speed = evt.loaded / (moment().valueOf() - start.valueOf())
        percentage = parseInt(100.0 * evt.loaded / evt.total)
        opts.progress?(speed,percentage, evt)
      .success (data) ->
        console.remote 'upload', 'file', {key: strategy.formData.key, size: file.size}
        opts.success?(strategy.prefix+strategy.formData.key)
      .error (ex) ->
        console.remote 'error', 'onFileUploadError', ex
        opts.fail(ex)
    , opts.fail

  doUploadVideo = (opts, file)->
    # get upload token
    Restangular.one('assets/upload/videos','').get(fileName: file.name.replace /[^a-z0-9\.-_]+/gi, '')
    .then (strategy)->
      startTime = moment()
      pipeUpload = (file, segment ,request, concurrents)->
        uploadQ = $q.defer()
        pieces = Math.ceil(file.size / segment)
        pad = (number, length) ->
          str = '' + number
          while str.length < length
            str = '0' + str
          str
        blocklist = [1..pieces].map (i) -> btoa('block-' + pad(i, 6))
        commitBlockList = ()->
          deferred = $q.defer()
          url = request.url + '&comp=blocklist'
          requestBody = '<?xml version="1.0" encoding="utf-8"?><BlockList>';
          requestBody += (blocklist.map (i)-> '<Latest>' + i + '</Latest>').join('')
          requestBody += '</BlockList>'
          $.ajax
            url: url
            type: "PUT"
            data: requestBody
            beforeSend:  (xhr) ->
              xhr.setRequestHeader('x-ms-blob-content-type', file.type)
            success: (data, status) ->
              deferred.resolve data
            error: (xhr, desc, err) ->
              throw err
          deferred.promise


        readBlob = (start, end)->
          deferred = $q.defer()
          blob = file.slice(start, end)
          fileReader = new FileReader()
          fileReader.readAsArrayBuffer(blob)
          fileReader.onload = (e)->
            deferred.resolve e.target.result
          deferred.promise

        segments = [0..pieces-1].map (i) ->
          blockName: blocklist[i]
          start: segment * i
          end: if segment * (i + 1) >= file.size - 1 then file.size - 1 else segment * (i + 1)

        finished = 0
        genJob = (defer)->
          seg = segments.shift()
          if seg
            readBlob(seg.start, seg.end)
            .then (data)->
              request.data = data
              $.ajax
                url: request.url + '&comp=block&blockid=' + seg.blockName
                type: request.method
                data: data
                processData: false
                beforeSend: (xhr)->
                  xhr.setRequestHeader('x-ms-blob-type', 'BlockBlob')
                  xhr.setRequestHeader('Content-Length', data.length)
                success: (data)->
                  finished += (seg.end - seg.start)
                  speed = finished / (moment().valueOf() - startTime.valueOf())
                  percentage = parseInt(100.0 * finished / file.size)
                  opts.progress?(speed, percentage)
                  genJob(defer)
                error: (err)->
                  # retry
                  console.remote 'error', 'onVideoUploadError', err
                  segments.push seg
                  genJob(defer)
          else
            defer?.resolve()

        $q.all([1..concurrents].map (i)->
          defer = $q.defer()
          genJob(defer)
          defer.promise
        ).then ()->
          commitBlockList()
        .then ()->
          uploadQ.resolve()

        uploadQ.promise

      request =
        url: strategy.url
        method: 'PUT'
        headers:
          'x-ms-blob-type': 'BlockBlob'
          'x-ms-version': '2013-08-15'
          'Content-Type': 'application/octet-stream'
          'Content-Length': file.size
        withCredentials: false
      pipeUpload(file, 4 * 1024 * 1024,request, 3)
      .then (data)->
        console.remote 'upload', 'video', {key: strategy.key, size: file.size}
        opts.success?(strategy.prefix + strategy.key)
      , (err)->
        opts.fail?(err)
    , opts.fail

  doUploadSlides = (opts, file)->
    # get upload token
    Restangular.one('assets/upload/slides','').get(fileName: file.name)
    .then (strategy)->
      start = moment()
      $upload.upload
        url: strategy.url
        method: 'POST'
        data: strategy.formData
        withCredentials: false
        file: file
        fileFormDataName: 'file'
      .progress (evt)->
        speed = evt.loaded / (moment().valueOf() - start.valueOf())
        percentage = parseInt(100.0 * evt.loaded / evt.total)
        opts.progress?(speed, percentage, evt)
      .success (data) ->
        console.remote 'upload', 'slide', {key: strategy.formData.key, size: file.size}
        key = strategy.formData.key
        opts.convert?(key)
        $http.post configs.fpUrl + 'api/convert?key=' + encodeURIComponent(key)
        .success (content)->
          console.remote 'convert', 'slide', {key: strategy.formData.key, size: file.size}
          result =
            fileWidth: content.width
            fileHeight: content.height
            fileName: file.name
            fileContent: _.map content.rawPics, (pic) ->
              raw: strategy.prefix + pic
              thumb: strategy.prefix + pic.replace('-lg.jpg', '-sm.jpg')
          opts.success?(result)
        .error (ex) ->
          console.remote 'error', 'onConvertError', ex
          opts.fail(ex)
      .error (ex) ->
        console.remote 'error', 'onFileUploadError', ex
        opts.fail(ex)
    , opts.fail

  uploadFile: (opts) ->
    error = validate(opts.validation, opts.files)
    if error?
      console.remote 'error', 'onFileUploadError', error
      return opts.fail?(error)
    # 根据后缀名匹配调用的上传方法
    file = opts.files[0]
    matchFileTypeName = _.findKey rexDict, (value) -> value.test(file.type)
    switch matchFileTypeName
      when 'slides' then doUploadSlides(opts, file)
      when 'video'  then doUploadVideo(opts, file)
      else               doUploadFile(opts, file)

  bulkUpload: (opts)->

    if not opts.files? or opts.files.length < 1
      opts.fail?('file not selected')
      return

    promises = []
    totalSize = 0
    finishedSize = 0

    for file in opts.files
      do (file)->
        error = validate(opts.validation, [file])
        return opts.fail?(error) if error?

        totalSize += file.size
        loaded = 0
        deferred = $q.defer()
        promises.push deferred.promise
        # get upload token
        Restangular.one('assets/upload/images','').get(fileName: file.name)
        .then (strategy)->
          start = moment()
          $upload.upload
            url: strategy.url
            method: 'POST'
            data: strategy.formData
            withCredentials: false
            file: file
            fileFormDataName: 'file'
          .progress (evt)->
            speed = evt.loaded / (moment().valueOf() - start.valueOf())
            finishedSize += (evt.loaded - loaded)
            loaded = evt.loaded
            percentage = 100 * finishedSize // totalSize
            evt.$fileName = file.name
            opts.progress?(speed, percentage, evt)
          .success (data) ->
            console.remote 'upload', 'file', {key: strategy.formData.key, size: file.size}
            deferred.resolve
              url: strategy.prefix+strategy.formData.key
              name: file.name
              size: file.size
          .error (response)->
            deferred.reject()
        , (error)->
          deferred.reject()

    $q.all(promises).then (result)->
      keys = []
      meta = []
      for data in result
        keys.push data.url
        meta.push data
      opts.success?(keys, meta)
    , opts.fail

