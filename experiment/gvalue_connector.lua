-- manipulate GValue objects from lua
-- pull in gobject via the vips library

local ffi = require("ffi")
local vips = ffi.load("vips")

ffi.cdef[[
    typedef struct _GValue {
        unsigned long int type;
        uint64_t data[2]; 
    } GValue;

    void vips_init (const char* argv0);

    void g_value_init (GValue* value, unsigned long int type);
    void g_value_unset (GValue* value);
    const char* g_type_name (unsigned long int type);
    unsigned long int g_type_from_name (const char* name);

    void g_value_set_string (GValue* value, const char *str);
    void g_value_set_int (GValue* value, int i);
    void g_value_set_object (GValue* value, void* object);

    const char* g_value_get_string (GValue* value);
    int g_value_get_int (GValue* value);
    void* g_value_get_object (GValue* value);

]]

-- this will add the vips types as well
vips.vips_init("")

local gvalue
local gvalue_mt = {
    __gc = function(value)
        print("freeing gvalue ", value)
        print("   type name =", ffi.string(vips.g_type_name(value.type)))

        vips.g_value_unset(value)
    end,
    __index = {
        -- make an ffi constructor we can reuse
        typeof = ffi.typeof("GValue"),

        -- look up some common gtypes at init for speed
        gint_type = vips.g_type_from_name("gint"),
        gstr_type = vips.g_type_from_name("gchararray"),
        VipsImage_type = vips.g_type_from_name("VipsImage"),
        
        new = function()
            -- with no init, this will initialize with 0, which is what we need
            -- for a blank GValue
            local value = ffi.new(gvalue.typeof)
            print("allocating gvalue ", value)
            return value
        end,
        init = function(value, type)
            print("starting init")
            print("  value =", value)
            print("  type name =", ffi.string(vips.g_type_name(type)))
            vips.g_value_init(value, type)
        end,

        set_int = function(value, i)
            vips.g_value_set_int(value, i)
        end,
        set_string = function(value, str)
            vips.g_value_set_string(value, str)
        end,
        set_object = function(value, object)
            vips.g_value_set_object(value, object)
        end,

        get_int = function(value, i)
            return vips.g_value_get_int(value)
        end,
        get_string = function(value, str)
            return ffi.string(vips.g_value_get_string(value))
        end,
        get_object = function(value, object)
            return vips.g_value_get_object(value)
        end,
    }
}

gvalue = ffi.metatype("GValue", gvalue_mt)
return gvalue
