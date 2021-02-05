static GdkPixbuf *pixbuf_gamma(GdkPixbuf *src, GdkPixbuf *dest, double gamma)
{
	int        has_alpha;
	int        s_width, s_height, s_rowstride;
	int        d_width, d_height, d_rowstride;
	guchar    *s_pix;
        guchar    *d_pix;
	guchar    *sp;
        guchar    *dp;
	int        i, j, pix_width;
	double map[256] = {0.0,};

	for (i=0; i < 256; i++)
		map[i] = 255 * pow((double) i/255, 1.0/gamma);

	g_return_val_if_fail(src != NULL, NULL);
	g_return_val_if_fail(dest != NULL, NULL);

	s_width = gdk_pixbuf_get_width(src);
	s_height = gdk_pixbuf_get_height(src);
	has_alpha = gdk_pixbuf_get_has_alpha(src);
	s_rowstride = gdk_pixbuf_get_rowstride(src);
	s_pix = gdk_pixbuf_get_pixels(src);

	d_width = gdk_pixbuf_get_width(dest);
	d_height = gdk_pixbuf_get_height(dest);
	d_rowstride = gdk_pixbuf_get_rowstride(dest);
	d_pix = gdk_pixbuf_get_pixels(dest);

	g_return_val_if_fail(d_width == s_width, NULL);
	g_return_val_if_fail(d_height == s_height, NULL);
	g_return_val_if_fail(has_alpha == gdk_pixbuf_get_has_alpha(dest), NULL);

	pix_width = (has_alpha ? 4 : 3);

	for (i = 0; i < s_height; i++) {
		sp = s_pix + (i * s_rowstride);
		dp = d_pix + (i * d_rowstride);
		for (j = 0; j < s_width; j++) {
			*(dp++) = map[*(sp++)];	/* red */
			*(dp++) = map[*(sp++)];	/* green */
			*(dp++) = map[*(sp++)];	/* blue */
			if (has_alpha) *(dp++) = map[*(sp++)];	/* alpha */
		}
	}

	return dest;
}

