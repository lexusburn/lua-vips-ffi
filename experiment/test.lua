local gvalue = require("gvalue_connector")
local image = require("vips_connector")

local value

value = gvalue.new()
value.init(value, gvalue.gint_type)
value.set_int(value, 12)
print("set value of 12")
print("fetch value:")
print("   ", value.get_int(value))


value = gvalue.new()
value.init(value, gvalue.gstr_type)
value.set_string(value, "banana")
print("set value of banana")
print("fetch value:")
print("   ", value.get_string(value))

testImg = image.black(800, 600, "options")

backgroundImg = image.open('/data/images/backgroundImg.png')
watermarkImg = image.open('/data/images/watermarkImg.png')
newImg = image.combine(backgroundImg, watermarkImg, 100, 100)
image.save(newImg, '/data/images/newImg.png')
