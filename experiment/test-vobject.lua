local vobject = require("vobject_connector")

local object

print("making test object")
object = vobject.test()
print("  object =", object)
object.set(object, "banana", 12)

object.set(object, "width", 12)
