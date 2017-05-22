local voperation = require("voperation_connector")
local vimage = require("vimage_connector")

local image = voperation.call("black", 100, 200, {bands = 3})

print("")
print("get height:")
local height = image:object():get("height")
print("height = ", height)

image.frank(1, 2, 3)

image2 = image:invert()

image3 = vimage:black(1, 2, {bands = 3})

image4 = vimage.new_from_file("/data/images/secondImg.png")
image4 = image4:invert()
image4:write_to_file("/data/images/x.jpg")

x = image4:linear({1, 2, 3}, {4, 5, 6})
