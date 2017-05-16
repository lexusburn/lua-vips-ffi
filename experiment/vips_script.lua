local image   = require("vips_connector")

-- open first image
local firstImg = image.open('/data/images/firstImg.png')
-- open second image
local secondImg = image.open('/data/images/secondImg.png')
-- output first image size
log(INFO, "first image width: ", image.width(firstImg))
log(INFO, "first image height: ", image.height(firstImg))
-- output second image size
log(INFO, "second image width: ", image.width(secondImg))
log(INFO, "second image height: ", image.height(secondImg))
-- add second image to first image and put into third image
local thirdImg = image.insert(firstImg, secondImg, 100, 100)
log(INFO, "third image width: ", image.width(thirdImg))
log(INFO, "third image height: ", image.height(thirdImg))
-- save third image
image.save(thirdImg, '/data/images/thirdImg.png')

