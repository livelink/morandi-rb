static GdkPixbuf *pixbuf_extract_alpha(GdkPixbuf *src, int cutoff, int force_2bit)
{
	int        s_has_alpha, d_has_alpha;
	int        s_width, s_height, s_rowstride;
	int        d_width, d_height, d_rowstride;
	GdkPixbuf *dest;
	guchar    *s_pix, *sp;
        guchar    *d_pix, *dp;
	int        i, j, pix_width, grey;

	g_return_val_if_fail(src != NULL, NULL);

	s_width = gdk_pixbuf_get_width(src);
	s_height = gdk_pixbuf_get_height(src);
	s_has_alpha = gdk_pixbuf_get_has_alpha(src);
	s_rowstride = gdk_pixbuf_get_rowstride(src);
	s_pix = gdk_pixbuf_get_pixels(src);
	g_return_val_if_fail(s_has_alpha, NULL);

	dest = gdk_pixbuf_new(GDK_COLORSPACE_RGB, FALSE, 8, s_width, s_height);

	g_return_val_if_fail(dest != NULL, NULL);

	d_rowstride = gdk_pixbuf_get_rowstride(dest);
	d_pix = gdk_pixbuf_get_pixels(dest);

	d_width = gdk_pixbuf_get_width(dest);
	d_height = gdk_pixbuf_get_height(dest);
	d_has_alpha = gdk_pixbuf_get_has_alpha(dest);
	d_rowstride = gdk_pixbuf_get_rowstride(dest);
	d_pix = gdk_pixbuf_get_pixels(dest);

	g_return_val_if_fail(d_width == s_width, NULL);
	g_return_val_if_fail(d_height == s_height, NULL);

	pix_width = (s_has_alpha ? 4 : 3);

	for (i = 0; i < s_height; i++) {
		sp = s_pix;
		dp = d_pix;

		for (j = 0; j < s_width; j++) {
			grey = sp[3];

			if (grey < cutoff)
				grey = 0;

			if (force_2bit)
				grey = (grey >= cutoff ? 255 : 0);

			dp[0] = grey;	/* red */
			dp[1] = grey;	/* green */
			dp[2] = grey;	/* blue */

			dp += 3;
			sp += 4;
		}

		d_pix += d_rowstride;
		s_pix += s_rowstride;
	}

	return dest;
}


