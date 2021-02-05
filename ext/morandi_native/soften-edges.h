static GdkPixbuf *pixbuf_soften_edges(GdkPixbuf *dest, int size)
{
	int        d_has_alpha;
	int        d_width, d_height, d_rowstride;
        guchar    *d_pix, *dp;
	int        i, j, pix_width;

	g_return_val_if_fail(dest != NULL, NULL);

	d_width = gdk_pixbuf_get_width(dest);
	d_height = gdk_pixbuf_get_height(dest);
	d_has_alpha = gdk_pixbuf_get_has_alpha(dest);
	d_rowstride = gdk_pixbuf_get_rowstride(dest);
	d_pix = gdk_pixbuf_get_pixels(dest);

	g_return_val_if_fail(d_has_alpha, NULL);

	pix_width = (d_has_alpha ? 4 : 3);

	for (i = 0; i < MIN(size,d_height); i++) {
		dp = d_pix + (i * d_rowstride);
		//pix = (pixel_t)dp;
		for (j = 0; j < d_width; j++) {
			dp[3] = (dp[3] * i) / size; /* alpha */
			dp += pix_width;
		}

		dp = d_pix + ((d_height - i - 1) * d_rowstride);
		for (j = 0; j < d_width; j++) {
			dp[3] = (dp[3] * i) / size; /* alpha */
			dp += pix_width;
		}

	}
	for (j = 0; j < d_height; j++) {
		//pix = (pixel_t)GINT_TO_POINTER(GPOINTER_TO_INT(d_pix) + (j * d_rowstride));
		dp = d_pix + ((d_height - i - 1) * d_rowstride);
		for (i = 0; i < MIN(size, d_width); i++) {
			dp[3] = (dp[3] * i) / size; /* alpha */
			dp += pix_width;
		}

		dp = d_pix + (j * d_rowstride) + (pix_width * d_width);
		for (i = 0; i < MIN(size, d_width); i++) {
			dp[3] = (dp[3] * i) / size; /* alpha */
			dp -= pix_width;
		}
	}

	return dest;
}

