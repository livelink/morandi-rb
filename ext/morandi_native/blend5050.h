static GdkPixbuf *pixbuf_blend5050(GdkPixbuf *src1, GdkPixbuf *src2)
{
	int        s1_has_alpha, s2_has_alpha;
	int        s1_width, s1_height, s1_rowstride;
	int        d_width, d_height, d_rowstride;
	int        s2_width, s2_height, s2_rowstride;
	guchar    *s1_pix, *sp;
        guchar    *d_pix, *dp;
        guchar    *s2_pix, *mp;
	int        i, j;
	GdkPixbuf *dest;

	g_return_val_if_fail(src1 != NULL, NULL);

	s1_width      = gdk_pixbuf_get_width(src1);
	s1_height     = gdk_pixbuf_get_height(src1);
	s1_has_alpha  = gdk_pixbuf_get_has_alpha(src1);
	s1_rowstride  = gdk_pixbuf_get_rowstride(src1);
	s1_pix        = gdk_pixbuf_get_pixels(src1);

	g_return_val_if_fail(src2 != NULL, NULL);

	s2_width      = gdk_pixbuf_get_width(src2);
	s2_height     = gdk_pixbuf_get_height(src2);
	s2_has_alpha  = gdk_pixbuf_get_has_alpha(src2);
	s2_rowstride  = gdk_pixbuf_get_rowstride(src2);
	s2_pix        = gdk_pixbuf_get_pixels(src2);

	g_return_val_if_fail(s2_width     == s1_width,     NULL);
	g_return_val_if_fail(s2_height    == s1_height,    NULL);
	g_return_val_if_fail(s2_has_alpha == s1_has_alpha, NULL);

	d_width       = s2_width;
	d_height      = s2_height;

	dest = gdk_pixbuf_new(GDK_COLORSPACE_RGB, TRUE, 8, d_width, d_height);

	g_return_val_if_fail(dest != NULL, NULL);

	d_rowstride   = gdk_pixbuf_get_rowstride(dest);
	d_pix         = gdk_pixbuf_get_pixels(dest);

	for (i = 0; i < s2_height; i++) {
		sp = s1_pix + (i * s1_rowstride);
		mp = s2_pix + (i * s2_rowstride);
		dp = d_pix  + (i * d_rowstride);

		for (j = 0; j < s2_width; j++) {
			*(dp++) = ((*(sp++)) >> 1) + ((*(mp++)) >> 1);	/* red   */
			*(dp++) = ((*(sp++)) >> 1) + ((*(mp++)) >> 1);	/* green */
			*(dp++) = ((*(sp++)) >> 1) + ((*(mp++)) >> 1);	/* blue  */

			if (s1_has_alpha)
				*(dp++) = ((*(sp++)) >> 1) + ((*(mp++)) >> 1);	/* alpha */
			else
				*(dp++) = 0xff;					/* alpha */

		}
	}

	return dest;
}

