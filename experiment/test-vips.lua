local image = require("vips_connector")

local backgroundImg = image.open('/data/images/backgroundImg.png')
local watermarkImg = image.open('/data/images/watermarkImg.png')
-- combine isn't implemented fully, because composite isn't ready yet
-- because of this background is missing behind watermark :(
local newImg = image.combine(backgroundImg, watermarkImg, 100, 100)
image.save(newImg, '/data/images/newImg.png')
