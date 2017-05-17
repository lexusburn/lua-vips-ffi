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

firstImg = image.open('/data/images/firstImg.png')
secondImg = image.open('/data/images/secondImg.png')
thirdImg = image.insert(firstImg, secondImg, 0, 0)
image.save(thirdImg, '/data/images/foo3.png')
