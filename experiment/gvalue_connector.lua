-- manipulate GValue objects from lua
-- pull in gobject via the vips library

local ffi = require("ffi")
local vips = ffi.load("vips")

ffi.cdef[[
    typedef struct _GValue {
        unsigned long int type;
        uint64_t data[2];
    } GValue;

    typedef struct _VipsImage VipsImage;
    typedef struct _VipsBlob VipsBlob;

    void vips_init (const char* argv0);

    void g_value_init (GValue* value, unsigned long int type);
    void g_value_unset (GValue* value);
    const char* g_type_name (unsigned long int type);
    unsigned long int g_type_from_name (const char* name);

    void g_value_set_string (GValue* value, const char *str);
    void g_value_set_int (GValue* value, int i);
    void g_value_set_object (GValue* value, void* object);
    void g_value_set_boolean (GValue* value, bool boolean);

    const char* g_value_get_string (GValue* value);
    int g_value_get_int (GValue* value);
    void* g_value_get_object (GValue* value);
    bool g_value_get_boolean (GValue* value);

    void vips_value_set_array_double (GValue* value, const double* array, int n );

]]

-- this will add the vips types as well
vips.vips_init("")

local gvalue
local gvalue_mt = {
    __gc = function(gv)
        print("freeing gvalue ", gv)
        print("  type name =", ffi.string(vips.g_type_name(gv.type)))

        vips.g_value_unset(gv)
    end,
    __index = {
        -- make an ffi constructor we can reuse
        gv_typeof    = ffi.typeof("GValue"),
        gva_typeof   = ffi.typeof("GValue[1]"),
        image_typeof = ffi.typeof("VipsImage*"),
        blob_typeof  = ffi.typeof("VipsBlob*"),
        pdouble_typeof = ffi.typeof("double[?]"),

        -- look up some common gtypes at init for speed
        gint_type     = vips.g_type_from_name("gint"),
        gstr_type     = vips.g_type_from_name("gchararray"),
        gboolean_type = vips.g_type_from_name("gboolean"),
        image_type    = vips.g_type_from_name("VipsImage"),
        blob_type     = vips.g_type_from_name("VipsBlob"),
        array_double_type = vips.g_type_from_name("VipsArrayDouble"),

        new = function()
            -- with no init, this will initialize with 0, which is what we need
            -- for a blank GValue
            local gv = ffi.new(gvalue.gv_typeof)
            print("allocating gvalue", gv)
            return gv
        end,
        newa = function()
            local gva = ffi.new(gvalue.gva_typeof)
            print("allocating one-element array of gvalue", gva)
            return gva
        end,
        init = function(gv, type)
            print("starting init")
            print("  gv =", gv)
            print("  type name =", ffi.string(vips.g_type_name(type)))
            vips.g_value_init(gv, type)
        end,

        set = function(gv, value)
            local gtype = gv.type

            if gtype == gvalue.gint_type then
                vips.g_value_set_int(gv, value)
            elseif gtype == gvalue.gstr_type then
                vips.g_value_set_string(gv, value)
            elseif gtype == gvalue.gboolean_type then
                vips.g_value_set_boolean(gv, value)
            elseif gtype == gvalue.image_type then
                vips.g_value_set_object(gv, value)
            elseif gtype == gvalue.blob_type then
                vips.g_value_set_object(gv, value)
            elseif gtype == gvalue.array_double_type then
                local n = #value
                local a = ffi.new(gvalue.pdouble_typeof, n, value)

                vips.vips_value_set_array_double(gv, a, n)
            else
                print("unsupported gtype", gtype)
            end
        end,

        get = function(gv)
            local gtype = gv.type
            local result

            if gtype == gvalue.gint_type then
                result = vips.g_value_get_int(gv)
            elseif gtype == gvalue.gstr_type then
                result = ffi.string(vips.g_value_get_string(gv))
            elseif gtype == gvalue.gboolean_type then
                result = vips.g_value_get_boolean(gv)
            elseif gtype == gvalue.image_type then
                result = ffi.cast(gvalue.image_typeof,
                    vips.g_value_get_object(gv))
            elseif gtype == gvalue.blob_type then
                result = ffi.cast(gvalue.blob_typeof,
                    vips.g_value_get_object(gv))
            else
                print("unsupported gtype", gtype)
            end

            return result
        end,

    }
}

gvalue = ffi.metatype("GValue", gvalue_mt)
return gvalue
