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
#include "rb_cairo.h"

static VALUE mGdkPixbufCairo;
void Init_gdk_pixbuf_cairo(void);

/**
* pixbuf_cairo_create:
* @pixbuf: GdkPixbuf that you wish to wrap with cairo context
*
* This function will initialize new cairo context with contents of @pixbuf. You
* can then draw using returned context. When finished drawing, you must call
* pixbuf_cairo_destroy() or your pixbuf will not be updated with new contents!
*
* Return value: New cairo_t context. When you're done with it, call
* pixbuf_cairo_destroy() to update your pixbuf and free memory.
*/
static cairo_surface_t *
pixbuf_to_surface(GdkPixbuf *pixbuf) {
    gint width,        /* Width of both pixbuf and surface */
    height,       /* Height of both pixbuf and surface */
    p_stride,     /* Pixbuf stride value */
    p_n_channels, /* RGB -> 3, RGBA -> 4 */
    s_stride,     /* Surface stride value */
    j;
    guchar *p_pixels,     /* Pixbuf's pixel data */
    *s_pixels;     /* Surface's pixel data */
    cairo_surface_t *surface;      /* Temporary image surface */

    g_object_ref(G_OBJECT(pixbuf));

    /* Inspect input pixbuf and create compatible cairo surface */
    g_object_get(G_OBJECT(pixbuf), "width", &width,
                 "height", &height,
                 "rowstride", &p_stride,
                 "n-channels", &p_n_channels,
                 "pixels", &p_pixels,
                 NULL);
    surface = cairo_image_surface_create(p_n_channels == 4 ? CAIRO_FORMAT_ARGB32 : CAIRO_FORMAT_RGB24, width, height);
    s_stride = cairo_image_surface_get_stride(surface);
    s_pixels = cairo_image_surface_get_data(surface);

    /* Copy pixel data from pixbuf to surface */
    for (j = height; j; j--) {
        guchar *p = p_pixels;
        guchar *q = s_pixels;

        if (p_n_channels == 3) {
            guchar *end = p + 3 * width;

            while (p < end) {
#if G_BYTE_ORDER == G_LITTLE_ENDIAN
                q[0] = p[2];
                q[1] = p[1];
                q[2] = p[0];
                q[3] = 0xFF;
#else
                q[0] = 0xFF;
              q[1] = p[0];
              q[2] = p[1];
              q[3] = p[2];
#endif
                p += 3;
                q += 4;
            }
        } else {
            guchar *end = p + 4 * width;
            guint t1, t2, t3;

#define MULT(d, c, a, t) G_STMT_START { t = c * a + 0x80; d = ((t >> 8) + t) >> 8; } G_STMT_END

            while (p < end) {
#if G_BYTE_ORDER == G_LITTLE_ENDIAN
                MULT(q[0], p[2], p[3], t1);
                MULT(q[1], p[1], p[3], t2);
                MULT(q[2], p[0], p[3], t3);
                q[3] = p[3];
#else
                q[0] = p[3];
              MULT(q[1], p[0], p[3], t1);
              MULT(q[2], p[1], p[3], t2);
              MULT(q[3], p[2], p[3], t3);
#endif

                p += 4;
                q += 4;
            }

#undef MULT
        }

        p_pixels += p_stride;
        s_pixels += s_stride;
    }
    g_object_unref(G_OBJECT(pixbuf));

    cairo_surface_mark_dirty(surface);

    return surface;
}

/**
* pixbuf_cairo_destroy:
* @cr: Cairo context that you wish to destroy
* @create_new_pixbuf: If TRUE, new pixbuf will be created and returned. If
*                     FALSE, input pixbuf will be updated in place.
*
* This function will destroy cairo context, created with pixbuf_cairo_create().
*
* Return value: New or updated GdkPixbuf. You own a new reference on return
* value, so you need to call g_object_unref() on returned pixbuf when you don't
* need it anymore.
*/
static GdkPixbuf *
surface_to_pixbuf(cairo_surface_t *surface) {
    gint width,        /* Width of both pixbuf and surface */
    height,       /* Height of both pixbuf and surface */
    p_stride,     /* Pixbuf stride value */
    p_n_channels, /* RGB -> 3, RGBA -> 4 */
    s_stride,     /* Surface stride value */
    j;
    guchar *p_pixels,     /* Pixbuf's pixel data */
    *s_pixels;     /* Surface's pixel data */
    GdkPixbuf *pixbuf;       /* Pixbuf to be returned */
    cairo_format_t format;  /* cairo surface format */

    format = cairo_image_surface_get_format(surface);

    switch (format) {
        case CAIRO_FORMAT_ARGB32:
            p_n_channels = 4;
            break;
        case CAIRO_FORMAT_RGB24:
            p_n_channels = 3;
            break;
        default:
            return (GdkPixbuf *) 0;
            break;
    }

    width = cairo_image_surface_get_width(surface);
    height = cairo_image_surface_get_height(surface);
    s_stride = cairo_image_surface_get_stride(surface);
    s_pixels = cairo_image_surface_get_data(surface);

    /* Create pixbuf to be returned */
    pixbuf = gdk_pixbuf_new(GDK_COLORSPACE_RGB, p_n_channels == 4, 8, width, height);

    g_return_val_if_fail(pixbuf != NULL, NULL);

    /* Inspect pixbuf and surface */
    g_object_get(G_OBJECT(pixbuf),
                 "width", &width,
                 "height", &height,
                 "rowstride", &p_stride,
                 "n-channels", &p_n_channels,
                 "pixels", &p_pixels,
                 NULL);


    /* Copy pixel data from surface to pixbuf */
    for (j = height; j; j--) {
        guchar *p = p_pixels;
        guchar *q = s_pixels;

        if (p_n_channels == 3) {
            guchar *end = p + 3 * width;

            while (p < end) {
#if G_BYTE_ORDER == G_LITTLE_ENDIAN
                p[2] = q[0];
                p[1] = q[1];
                p[0] = q[2];
#else
                p[0] = q[1];
                p[1] = q[2];
                p[2] = q[3];
#endif
                p += 3;
                q += 4;
            }
        } else {
            guchar *end = p + 4 * width;
            guint t1, t2, t3;

#define UNMULT(s_byte, p_byte, a, t) G_STMT_START { \
t = s_byte * 255 / a;                         \
p_byte = t; \
} G_STMT_END

            while (p < end) {
#if G_BYTE_ORDER == G_LITTLE_ENDIAN
                UNMULT(q[0], p[2], q[3], t1);
                UNMULT(q[1], p[1], q[3], t2);
                UNMULT(q[2], p[0], q[3], t3);
                p[3] = q[3];
#else
                p[3] = q[0];
                UNMULT(q[1], p[0], q[3], t1);
                UNMULT(q[2], p[1], q[3], t2);
                UNMULT(q[3], p[2], q[3], t3);
#endif

                p += 4;
                q += 4;
            }

#undef MULT
        }

        p_pixels += p_stride;
        s_pixels += s_stride;
    }

    /* Return pixbuf */
    return (pixbuf);
}

static
VALUE rb_pixbuf_to_surface(__attribute__((unused)) VALUE _self, VALUE pixbuf) {
    cairo_surface_t *surface = pixbuf_to_surface(GDK_PIXBUF(RVAL2GOBJ(pixbuf)));
    return CRSURFACE2RVAL_WITH_DESTROY(surface);
}

static
VALUE rb_surface_to_pixbuf(__attribute__((unused)) VALUE _self, VALUE surface) {
    VALUE obj;
    GdkPixbuf *pixbuf = surface_to_pixbuf(RVAL2CRSURFACE(surface));
    if (pixbuf) {
        obj = GOBJ2RVAL(pixbuf);
        g_object_unref(pixbuf);
        return obj;
    }

    rb_raise(rb_eRuntimeError, "Unable to convert Cairo::ImageSurface to Gdk::Pixbuf");

    return Qnil;
}

/* Init */
void
Init_gdk_pixbuf_cairo(void) {
    mGdkPixbufCairo = rb_define_module("GdkPixbufCairo");
    rb_define_singleton_method(mGdkPixbufCairo, "pixbuf_to_surface", rb_pixbuf_to_surface, 1);
    rb_define_singleton_method(mGdkPixbufCairo, "surface_to_pixbuf", rb_surface_to_pixbuf, 1);
}