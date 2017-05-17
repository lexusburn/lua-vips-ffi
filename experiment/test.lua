local gvalue = require("gvalue_connector")
local vobject = require("vobject_connector")
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

print("")
print("")

local object

print("making test object")
object = vobject.test()
print("   object =", object)
object.set(object, "banana", 12)

object = nil


firstImg = image.open('/data/images/firstImg.png')
secondImg = image.open('/data/images/secondImg.png')
thirdImg = image.insert(firstImg, secondImg, 0, 0)
image.save(thirdImg, '/data/images/foo3.png')
-- it seems to work but secondImg lost transparency :(
