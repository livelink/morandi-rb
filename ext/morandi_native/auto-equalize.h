// Auto-equalize stuff here...
//

static long **
get_cumulative (histogram *data)
{
	long **cumulative;
	int    i, v;

	cumulative = ALLOC_N(long *, N_CHANNELS);
	for (i = 0; i < N_CHANNELS; i++) {
		int s;

		cumulative[i] = ALLOC_N(long, 256);
		s = 0;
		for (v = 0; v < 256; v++) {
			s += data->values[i][v];
			cumulative[i][v] = s;
		}
	}

	return cumulative;
}


static void
free_cumulative (long **cumulative)
{
	int i;
	for (i = 0; i <  N_CHANNELS; i++)
		free(cumulative[i]);

	free(cumulative);
}


static GdkPixbuf *
auto_equalize(GdkPixbuf *src, GdkPixbuf *dest)
{
	int        s_has_alpha, d_has_alpha;
	int        s_width, s_height, s_rowstride;
	guchar    *s_pix, *sp;
	int        i, j, n_channels, r, g, b, a;
  histogram *data;
  long    ** cumulative = NULL;
  double     factor;


	int        d_width, d_height, d_rowstride;
  guchar    *d_pix, *dp;

	g_return_val_if_fail(src != NULL, NULL);

	s_width = gdk_pixbuf_get_width(src);
	s_height = gdk_pixbuf_get_height(src);
	s_has_alpha = gdk_pixbuf_get_has_alpha(src);
	s_rowstride = gdk_pixbuf_get_rowstride(src);
	s_pix = gdk_pixbuf_get_pixels(src);
  n_channels = s_has_alpha ? 4 : 3;

  d_width = gdk_pixbuf_get_width(dest);
	d_height = gdk_pixbuf_get_height(dest);
	d_has_alpha = gdk_pixbuf_get_has_alpha(dest);
	d_rowstride = gdk_pixbuf_get_rowstride(dest);
	d_pix = gdk_pixbuf_get_pixels(dest);

	g_return_val_if_fail(d_width == s_width, NULL);
	g_return_val_if_fail(d_height == s_height, NULL);
	g_return_val_if_fail(d_has_alpha == s_has_alpha, NULL);

  data = histogram_from_pixbuf(src);
  cumulative = get_cumulative(data);
  factor = 255.0/(s_width * s_height);

	for (i = 0; i < s_height; i++) {
		sp = s_pix + (i * s_rowstride);
		dp = d_pix + (i * d_rowstride);

		for (j = 0; j < s_width; j++) {
      r = *sp++;
      g = *sp++;
      b = *sp++;
      if (s_has_alpha) {
        a = *sp++;
      }
      /*fprintf(stderr, "r=%i,g=%i,b=%i -> count %li %li %li -- ", r, g, b, data->values[CHAN_RED][r], data->values[CHAN_GREEN][g], data->values[CHAN_BLUE][b]);
      fprintf(stderr, "r=%i,g=%i,b=%i -> cumulative %li %li %li \n", r, g, b, cumulative[CHAN_RED][r], cumulative[CHAN_GREEN][g], cumulative[CHAN_BLUE][b]);*/
      *dp ++ = (unsigned char)((double)cumulative[CHAN_RED][r] * factor);
      *dp ++ = (unsigned char)((double)cumulative[CHAN_GREEN][g] * factor);
      *dp ++ = (unsigned char)((double)cumulative[CHAN_BLUE][b] * factor);
      if (s_has_alpha) {
        *dp ++ = (unsigned char)((double)cumulative[CHAN_ALPHA][a] * factor);
      }
    }
  }

  free_cumulative(cumulative);
  free_histogram(data);

  return dest;
}

