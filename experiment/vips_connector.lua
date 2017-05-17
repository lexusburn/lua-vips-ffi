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
