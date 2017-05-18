local gvalue = require("gvalue_connector")

local value

value = gvalue.new()
value:init(gvalue.gint_type)
value:set_int(12)
print("set value of 12")
print("fetch value:")
print("   ", value:get_int())

value = gvalue.new()
value:init(gvalue.gstr_type)
value:set_string("banana")
print("set value of banana")
print("fetch value:")
print("   ", value:get_string())

value = gvalue.new()
value:init(gvalue.gboolean_type)
value:set_boolean(true)
print("set value of true")
print("fetch value:")
print("   ", value:get_boolean())
