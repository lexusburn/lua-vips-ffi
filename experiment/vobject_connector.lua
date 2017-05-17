-- manage VipsObject
-- base class for operation and image

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

    typedef struct _VipsObjectClass {
        // opaque
    } VipsObjectClass;

    typedef struct _GParamSpec {
        void* g_type_instance;

        const char* name;     
        unsigned int flags;
        unsigned long int value_type;
        unsigned long int owner_type;

        // rest opaque
    } GParamSpec;

    typedef struct _VipsArgument {
        GParamSpec *pspec;
    } VipsArgument;

    typedef struct _VipsArgumentInstance {
        VipsArgument parent;

        // opaque
    } VipsArgumentInstance;

    typedef enum _VipsArgumentFlags {
        VIPS_ARGUMENT_NONE = 0,
        VIPS_ARGUMENT_REQUIRED = 1,
        VIPS_ARGUMENT_CONSTRUCT = 2,
        VIPS_ARGUMENT_SET_ONCE = 4,
        VIPS_ARGUMENT_SET_ALWAYS = 8,
        VIPS_ARGUMENT_INPUT = 16,
        VIPS_ARGUMENT_OUTPUT = 32,
        VIPS_ARGUMENT_DEPRECATED = 64,
        VIPS_ARGUMENT_MODIFY = 128
    } VipsArgumentFlags;

    typedef struct _VipsArgumentClass {
        VipsArgument parent;

        VipsObjectClass *object_class;
        VipsArgumentFlags flags;
        int priority;
        unsigned long int offset;
    } VipsArgumentClass;

    void g_object_unref (void* object);

    int vips_object_get_argument (VipsObject* object, const char *name,
        GParamSpec** pspec, VipsArgumentClass** argument_class,
        VipsArgumentInstance** argument_instance);

    void g_object_set_property (void* object, const char *name, GValue* value);
    void g_object_get_property (GObject* object, const char* property_name,
        GValue* value);

    VipsObject* vips_operation_new (const char* operation_name);

]]

local vobject
local vobject_mt = {
    __gc = function(object)
        print("freeing vobject ", object)
        vips.g_value_unref(value)
    end,
    -- no __gc method, we don't build these things ourselves, just wrap the
    -- pointer, so we use ffi.gc() instead
    -- .... or should there be? unclear, experiment
    __index = {
        new = function(object)
            print("vobject.new")
            print("  ptr =", object)
            ffi.gc(object, vips.g_object_unref)
            return object
        end,
        set = function(object, name, value)
            print("vobject.set")
            print("  object =", object)
            print("  name =", name)
            print("  value =", value)

            local pspec = ffi.new("GParamSpec*[1]")
            local argument_class = ffi.new("VipsArgumentClass*[1]")
            local argument_instance = ffi.new("VipsArgumentInstance*[1]")
            print("calling vips.vips_object_get_argument ...")
            local result = vips.vips_object_get_argument(object, name,
                pspec, argument_class, argument_instance)
            print("   result =", result)
            if result ~= 0 then
                print("unknown field ", name)
                return nil
            end

            local type = pspec[0].value_type

            print("  object param type =", type)
            
        end,

        test = function()
            local operation = vips.vips_operation_new("black")
            --return vobject.new(operation)
            return operation
        end,

    }
}

vobject = ffi.metatype("VipsObject", vobject_mt)
return vobject
