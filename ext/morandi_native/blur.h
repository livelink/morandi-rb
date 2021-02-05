static GdkPixbuf *
pixbuf_blur(GdkPixbuf *src, gint radius)
{
	/* Pixels and Rowstride To Perform Blur On */
	guchar *pixels;
	GdkPixbuf *pixbuf;
	gint rowstride, width, height;

	pixbuf = gdk_pixbuf_copy(src);

	/* Get Pixels and Rowstride Of Image Buffer */
	if (pixbuf)
	{
		pixels = gdk_pixbuf_get_pixels (pixbuf);
		rowstride = gdk_pixbuf_get_rowstride (pixbuf);
		width = gdk_pixbuf_get_width(pixbuf);
		height = gdk_pixbuf_get_height(pixbuf);
		/*printf("%i, %i, %i, %i\n", rowstride, width, height, rowstride/width);*/
	}
	else
	{
		return NULL;
	}
	if (radius > 1)
	{
		/* Some Important Consts */
		gint bytes = rowstride/width;
		gboolean alpha = (bytes == 4);

		gint div = radius+radius+1;
		gint divsum = ((div+1)>>1)*((div+1)>>1);
		gint dv[256*divsum]; /* Table of Const RGBA Values */

		/* Some Important Variables */
		guchar stack[div][bytes];
		gint stackpointer;
		gint stackstart;
		gint vmin[MAX(width,height)];
		guchar *sir;
		gint rbs;

		gint current = 0;

		/* RGBA Sums
			0 - Sum of Incoming pixels(the radius pixels above the Center/to left of Center)
			1 - Sum of Outgoing pixels(the Center and the radius pixels below the Center/to right of Center)
			2 - Sum of All pixels within radius
		*/
		gint rgba_sums[3][bytes];

		/* RGBA Values */
		guchar rgba[bytes][width*height];

		/* Temp Indexes/Counters */
		gint x, y, i, p, yp, yi=0, yw=0;

		for (i=0; i<256*divsum; i++)
		{
			dv[i] = (i/divsum);
		}

		for (y=0; y < height; y++)
		{
			/* initialize sums to zero */
			for (i = 0; i<bytes; i++)
			{
				rgba_sums[0][i] = 0;
				rgba_sums[1][i] = 0;
				rgba_sums[2][i] = 0;
			}

			/* Calculate Initial Sums For radius */
			for(i=-radius; i<=radius; i++)
			{
				current = (yi + MIN(width - 1, MAX(i,0)))*bytes;

				sir = stack[i+radius];

				sir[0] = pixels[current + 0];
				sir[1] = pixels[current + 1];
				sir[2] = pixels[current + 2];
				sir[3] = pixels[current + 3];

				rbs = (radius + 1) - abs(i);

				rgba_sums[2][0] += sir[0]*rbs;
				rgba_sums[2][1] += sir[1]*rbs;
				rgba_sums[2][2] += sir[2]*rbs;
				if (alpha)
				{
					rgba_sums[2][3] += sir[3]*rbs;
				}

				if (i>0)
				{
					rgba_sums[0][0] += sir[0];
					rgba_sums[0][1] += sir[1];
					rgba_sums[0][2] += sir[2];
					if (alpha)
					{
						rgba_sums[0][3] += sir[3];
					}
				}
				else
				{
					rgba_sums[1][0] += sir[0];
					rgba_sums[1][1] += sir[1];
					rgba_sums[1][2] += sir[2];
					if (alpha)
					{
						rgba_sums[1][3] += sir[3];
					}
				}
			}

			stackpointer = radius;

			for (x=0; x<width; x++)
			{
				rgba[0][yi] = dv[rgba_sums[2][0]];
				rgba[1][yi] = dv[rgba_sums[2][1]];
				rgba[2][yi] = dv[rgba_sums[2][2]];
				if (alpha)
				{
					rgba[3][yi] = dv[rgba_sums[2][3]];
				}

				rgba_sums[2][0] -= rgba_sums[1][0];
				rgba_sums[2][1] -= rgba_sums[1][1];
				rgba_sums[2][2] -= rgba_sums[1][2];
				if (alpha)
				{
					rgba_sums[2][3] -= rgba_sums[1][3];
				}

				stackstart = stackpointer - radius + div;
				sir = stack[stackstart%div];

				rgba_sums[1][0] -= sir[0];
				rgba_sums[1][1] -= sir[1];
				rgba_sums[1][2] -= sir[2];
				if (alpha)
				{
					rgba_sums[1][3] -= sir[3];
				}

				if(y==0)
				{
					vmin[x] = MIN(x + radius + 1, width - 1);
				}

				current = (yw + vmin[x])*bytes;

				sir[0] = pixels[current + 0];
				sir[1] = pixels[current + 1];
				sir[2] = pixels[current + 2];
				if (alpha)
				{
					sir[3] = pixels[current + 3];
				}

				rgba_sums[0][0] += sir[0];
				rgba_sums[0][1] += sir[1];
				rgba_sums[0][2] += sir[2];
				if (alpha)
				{
					rgba_sums[0][3] += sir[3];
				}

				rgba_sums[2][0] += rgba_sums[0][0];
				rgba_sums[2][1] += rgba_sums[0][1];
				rgba_sums[2][2] += rgba_sums[0][2];
				if (alpha)
				{
					rgba_sums[2][3] += rgba_sums[0][3];
				}

				stackpointer=(stackpointer+1)%div;
				sir=stack[(stackpointer)%div];

				rgba_sums[1][0] += sir[0];
				rgba_sums[1][1] += sir[1];
				rgba_sums[1][2] += sir[2];
				if (alpha)
				{
					rgba_sums[1][3] += sir[3];
				}

				rgba_sums[0][0] -= sir[0];
				rgba_sums[0][1] -= sir[1];
				rgba_sums[0][2] -= sir[2];
				if (alpha)
				{
					rgba_sums[0][3] -= sir[3];
				}

				yi++;
			}

			yw += width;
		}

		for (x=0; x<width; x++)
		{
			yp=-radius*width;

			/* initialize sums to zero */
			for (i = 0; i<bytes; i++)
			{
				rgba_sums[0][i] = 0;
				rgba_sums[1][i] = 0;
				rgba_sums[2][i] = 0;
			}

			/* Calculate Initial Sums For radius */
			for(i=-radius; i<=radius; i++)
			{
				yi = MAX(0,yp) + x;

				sir = stack[i+radius];

				sir[0] = rgba[0][yi];
				sir[1] = rgba[1][yi];
				sir[2] = rgba[2][yi];
				if (alpha)
				{
					sir[3] = rgba[3][yi];
				}

				rbs = (radius + 1) - abs(i);

				rgba_sums[2][0] += rgba[0][yi]*rbs;
				rgba_sums[2][1] += rgba[1][yi]*rbs;
				rgba_sums[2][2] += rgba[2][yi]*rbs;
				if (alpha)
				{
					rgba_sums[2][3] += rgba[3][yi]*rbs;
				}

				if (i>0)
				{
					rgba_sums[0][0] += sir[0];
					rgba_sums[0][1] += sir[1];
					rgba_sums[0][2] += sir[2];
					if (alpha)
					{
						rgba_sums[0][3] += sir[3];
					}
				}
				else
				{
					rgba_sums[1][0] += sir[0];
					rgba_sums[1][1] += sir[1];
					rgba_sums[1][2] += sir[2];
					if (alpha)
					{
						rgba_sums[1][3] += sir[3];
					}
				}

				if(i < height - 1)
				{
					yp += width;
				}
			}

			yi = x;
			stackpointer = radius;

			for (y=0; y<height; y++)
			{
				current = (yi)*bytes;

				pixels[current + 0] = dv[rgba_sums[2][0]];
				pixels[current + 1] = dv[rgba_sums[2][1]];
				pixels[current + 2] = dv[rgba_sums[2][2]];
				if (alpha)
				{
					pixels[current + 3] = dv[rgba_sums[2][3]];
				}

				rgba_sums[2][0] -= rgba_sums[1][0];
				rgba_sums[2][1] -= rgba_sums[1][1];
				rgba_sums[2][2] -= rgba_sums[1][2];
				if (alpha)
				{
					rgba_sums[2][3] -= rgba_sums[1][3];
				}

				stackstart = stackpointer - radius + div;
				sir = stack[stackstart%div];

				rgba_sums[1][0] -= sir[0];
				rgba_sums[1][1] -= sir[1];
				rgba_sums[1][2] -= sir[2];
				if (alpha)
				{
					rgba_sums[1][3] -= sir[3];
	     			}

				if (x == 0)
				{
					vmin[y] = MIN(y + (radius + 1), height - 1)*width;
				}

				p = x + vmin[y];

				sir[0] = rgba[0][p];
				sir[1] = rgba[1][p];
				sir[2] = rgba[2][p];
				if (alpha)
				{
					sir[3] = rgba[3][p];
				}

				rgba_sums[0][0] += sir[0];
				rgba_sums[0][1] += sir[1];
				rgba_sums[0][2] += sir[2];
				if (alpha)
				{
					rgba_sums[0][3] += sir[3];
				}

				rgba_sums[2][0] += rgba_sums[0][0];
				rgba_sums[2][1] += rgba_sums[0][1];
				rgba_sums[2][2] += rgba_sums[0][2];
				if (alpha)
				{
					rgba_sums[2][3] += rgba_sums[0][3];
				}

				stackpointer = (stackpointer+1)%div;
				sir = stack[stackpointer];

				rgba_sums[1][0] += sir[0];
				rgba_sums[1][1] += sir[1];
				rgba_sums[1][2] += sir[2];
				if (alpha)
				{
					rgba_sums[1][3] += sir[3];
				}

				rgba_sums[0][0] -= sir[0];
				rgba_sums[0][1] -= sir[1];
				rgba_sums[0][2] -= sir[2];
				if (alpha)
				{
					rgba_sums[0][3] -= sir[3];
				}

				yi += width;
			}
		}
	}

	return pixbuf;
}

