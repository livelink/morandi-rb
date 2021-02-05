

#define RLUM    (0.3086)
#define GLUM    (0.6094)
#define BLUM    (0.0820)

// Graphica Obscure
#define GO_RGB_TO_GREY(r,g,b) ((int)((RLUM * (double)r) + (GLUM * (double)g) + (BLUM * (double)b)))

// Gimp Values
#define GIMP_RGB_TO_GREY(r,g,b) (((77 * r) + (151 * g) + (28 * b)) >> 8)

static GdkPixbuf *pixbuf_greyscale(GdkPixbuf *src, GdkPixbuf *dest)
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
			grey = GIMP_RGB_TO_GREY(sp[0], sp[1], sp[2]);

			dp[0] = grey;	/* red */
			dp[1] = grey;	/* green */
			dp[2] = grey;	/* blue */

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

static GdkPixbuf *pixbuf_greyscale_go(GdkPixbuf *src, GdkPixbuf *dest)
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

			dp[0] = grey;	/* red */
			dp[1] = grey;	/* green */
			dp[2] = grey;	/* blue */

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

