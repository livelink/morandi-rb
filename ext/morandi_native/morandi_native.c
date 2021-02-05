#pragma GCC diagnostic ignored "-Wunused-but-set-variable"
/* Includes */
#include <ruby.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#if defined GCC
#define OPTIONAL_ATTR __attribute__((unused))
#else
#define OPTIONAL_ATTR
#endif

#include "gdk-pixbuf/gdk-pixbuf.h"
#include "rbglib.h"
#include "rbgobject.h"

/* Setup types */
/* Try not to clash with other definitions of bool... */
typedef int rubber_bool;
#define bool rubber_bool

/* Prototypes */

static VALUE mMorandiNative;
static VALUE cRedEye;
static VALUE mPixbufUtils;
static VALUE structRegion;


static VALUE
RedEye___alloc__(VALUE self OPTIONAL_ATTR);

static VALUE
RedEye_initialize(VALUE self OPTIONAL_ATTR, VALUE __v_pixbuf OPTIONAL_ATTR, VALUE __v_minX OPTIONAL_ATTR, VALUE __v_minY
                  OPTIONAL_ATTR, VALUE __v_maxX OPTIONAL_ATTR, VALUE __v_maxY OPTIONAL_ATTR);

static VALUE
RedEye_identify_blobs(int __p_argc, VALUE *__p_argv, VALUE self);

static VALUE
RedEye_correct_blob(VALUE self OPTIONAL_ATTR, VALUE __v_blob_id OPTIONAL_ATTR);

static VALUE
RedEye_highlight_blob(int __p_argc, VALUE *__p_argv, VALUE self);

static VALUE
RedEye_preview_blob(int __p_argc, VALUE *__p_argv, VALUE self);

static VALUE
RedEye_preview(VALUE self OPTIONAL_ATTR);

static VALUE
RedEye_pixbuf(VALUE self OPTIONAL_ATTR);


static VALUE
PixbufUtils_CLASS_sharpen(VALUE self OPTIONAL_ATTR, VALUE __v_src OPTIONAL_ATTR, VALUE __v_radius OPTIONAL_ATTR);

static VALUE
PixbufUtils_CLASS_extract_alpha(int __p_argc, VALUE *__p_argv, VALUE self);

static VALUE
PixbufUtils_CLASS_blur(VALUE self OPTIONAL_ATTR, VALUE __v_src OPTIONAL_ATTR, VALUE __v_radius OPTIONAL_ATTR);

static VALUE
PixbufUtils_CLASS_contrast(VALUE self OPTIONAL_ATTR, VALUE __v_src OPTIONAL_ATTR, VALUE __v_adjust OPTIONAL_ATTR);

static VALUE
PixbufUtils_CLASS_vibrance(VALUE self OPTIONAL_ATTR, VALUE __v_src OPTIONAL_ATTR, VALUE __v_adjust OPTIONAL_ATTR);

static VALUE
PixbufUtils_CLASS_saturation(VALUE self OPTIONAL_ATTR, VALUE __v_src OPTIONAL_ATTR, VALUE __v_adjust OPTIONAL_ATTR);

static VALUE
PixbufUtils_CLASS_brightness(VALUE self OPTIONAL_ATTR, VALUE __v_src OPTIONAL_ATTR, VALUE __v_adjust OPTIONAL_ATTR);

static VALUE
PixbufUtils_CLASS_filter(VALUE self OPTIONAL_ATTR, VALUE __v_src OPTIONAL_ATTR, VALUE filter OPTIONAL_ATTR,
                         VALUE __v_divisor OPTIONAL_ATTR);

static VALUE
PixbufUtils_CLASS_rotate_90(VALUE self OPTIONAL_ATTR, VALUE __v_src OPTIONAL_ATTR, VALUE __v_counter_clockwise
                            OPTIONAL_ATTR);

static VALUE
PixbufUtils_CLASS_rotate_cw(VALUE self OPTIONAL_ATTR, VALUE __v_src OPTIONAL_ATTR);

static VALUE
PixbufUtils_CLASS_rotate_180(VALUE self OPTIONAL_ATTR, VALUE __v_src OPTIONAL_ATTR);

static VALUE
PixbufUtils_CLASS_rotate(VALUE self OPTIONAL_ATTR, VALUE __v_src OPTIONAL_ATTR, VALUE __v_angle OPTIONAL_ATTR);

static VALUE
PixbufUtils_CLASS_rotate_ccw(VALUE self OPTIONAL_ATTR, VALUE __v_src OPTIONAL_ATTR);

static VALUE
PixbufUtils_CLASS_gamma_pling(VALUE self OPTIONAL_ATTR, VALUE __v_src OPTIONAL_ATTR, VALUE __v_level OPTIONAL_ATTR);

static VALUE
PixbufUtils_CLASS_soften_edges_pling(VALUE self OPTIONAL_ATTR, VALUE __v_src OPTIONAL_ATTR, VALUE __v_size
                                     OPTIONAL_ATTR);

static VALUE
PixbufUtils_CLASS_gamma(VALUE self OPTIONAL_ATTR, VALUE __v_src OPTIONAL_ATTR, VALUE __v_level OPTIONAL_ATTR);

static VALUE
PixbufUtils_CLASS_greyscale_pling(VALUE self OPTIONAL_ATTR, VALUE __v_src OPTIONAL_ATTR);

static VALUE
PixbufUtils_CLASS_greyscale(VALUE self OPTIONAL_ATTR, VALUE __v_src OPTIONAL_ATTR);

static VALUE
PixbufUtils_CLASS_greyscale_go_pling(VALUE self OPTIONAL_ATTR, VALUE __v_src OPTIONAL_ATTR);

static VALUE
PixbufUtils_CLASS_greyscale_go(VALUE self OPTIONAL_ATTR, VALUE __v_src OPTIONAL_ATTR);

static VALUE
PixbufUtils_CLASS_tint(int __p_argc, VALUE *__p_argv, VALUE self);

static VALUE
PixbufUtils_CLASS_perspect_v(VALUE self OPTIONAL_ATTR, VALUE __v_src OPTIONAL_ATTR, VALUE __v_top_x1 OPTIONAL_ATTR,
                             VALUE __v_top_x2 OPTIONAL_ATTR, VALUE __v_bot_x1 OPTIONAL_ATTR, VALUE __v_bot_x2
                             OPTIONAL_ATTR);

static VALUE
PixbufUtils_CLASS_mask(VALUE self OPTIONAL_ATTR, VALUE __v_src OPTIONAL_ATTR, VALUE __v_mask OPTIONAL_ATTR);

static VALUE
PixbufUtils_CLASS_auto_equalize(VALUE self OPTIONAL_ATTR, VALUE __v_src OPTIONAL_ATTR);

static VALUE
PixbufUtils_CLASS_blend5050(VALUE self OPTIONAL_ATTR, VALUE __v_src1 OPTIONAL_ATTR, VALUE __v_src2 OPTIONAL_ATTR);

static VALUE
PixbufUtils_CLASS_mask_area(int __p_argc, VALUE *__p_argv, VALUE self);

static VALUE
PixbufUtils_CLASS_scale_max(int __p_argc, VALUE *__p_argv, VALUE self);

/* Inline C code */

#define PIXEL(row, channels, x)  ((pixel_t)(row + (channels * x)))

typedef struct {
    unsigned char r, g, b, a;
} *pixel_t;

extern void Init_morandi_c(void);

#ifndef IGNORE
#define IGNORE(x) x=x
#endif

#include <unistd.h>
#include <math.h>

#include "extract-alpha.h"
#include "blur.h"
#include "sharpen.h"
#include "greyscale.h"
#include "rotate.h"
#include "gamma.h"
#include "mask.h"
#include "blend5050.h"
#include "tint.h"
#include "soften-edges.h"
#include "histogram.h"
#include "auto-equalize.h"
#include "filter.h"

/*
GdkPixbuf *pixbuf_op(GdkPixbuf *src, GdkPixbuf *dest,
*/

static GdkPixbuf *pixbuf_perspect_v(GdkPixbuf *src, int top_x1, int top_x2, int bot_x1, int bot_x2) {
    int s_width, s_height, s_rowstride;
    int d_width, d_height, d_rowstride;
    guchar *s_pix;
    guchar *d_pix;
    guchar *sp;
    guchar *dp;
    gboolean has_alpha;
    GdkPixbuf *dest;
    int min_x, max_x, top_width, bot_width;
    int x, y, alpha, channels, s_channels;
    int row_width;
    double row_offset, row_end;
    double row_offset2, row_end2;
    double left_theta, right_theta;
    pixel_t spx[3];
    double ex;

    s_width = gdk_pixbuf_get_width(src);
    s_height = gdk_pixbuf_get_height(src);
    has_alpha = gdk_pixbuf_get_has_alpha(src);
    s_rowstride = gdk_pixbuf_get_rowstride(src);
    s_pix = gdk_pixbuf_get_pixels(src);

    g_return_val_if_fail((top_x2 - top_x1) <= s_width, NULL);
    g_return_val_if_fail((bot_x2 - bot_x1) <= s_width, NULL);

    d_width = s_width;
    d_height = s_height;
    dest = gdk_pixbuf_new(GDK_COLORSPACE_RGB, TRUE, 8, d_width, d_height);
    d_rowstride = gdk_pixbuf_get_rowstride(dest);
    d_pix = gdk_pixbuf_get_pixels(dest);

    // Shortcut ... should be harmless?
    // We should really only touch info
    // Within the range d_pix + (d_rowstride * y) + ((has_alpha ? 4 : 3) * x)
    bzero(d_pix, (d_rowstride * d_height));

    top_width = top_x2 - top_x1;
    bot_width = bot_x2 - bot_x1;

    min_x = MIN(top_x1, bot_x1);
    max_x = MAX(top_x2, bot_x2);

    s_channels = has_alpha ? 4 : 3;
    channels = 4;

    left_theta = ((double) (min_x == bot_x1 ? top_x1 : bot_x1) - min_x) / (double) d_height;
    right_theta = ((double) max_x - ((max_x == bot_x2) ? top_x2 : bot_x2)) / (double) d_height;

    for (y = 0; y < d_height; y++) {
        sp = s_pix + (y * s_rowstride);

        row_offset = min_x;
        row_end = max_x;

        row_offset2 = min_x;
        row_end2 = max_x;

        row_offset += (left_theta * ((min_x == bot_x1) ? (d_height - y - 1) : y));
        row_end -= (right_theta * ((max_x == bot_x2) ? (d_height - y - 1) : y));

        row_offset2 += (left_theta * ((min_x == bot_x1) ? (d_height - y) : y + 1));
        row_end2 -= (right_theta * ((max_x == bot_x2) ? (d_height - y) : y + 1));

        row_width = ceil(row_end) - floor(row_offset);

        dp = d_pix + (y * d_rowstride) + ((int) floor(row_offset) * channels);

        for (x = (int) floor(row_offset); x < (int) ceil(row_end); x++) {
            ex = x - floor(row_offset);

            if ((x < ceil(row_offset))) {
                alpha = ((int) ((double) 255 * (ceil(row_offset) - row_offset)));
                alpha = MAX(alpha, 0);
            } else if ((x >= floor(row_end))) {
                alpha = ((int) ((double) 255 * (row_end - floor(row_end))));
                alpha = MAX(alpha, 0);
            } else {
                alpha = 0xff;
            }

            spx[0] = PIXEL(sp, s_channels, (int) floor(((ex - 1) * (double) s_width) / (double) row_width));
            spx[1] = PIXEL(sp, s_channels, (int) floor((ex * (double) s_width) / (double) row_width));
            spx[2] = PIXEL(sp, s_channels, (int) floor(((ex + 1) * (double) s_width) / (double) row_width));

            *(dp++) = ((spx[1]->r * 14) + ((spx[0]->r + spx[2]->r))) >> 4; /* red */
            *(dp++) = ((spx[1]->g * 14) + ((spx[0]->g + spx[2]->g))) >> 4; /* green */
            *(dp++) = ((spx[1]->b * 14) + ((spx[0]->b + spx[2]->b))) >> 4; /* blue */
            if (has_alpha)
                *(dp++) = sqrt(alpha * (((spx[1]->a * 14) + ((spx[0]->a + spx[2]->a))) >> 4));    /* alpha */
            else
                *(dp++) = alpha;    /* alpha */
        }

    }

    return dest;
}

static VALUE pixbuf_mask_area(GdkPixbuf *mask, double cutoff) {
    long int x0 = 0, x1 = 0, y0 = 0, y1 = 0;
    long int m_has_alpha;
    long int m_width, m_height, m_rowstride;
    guchar *m_pix, *mp;
    long int y, x;
    long pix_width;
    volatile
    double grey;

    g_return_val_if_fail(mask != NULL, Qnil);

    m_width = gdk_pixbuf_get_width(mask);
    m_height = gdk_pixbuf_get_height(mask);
    m_has_alpha = gdk_pixbuf_get_has_alpha(mask);
    m_rowstride = gdk_pixbuf_get_rowstride(mask);
    m_pix = gdk_pixbuf_get_pixels(mask);

    pix_width = (m_has_alpha ? 4 : 3);

    x1 = m_width;
    y1 = m_height;

    for (y = 0; y < m_height; y++) {
        mp = m_pix;
        for (x = 0; x < m_width; x++) {
            grey = GIMP_RGB_TO_GREY(mp[0], mp[1], mp[2]);
            if (grey < cutoff)// ie. darker than cutoff
            {
                if (x0 == 0) {
                    x0 = MAX(x0, x);
                    x1 = MIN(x1, x);
                } else {
                    x0 = MIN(x0, x);
                    x1 = MAX(x1, x);
                }

                if (y0 == 0) {
                    y0 = MAX(y0, y);
                    y1 = MIN(y1, y);
                } else {
                    y0 = MIN(y0, y);
                    y1 = MAX(y1, y);
                }
            }

            mp += pix_width;
        }
        m_pix += m_rowstride;
    }

    return rb_ary_new3(4, INT2NUM(x0), INT2NUM(y0), INT2NUM(x1), INT2NUM(y1));
}

static inline VALUE
unref_pixbuf(GdkPixbuf *pixbuf) {
    volatile VALUE pb = Qnil;

    pb = GOBJ2RVAL(pixbuf);

    g_object_unref(pixbuf);

    return pb;
}

typedef struct {
    char red, green, blue;
} rgb_t;

typedef struct {
    int minX, maxX, minY, maxY;
    int width, height;
    int noPixels, mergeWith;
} region_info;

typedef struct {
    struct {
        int minX, maxX, minY, maxY;
        int width, height;
    } area;
    struct {
        int *data;
        region_info *region;
        int len, size;
    } regions;
    int *mask;
    GdkPixbuf *pixbuf, *preview;
} redeyeop_t;

#define MIN_RED_VAL 20

static void identify_possible_redeye_pixels(redeyeop_t *op,
                                            double green_sensitivity, double blue_sensitivity,
                                            int min_red_val) {
    guchar *data = gdk_pixbuf_get_pixels(op->pixbuf);
    int rowstride = gdk_pixbuf_get_rowstride(op->pixbuf);
    int pixWidth = gdk_pixbuf_get_has_alpha(op->pixbuf) ? 4 : 3;

    int y, ry = 0, x, rx = 0;
    for (y = op->area.minY; y < op->area.maxY; y++) {
        guchar *thisLine = data + (rowstride * y);
        guchar *pixel;

        pixel = thisLine + (op->area.minX * pixWidth);
        rx = 0;

        for (x = op->area.minX; x < op->area.maxX; x++) {

            int r, g, b;

            r = pixel[0];
            g = pixel[1];
            b = pixel[2];

            gboolean threshMet;

            threshMet = (((double) r) > (green_sensitivity * (double) g)) &&
                        (((double) r) > (blue_sensitivity * (double) b)) &&
                        (r > min_red_val);

            if (threshMet)
                op->mask[rx + ry] = r;
            else
                op->mask[rx + ry] = 0; /* MEMZERO should have done its job ? */

            pixel += pixWidth;
            rx++;
        }

        ry += op->area.width;
    }
}

inline int group_at(redeyeop_t *op, int px, int py) {
    int index, region;

    if (px < 0 || py < 0)
        return 0;

    index = px + (py * op->area.width);

    if (index < 0)
        return 0;
    if (index > (op->area.width * op->area.height))
        return 0;

    region = op->regions.data[index];
    if (region > 0) {
        if (op->regions.region[region].mergeWith) {
            return op->regions.region[region].mergeWith;
        } else {
            return region;
        }
    } else {
        return 0;
    }
}

#define group_for(x, y) group_at(op, x, y)

static void identify_blob_groupings(redeyeop_t *op) {
    volatile int next_blob_id = 1, blob_id, y, x;

    for (y = 0; y < op->area.height; y++) {
        for (x = 0; x < op->area.width; x++) {
            if (op->mask[x + (y * op->area.width)] > 0) {
                gboolean existing = FALSE;
                int sx, sy, group = 0;
                // Target pixel is true
                blob_id = 0;

                for (sy = y; sy >= y - 1; sy--) {
                    sx = (sy == y) ? x : x + 1;
                    for (; sx >= (x - 1); sx--) {
                        /*if ((sx >= x) && (sy >= y))
                                goto blob_scan_done;*/

                        if (sx >= 0 && sy >= 0)
                            group = group_for(sx, sy);

                        if (group) {
                            existing = TRUE;
                            if (blob_id) {
                                int target = MIN(blob_id, group);
                                int from = MAX(blob_id, group);

                                if (op->regions.region[target].mergeWith > 0) {
                                    // Already merged
                                    target = op->regions.region[target].mergeWith;
                                }
                                op->regions.region[from].mergeWith = target;

                                // Merge blob_id & group
                            }
                            blob_id = group;
                        }
                    }
                }

                if (blob_id == 0) { // Allocate new group
                    blob_id = next_blob_id;
                    op->regions.region[blob_id].minX = x;
                    op->regions.region[blob_id].maxX = x;
                    op->regions.region[blob_id].minY = y;
                    op->regions.region[blob_id].maxY = y;
                    op->regions.region[blob_id].width = 1;
                    op->regions.region[blob_id].height = 1;
                    op->regions.region[blob_id].noPixels = 1;
                    op->regions.region[blob_id].mergeWith = 0;

                    next_blob_id++;
                    op->regions.len = next_blob_id;

                    if (next_blob_id >= op->regions.size) {
                        int extra, new_size;

                        /*
                         * Realloc in increasingly large chunks to reduce memory fragmentation
                         */
                        extra = op->regions.size;
                        new_size = op->regions.size + extra;

                        REALLOC_N(op->regions.region, region_info, new_size);

                        op->regions.size = new_size;
                    }
                }

                if (existing) {
                    op->regions.region[blob_id].minX = MIN(x, op->regions.region[blob_id].minX);
                    op->regions.region[blob_id].maxX = MAX(x, op->regions.region[blob_id].maxX);
                    op->regions.region[blob_id].minY = MIN(y, op->regions.region[blob_id].minY);
                    op->regions.region[blob_id].maxY = MAX(y, op->regions.region[blob_id].maxY);
                    op->regions.region[blob_id].width = op->regions.region[blob_id].maxX -
                                                        op->regions.region[blob_id].minX + 1;
                    op->regions.region[blob_id].height = op->regions.region[blob_id].maxY -
                                                         op->regions.region[blob_id].minY + 1;
                    op->regions.region[blob_id].noPixels++;
                }

                op->regions.data[x + (y * op->area.width)] = blob_id;
            }
        }
    }
    /*FILE *fp = fopen("regions.txt","w");*/
    for (y = 0; y < op->area.height; y++) {
        for (x = 0; x < op->area.width; x++) {
            int g = group_at(op, x, y); // Returns the merged group...
            op->regions.data[x + (y * op->area.width)] = g;
            /*
            if (op->regions.len <= 0xf || 1)
            {
            if (g == 0)
                fprintf(fp, " ");
            else
                fprintf(fp, "%x", g);
            }
            else
            {
            if (g == 0)
                fprintf(fp, "  ");
            else
                fprintf(fp, "%x ", g);
            }*/
        }
        /*fprintf(fp, "\n");*/
    }
    /*fclose(fp);*/
}

#define NO_REGIONS_DEFAULT 20
#define MIN_ID 1

static redeyeop_t *new_redeye(void) {
    redeyeop_t *ptr = ALLOC(redeyeop_t);
    MEMZERO(ptr, redeyeop_t, 1);
    return ptr;
}

static void free_redeye(redeyeop_t *ptr) {
    if (ptr->mask)
        free(ptr->mask);
    if (ptr->regions.data);
    free(ptr->regions.data);
    if (ptr->regions.region);
    free(ptr->regions.region);
    if (ptr->pixbuf)
        g_object_unref(ptr->pixbuf);
    if (ptr->preview)
        g_object_unref(ptr->preview);
    free(ptr);
}

inline gboolean in_region(redeyeop_t *op, int x, int y, int blob_id) {
    int index;

    if (x < op->area.minX || x > op->area.maxX ||
        y < op->area.minY || y > op->area.maxY)
        return FALSE;

    index = (x - op->area.minX) + ((y - op->area.minY) * op->area.width);

    return op->regions.data[index] == blob_id;
}

inline double alpha_level_for_pixel(redeyeop_t *op, int x, int y, int blob_id) {
    int j = 0, c = 0, xm, ym;

    if (in_region(op, x, y, blob_id))
        return 1.0;

    for (xm = -2; xm <= 2; xm++) {
        for (ym = -2; ym <= 2; ym++) {
            c++;
            if (xm == 0 && ym == 0)
                continue;
            if (in_region(op, x + xm, y + ym, blob_id))
                j++;
        }
    }

    return ((double) j) / ((double) c);
}

inline char col(double val) {
    if (val < 0) return 0;
    if (val > 255) return 255;
    return val;

}

static GdkPixbuf *redeye_preview(redeyeop_t *op, gboolean reset) {
    int width, height;
    width = op->area.width;
    height = op->area.height;

    if (width + op->area.minX > gdk_pixbuf_get_width(op->pixbuf)) {
        width = gdk_pixbuf_get_width(op->pixbuf) - op->area.minX;
    }
    if (height + op->area.minY > gdk_pixbuf_get_height(op->pixbuf)) {
        height = gdk_pixbuf_get_height(op->pixbuf) - op->area.minY;
    }

    if (op->preview == NULL) {
        GdkPixbuf *sub = NULL;
        sub = gdk_pixbuf_new_subpixbuf(op->pixbuf, op->area.minX, op->area.minY,
                                       width, height);

        op->preview = gdk_pixbuf_copy(sub);
        g_object_unref(sub);
    } else if (reset) {
        gdk_pixbuf_copy_area(op->pixbuf, op->area.minX, op->area.minY,
                             width, height, op->preview, 0, 0);
    }

    return op->preview;
}

static void desaturate_blob(redeyeop_t *op, int blob_id) {
    int y, x;
    int minX, minY, maxX, maxY;

    minY = MAX(0, op->area.minY + op->regions.region[blob_id].minY - 1);
    maxY = MIN(op->area.maxY + op->regions.region[blob_id].maxY + 1,
               gdk_pixbuf_get_height(op->pixbuf) - 1);
    minX = MAX(0, op->area.minX + op->regions.region[blob_id].minX - 1);
    maxX = MIN(op->area.maxX + op->regions.region[blob_id].maxX + 1,
               gdk_pixbuf_get_width(op->pixbuf) - 1);

    guchar *data = gdk_pixbuf_get_pixels(op->pixbuf);
    int rowstride = gdk_pixbuf_get_rowstride(op->pixbuf);
    int pixWidth = gdk_pixbuf_get_has_alpha(op->pixbuf) ? 4 : 3;

    for (y = minY; y <= maxY; y++) {
        guchar *thisLine = data + (rowstride * y);
        guchar *pixel;

        pixel = thisLine + (minX * pixWidth);

        for (x = minX; x <= maxX; x++) {

            double alpha = alpha_level_for_pixel(op, x, y, blob_id);
            int r, g, b, grey;

            r = pixel[0];
            g = pixel[1];
            b = pixel[2];

            if (alpha > 0) {
                grey = alpha * ((double) (5 * (double) r + 60 * (double) g + 30 * (double) b)) / 100.0 +
                       (1 - alpha) * r;

                pixel[0] = col((grey * alpha) + (1 - alpha) * r);
                pixel[1] = col((grey * alpha) + (1 - alpha) * g);
                pixel[2] = col((grey * alpha) + (1 - alpha) * b);
            }

            pixel += pixWidth;
        }
    }

}

static void highlight_blob(redeyeop_t *op, int blob_id, int colour) {
    int y, x;
    int minX, minY, maxX, maxY;
    int hr, hg, hb;

    hr = (colour >> 16) & 0xff;
    hg = (colour >> 8) & 0xff;
    hb = (colour) & 0xff;

    minY = MAX(0, op->area.minY - 1);
    maxY = MIN(op->area.maxY + 1, gdk_pixbuf_get_height(op->pixbuf) - 1);
    minX = MAX(0, op->area.minX - 1);
    maxX = MIN(op->area.maxX + 1, gdk_pixbuf_get_width(op->pixbuf) - 1);

    guchar *data = gdk_pixbuf_get_pixels(op->pixbuf);
    int rowstride = gdk_pixbuf_get_rowstride(op->pixbuf);
    int pixWidth = gdk_pixbuf_get_has_alpha(op->pixbuf) ? 4 : 3;

    for (y = minY; y <= maxY; y++) {
        guchar *thisLine = data + (rowstride * y);
        guchar *pixel;

        pixel = thisLine + (minX * pixWidth);

        for (x = minX; x <= maxX; x++) {

            double alpha = alpha_level_for_pixel(op, x, y, blob_id);
            int r, g, b;

            r = (pixel[0]);
            g = (pixel[1]);
            b = (pixel[2]);

            if (alpha > 0) {

                pixel[0] = col((1 - alpha) * r + (alpha * hr));
                pixel[1] = col((1 - alpha) * g + (alpha * hg));
                pixel[2] = col((1 - alpha) * b + (alpha * hb));
            }

            pixel += pixWidth;
        }
    }

}

static void preview_blob(redeyeop_t *op, int blob_id, int colour, gboolean reset_preview) {
    int y, x;
    int minX, minY, maxX, maxY;
    int hr, hg, hb;

    redeye_preview(op, reset_preview);

    hr = (colour >> 16) & 0xff;
    hg = (colour >> 8) & 0xff;
    hb = (colour) & 0xff;

    minY = 0;
    maxY = gdk_pixbuf_get_height(op->preview) - 1;
    minX = 0;
    maxX = gdk_pixbuf_get_width(op->preview) - 1;

    guchar *data = gdk_pixbuf_get_pixels(op->preview);
    int rowstride = gdk_pixbuf_get_rowstride(op->preview);
    int pixWidth = gdk_pixbuf_get_has_alpha(op->preview) ? 4 : 3;

    for (y = minY; y <= maxY; y++) {
        guchar *thisLine = data + (rowstride * y);
        guchar *pixel;

        pixel = thisLine + (minX * pixWidth);

        for (x = minX; x <= maxX; x++) {

            double alpha = alpha_level_for_pixel(op, x + op->area.minX, y + op->area.minY, blob_id);
            int r, g, b;

            r = (pixel[0]);
            g = (pixel[1]);
            b = (pixel[2]);

            if (alpha > 0) {

                pixel[0] = col((1 - alpha) * r + (alpha * hr));
                pixel[1] = col((1 - alpha) * g + (alpha * hg));
                pixel[2] = col((1 - alpha) * b + (alpha * hb));
            }

            pixel += pixWidth;
        }
    }

}

/* Code */

static VALUE
PixbufUtils_CLASS_sharpen(VALUE self OPTIONAL_ATTR, VALUE __v_src OPTIONAL_ATTR, VALUE __v_radius OPTIONAL_ATTR) {
    VALUE __p_retval OPTIONAL_ATTR = Qnil;
    GdkPixbuf *src;
    GdkPixbuf *__orig_src;
    int radius;
    int __orig_radius;
    __orig_src = src = GDK_PIXBUF(RVAL2GOBJ(__v_src));
    __orig_radius = radius = NUM2INT(__v_radius);

    IGNORE(self);
    do {
        __p_retval = unref_pixbuf((pixbuf_sharpen(src, radius)));
        goto out;
    }
    while (0);
    out:;
    return __p_retval;
}

static VALUE
PixbufUtils_CLASS_extract_alpha(int __p_argc, VALUE *__p_argv, VALUE self) {
    VALUE __p_retval OPTIONAL_ATTR = Qnil;
    VALUE __v_src = Qnil;
    GdkPixbuf *src;
    GdkPixbuf *__orig_src;
    VALUE __v_cutoff = Qnil;
    int cutoff;
    int __orig_cutoff;
    VALUE __v_force_2bit = Qnil;
    bool force_2bit;
    bool __orig_force_2bit;

    /* Scan arguments */
    rb_scan_args(__p_argc, __p_argv, "12", &__v_src, &__v_cutoff, &__v_force_2bit);

    /* Set defaults */
    __orig_src = src = GDK_PIXBUF(RVAL2GOBJ(__v_src));

    if (__p_argc > 1)
        __orig_cutoff = cutoff = NUM2INT(__v_cutoff);
    else
        cutoff = 127;

    if (__p_argc > 2)
        __orig_force_2bit = force_2bit = RTEST(__v_force_2bit);
    else
        force_2bit = FALSE;

    IGNORE(self);
    do {
        __p_retval = unref_pixbuf((pixbuf_extract_alpha(src, cutoff, force_2bit)));
        goto out;
    }
    while (0);
    out:;
    return __p_retval;
}

static VALUE
PixbufUtils_CLASS_blur(VALUE self OPTIONAL_ATTR, VALUE __v_src OPTIONAL_ATTR, VALUE __v_radius OPTIONAL_ATTR) {
    VALUE __p_retval OPTIONAL_ATTR = Qnil;
    GdkPixbuf *src;
    GdkPixbuf *__orig_src;
    int radius;
    int __orig_radius;
    __orig_src = src = GDK_PIXBUF(RVAL2GOBJ(__v_src));
    __orig_radius = radius = NUM2INT(__v_radius);

    IGNORE(self);
    do {
        __p_retval = unref_pixbuf((pixbuf_blur(gdk_pixbuf_copy(src), radius)));
        goto out;
    }
    while (0);
    out:;
    return __p_retval;
}

static VALUE
PixbufUtils_CLASS_contrast(VALUE self OPTIONAL_ATTR, VALUE __v_src OPTIONAL_ATTR, VALUE __v_adjust OPTIONAL_ATTR) {
    VALUE __p_retval OPTIONAL_ATTR = Qnil;
    GdkPixbuf *src;
    GdkPixbuf *__orig_src;
    int adjust;
    int __orig_adjust;
    __orig_src = src = GDK_PIXBUF(RVAL2GOBJ(__v_src));
    __orig_adjust = adjust = NUM2INT(__v_adjust);

    IGNORE(self);
    do {
        __p_retval = unref_pixbuf((pixbuf_adjust_contrast(src, gdk_pixbuf_copy(src), adjust)));
        goto out;
    }
    while (0);
    out:;
    return __p_retval;
}

static VALUE
PixbufUtils_CLASS_vibrance(VALUE self OPTIONAL_ATTR, VALUE __v_src OPTIONAL_ATTR, VALUE __v_adjust OPTIONAL_ATTR) {
    VALUE __p_retval OPTIONAL_ATTR = Qnil;
    GdkPixbuf *src;
    GdkPixbuf *__orig_src;
    int adjust;
    int __orig_adjust;
    __orig_src = src = GDK_PIXBUF(RVAL2GOBJ(__v_src));
    __orig_adjust = adjust = NUM2INT(__v_adjust);

    IGNORE(self);
    do {
        __p_retval = unref_pixbuf((pixbuf_adjust_vibrance(src, gdk_pixbuf_copy(src), adjust)));
        goto out;
    }
    while (0);
    out:;
    return __p_retval;
}

static VALUE
PixbufUtils_CLASS_saturation(VALUE self OPTIONAL_ATTR, VALUE __v_src OPTIONAL_ATTR, VALUE __v_adjust OPTIONAL_ATTR) {
    VALUE __p_retval OPTIONAL_ATTR = Qnil;
    GdkPixbuf *src;
    GdkPixbuf *__orig_src;
    int adjust;
    int __orig_adjust;
    __orig_src = src = GDK_PIXBUF(RVAL2GOBJ(__v_src));
    __orig_adjust = adjust = NUM2INT(__v_adjust);

    IGNORE(self);
    do {
        __p_retval = unref_pixbuf((pixbuf_adjust_saturation(src, gdk_pixbuf_copy(src), adjust)));
        goto out;
    }
    while (0);
    out:;
    return __p_retval;
}

static VALUE
PixbufUtils_CLASS_brightness(VALUE self OPTIONAL_ATTR, VALUE __v_src OPTIONAL_ATTR, VALUE __v_adjust OPTIONAL_ATTR) {
    VALUE __p_retval OPTIONAL_ATTR = Qnil;
    GdkPixbuf *src;
    GdkPixbuf *__orig_src;
    int adjust;
    int __orig_adjust;
    __orig_src = src = GDK_PIXBUF(RVAL2GOBJ(__v_src));
    __orig_adjust = adjust = NUM2INT(__v_adjust);

    IGNORE(self);
    do {
        __p_retval = unref_pixbuf((pixbuf_adjust_brightness(src, gdk_pixbuf_copy(src), adjust)));
        goto out;
    }
    while (0);
    out:;
    return __p_retval;
}

static VALUE
PixbufUtils_CLASS_filter(VALUE self OPTIONAL_ATTR, VALUE __v_src OPTIONAL_ATTR, VALUE filter OPTIONAL_ATTR,
                         VALUE __v_divisor OPTIONAL_ATTR) {
    VALUE __p_retval OPTIONAL_ATTR = Qnil;
    GdkPixbuf *src;
    GdkPixbuf *__orig_src;
    double divisor;
    double __orig_divisor;
    __orig_src = src = GDK_PIXBUF(RVAL2GOBJ(__v_src));
    Check_Type(filter, T_ARRAY);
    __orig_divisor = divisor = NUM2DBL(__v_divisor);

    do {
        int matrix_size = RARRAY_LEN(filter), len, i;
        double *matrix;
        IGNORE(self);
        len = (int) sqrt((double) matrix_size);
        if ((len * len) != matrix_size) {
            rb_raise(rb_eArgError, "Invalid matrix size - sqrt(%i)*sqrt(%i) != %i", matrix_size, matrix_size,
                     matrix_size);
        }
        matrix = ALLOCA_N(
        double, matrix_size);
        for (i = 0;
             i < matrix_size;
             i++) {
            matrix[i] = NUM2DBL(RARRAY_PTR(filter)[i]);
        }
        do {
            __p_retval = unref_pixbuf((pixbuf_convolution_matrix(src, gdk_pixbuf_copy(src), len, matrix, divisor)));
            goto out;
        }
        while (0);

    } while (0);

    out:;
    return __p_retval;
}

static VALUE
PixbufUtils_CLASS_rotate_90(VALUE self OPTIONAL_ATTR, VALUE __v_src OPTIONAL_ATTR, VALUE __v_counter_clockwise
                            OPTIONAL_ATTR) {
    VALUE __p_retval OPTIONAL_ATTR = Qnil;
    GdkPixbuf *src;
    GdkPixbuf *__orig_src;
    bool counter_clockwise;
    bool __orig_counter_clockwise;
    __orig_src = src = GDK_PIXBUF(RVAL2GOBJ(__v_src));
    __orig_counter_clockwise = counter_clockwise = RTEST(__v_counter_clockwise);

    IGNORE(self);
    do {
        __p_retval = unref_pixbuf((pixbuf_rotate(src, counter_clockwise ? ANGLE_270 : ANGLE_90)));
        goto out;
    }
    while (0);
    out:;
    return __p_retval;
}

static VALUE
PixbufUtils_CLASS_rotate_cw(VALUE self OPTIONAL_ATTR, VALUE __v_src OPTIONAL_ATTR) {
    VALUE __p_retval OPTIONAL_ATTR = Qnil;
    GdkPixbuf *src;
    GdkPixbuf *__orig_src;
    __orig_src = src = GDK_PIXBUF(RVAL2GOBJ(__v_src));

    IGNORE(self);
    do {
        __p_retval = unref_pixbuf((pixbuf_rotate(src, ANGLE_90)));
        goto out;
    }
    while (0);
    out:;
    return __p_retval;
}

static VALUE
PixbufUtils_CLASS_rotate_180(VALUE self OPTIONAL_ATTR, VALUE __v_src OPTIONAL_ATTR) {
    VALUE __p_retval OPTIONAL_ATTR = Qnil;
    GdkPixbuf *src;
    GdkPixbuf *__orig_src;
    __orig_src = src = GDK_PIXBUF(RVAL2GOBJ(__v_src));

    IGNORE(self);
    do {
        __p_retval = unref_pixbuf((pixbuf_rotate(src, ANGLE_180)));
        goto out;
    }
    while (0);
    out:;
    return __p_retval;
}

static VALUE
PixbufUtils_CLASS_rotate(VALUE self OPTIONAL_ATTR, VALUE __v_src OPTIONAL_ATTR, VALUE __v_angle OPTIONAL_ATTR) {
    VALUE __p_retval OPTIONAL_ATTR = Qnil;
    GdkPixbuf *src;
    GdkPixbuf *__orig_src;
    int angle;
    int __orig_angle;
    __orig_src = src = GDK_PIXBUF(RVAL2GOBJ(__v_src));
    __orig_angle = angle = NUM2INT(__v_angle);

    IGNORE(self);
    g_assert(angle == 0 || angle == 90 || angle == 180 || angle == 270);
    do {
        __p_retval = unref_pixbuf((pixbuf_rotate(src, (rotate_angle_t) angle)));
        goto out;
    }
    while (0);
    out:;
    return __p_retval;
}

static VALUE
PixbufUtils_CLASS_rotate_ccw(VALUE self OPTIONAL_ATTR, VALUE __v_src OPTIONAL_ATTR) {
    VALUE __p_retval OPTIONAL_ATTR = Qnil;
    GdkPixbuf *src;
    GdkPixbuf *__orig_src;
    __orig_src = src = GDK_PIXBUF(RVAL2GOBJ(__v_src));

    IGNORE(self);
    do {
        __p_retval = unref_pixbuf((pixbuf_rotate(src, ANGLE_270)));
        goto out;
    }
    while (0);
    out:;
    return __p_retval;
}

static VALUE
PixbufUtils_CLASS_gamma_pling(VALUE self OPTIONAL_ATTR, VALUE __v_src OPTIONAL_ATTR, VALUE __v_level OPTIONAL_ATTR) {
    VALUE __p_retval OPTIONAL_ATTR = Qnil;
    GdkPixbuf *src;
    GdkPixbuf *__orig_src;
    double level;
    double __orig_level;
    __orig_src = src = GDK_PIXBUF(RVAL2GOBJ(__v_src));
    __orig_level = level = NUM2DBL(__v_level);

    IGNORE(self);
    do {
        __p_retval = GOBJ2RVAL(pixbuf_gamma(src, src, level));
        goto out;
    }
    while (0);
    out:;
    return __p_retval;
}

static VALUE
PixbufUtils_CLASS_soften_edges_pling(VALUE self OPTIONAL_ATTR, VALUE __v_src OPTIONAL_ATTR, VALUE __v_size
                                     OPTIONAL_ATTR) {
    VALUE __p_retval OPTIONAL_ATTR = Qnil;
    GdkPixbuf *src;
    GdkPixbuf *__orig_src;
    int size;
    int __orig_size;
    __orig_src = src = GDK_PIXBUF(RVAL2GOBJ(__v_src));
    __orig_size = size = NUM2INT(__v_size);

    IGNORE(self);
    do {
        __p_retval = GOBJ2RVAL(pixbuf_soften_edges(src, size));
        goto out;
    }
    while (0);
    out:;
    return __p_retval;
}

static VALUE
PixbufUtils_CLASS_gamma(VALUE self OPTIONAL_ATTR, VALUE __v_src OPTIONAL_ATTR, VALUE __v_level OPTIONAL_ATTR) {
    VALUE __p_retval OPTIONAL_ATTR = Qnil;
    GdkPixbuf *src;
    GdkPixbuf *__orig_src;
    double level;
    double __orig_level;
    __orig_src = src = GDK_PIXBUF(RVAL2GOBJ(__v_src));
    __orig_level = level = NUM2DBL(__v_level);

    IGNORE(self);
    do {
        __p_retval = unref_pixbuf((pixbuf_gamma(src, gdk_pixbuf_copy(src), level)));
        goto out;
    }
    while (0);
    out:;
    return __p_retval;
}

static VALUE
PixbufUtils_CLASS_greyscale_pling(VALUE self OPTIONAL_ATTR, VALUE __v_src OPTIONAL_ATTR) {
    VALUE __p_retval OPTIONAL_ATTR = Qnil;
    GdkPixbuf *src;
    GdkPixbuf *__orig_src;
    __orig_src = src = GDK_PIXBUF(RVAL2GOBJ(__v_src));

    IGNORE(self);
    do {
        __p_retval = GOBJ2RVAL(pixbuf_greyscale(src, src));
        goto out;
    }
    while (0);
    out:;
    return __p_retval;
}

static VALUE
PixbufUtils_CLASS_greyscale(VALUE self OPTIONAL_ATTR, VALUE __v_src OPTIONAL_ATTR) {
    VALUE __p_retval OPTIONAL_ATTR = Qnil;
    GdkPixbuf *src;
    GdkPixbuf *__orig_src;
    __orig_src = src = GDK_PIXBUF(RVAL2GOBJ(__v_src));

    IGNORE(self);
    do {
        __p_retval = unref_pixbuf((pixbuf_greyscale(src, gdk_pixbuf_copy(src))));
        goto out;
    }
    while (0);
    out:;
    return __p_retval;
}

static VALUE
PixbufUtils_CLASS_greyscale_go_pling(VALUE self OPTIONAL_ATTR, VALUE __v_src OPTIONAL_ATTR) {
    VALUE __p_retval OPTIONAL_ATTR = Qnil;
    GdkPixbuf *src;
    GdkPixbuf *__orig_src;
    __orig_src = src = GDK_PIXBUF(RVAL2GOBJ(__v_src));

    IGNORE(self);
    do {
        __p_retval = GOBJ2RVAL(pixbuf_greyscale_go(src, src));
        goto out;
    }
    while (0);
    out:;
    return __p_retval;
}

static VALUE
PixbufUtils_CLASS_greyscale_go(VALUE self OPTIONAL_ATTR, VALUE __v_src OPTIONAL_ATTR) {
    VALUE __p_retval OPTIONAL_ATTR = Qnil;
    GdkPixbuf *src;
    GdkPixbuf *__orig_src;
    __orig_src = src = GDK_PIXBUF(RVAL2GOBJ(__v_src));

    IGNORE(self);
    do {
        __p_retval = unref_pixbuf((pixbuf_greyscale_go(src, gdk_pixbuf_copy(src))));
        goto out;
    }
    while (0);
    out:;
    return __p_retval;
}

static VALUE
PixbufUtils_CLASS_tint(int __p_argc, VALUE *__p_argv, VALUE self) {
    VALUE __p_retval OPTIONAL_ATTR = Qnil;
    VALUE __v_src = Qnil;
    GdkPixbuf *src;
    GdkPixbuf *__orig_src;
    VALUE __v_r = Qnil;
    int r;
    int __orig_r;
    VALUE __v_g = Qnil;
    int g;
    int __orig_g;
    VALUE __v_b = Qnil;
    int b;
    int __orig_b;
    VALUE __v_alpha = Qnil;
    int alpha;
    int __orig_alpha;

    /* Scan arguments */
    rb_scan_args(__p_argc, __p_argv, "41", &__v_src, &__v_r, &__v_g, &__v_b, &__v_alpha);

    /* Set defaults */
    __orig_src = src = GDK_PIXBUF(RVAL2GOBJ(__v_src));

    __orig_r = r = NUM2INT(__v_r);

    __orig_g = g = NUM2INT(__v_g);

    __orig_b = b = NUM2INT(__v_b);

    if (__p_argc > 4)
        __orig_alpha = alpha = NUM2INT(__v_alpha);
    else
        alpha = 255;

    IGNORE(self);
    do {
        __p_retval = unref_pixbuf((pixbuf_tint(src, gdk_pixbuf_copy(src), r, g, b, alpha)));
        goto out;
    }
    while (0);
    out:;
    return __p_retval;
}

static VALUE
PixbufUtils_CLASS_perspect_v(VALUE self OPTIONAL_ATTR, VALUE __v_src OPTIONAL_ATTR, VALUE __v_top_x1 OPTIONAL_ATTR,
                             VALUE __v_top_x2 OPTIONAL_ATTR, VALUE __v_bot_x1 OPTIONAL_ATTR, VALUE __v_bot_x2
                             OPTIONAL_ATTR) {
    VALUE __p_retval OPTIONAL_ATTR = Qnil;
    GdkPixbuf *src;
    GdkPixbuf *__orig_src;
    int top_x1;
    int __orig_top_x1;
    int top_x2;
    int __orig_top_x2;
    int bot_x1;
    int __orig_bot_x1;
    int bot_x2;
    int __orig_bot_x2;
    __orig_src = src = GDK_PIXBUF(RVAL2GOBJ(__v_src));
    __orig_top_x1 = top_x1 = NUM2INT(__v_top_x1);
    __orig_top_x2 = top_x2 = NUM2INT(__v_top_x2);
    __orig_bot_x1 = bot_x1 = NUM2INT(__v_bot_x1);
    __orig_bot_x2 = bot_x2 = NUM2INT(__v_bot_x2);

    IGNORE(self);
    do {
        __p_retval = unref_pixbuf((pixbuf_perspect_v(src, top_x1, top_x2, bot_x1, bot_x2)));
        goto out;
    }
    while (0);
    out:;
    return __p_retval;
}

static VALUE
PixbufUtils_CLASS_mask(VALUE self OPTIONAL_ATTR, VALUE __v_src OPTIONAL_ATTR, VALUE __v_mask OPTIONAL_ATTR) {
    VALUE __p_retval OPTIONAL_ATTR = Qnil;
    GdkPixbuf *src;
    GdkPixbuf *__orig_src;
    GdkPixbuf *mask;
    GdkPixbuf *__orig_mask;
    __orig_src = src = GDK_PIXBUF(RVAL2GOBJ(__v_src));
    __orig_mask = mask = GDK_PIXBUF(RVAL2GOBJ(__v_mask));

    IGNORE(self);
    do {
        __p_retval = unref_pixbuf((pixbuf_mask(src, mask)));
        goto out;
    }
    while (0);
    out:;
    return __p_retval;
}

static VALUE
PixbufUtils_CLASS_auto_equalize(VALUE self OPTIONAL_ATTR, VALUE __v_src OPTIONAL_ATTR) {
    VALUE __p_retval OPTIONAL_ATTR = Qnil;
    GdkPixbuf *src;
    GdkPixbuf *__orig_src;
    __orig_src = src = GDK_PIXBUF(RVAL2GOBJ(__v_src));

    IGNORE(self);
    do {
        __p_retval = unref_pixbuf((auto_equalize(src, gdk_pixbuf_copy(src))));
        goto out;
    }
    while (0);
    out:;
    return __p_retval;
}

static VALUE
PixbufUtils_CLASS_blend5050(VALUE self OPTIONAL_ATTR, VALUE __v_src1 OPTIONAL_ATTR, VALUE __v_src2 OPTIONAL_ATTR) {
    VALUE __p_retval OPTIONAL_ATTR = Qnil;
    GdkPixbuf *src1;
    GdkPixbuf *__orig_src1;
    GdkPixbuf *src2;
    GdkPixbuf *__orig_src2;
    __orig_src1 = src1 = GDK_PIXBUF(RVAL2GOBJ(__v_src1));
    __orig_src2 = src2 = GDK_PIXBUF(RVAL2GOBJ(__v_src2));

    IGNORE(self);
    do {
        __p_retval = unref_pixbuf((pixbuf_blend5050(src1, src2)));
        goto out;
    }
    while (0);
    out:;
    return __p_retval;
}

static VALUE
PixbufUtils_CLASS_mask_area(int __p_argc, VALUE *__p_argv, VALUE self) {
    VALUE __p_retval OPTIONAL_ATTR = Qnil;
    VALUE __v_mask = Qnil;
    GdkPixbuf *mask;
    GdkPixbuf *__orig_mask;
    VALUE __v_cutoff = Qnil;
    int cutoff;
    int __orig_cutoff;

    /* Scan arguments */
    rb_scan_args(__p_argc, __p_argv, "11", &__v_mask, &__v_cutoff);

    /* Set defaults */
    __orig_mask = mask = GDK_PIXBUF(RVAL2GOBJ(__v_mask));

    if (__p_argc > 1)
        __orig_cutoff = cutoff = NUM2INT(__v_cutoff);
    else
        cutoff = 127;

    IGNORE(self);
    do {
        __p_retval = pixbuf_mask_area(mask, cutoff);
        goto out;
    }
    while (0);
    out:;
    return __p_retval;
}

static VALUE
PixbufUtils_CLASS_scale_max(int __p_argc, VALUE *__p_argv, VALUE self) {
    VALUE __p_retval OPTIONAL_ATTR = Qnil;
    VALUE __v_src = Qnil;
    GdkPixbuf *src;
    GdkPixbuf *__orig_src;
    VALUE __v_max = Qnil;
    gulong max;
    gulong __orig_max;
    VALUE __v_interp = Qnil;
    GdkInterpType interp;
    GdkInterpType __orig_interp;

    /* Scan arguments */
    rb_scan_args(__p_argc, __p_argv, "21", &__v_src, &__v_max, &__v_interp);

    /* Set defaults */
    __orig_src = src = GDK_PIXBUF(RVAL2GOBJ(__v_src));

    __orig_max = max = NUM2UINT(__v_max);

    if (__p_argc > 2)
        __orig_interp = interp = RVAL2GENUM(__v_interp, GDK_TYPE_INTERP_TYPE);
    else
        interp = GDK_INTERP_BILINEAR;

    do {
        gulong width, height, largest;
        gdouble scale;
        IGNORE(self);
        width = gdk_pixbuf_get_width(src);
        height = gdk_pixbuf_get_height(src);
        largest = MAX(width, height);
        if (max > largest) {
            do {
                __p_retval = unref_pixbuf((gdk_pixbuf_copy(src)));
                goto out;
            }
            while (0);
        }
        scale = (double) (max) / (double) (largest);
        do {
            __p_retval = unref_pixbuf(
                    (gdk_pixbuf_scale_simple(src, (int) (scale * width), (int) (scale * height), interp)));
            goto out;
        }
        while (0);

    } while (0);

    out:;
    return __p_retval;
}

static VALUE
RedEye___alloc__(VALUE self OPTIONAL_ATTR) {
    VALUE __p_retval OPTIONAL_ATTR = Qnil;

    do {
        __p_retval = Data_Wrap_Struct(self, NULL, free_redeye, new_redeye());
        goto out;
    }
    while (0);
    out:
    return __p_retval;
}

static VALUE
RedEye_initialize(VALUE self OPTIONAL_ATTR, VALUE __v_pixbuf OPTIONAL_ATTR, VALUE __v_minX OPTIONAL_ATTR, VALUE __v_minY
                  OPTIONAL_ATTR, VALUE __v_maxX OPTIONAL_ATTR, VALUE __v_maxY OPTIONAL_ATTR) {
    GdkPixbuf *pixbuf;
    GdkPixbuf *__orig_pixbuf;
    int minX;
    int __orig_minX;
    int minY;
    int __orig_minY;
    int maxX;
    int __orig_maxX;
    int maxY;
    int __orig_maxY;
    __orig_pixbuf = pixbuf = GDK_PIXBUF(RVAL2GOBJ(__v_pixbuf));
    __orig_minX = minX = NUM2INT(__v_minX);
    __orig_minY = minY = NUM2INT(__v_minY);
    __orig_maxX = maxX = NUM2INT(__v_maxX);
    __orig_maxY = maxY = NUM2INT(__v_maxY);

    do {
        redeyeop_t *op;
        Data_Get_Struct(self, redeyeop_t, op);
        op->pixbuf = pixbuf;
        op->preview = NULL;
        g_object_ref(op->pixbuf);
        op->area.minX = minX;
        op->area.maxX = maxX;
        op->area.minY = minY;
        op->area.maxY = maxY;
        op->area.width = maxX - minX + 1;
        op->area.height = maxY - minY + 1;
        g_assert(op->pixbuf != NULL);
        g_assert(op->area.maxX <= gdk_pixbuf_get_width(op->pixbuf));
        g_assert(op->area.minX >= 0);
        g_assert(op->area.minX < op->area.maxX);
        g_assert(op->area.maxY <= gdk_pixbuf_get_height(op->pixbuf));
        g_assert(op->area.minY >= 0);
        g_assert(op->area.minY < op->area.maxY);
        op->mask = ALLOC_N(
        int, op->area.width * op->area.height);
        op->regions.data = ALLOC_N(
        int, op->area.width * op->area.height);
        op->regions.region = ALLOC_N(region_info, NO_REGIONS_DEFAULT);
        op->regions.len = 0;
        op->regions.size = NO_REGIONS_DEFAULT;

    } while (0);

    ;
    return Qnil;
}

static VALUE
RedEye_identify_blobs(int __p_argc, VALUE *__p_argv, VALUE self) {
    VALUE __p_retval OPTIONAL_ATTR = Qnil;
    VALUE __v_green_sensitivity = Qnil;
    double green_sensitivity;
    double __orig_green_sensitivity;
    VALUE __v_blue_sensitivity = Qnil;
    double blue_sensitivity;
    double __orig_blue_sensitivity;
    VALUE __v_min_red_val = Qnil;
    int min_red_val;
    int __orig_min_red_val;

    /* Scan arguments */
    rb_scan_args(__p_argc, __p_argv, "03", &__v_green_sensitivity, &__v_blue_sensitivity, &__v_min_red_val);

    /* Set defaults */
    if (__p_argc > 0)
        __orig_green_sensitivity = green_sensitivity = NUM2DBL(__v_green_sensitivity);
    else
        green_sensitivity = 2.0;

    if (__p_argc > 1)
        __orig_blue_sensitivity = blue_sensitivity = NUM2DBL(__v_blue_sensitivity);
    else
        blue_sensitivity = 0.0;

    if (__p_argc > 2)
        __orig_min_red_val = min_red_val = NUM2INT(__v_min_red_val);
    else
        min_red_val = MIN_RED_VAL;

    do {
        redeyeop_t *op;
        Data_Get_Struct(self, redeyeop_t, op);
        MEMZERO(op->mask,
        int, op->area.width * op->area.height);
        MEMZERO(op->regions.data,
        int, op->area.width * op->area.height);
        identify_possible_redeye_pixels(op, green_sensitivity, blue_sensitivity, min_red_val);
        identify_blob_groupings(op);
        volatile VALUE ary =
                rb_ary_new2(op->regions.len);
        int i;
        for (i = MIN_ID;
             i < op->regions.len;
             i++) {
            region_info *r =
                    &op->regions.region[i];
            /* Ignore CCD noise */ if (r->noPixels < 2) continue;
            rb_ary_push(ary, rb_struct_new(structRegion, self, INT2NUM(i), INT2NUM(r->minX), INT2NUM(r->minY),
                                           INT2NUM(r->maxX), INT2NUM(r->maxY), INT2NUM(r->width), INT2NUM(r->height),
                                           INT2NUM(r->noPixels)));
        }
        do {
            __p_retval = ary;
            goto out;
        }
        while (0);

    } while (0);

    out:
    return __p_retval;
}

static VALUE
RedEye_correct_blob(VALUE self OPTIONAL_ATTR, VALUE __v_blob_id OPTIONAL_ATTR) {
    int blob_id;
    int __orig_blob_id;
    __orig_blob_id = blob_id = NUM2INT(__v_blob_id);

    do {
        redeyeop_t *op;
        Data_Get_Struct(self, redeyeop_t, op);
        if (op->regions.len <= blob_id)
            rb_raise(rb_eIndexError, "Only %i blobs in region - %i is invalid", op->regions.len, blob_id);
        desaturate_blob(op, blob_id);

    } while (0);

    return Qnil;
}

static VALUE
RedEye_highlight_blob(int __p_argc, VALUE *__p_argv, VALUE self) {
    VALUE __v_blob_id = Qnil;
    int blob_id;
    int __orig_blob_id;
    VALUE __v_col = Qnil;
    int col;
    int __orig_col;

    /* Scan arguments */
    rb_scan_args(__p_argc, __p_argv, "11", &__v_blob_id, &__v_col);

    /* Set defaults */
    __orig_blob_id = blob_id = NUM2INT(__v_blob_id);

    if (__p_argc > 1)
        __orig_col = col = NUM2INT(__v_col);
    else
        col = 0x00ff00;

    do {
        redeyeop_t *op;
        Data_Get_Struct(self, redeyeop_t, op);
        if (op->regions.len <= blob_id)
            rb_raise(rb_eIndexError, "Only %i blobs in region - %i is invalid", op->regions.len, blob_id);
        highlight_blob(op, blob_id, col);

    } while (0);

    return Qnil;
}

static VALUE
RedEye_preview_blob(int __p_argc, VALUE *__p_argv, VALUE self) {
    VALUE __p_retval OPTIONAL_ATTR = Qnil;
    VALUE __v_blob_id = Qnil;
    int blob_id;
    int __orig_blob_id;
    VALUE __v_col = Qnil;
    int col;
    int __orig_col;
    VALUE __v_reset_preview = Qnil;
    gboolean reset_preview;
    gboolean __orig_reset_preview;

    /* Scan arguments */
    rb_scan_args(__p_argc, __p_argv, "12", &__v_blob_id, &__v_col, &__v_reset_preview);

    /* Set defaults */
    __orig_blob_id = blob_id = NUM2INT(__v_blob_id);

    if (__p_argc > 1)
        __orig_col = col = NUM2INT(__v_col);
    else
        col = 0x00ff00;

    if (__p_argc > 2)
        __orig_reset_preview = reset_preview = RTEST(__v_reset_preview);
    else
        reset_preview = TRUE;

    do {
        redeyeop_t *op;
        Data_Get_Struct(self, redeyeop_t, op);
        if (op->regions.len <= blob_id)
            rb_raise(rb_eIndexError, "Only %i blobs in region - %i is invalid", op->regions.len, blob_id);
        preview_blob(op, blob_id, col, reset_preview);
        do {
            __p_retval = GOBJ2RVAL(GDK_PIXBUF(op->preview));
            goto out;
        }
        while (0);

    } while (0);

    out:
    return __p_retval;
}

static VALUE
RedEye_preview(VALUE self OPTIONAL_ATTR) {
    VALUE __p_retval OPTIONAL_ATTR = Qnil;

    do {
        redeyeop_t *op;
        Data_Get_Struct(self, redeyeop_t, op);
        do {
            __p_retval = GOBJ2RVAL(GDK_PIXBUF(redeye_preview(op, FALSE)));
            goto out;
        }
        while (0);

    } while (0);

    out:
    return __p_retval;
}

static VALUE
RedEye_pixbuf(VALUE self OPTIONAL_ATTR) {
    VALUE __p_retval OPTIONAL_ATTR = Qnil;

    do {
        redeyeop_t *op;
        Data_Get_Struct(self, redeyeop_t, op);
        do {
            __p_retval = GOBJ2RVAL(GDK_PIXBUF(op->pixbuf));
            goto out;
        }
        while (0);

    } while (0);

    out:
    return __p_retval;
}

static VALUE
Region_ratio(VALUE self OPTIONAL_ATTR) {
    VALUE __p_retval OPTIONAL_ATTR = Qnil;

    int width, height;
    double min, max, ratio;
    width = NUM2INT(rb_struct_getmember(self, rb_intern("width")));
    height = NUM2INT(rb_struct_getmember(self, rb_intern("height")));
    min = (double) MIN(width, height);
    max = (double) MAX(width, height);
    ratio = (min / max);
    do {
        __p_retval = rb_float_new(ratio);
        goto out;
    }
    while (0);
    out:
    return __p_retval;
}

static VALUE
Region_density(VALUE self OPTIONAL_ATTR) {
    VALUE __p_retval OPTIONAL_ATTR = Qnil;

    do {
        int noPixels, width, height;
        double density;
        noPixels = NUM2INT(rb_struct_getmember(self, rb_intern("noPixels")));
        width = NUM2INT(rb_struct_getmember(self, rb_intern("width")));
        height = NUM2INT(rb_struct_getmember(self, rb_intern("height")));
        density = ((double) noPixels / (double) (width * height));
        do {
            __p_retval = rb_float_new(density);
            goto out;
        }
        while (0);

    } while (0);

    out:
    return __p_retval;
}

static VALUE
Region_squareish_query(int __p_argc, VALUE *__p_argv, VALUE self) {
    VALUE __p_retval OPTIONAL_ATTR = Qnil;
    VALUE __v_min_ratio = Qnil;
    double min_ratio;
    double __orig_min_ratio;
    VALUE __v_min_density = Qnil;
    double min_density;
    double __orig_min_density;

    /* Scan arguments */
    rb_scan_args(__p_argc, __p_argv, "02", &__v_min_ratio, &__v_min_density);

    /* Set defaults */
    if (__p_argc > 0)
        __orig_min_ratio = min_ratio = NUM2DBL(__v_min_ratio);
    else
        min_ratio = 0.5;

    if (__p_argc > 1)
        __orig_min_density = min_density = NUM2DBL(__v_min_density);
    else
        min_density = 0.5;

    int noPixels, width, height;
    double min, max, ratio, density;
    noPixels = NUM2INT(rb_struct_getmember(self, rb_intern("noPixels")));
    width = NUM2INT(rb_struct_getmember(self, rb_intern("width")));
    height = NUM2INT(rb_struct_getmember(self, rb_intern("height")));
    min = (double) MIN(width, height);
    max = (double) MAX(width, height);
    ratio = (min / max);
    density = ((double) noPixels / (double) (width * height));
    do {
        __p_retval = ((((ratio >= min_ratio) && (density > min_density))) ? Qtrue : Qfalse);
        goto out;
    }
    while (0);
    out:
    return __p_retval;
}

/* Init */
void
Init_morandi_native(void) {
    mMorandiNative = rb_define_module("MorandiNative");
    mPixbufUtils = rb_define_module_under(mMorandiNative, "PixbufUtils");
    rb_define_singleton_method(mPixbufUtils, "sharpen", PixbufUtils_CLASS_sharpen, 2);
    rb_define_singleton_method(mPixbufUtils, "extract_alpha", PixbufUtils_CLASS_extract_alpha, -1);
    rb_define_singleton_method(mPixbufUtils, "blur", PixbufUtils_CLASS_blur, 2);
    rb_define_singleton_method(mPixbufUtils, "contrast", PixbufUtils_CLASS_contrast, 2);
    rb_define_singleton_method(mPixbufUtils, "vibrance", PixbufUtils_CLASS_vibrance, 2);
    rb_define_singleton_method(mPixbufUtils, "saturation", PixbufUtils_CLASS_saturation, 2);
    rb_define_singleton_method(mPixbufUtils, "brightness", PixbufUtils_CLASS_brightness, 2);
    rb_define_singleton_method(mPixbufUtils, "filter", PixbufUtils_CLASS_filter, 3);
    rb_define_singleton_method(mPixbufUtils, "rotate_90", PixbufUtils_CLASS_rotate_90, 2);
    rb_define_singleton_method(mPixbufUtils, "rotate_cw", PixbufUtils_CLASS_rotate_cw, 1);
    rb_define_singleton_method(mPixbufUtils, "rotate_180", PixbufUtils_CLASS_rotate_180, 1);
    rb_define_singleton_method(mPixbufUtils, "rotate", PixbufUtils_CLASS_rotate, 2);
    rb_define_singleton_method(mPixbufUtils, "rotate_ccw", PixbufUtils_CLASS_rotate_ccw, 1);
    rb_define_singleton_method(mPixbufUtils, "gamma!", PixbufUtils_CLASS_gamma_pling, 2);
    rb_define_singleton_method(mPixbufUtils, "soften_edges!", PixbufUtils_CLASS_soften_edges_pling, 2);
    rb_define_singleton_method(mPixbufUtils, "gamma", PixbufUtils_CLASS_gamma, 2);
    rb_define_singleton_method(mPixbufUtils, "greyscale!", PixbufUtils_CLASS_greyscale_pling, 1);
    rb_define_singleton_method(mPixbufUtils, "greyscale", PixbufUtils_CLASS_greyscale, 1);
    rb_define_singleton_method(mPixbufUtils, "greyscale_go!", PixbufUtils_CLASS_greyscale_go_pling, 1);
    rb_define_singleton_method(mPixbufUtils, "greyscale_go", PixbufUtils_CLASS_greyscale_go, 1);
    rb_define_singleton_method(mPixbufUtils, "tint", PixbufUtils_CLASS_tint, -1);
    rb_define_singleton_method(mPixbufUtils, "perspect_v", PixbufUtils_CLASS_perspect_v, 5);
    rb_define_singleton_method(mPixbufUtils, "mask", PixbufUtils_CLASS_mask, 2);
    rb_define_singleton_method(mPixbufUtils, "auto_equalize", PixbufUtils_CLASS_auto_equalize, 1);
    rb_define_singleton_method(mPixbufUtils, "blend5050", PixbufUtils_CLASS_blend5050, 2);
    rb_define_singleton_method(mPixbufUtils, "mask_area", PixbufUtils_CLASS_mask_area, -1);
    rb_define_singleton_method(mPixbufUtils, "scale_max", PixbufUtils_CLASS_scale_max, -1);


    cRedEye = rb_define_class_under(mMorandiNative, "RedEye", rb_cObject);
    rb_define_alloc_func(cRedEye, RedEye___alloc__);
    rb_define_method(cRedEye, "initialize", RedEye_initialize, 5);
    rb_define_method(cRedEye, "identify_blobs", RedEye_identify_blobs, -1);
    rb_define_method(cRedEye, "correct_blob", RedEye_correct_blob, 1);
    rb_define_method(cRedEye, "highlight_blob", RedEye_highlight_blob, -1);
    rb_define_method(cRedEye, "preview_blob", RedEye_preview_blob, -1);
    rb_define_method(cRedEye, "preview", RedEye_preview, 0);
    rb_define_method(cRedEye, "pixbuf", RedEye_pixbuf, 0);
    structRegion = rb_struct_define_under(cRedEye, "Region", "op", "id", "minX", "minY", "maxX", "maxY", "width", "height", "noPixels",
                                    NULL);
    // rb_define_const(cRedEye, "Region", structRegion);
    rb_define_method(structRegion, "ratio", Region_ratio, 0);
    rb_define_method(structRegion, "density", Region_density, 0);
    rb_define_method(structRegion, "squareish?", Region_squareish_query, -1);
}
