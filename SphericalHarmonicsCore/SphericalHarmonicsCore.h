/*
 *  SphericalHarmonicsCore.h
 *  SphericalHarmonics
 *
 *  Created by Ichi Kanaya on Thu Jan 08 2004.
 *  Copyright (c) 2004 Ichi Kanaya. All rights reserved.
 *
 */


#ifndef __SPHERICALHARMONICSCORE_H
#define __SPHERICALHARMONICSCORE_H

void comp_spherical_harmonics_coeffs(double *sh_coeffs, int n_bands,
									 const double *image, int sqrt_n_pixels,
									 const double *sampling_points, int n_sampling_points);
void comp_image(double *image, int sqrt_n_pixels, const double *sh_coeffs, int n_bands);

void comp_spherical_harmonics_coeffs_step_by_step(double *sh_coeffs, int n_bands,
												  const double *image, int sqrt_n_pixels,
												  double alpha, double beta);
double comp_pixel(int x, int y, int sqrt_n_pixels, const double *sh_coeffs, int n_bands);

void clip_image(double *image, int sqrt_n_pixels);
void scale_image(double *image, int sqrt_n_pixels);
void normalize_image(double *image, int sqrt_n_pixels);

void setup_uniform_hemispherical_dist(double *dist, int n_points);
void setup_weighted_hemispherical_dist(double *dist, int n_points,
									   const double *image, int sqrt_n_pixels);

#endif