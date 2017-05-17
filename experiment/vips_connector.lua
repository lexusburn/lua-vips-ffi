local ffi = require("ffi")
local C = ffi.C
local vips = ffi.load("vips")
local gvalue = require("gvalue_connector")

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

    typedef enum {
        VIPS_DEMAND_STYLE_ERROR = -1,
        VIPS_DEMAND_STYLE_SMALLTILE,
        VIPS_DEMAND_STYLE_FATSTRIP,
        VIPS_DEMAND_STYLE_THINSTRIP,
        VIPS_DEMAND_STYLE_ANY
    } VipsDemandStyle;

    typedef enum {
        VIPS_IMAGE_ERROR = -1,
        VIPS_IMAGE_NONE,
        VIPS_IMAGE_SETBUF,
        VIPS_IMAGE_SETBUF_FOREIGN,
        VIPS_IMAGE_OPENIN,
        VIPS_IMAGE_MMAPIN,
        VIPS_IMAGE_MMAPINRW,
        VIPS_IMAGE_OPENOUT,
        VIPS_IMAGE_PARTIAL
    } VipsImageType;

    typedef enum {
        VIPS_INTERPRETATION_ERROR = -1,
        VIPS_INTERPRETATION_MULTIBAND = 0,
        VIPS_INTERPRETATION_B_W = 1,
        VIPS_INTERPRETATION_HISTOGRAM = 10,
        VIPS_INTERPRETATION_XYZ = 12,
        VIPS_INTERPRETATION_LAB = 13,
        VIPS_INTERPRETATION_CMYK = 15,
        VIPS_INTERPRETATION_LABQ = 16,
        VIPS_INTERPRETATION_RGB = 17,
        VIPS_INTERPRETATION_CMC = 18,
        VIPS_INTERPRETATION_LCH = 19,
        VIPS_INTERPRETATION_LABS = 21,
        VIPS_INTERPRETATION_sRGB = 22,
        VIPS_INTERPRETATION_YXY = 23,
        VIPS_INTERPRETATION_FOURIER = 24,
        VIPS_INTERPRETATION_RGB16 = 25,
        VIPS_INTERPRETATION_GREY16 = 26,
        VIPS_INTERPRETATION_MATRIX = 27,
        VIPS_INTERPRETATION_scRGB = 28
    } VipsInterpretation;

    typedef enum {
        VIPS_FORMAT_NOTSET = -1,
        VIPS_FORMAT_UCHAR = 0,
        VIPS_FORMAT_CHAR = 1,
        VIPS_FORMAT_USHORT = 2,
        VIPS_FORMAT_SHORT = 3,
        VIPS_FORMAT_UINT = 4,
        VIPS_FORMAT_INT = 5,
        VIPS_FORMAT_FLOAT = 6,
        VIPS_FORMAT_COMPLEX = 7,
        VIPS_FORMAT_DOUBLE = 8,
        VIPS_FORMAT_DPCOMPLEX = 9,
        VIPS_FORMAT_LAST = 10
    } VipsBandFormat;

    typedef enum {
        VIPS_CODING_ERROR = -1,
        VIPS_CODING_NONE = 0,
        VIPS_CODING_LABQ = 2,
        VIPS_CODING_RAD = 6,
        VIPS_CODING_LAST = 7
    } VipsCoding;

    typedef enum {
        VIPS_ACCESS_RANDOM,
        VIPS_ACCESS_SEQUENTIAL,
        VIPS_ACCESS_SEQUENTIAL_UNBUFFERED,
        VIPS_ACCESS_LAST
    } VipsAccess;

    typedef struct _VipsProgress {
        struct _VipsImage *im;
        int run;
        int eta;
        long long tpels;
        long long npels;
        int percent;
        void *start;
    } VipsProgress;

    typedef struct _VipsImage {
        VipsObject parent_object;
        int Xsize;
        int Ysize;
        int Bands;
        VipsBandFormat BandFmt;
        VipsCoding Coding;
        VipsInterpretation Type;
        double Xres;
        double Yres;
        int Xoffset;
        int Yoffset;
        int Length;
        short Compression;
        short Level;
        int Bbits;
        VipsProgress *time;
        char *Hist;
        char *filename;
        void *data;
        int kill;
        float Xres_float;
        float Yres_float;
        char *mode;
        VipsImageType dtype;
        int fd;
        void *baseaddr;
        size_t length;
        unsigned long magic;
        void *(*start_fn)();
        int (*generate_fn)();
        int (*stop_fn)();
        void *client1;
        void *client2;
        void *sslock;
        void *regions;
        VipsDemandStyle dhint;
        void *meta;
        void *meta_traverse;
        long long sizeof_header;
        void *windows;
        void *upstream;
        void *downstream;
        int serial;
        void *history_list;
        struct _VipsImage *progress_signal;
        long long file_length;
        bool hint_set;
        bool delete_on_close;
        char *delete_on_close_filename;
    } VipsImage;

    VipsImage *vips_image_new( void );
    VipsImage *vips_image_new_mode( const char *name, const char *mode );
    VipsImage *vips_image_new_from_file( const char *name, ... );
    int vips_image_write( VipsImage *image, VipsImage *out );
    int vips_image_write_to_file( VipsImage *image, const char *filename, ... );

    void* vips_operation_new (const char* operation_name);
    void g_object_set_property (void* object, const char *name, GValue* value);
    void g_object_get_property (void* object, const char *name, GValue* value);
    void* vips_cache_operation_build (void* operation);
    void vips_object_unref_outputs (VipsObject *object);
    void g_object_unref(void* object);
    int vips_image_get_width( const VipsImage *image );
    int vips_image_get_height( const VipsImage *image );
    int vips_image_get_bands( const VipsImage *image );

]]

local image
local image_mt = {
    __gc = function(self)
        vips.g_object_unref(self)
    end,
    __index = {
        open = function(path, mode)
            return ffi.gc(vips.vips_image_new_mode(path, mode or "r"), vips.g_object_unref)
        end,
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
            value.set_int(value, width)
            vips.g_object_set_property(operation, "width", value)

            value = gvalue.new()
            value.init(value, gvalue.gint_type);
            value.set_int(value, height)
            vips.g_object_set_property(operation, "height", value)


            if  vips.vips_cache_operation_build( operation ) then
                vips.vips_object_unref_outputs( operation )
                vips.g_object_unref( operation )
                -- vips.vips_error_exit( NULL ) -- do we need this?
            end

            value = gvalue.new()
            value.init(value, gvalue.VipsImage_type)
            vips.g_object_get_property(operation, "out", value)
            img = gvalue.get_object( value )
            print("generated image: ", img)
            print("width: ", vips.vips_image_get_width(img) )
            print("height: ", vips.vips_image_get_height(img) )
        end,
        write_to_file = function(filename, options)
            print("write_to_file")
            print("  filename =", filename)
            print("  options =", options)

        end,
        insert = function(main, sub, x, y)
            local operation = vips.vips_operation_new("insert")

            local value;

            value = gvalue.new()
            value.init(value, gvalue.VipsImage_type);
            value.set_object(value, main)
            vips.g_object_set_property(operation, "main", value)

            value = gvalue.new()
            value.init(value, gvalue.VipsImage_type);
            value.set_object(value, sub)
            vips.g_object_set_property(operation, "sub", value)

            value = gvalue.new()
            value.init(value, gvalue.gint_type);
            value.set_int(value, x)
            vips.g_object_set_property(operation, "x", value)

            value = gvalue.new()
            value.init(value, gvalue.gint_type);
            value.set_int(value, y)
            vips.g_object_set_property(operation, "y", value)


            if  vips.vips_cache_operation_build( operation ) then
                vips.vips_object_unref_outputs( operation )
                vips.g_object_unref( operation )
                -- vips.vips_error_exit( NULL ) -- do we need this?
            end

            value = gvalue.new()
            value.init(value, gvalue.VipsImage_type)
            vips.g_object_get_property(operation, "out", value)
            img = gvalue.get_object( value )

            value = gvalue.new()
            value.init(value, gvalue.VipsImage_type)
            vips.g_object_get_property(operation, "out", value)
            img = gvalue.get_object( value )
            print("generated image: ", img)
            print("width: ", vips.vips_image_get_width(img) )
            print("height: ", vips.vips_image_get_height(img) )
            return img
        end,

        -- instance variables
        width = function(im)
            return vips.vips_image_get_width(im)
        end,
        height = function(im)
            return vips.vips_image_get_height(im)
        end,
        channels = function(im)
            return vips.vips_image_get_bands(im)
        end,
        save = function(im, path)
            return vips.vips_image_write_to_file(im, path)
        end
    }
}

image = ffi.metatype("VipsImage", image_mt)
return image
