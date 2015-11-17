$ ->
  file = null
  
  result = $('#result_image')

  f_rep_cnt = $('#rep_count')
  f_delta_x = $('#delta_x')
  f_delta_h = $('#delta_h')
  f_right = $('#right')

  f_rep_cnt.val('5')
  f_delta_x.val('80')
  f_delta_h.val('30')

  tmp_canvas = $('#tmp_canvas')
  res_canvas = $('#res_canvas')
  tmp_ctx = tmp_canvas[0].getContext('2d')
  res_ctx = res_canvas[0].getContext('2d')

  result.hide()
  tmp_canvas.hide()
  res_canvas.hide()

  draw_res = (x, w, h, image_data) ->

    res_image = res_ctx.getImageData(x, 0, w, h)

    for y in [0..h]
      for xx in [0..w]
        idx = (w * y + xx) * 4
        continue if image_data.data[idx + 3] != 255
        res_image.data[idx + 0] = image_data.data[idx + 0]
        res_image.data[idx + 1] = image_data.data[idx + 1]
        res_image.data[idx + 2] = image_data.data[idx + 2]
        res_image.data[idx + 3] = image_data.data[idx + 3]

    res_ctx.putImageData(res_image, x, 0)


  rgb_to_hsv = (rgb) ->
    max = rgb.r
    max = rgb.g if rgb.g > max
    max = rgb.b if rgb.b > max
    min = rgb.r
    max = rgb.g if rgb.g < min
    max = rgb.b if rgb.b < min

    _h = 0
    if max != min
      if min == rgb.b
        _h = 60 * (rgb.b - rgb.r) / (max - min) + 60
      else if min ==rgb.r
        _h = 60 * (rgb.b - rgb.g) / (max - min) + 180
      else if min ==rgb.g
        _h = 60 * (rgb.r - rgb.b) / (max - min) + 300
      
      _h += 360 while _h < 0
      _h %= 360 if _h > 360

    hsv = {
      h : _h
      v : max
      s : max - min
    }
    return hsv

  hsv_to_rgb = (hsv) ->
    rgb = {
      r : 0
      g : 0
      b : 0
    }
    _h = hsv.h / 60
    n = hsv.v - hsv.s
    x = hsv.s * (1 - Math.abs(_h % 2 - 1))
    if _h < 1
      rgb.r = n + hsv.s
      rgb.g = n + x
      rgb.b = n
    else if _h < 2
      rgb.r = n + x
      rgb.g = n + hsv.s
      rgb.b = n
    else if _h < 3
      rgb.r = n
      rgb.g = n + hsv.s
      rgb.b = n + x
    else if _h < 4
      rgb.r = n
      rgb.g = n + x
      rgb.b = n + hsv.s
    else if _h < 5
      rgb.r = n + x
      rgb.g = n
      rgb.b = n + hsv.s
    else
      rgb.r = n + hsv.s
      rgb.g = n
      rgb.b = n + x

    return rgb

  proc_image = (w, h, image_data, d) ->
    for y in [0..h]
      for x in [0..w]
        idx = (w * y + x) * 4
        continue if image_data.data[idx + 3] != 255
        rgb = {
          r : image_data.data[idx + 0] / 255.0
          g : image_data.data[idx + 1] / 255.0
          b : image_data.data[idx + 2] / 255.0
        }
        hsv = rgb_to_hsv(rgb)
        hsv.h = (hsv.h + d) % 360
        rgb = hsv_to_rgb(hsv)
        image_data.data[idx + 0] = (rgb.r * 255.0 + 0.5)
        image_data.data[idx + 1] = (rgb.g * 255.0 + 0.5)
        image_data.data[idx + 2] = (rgb.b * 255.0 + 0.5)


    return image_data

  $('#selectFile').change ->
    file = this.files[0]

  $('#process').click ->
    return if file == null

    rep_cnt = parseInt(f_rep_cnt.val(), 10)
    delta_x = parseInt(f_delta_x.val(), 10)
    delta_h = parseInt(f_delta_h.val(), 10)
    right = f_right.prop('checked')

    return unless file.type.match(/^image\/(png|jpeg|jpg|gif)$/)

    image = new Image()
    reader = new FileReader()

    reader.onload = (evt) ->
      image.onload = ->
        res_canvas.hide()

        w = this.width
        h = this.height
        rw = w + (rep_cnt - 1) * delta_x

        tmp_canvas.attr('width', w)
        tmp_canvas.attr('height', h)

        res_canvas.attr('width', rw)
        res_canvas.attr('height', h)

        tmp_ctx.drawImage(image, 0, 0)
       
        for i in [0...(rep_cnt - 1)]
          i = (rep_cnt - 1) - i if right
          image_data = tmp_ctx.getImageData(0, 0, w, h)

          dh = i if right
          dh = rep_cnt - 1 - i if !right
          img = proc_image(w, h, image_data, delta_h * dh)
          draw_res(i * delta_x, w, h, img)

        image_data = tmp_ctx.getImageData(0, 0, w, h)
        draw_res((rep_cnt - 1) * delta_x, w, h, image_data) if !right
        draw_res(0, w, h, image_data) if right

        png = res_canvas.get(0).toDataURL()
        result.attr('width', rw)
        result.attr('height', h)
        result.attr('src', png)
        result.show()


      image.src = evt.target.result

    reader.readAsDataURL(file)

