-- manage VipsImage

local ffi = require("ffi")
local gvalue = require("gvalue_connector")
local vobject = require("vobject_connector")
local voperation = require("voperation_connector")
local vips = ffi.load("vips")

ffi.cdef[[
    typedef struct _VipsImage {
        VipsObject parent_instance;

        // opaque
    } VipsImage;

    const char* vips_foreign_find_load (const char *name);
    const char *vips_foreign_find_load_buffer(const void *data, size_t size);

    const char* vips_foreign_find_save (const char* name);
    const char *vips_foreign_find_save_buffer( const char *suffix );

]]

local vimage
local vimage_mt = {
    __index = {
        -- cast to an object
        object = function(self)
            return ffi.cast(vobject.typeof, self)
        end,

        new_from_file = function(filename, ...)
            local operation_name =
            ffi.string(vips.vips_foreign_find_load(filename))
            return voperation.call(operation_name, filename, unpack{...})
        end,

        new_from_buffer = function(format_string, data, ...)
            local operation_name =
            ffi.string(vips.vips_foreign_find_load_buffer(data, string.len(data)))
            return voperation.call(operation_name, data, format_string, unpack{...})
        end,

        write_to_file = function(self, filename, ...)
            local operation_name =
            ffi.string(vips.vips_foreign_find_save(filename))
            return voperation.call(operation_name, self, filename, unpack{...})
        end,

        write_to_buffer = function(self, format_string, ...)
            local operation_name =
            ffi.string(vips.vips_foreign_find_save_buffer(format_string))
            return voperation.call(operation_name, self, format_string, unpack{...})
        end,
    }
}

setmetatable(vimage_mt.__index, {
    __index = function(table, name)
        return function(...)
            return voperation.call(name, unpack{...})
        end
    end
})

vimage = ffi.metatype("VipsImage", vimage_mt)
return vimage
