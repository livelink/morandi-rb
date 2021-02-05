static inline unsigned char pu_clamp(int x)
{
 	unsigned char i = (x > 255) ? 255 : (x < 0 ? 0 : x);
  return i;
}

static GdkPixbuf *pixbuf_tint(GdkPixbuf *src, GdkPixbuf *dest, int r, int g, int b, int alpha)
{
	int        s_has_alpha, d_has_alpha;
	int        s_width, s_height, s_rowstride;
	int        d_width, d_height, d_rowstride;
	guchar    *s_pix, *sp;
	guchar    *d_pix, *dp;
	int        i, j, pix_width, grey;

	g_return_val_if_fail(src != NULL, NULL);
	g_return_val_if_fail(dest != NULL, NULL);

	s_width = gdk_pixbuf_get_width(src);
	s_height = gdk_pixbuf_get_height(src);
	s_has_alpha = gdk_pixbuf_get_has_alpha(src);
	s_rowstride = gdk_pixbuf_get_rowstride(src);
	s_pix = gdk_pixbuf_get_pixels(src);

	d_width = gdk_pixbuf_get_width(dest);
	d_height = gdk_pixbuf_get_height(dest);
	d_has_alpha = gdk_pixbuf_get_has_alpha(dest);
	d_rowstride = gdk_pixbuf_get_rowstride(dest);
	d_pix = gdk_pixbuf_get_pixels(dest);

	g_return_val_if_fail(d_width == s_width, NULL);
	g_return_val_if_fail(d_height == s_height, NULL);
	g_return_val_if_fail(d_has_alpha == s_has_alpha, NULL);

	pix_width = (s_has_alpha ? 4 : 3);

	for (i = 0; i < s_height; i++) {
		sp = s_pix;
		dp = d_pix;

		for (j = 0; j < s_width; j++) {
			grey = GO_RGB_TO_GREY(sp[0], sp[1], sp[2]);

			dp[0] = pu_clamp(pu_clamp(((int)grey + r) * alpha / 255) + pu_clamp((int)sp[0] * (255 - alpha) / 255));	/* red */

			//fprintf(stderr, "alpha=%i, r=%i, grey=%i -> %i + %i = %i\n", alpha, r, grey, pu_clamp(((int)grey + r) * alpha / 255), pu_clamp((int)sp[0] * (255 - alpha) / 255), dp[0]);	/* red */

			dp[1] = pu_clamp(pu_clamp((grey + g) * alpha / 255) + pu_clamp((int)sp[1] * (255 - alpha) / 255));	/* green */
			dp[2] = pu_clamp(pu_clamp((grey + b) * alpha / 255) + pu_clamp((int)sp[2] * (255 - alpha) / 255));	/* blue */

			if (s_has_alpha)
			{
				dp[3] = sp[3];	/* alpha */
			}

			dp += pix_width;
			sp += pix_width;
		}

		d_pix += d_rowstride;
		s_pix += s_rowstride;
	}

	return dest;
}

