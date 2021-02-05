typedef enum {
	ANGLE_0 = 0,
	ANGLE_90 = 90,
	ANGLE_180 = 180,
	ANGLE_270 = 270
} rotate_angle_t;

static GdkPixbuf *
pixbuf_rotate(GdkPixbuf *src, rotate_angle_t angle)
{
	GdkPixbuf *dest;
	int        has_alpha;
	int        s_width, s_height, s_rowstride;
	int        d_width, d_height, d_rowstride;
	guchar    *s_pix;
        guchar    *d_pix;
	guchar    *sp;
        guchar    *dp;
	int        i, j, pix_width;

	if (!src) return NULL;

	if (angle == ANGLE_0)
		return gdk_pixbuf_copy(src);

	s_width = gdk_pixbuf_get_width(src);
	s_height = gdk_pixbuf_get_height(src);
	has_alpha = gdk_pixbuf_get_has_alpha(src);
	s_rowstride = gdk_pixbuf_get_rowstride(src);
	s_pix = gdk_pixbuf_get_pixels(src);

	switch (angle)
	{
	case ANGLE_90:
	case ANGLE_270:
		d_width = s_height;
		d_height = s_width;
		break;
	default:
	case ANGLE_0:/* Avoid compiler warnings... */
	case ANGLE_180:
		d_width = s_width;
		d_height = s_height;
		break;
	}

	dest = gdk_pixbuf_new(GDK_COLORSPACE_RGB, has_alpha, 8, d_width, d_height);
	d_rowstride = gdk_pixbuf_get_rowstride(dest);
	d_pix = gdk_pixbuf_get_pixels(dest);

	pix_width = (has_alpha ? 4 : 3);

	for (i = 0; i < s_height; i++) {
		sp = s_pix + (i * s_rowstride);
		for (j = 0; j < s_width; j++) {
			switch (angle)
			{
			case ANGLE_180:
				dp = d_pix + ((d_height - i - 1) * d_rowstride) + ((d_width - j - 1) * pix_width);
				break;
			case ANGLE_90:
				dp = d_pix + (j * d_rowstride) + ((d_width - i - 1) * pix_width);
				break;
			case ANGLE_270:
				dp = d_pix + ((d_height - j - 1) * d_rowstride) + (i * pix_width);
				break;
			default:
			case ANGLE_0:/* Avoid compiler warnings... */
				dp = d_pix + (i * d_rowstride) + (j * pix_width);
				break;
			}

			*(dp++) = *(sp++);	/* red */
			*(dp++) = *(sp++);	/* green */
			*(dp++) = *(sp++);	/* blue */
			if (has_alpha) *(dp) = *(sp++);	/* alpha */
		}
	}

	return dest;
}

