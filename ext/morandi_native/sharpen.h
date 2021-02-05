static GdkPixbuf *
pixbuf_sharpen(GdkPixbuf *src, int strength)
{
	GdkPixbuf *dest;
	int        has_alpha;
	int        s_width, s_height, s_rowstride;
	int        d_width, d_height, d_rowstride;
	guchar    *s_pix;
        guchar    *d_pix;
	guchar    *sp;
        guchar    *dp;
	int       pix_width;
	bool	row_only = TRUE;
	int        a=0, r, g, b, x, y, mul;
	int        b_a=0, b_r, b_g, b_b;

	if (!src) return NULL;

	s_width = gdk_pixbuf_get_width(src);
	s_height = gdk_pixbuf_get_height(src);
	has_alpha = gdk_pixbuf_get_has_alpha(src);
	s_rowstride = gdk_pixbuf_get_rowstride(src);
	s_pix = gdk_pixbuf_get_pixels(src);

	d_width = s_width;
	d_height = s_height;

	dest = gdk_pixbuf_copy(src);
	d_rowstride = gdk_pixbuf_get_rowstride(dest);
	d_pix = gdk_pixbuf_get_pixels(dest);

	pix_width = (has_alpha ? 4 : 3);

 	mul = (row_only ? 3 : 5);

	for (y = 0; y < (s_height); y++)
	{
             sp = s_pix + (y * s_rowstride) + pix_width;
             dp = d_pix + (y * d_rowstride) + pix_width;

		for (x = 1; x < (s_width - 1); x++)
		{

			b_r = ((int)*(sp));
			b_g = ((int)*(sp+1));
			b_b = ((int)*(sp+2));
			if (has_alpha)
				b_a = ((int)*((sp+3)));

			r = b_r * mul;
			g = b_g * mul;
			b = b_b * mul;
			if (has_alpha)
				a = b_a * mul;

			r = ((int)*(sp)) * mul;
			g = ((int)*(sp+1)) * mul;
			b = ((int)*(sp+2)) * mul;
			if (has_alpha)
				a = ((int)*((sp+3))) * mul;

 			r -= (int)*(sp - pix_width);
			g -= (int)*(sp - pix_width + 1);
			b -= (int)*(sp - pix_width + 2);
			if (has_alpha)
				a -= (int)*(sp - pix_width + 3);

			r -= (int)*(sp + pix_width);
			g -= (int)*(sp + pix_width + 1);
			b -= (int)*(sp + pix_width + 2);
			if (has_alpha)
				a -= (int)*(sp + pix_width + 3);

			if (row_only == 0)
			{
				r -= (int)*(sp - (s_rowstride));
				g -= (int)*(sp + 1 - (s_rowstride));
				b -= (int)*(sp + 2 - (s_rowstride));
				if (has_alpha)
					a -= (int)*(sp + 3 - (s_rowstride));

				r -= (int)*(sp + (s_rowstride));
				g -= (int)*(sp + 1 + (s_rowstride));
				b -= (int)*(sp + 2 + (s_rowstride));
				if (has_alpha)
					a -= (int)*(sp + 3 + (s_rowstride));
			}

			r = (r & ((~r) >> 16));
			r = ((r | ((r & 256) - ((r & 256) >> 8))));
			g = (g & ((~g) >> 16));
			g = ((g | ((g & 256) - ((g & 256) >> 8))));
			b = (b & ((~b) >> 16));
			b = ((b | ((b & 256) - ((b & 256) >> 8))));
			a = (a & ((~a) >> 16));
			a = ((a | ((a & 256) - ((a & 256) >> 8))));

			r = 0xff & (MAX(r,0));
			g = 0xff & (MAX(g,0));
			b = 0xff & (MAX(b,0));
			if (has_alpha)
				a = 0xff & (MAX(a,0));

			r = ((r * strength) + b_r) / (strength + 1);
			g = ((g * strength) + b_g) / (strength + 1);
			b = ((b * strength) + b_b) / (strength + 1);
			if (has_alpha)
				a = ((a * strength) + b_a) / (strength + 1);

			*(dp++) = r;
			*(dp++) = g;
			*(dp++) = b;
			if (has_alpha)
				*(dp++) = a;

			sp += pix_width;
		}
	}
	return dest;
} // */

