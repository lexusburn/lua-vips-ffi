local image = require("vips_connector")

local firstImg = image.open('/data/images/firstImg.png')
local secondImg = image.open('/data/images/secondImg.png')
local thirdImg = image.insert(firstImg, secondImg, 0, 0)
image.save(thirdImg, '/data/images/foo3.png')
-- it seems to work but secondImg lost transparency :(
