/*
 *  SphericalHarmonicsCore.c
 *  SphericalHarmonics
 *
 *  Created by Ichi Kanaya on Thu Jan 08 2004.
 *  Copyright (c) 2004 Ichi Kanaya. All rights reserved.
 *
 */

#include <math.h>
#include <gsl/gsl_sf_legendre.h>
#include "SphericalHarmonicsCore.h"
#include "MersenneTwister.h"

static double y_func(int l, int m, double alpha, double beta)
{
  if (m == 0) {
    return gsl_sf_legendre_sphPlm(l, 0, cos(beta));
  }
  else if (m > 0) {
    return cos((double)m * alpha) * gsl_sf_legendre_sphPlm(l, m, cos(beta));
  }
  else {
    return sin((double)-m * alpha) * gsl_sf_legendre_sphPlm(l, -m, cos(beta));
  }
}

static int spherical_harmonics_index(int l, int m)
{
  return l * (l + 1) + m;
}

static int image_index(double alpha, double beta, int sqrt_n_pixels)
{
  const double xi = cos(alpha) * sin(beta);
  const double eta = sin(alpha) * sin(beta);
  const int x = (int)(xi * (double)sqrt_n_pixels / 2.0) + sqrt_n_pixels / 2 - 1;
  const int y = (int)(eta * (double)sqrt_n_pixels / 2.0) + sqrt_n_pixels / 2 - 1;
	
  return y * sqrt_n_pixels + x;
}

void comp_spherical_harmonics_coeffs(double *sh_coeffs, int n_bands,
				     const double *image, int sqrt_n_pixels,
				     const double *sampling_points, int n_sampling_points)
{
  const int n_coeffs = n_bands * n_bands;
  int i;
  
  for (i = 0; i < n_coeffs; ++i) {
    sh_coeffs[i] = 0.0;
  }
  for (i = 0; i < n_sampling_points; ++i) {
    double alpha, beta;
    double p;
    int l, m;
    
    alpha = *sampling_points++;
    beta = *sampling_points++;
    p = image[image_index(alpha, beta, sqrt_n_pixels)];
    for (l = 0; l < n_bands; ++l) {
      for (m = -l; m <= l; ++m) {
	int index = spherical_harmonics_index(l, m);
	
	sh_coeffs[index] += p * y_func(l, m, alpha, beta);
      }
    }
  }
  for (i = 0; i < n_coeffs; ++i) {
    sh_coeffs[i] /= (double)n_sampling_points;
  }
}

void comp_image(double *image, int sqrt_n_pixels, const double *sh_coeffs, int n_bands)
{
  int i, x, y;
  
  for (i = 0; i < sqrt_n_pixels * sqrt_n_pixels; ++i) {
    image[i] = 0.0;
  }
  for (y = 0; y < sqrt_n_pixels; ++y) {
    const double eta = (double)(y * 2 - sqrt_n_pixels - 1) / (double)sqrt_n_pixels;
    
    for (x = 0; x < sqrt_n_pixels; ++x) {
      const double xi = (double)(x * 2 - sqrt_n_pixels- 1) / (double)sqrt_n_pixels;
      
      if (xi * xi + eta * eta < 1.0) {
	const double alpha = atan2(eta, xi);
	const double beta = asin(xi / cos(alpha));  /* what if beta < 0 happens??? */
	double p = 0.0;
	int l, m;
	
	for (l = 0; l < n_bands; ++l) {
	  for (m = -l; m <= l; ++m) {
	    int index = spherical_harmonics_index(l, m);
	    
	    p += sh_coeffs[index] * y_func(l, m, alpha, beta);
	  }
	}
	if (p > 1.0) {
	  p = 1.0;
	}
	else if (p < 0.0) {
	  p = 0.0;
	}
	image[y * sqrt_n_pixels + x] = p;
      }
    }
  }
}

void comp_spherical_harmonics_coeffs_step_by_step(double *sh_coeffs, int n_bands,
						  const double *image, int sqrt_n_pixels,
						  double alpha, double beta)
{
  double p;
  int l, m;
  
  p = image[image_index(alpha, beta, sqrt_n_pixels)];
  for (l = 0; l < n_bands; ++l) {
    for (m = -l; m <= l; ++m) {
      int index = spherical_harmonics_index(l, m);
      
      sh_coeffs[index] += p * y_func(l, m, alpha, beta);
    }
  }
}

double comp_pixel(int x, int y, int sqrt_n_pixels, const double *sh_coeffs, int n_bands)
{
  const double xi = (double)(x * 2 - sqrt_n_pixels- 1) / (double)sqrt_n_pixels;
  const double eta = (double)(y * 2 - sqrt_n_pixels - 1) / (double)sqrt_n_pixels;
  
  if (xi * xi + eta * eta < 1.0) {
    const double alpha = atan2(eta, xi);
    const double beta = asin(xi / cos(alpha));  /* what if beta < 0 happens??? */
    double p = 0.0;
    int l, m;
    
    for (l = 0; l < n_bands; ++l) {
      for (m = -l; m <= l; ++m) {
	int index = spherical_harmonics_index(l, m);
	
	p += sh_coeffs[index] * y_func(l, m, alpha, beta);
      }
    }
    if (p > 1.0) {
      p = 1.0;
    }
    else if (p < 0.0) {
      p = 0.0;
    }
    return p;
  }
  else {
    return 0.0;
  }
}

void clip_image(double *image, int sqrt_n_pixels)
{
  int x, y;
  
  for (y = 0; y < sqrt_n_pixels; ++y) {
    const double eta = (double)(y * 2 - sqrt_n_pixels - 1) / (double)sqrt_n_pixels;
    
    for (x = 0; x < sqrt_n_pixels; ++x) {
      const double xi = (double)(x * 2 - sqrt_n_pixels- 1) / (double)sqrt_n_pixels;
      
      if (xi * xi + eta * eta >= 1.0) {
	image[y * sqrt_n_pixels + x] = 0.0;
      }
    }
  }
}

void scale_image(double *image, int sqrt_n_pixels)
{
  const int n_pixels = sqrt_n_pixels * sqrt_n_pixels;
  double max = 0.0;
  int i;
  
  for (i = 0; i < n_pixels; ++i) {
    if (max < image[i]) {
      max = image[i];
    }
  }
  for (i = 0; i < n_pixels; ++i) {
    image[i] /= max;
  }
}

void normalize_image(double *image, int sqrt_n_pixels)
{
  const int n_pixels = sqrt_n_pixels * sqrt_n_pixels;
  double total = 0.0;
  int i;
  
  for (i = 0; i < n_pixels; ++i) {
    total += image[i];
  }
  for (i = 0; i < n_pixels; ++i) {
    image[i] /= total;
  }
}

void setup_uniform_hemispherical_dist(double *dist, int n_points)
{
  int i;
  
  for (i = 0; i < n_points; ++i) {
    const double a = random_number_closed();
    const double b = random_number_closed();
    const double alpha = 2.0 * M_PI * a;
    const double beta = acos(sqrt(1.0 - b));
    
    *dist++ = alpha;
    *dist++ = beta;
  }
}

void setup_weighted_hemispherical_dist(double *dist, int n_points,
				       const double *image, int sqrt_n_pixels)
{
  int n = 0;
  
  while (n < n_points) {
    const double a = random_number_closed();
    const double b = random_number_closed();
    const double alpha = 2.0 * M_PI * a;
    const double beta = acos(sqrt(1.0 - b));
    const int index = image_index(alpha, beta, sqrt_n_pixels);
    const double p = image[index];
    
    if (random_number_closed() < p) {
      *dist++ = alpha;
      *dist++ = beta;
      ++n;
    }
  }
}
