local ffi = require("ffi")
local C = ffi.C
local gvalue = require("gvalue_connector")
local vips = ffi.load("vips")

ffi.cdef[[
    typedef struct {
        int g_type_instance;
        unsigned ref_count;
        void *qdata;
    } GObject;

    typedef struct {
        GObject parent_object;
        bool constructed;
        bool static_object;
        void *argument_table;
        char *nickname;
        char *description;
        bool preclose;
        bool close;
        bool postclose;
        size_t local_memory;
    } VipsObject;

    void* vips_operation_new (const char* operation_name);
    void g_object_set_property (void* object, const char *name, GValue* value);
    void* vips_cache_operation_build (void* operation);

]]

local image
local image_mt = {
    __gc = function(self)
        vips.g_object_unref(self)
    end,
    __index = {
        new_from_file = function(filename, options)
            print("new_from_file")
            print("  filename =", filename)
            print("  options =", options)

        end,
        black = function(width, height, options)
            print("black")
            print("  width =", width)
            print("  height =", height)
            print("  options =", options)

            local operation = vips.vips_operation_new("black")

            local value;

            value = gvalue.new()
            value.init(value, gvalue.gint_type);
            value.set_int(value, filename)
            vips.g_object_set_property(operation, "width", value)

            value = gvalue.new()
            value.init(value, gvalue.gint_type);
            value.set_int(value, height)
            vips.g_object_set_property(operation, "height", value)



        end,
    }
}
