local image   = require("vips_connector")

-- open first image
local firstImg = image.open('/home/john/pics/k2.jpg')
-- open second image
local secondImg = image.open('/home/john/pics/shark.jpg')
-- output first image size
print("first image width: ", image.width(firstImg))
print("first image height: ", image.height(firstImg))
-- output second image size
print("second image width: ", image.width(secondImg))
print("second image height: ", image.height(secondImg))
-- add second image to first image and put into third image
local thirdImg = image.insert(firstImg, secondImg, 100, 100)
print("third image width: ", image.width(thirdImg))
print("third image height: ", image.height(thirdImg))
-- save third image
image.save(thirdImg, 'x.jpg')

