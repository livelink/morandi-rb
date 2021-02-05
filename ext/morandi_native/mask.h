static GdkPixbuf *pixbuf_mask(GdkPixbuf *src, GdkPixbuf *mask)
{
	int        s_has_alpha, m_has_alpha;
	int        s_width, s_height, s_rowstride;
	int        d_width, d_height, d_rowstride;
	int        m_width, m_height, m_rowstride;
	guchar    *s_pix, *sp;
        guchar    *d_pix, *dp;
        guchar    *m_pix, *mp;
	int        i, j, pix_width, alpha, grey;
	pixel_t    pix;
	GdkPixbuf *dest;

	g_return_val_if_fail(src != NULL, NULL);

	s_width = gdk_pixbuf_get_width(src);
	s_height = gdk_pixbuf_get_height(src);
	s_has_alpha = gdk_pixbuf_get_has_alpha(src);
	s_rowstride = gdk_pixbuf_get_rowstride(src);
	s_pix = gdk_pixbuf_get_pixels(src);

	g_return_val_if_fail(mask != NULL, NULL);

	m_width = gdk_pixbuf_get_width(mask);
	m_height = gdk_pixbuf_get_height(mask);
	m_has_alpha = gdk_pixbuf_get_has_alpha(mask);
	m_rowstride = gdk_pixbuf_get_rowstride(mask);
	m_pix = gdk_pixbuf_get_pixels(mask);

	g_return_val_if_fail(m_width <= s_width, NULL);
	g_return_val_if_fail(m_height <= s_height, NULL);

	d_width = m_width;
	d_height = m_height;
	dest = gdk_pixbuf_new(GDK_COLORSPACE_RGB, TRUE, 8, d_width, d_height);

	g_return_val_if_fail(dest != NULL, NULL);

	d_rowstride = gdk_pixbuf_get_rowstride(dest);
	d_pix = gdk_pixbuf_get_pixels(dest);

	pix_width = (m_has_alpha ? 4 : 3);



	for (i = 0; i < m_height; i++) {
		sp = s_pix + (i * s_rowstride);
		dp = d_pix + (i * d_rowstride);
		mp = m_pix + (i * m_rowstride);

		for (j = 0; j < m_width; j++) {
			*(dp++) = *(sp++);	/* red */
			*(dp++) = *(sp++);	/* green */
			*(dp++) = *(sp++);	/* blue */

			if (s_has_alpha)
			{
				alpha = *(sp++);	/* alpha */
			}
			else
			{
				alpha = 0xff;
			}

			pix = PIXEL(mp, pix_width, j);
			grey = GIMP_RGB_TO_GREY(pix->r, pix->g, pix->b);

			*(dp++) = sqrt(alpha * (255 - grey));	/* alpha */
		}
	}

	return dest;
}

