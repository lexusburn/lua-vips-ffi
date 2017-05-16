-- connector code from zshipco (http://codegist.net/user/zshipko)
-- http://codegist.net/snippet/lua/vipslua_zshipko_lua

local ffi    = require("ffi")
local C      = ffi.C
local vips   = ffi.load("vips")
local log    = ngx.log
local INFO   = ngx.INFO
local WARN   = ngx.WARN
local ERR    = ngx.ERR

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
    }VipsObject ;

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

    typedef struct _VipsRect {
        int left;
        int top;
        int width;
        int height;
    } VipsRect;

    typedef struct _VipsRegion {
        VipsObject parent_object;
        VipsImage *im;
        VipsRect valid;
        int type;
        unsigned char *data;
        int bpl;
        void *seq;
        void *thread;
        void *window;
        void *buffer;
        bool invalid;
    } VipsRegion;

    VipsImage *vips_image_new( void );
    VipsImage *vips_image_new_mode( const char *name, const char *mode );
    VipsImage *vips_image_new_from_file( const char *name, ... );
    int vips_image_write( VipsImage *image, VipsImage *out );
    int vips_image_write_to_file( VipsImage *image, const char *filename, ... );
    int vips_insert (VipsImage *main, VipsImage *sub, VipsImage **out, int x, int y, ... );
    int vips_call( const char *operation_name, ... );
    void g_object_unref (void* object);
    int vips_image_get_width( const VipsImage *image );
    int vips_image_get_height( const VipsImage *image );
    int vips_image_get_bands( const VipsImage *image );

    VipsRegion *vips_region_new( VipsImage *image );
    int vips_region_prepare( VipsRegion *reg, VipsRect *r );
]]

local image
local image_mt = {
    __gc = function(self)
        vips.g_object_unref(self)
    end,
    __index = {
        run = function(cmd, ...)
            vips.vips_call(cmd, ...)
        end,
        out = function(cmd, im, ...)
            o = image.ptr()
            image.run(cmd, im, o, ...)
            return o[0]
        end,
        open = function(path, mode)
            return ffi.gc(vips.vips_image_new_mode(path, mode or "r"), vips.g_object_unref)
        end,
        new = function(width, height)
            if width == nil and height == nil then
                return ffi.gc(vips.vips_image_new(), vips.g_object_unref)
            end

            p = image.ptr()
            vips.vips_call("black", p, ffi.new("int", width), ffi.new("int", height))
            return p[0]
        end,
        ptr = function(im)
            out = ffi.new("VipsImage*[1]")
            out[0] = im or ffi.gc(vips.vips_image_new(), vips.g_object_unref)
            return out
        end,
        insert = function(main, sub, x, y)
            log(INFO, "vips insert called")
            o = image.ptr()
            width = image.width(main)
            height = image.height(main)
            log(INFO, "output image created")
            vips.vips_call("black", o, ffi.new("int", width), ffi.new("int", height))
            log(INFO, "output image modified")
            vips.vips_call("insert", main, sub, o, ffi.new("int", x), ffi.new("int", y))
            log(INFO, "sub inserted into main and created output")
            return o[0]
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
