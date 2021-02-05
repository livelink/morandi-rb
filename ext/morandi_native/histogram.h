typedef struct histogram_data {
	int **values;
	int  *values_max;
	int   n_channels;
} histogram;

enum {
  CHAN_VALUE = 0,
  CHAN_RED,
  CHAN_GREEN,
  CHAN_BLUE,
  CHAN_ALPHA,
  N_CHANNELS
};


static histogram *
new_histogram(long width, long height)
{
  histogram * data = ALLOC(histogram);
  int i;

  data->values_max = ALLOC_N(int, N_CHANNELS + 1);
  data->values = ALLOC_N(int *, N_CHANNELS + 1);

  for (i = 0; i < N_CHANNELS; i++) {
    data->values[i] = ALLOC_N(int, 256);
  }

  return data;
}

static void
free_histogram(histogram *data)
{
  int i;
  if (data) {
    for (i = 0; i < N_CHANNELS; i++) {
      free(data->values[i]);
    }
    free(data->values_max);
    free(data);
  }
}

static void
wipe_histogram(histogram * data)
{
  int i = 0;
  MEMZERO(data->values_max, int, N_CHANNELS);
  for (i = 0; i < N_CHANNELS; i++) {
    MEMZERO(data->values[i], int, 256);
  }
  data->n_channels = 0;
}

static histogram *
histogram_from_pixbuf(GdkPixbuf *src)
{
	int        s_has_alpha;
	int        s_width, s_height, s_rowstride;
	guchar    *s_pix, *sp;
	int        i, j, n_channels, r, g, b, a, max;
  int **values, *values_max;

  histogram * data;

	g_return_val_if_fail(src != NULL, NULL);

	s_width = gdk_pixbuf_get_width(src);
	s_height = gdk_pixbuf_get_height(src);
	s_has_alpha = gdk_pixbuf_get_has_alpha(src);
	s_rowstride = gdk_pixbuf_get_rowstride(src);
	s_pix = gdk_pixbuf_get_pixels(src);
  n_channels = s_has_alpha ? 4 : 3;

  data = new_histogram(s_width, s_height);
  wipe_histogram(data);

  data->n_channels = n_channels;

  values = data->values;
  values_max = data->values_max;

	for (i = 0; i < s_height; i++) {
		sp = s_pix + (i * s_rowstride);

		for (j = 0; j < s_width; j++) {
      r = *sp++;
      g = *sp++;
      b = *sp++;
      if (s_has_alpha) {
        a = *sp++;
      }

      max = MAX(MAX(r,g),b);

      values[CHAN_VALUE][max] += 1;
      values[CHAN_RED][r] += 1;
      values[CHAN_GREEN][g] += 1;
      values[CHAN_BLUE][b] += 1;

      if (s_has_alpha) {
        values[CHAN_ALPHA][a] += 1;
      }

      values_max[CHAN_VALUE] = MAX(values_max[CHAN_VALUE], values[CHAN_VALUE][max]);
      values_max[CHAN_RED] = MAX(values_max[CHAN_RED], values[CHAN_RED][r]);
      values_max[CHAN_GREEN] = MAX(values_max[CHAN_GREEN], values[CHAN_GREEN][g]);
      values_max[CHAN_BLUE] = MAX(values_max[CHAN_BLUE], values[CHAN_BLUE][b]);
      if (s_has_alpha) {
        values_max[CHAN_ALPHA] = MAX(values_max[CHAN_ALPHA], values[CHAN_ALPHA][a]);
      }
    }
  }

  return data;
}

