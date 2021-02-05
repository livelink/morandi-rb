#include <math.h>

inline unsigned char pix_value(int value)
{
  if (value < 0)
    return 0;
  if (value > 255)
    return 255;
  return (unsigned char) value;
}

static GdkPixbuf *pixbuf_adjust_brightness(GdkPixbuf *src, GdkPixbuf *dest, int adjust) {
  int        s_has_alpha, d_has_alpha;
	int        s_width, s_height, s_rowstride;
	int        d_width, d_height, d_rowstride;
	guchar    *s_pix, *sp;
  guchar    *d_pix, *dp;
	int        i, j, pix_width;
  int        mod = (int) floor(255 * ((double)adjust/100.0));


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

      dp[0] = pix_value(mod + sp[0]);
      dp[1] = pix_value(mod + sp[1]);
      dp[2] = pix_value(mod + sp[2]);

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

static GdkPixbuf *pixbuf_adjust_saturation(GdkPixbuf *src, GdkPixbuf *dest, int adjust) {
  int        s_has_alpha, d_has_alpha;
	int        s_width, s_height, s_rowstride;
	int        d_width, d_height, d_rowstride;
	guchar    *s_pix, *sp;
  guchar    *d_pix, *dp, max;
	int        i, j, pix_width;
  double     mod = adjust * -0.01;


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
      max = sp[0];
      if (sp[1] > max)
        max = sp[1];
      if (sp[2] > max)
        max = sp[2];


      if (max != sp[0])
        dp[0] = pix_value(sp[0] + ((double)(max - sp[0])) * mod);
      else
        dp[0] = sp[0];

      if (max != sp[1])
        dp[1] = pix_value(sp[1] + ((double)(max - sp[1])) * mod);
      else
        dp[1] = sp[1];

      if (max != sp[2])
        dp[2] = pix_value(sp[2] + ((double)(max - sp[2])) * mod);
      else
        dp[2] = sp[2];

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


static GdkPixbuf *pixbuf_adjust_vibrance(GdkPixbuf *src, GdkPixbuf *dest, int adjust) {
  int        s_has_alpha, d_has_alpha;
	int        s_width, s_height, s_rowstride;
	int        d_width, d_height, d_rowstride;
	guchar    *s_pix, *sp;
  guchar    *d_pix, *dp;
	int        i, j, pix_width, avg, max;
  double     mod = adjust * -1;


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
      max = sp[0];
      if (sp[1] > max)
        max = sp[1];
      if (sp[2] > max)
        max = sp[2];

      avg = (sp[0] + sp[1] + sp[2])/3;
      mod = ((abs(max - avg) * 2/255) * -1 * adjust) / 100.0;

      if (max != sp[0])
        dp[0] = pix_value(sp[0] + ( max - sp[0] ) * mod);
      if (max != sp[1])
        dp[1] = pix_value(sp[1] + ( max - sp[1] ) * mod);
      if (max != sp[2])
        dp[2] = pix_value(sp[2] + ( max - sp[2] ) * mod);

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
static GdkPixbuf *pixbuf_adjust_contrast(GdkPixbuf *src, GdkPixbuf *dest, int adjust) {
  int        s_has_alpha, d_has_alpha;
	int        s_width, s_height, s_rowstride;
	int        d_width, d_height, d_rowstride;
	guchar    *s_pix, *sp;
  guchar    *d_pix, *dp;
	int        i, j, pix_width;
  double     mod = pow(((double)adjust + 100.0)/100.0, 2);


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

      dp[0] = pix_value(127 + ( (((double)sp[0]) - 127) * mod ));
      dp[1] = pix_value(127 + ( (((double)sp[1]) - 127) * mod ));
      dp[2] = pix_value(127 + ( (((double)sp[2]) - 127) * mod ));

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


static GdkPixbuf *pixbuf_convolution_matrix(GdkPixbuf *src, GdkPixbuf *dest, int matrix_size, double *matrix, double divisor)
{
	int        s_has_alpha, d_has_alpha;
	int        s_width, s_height, s_rowstride;
	int        d_width, d_height, d_rowstride;
	guchar    *s_pix, *sp, *cp;
  guchar    *d_pix, *dp;
	int        i, j, pix_width;

  int xx, yy, mp;
  int matrix_from, matrix_to;
  double sum_red, sum_green, sum_blue;

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

  mp = matrix_size >> 1;
  matrix_from = -1 * mp;
  matrix_to = mp;

/*
  fprintf(stderr, "FILTER: %i -> %i", matrix_from, matrix_to);
  for (yy = matrix_from; yy <= matrix_to; yy ++) {
    for (xx = matrix_from; xx <= matrix_to; xx ++) {
      int index = ((mp + yy) * matrix_size) + (mp + xx);
      double multiplier = matrix[ index ];
      if ((xx == matrix_from)) {
        fprintf(stderr, "\n");
      }
      fprintf(stderr, "(%i,%i) [%i] : %5.3f  ", xx, yy, index, multiplier);
    }
  }
  fprintf(stderr, "\n\n");
// */

	for (i = 0; i < s_height; i++) {
		sp = s_pix;
		dp = d_pix;

		for (j = 0; j < s_width; j++) {
      sum_red = 0.0;
      sum_green = 0.0;
      sum_blue = 0.0;

      for (yy = matrix_from; yy <= matrix_to; yy ++) {
        for (xx = matrix_from; xx <= matrix_to; xx ++) {

          int index = ((mp + yy) * matrix_size) + (mp + xx);
          double multiplier = matrix[ index ];

          if ( ((j + xx) < 0) || ((j + xx) >= s_width) ||
               ((i + yy) < 0) || ((i + yy) >= s_height) ) {
            sum_red   += multiplier;
            sum_green += multiplier;
            sum_blue  += multiplier;
            continue;
          }

          cp = sp + (yy * s_rowstride) + (xx * pix_width);
          sum_red   += (multiplier * (double)cp[0]);
          sum_green += (multiplier * (double)cp[1]);
          sum_blue  += (multiplier * (double)cp[2]);
        }
      }
      sum_red   /= divisor;
      sum_green /= divisor;
      sum_blue  /= divisor;

			dp[0] = pix_value(sum_red);	/* red */
			dp[1] = pix_value(sum_green);	/* green */
			dp[2] = pix_value(sum_blue);	/* blue */

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

