//
//  SphericalHarmonicsDoc.m
//  SphericalHarmonics
//
//  Created by Ichi Kanaya on Tue Dec 16 2003.
//  Copyright (c) 2003 Ichi Kanaya. All rights reserved.
//

#import <math.h>
#import <stdlib.h>
#import <gsl/gsl_sf_legendre.h>
#import <SphericalHarmonicsCore.h>
#import <MersenneTwister.h>
#import "SphericalHarmonicsDoc.h"

@implementation SphericalHarmonicsDoc

#define PIXEL_DEPTH                8
#define SQRT_N_PIXELS              256
#define N_PIXELS                   (SQRT_N_PIXELS * SQRT_N_PIXELS)
#define SQRT_N_PIXELS_TO_PRERENDER 64
#define HALF_SIZE                  128
#define FULL_SIZE                  256

#define FREE(x) ((x) ? free(x) : (void)0)

#define ADVANCE(p, n, T)            (p = (void *)((T *)(p) + (n)))
#define ADVANCE_CONST(p, n, T)      (p = (const void *)((const T *)(p) + (n)))
#define SET_AND_ADVANCE(p, x, n, T) (memcpy((p), (x), (n) * sizeof(T)), ADVANCE(p, n, T))

- (id)init
{
    self = [super init];
    if (self) {
        init_mersenne_twister(123456789L);
    }
    return self;
}

- (void)dealloc
{
    if (coeffs) {
        free(coeffs);
        coeffs = nil;
    }
    [super dealloc];
}

- (NSString *)windowNibName
{
    return @"SphericalHarmonicsDoc";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
    // sync all view
    // enable inverse_transform button
}

- (NSData *)dataRepresentationOfType:(NSString *)aType
{
    const char *document_header = "SPHD";      // SphericalHarmonics Document
    const char *stream_header = "STRM";        // Object Stream
    const char *integer_header = "SI4S";       // Signed Integer 32-bit Single
    const char *double_array_header = "DP8V";  // Double Precision 64-bit Array
    
    const int n_coeffs = n_bands * n_bands;
    
    const int total_size = 4 * sizeof(char)    // "SPHD"
        + 4 * sizeof(char)                     // "STRM"
        + 1 * sizeof(int)                      // num of objects = 2
        + 4 * sizeof(char)                     // "SI4S"
        + 1 * sizeof(int)                      // n_bands
        + 4 * sizeof(char)                     // "DP8V"
        + 1 * sizeof(int)                      // n_coeffs
        + n_coeffs * sizeof(double);           // coeffs

    int size;
    void *data = malloc(total_size);
    void *p_data = data;
    NSData *ret;
    
    // Document header
    SET_AND_ADVANCE(p_data, document_header, 4, char);
    // Stream header
    SET_AND_ADVANCE(p_data, stream_header, 4, char);
    size = 2;
    SET_AND_ADVANCE(p_data, &size, 1, int);
    // n_bands
    SET_AND_ADVANCE(p_data, integer_header, 4, char);
    SET_AND_ADVANCE(p_data, &n_bands, 1, int);
    // coeffs
    SET_AND_ADVANCE(p_data, double_array_header, 4, char);
    SET_AND_ADVANCE(p_data, &n_coeffs, 1, int);
    SET_AND_ADVANCE(p_data, coeffs, n_coeffs, double);
    
    ret = [NSData dataWithBytes: data length: total_size];
    free(data);
    return ret;
}

- (BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)aType
{
    const void *p_data;
    int n_coeffs;
    
    if (coeffs) {
        free(coeffs);
        coeffs = nil;
    }
    p_data = [data bytes];

    ADVANCE_CONST(p_data, 4, char);  // "SPHD"
    ADVANCE_CONST(p_data, 4, char);  // "STRM"
    ADVANCE_CONST(p_data, 1, int);   // num of objects
    ADVANCE_CONST(p_data, 4, char);  // "SI4S"
    n_bands = *(const int *)p_data;
    ADVANCE_CONST(p_data, 1, int);
    ADVANCE_CONST(p_data, 4, char);  // "DP8V"
    n_coeffs = *(const int *)p_data;
    ADVANCE_CONST(p_data, 1, int);
    coeffs = (double *)calloc(n_coeffs, sizeof(double));
    memcpy(coeffs, p_data, n_coeffs * sizeof(double));

    return YES;
}

- (void)close
{
    [super close];
}

- (IBAction)load_source:(id)sender
{
    NSOpenPanel *open_panel;
    NSArray *types;
    int status;
    
    open_panel = [NSOpenPanel openPanel];
    types = [NSImage imageFileTypes];
    status = [open_panel runModalForDirectory: NSHomeDirectory() file: @"Desktop" types: types];
    if (status == NSOKButton) {
        [source_view setImage: [[[NSImage alloc] initWithContentsOfFile: [open_panel filename]] autorelease]];
        [transform_button setEnabled: YES];
    }	
}

- (IBAction)trnasform:(id)sender
{
    NSRange whole_range, end_range;
    
    const int n_sampling_points = 1 << ((int)[sampling_points_slider floatValue] + 7);

    unsigned char *source_image_rep = [[[[NSBitmapImageRep alloc]
        initWithData: [[source_view image] TIFFRepresentation]] autorelease] bitmapData];
    double *sampling_points;
    double *image;
    int i;
    
    n_bands = (int)[sampling_bands_slider floatValue];
    sampling_points = calloc(n_sampling_points * 2, sizeof(double));
    image = calloc(N_PIXELS, sizeof(double));
    for (i = 0; i < N_PIXELS; ++i) {
        image[i] = (double)source_image_rep[i] / (double)((1 << PIXEL_DEPTH) - 1);
    }

    if ([importance_sampling_checkbox state] == NSOnState) {
        const int n_points_for_presampling = 1 << ((int)[presampling_points_slider floatValue] + 7);
        const int n_bands_for_presampling = (int)[presampling_bands_slider floatValue];
        double *coeffs_for_presampling = calloc(n_bands_for_presampling * n_bands_for_presampling, sizeof(double));
        double *points_for_presampling = calloc(n_points_for_presampling * 2, sizeof(double));
        double *image_for_presampling = calloc(SQRT_N_PIXELS_TO_PRERENDER * SQRT_N_PIXELS_TO_PRERENDER, sizeof(double));
        
        setup_uniform_hemispherical_dist(points_for_presampling, n_points_for_presampling);
        comp_spherical_harmonics_coeffs(coeffs_for_presampling, n_bands_for_presampling, image, SQRT_N_PIXELS,
                                        points_for_presampling, n_points_for_presampling);
        comp_image(image_for_presampling, SQRT_N_PIXELS_TO_PRERENDER, coeffs_for_presampling, n_bands_for_presampling);
        // normalize_image...
        setup_weighted_hemispherical_dist(sampling_points, n_sampling_points, image_for_presampling, SQRT_N_PIXELS_TO_PRERENDER);
        
        free(image_for_presampling);
        free(points_for_presampling);
        free(coeffs_for_presampling);
    }
    else {
        setup_uniform_hemispherical_dist(sampling_points, n_sampling_points);        
    }
    
    if (coeffs) {
        free(coeffs);
        coeffs = nil;
    }
    coeffs = calloc(n_bands * n_bands, sizeof(double));
#if 1
    [transform_gage setDoubleValue: 0.0];
    [transform_gage setMaxValue: n_sampling_points];
    for (i = 0; i < n_sampling_points; ++i) {
        double alpha, beta;
        
        alpha = *sampling_points++;
        beta = *sampling_points++;
        comp_spherical_harmonics_coeffs_step_by_step(coeffs, n_bands, image, SQRT_N_PIXELS, alpha, beta);
        [transform_gage incrementBy: 1.0];
        [transform_gage displayIfNeeded];
    }
    for (i = 0; i < n_bands * n_bands; ++i) {
        coeffs[i] /= (double)n_sampling_points;
    }
#else
    comp_spherical_harmonics_coeffs(coeffs, n_bands, image, SQRT_N_PIXELS, sampling_points, n_sampling_points);
#endif
    
    [coeff_view selectAll: nil];
    whole_range = [coeff_view selectedRange];
    end_range = NSMakeRange(whole_range.length, 0);
    [coeff_view setSelectedRange: end_range];
    for (i = 0; i < n_bands * n_bands; ++i) {
        NSString *text = [NSString stringWithFormat: @"%d: %f\n", i, coeffs[i]];
        [coeff_view insertText: text];
    }
    
    [inverse_transform_button setEnabled: YES];
    
    free(image);
    ///// free(sampling_points); ///// Error? Temporary commented out (2012-11-23)
}

- (IBAction)inverse_transform:(id)sender
{
    int sqrt_n_pixels_to_render;
    NSImage *bitmap_image;
    NSBitmapImageRep *bitmap_image_rep;
    unsigned char *bitmap_image_buff[3];
    double *image;
    int i, x, y;
    
    if ([half_size_checkbox state] == NSOnState) {
        sqrt_n_pixels_to_render = HALF_SIZE;
    }
    else {
        sqrt_n_pixels_to_render = FULL_SIZE;
    }
    
    for (i = 0; i < 3; ++i) {
        bitmap_image_buff[i] = calloc(sqrt_n_pixels_to_render * sqrt_n_pixels_to_render, sizeof(char));
    }
    image = calloc(sqrt_n_pixels_to_render * sqrt_n_pixels_to_render, sizeof(double));
#if 1
    [inverse_transform_gage setMaxValue: sqrt_n_pixels_to_render * sqrt_n_pixels_to_render];
    [inverse_transform_gage setDoubleValue: 0.0];
    for (y = 0; y < sqrt_n_pixels_to_render; ++y) {
        for (x = 0; x < sqrt_n_pixels_to_render; ++x) {
            image[y * sqrt_n_pixels_to_render + x] = comp_pixel(x, y, sqrt_n_pixels_to_render, coeffs, n_bands);
            [inverse_transform_gage incrementBy: 1.0];
            [inverse_transform_gage displayIfNeeded];
        }
    }
#else
    comp_image(image, sqrt_n_pixels_to_render, coeffs, n_bands);
#endif
    if ([autoscaling_checkbox state] == NSOnState) {
        scale_image(image, sqrt_n_pixels_to_render);        
    }
    for (y = 0; y < sqrt_n_pixels_to_render; ++y) {
        for (x = 0; x < sqrt_n_pixels_to_render; ++x) {
            double p = image[y * sqrt_n_pixels_to_render+ x];
            
            bitmap_image_buff[0][y * sqrt_n_pixels_to_render + x]
                = bitmap_image_buff[1][y * sqrt_n_pixels_to_render + x]
                = bitmap_image_buff[2][y * sqrt_n_pixels_to_render + x]
                = (int)(p * (double)((1 << PIXEL_DEPTH) - 1));
        }
    }
    bitmap_image_rep = [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes: &bitmap_image_buff[0]
                                                                pixelsWide: sqrt_n_pixels_to_render
                                                                pixelsHigh: sqrt_n_pixels_to_render
                                                             bitsPerSample: PIXEL_DEPTH
                                                           samplesPerPixel: 3
                                                                  hasAlpha: NO
                                                                  isPlanar: YES
                                                            colorSpaceName: NSDeviceRGBColorSpace
                                                               bytesPerRow: sqrt_n_pixels_to_render
                                                              bitsPerPixel: PIXEL_DEPTH]
        autorelease];
    bitmap_image = [[[NSImage alloc] initWithData: [bitmap_image_rep TIFFRepresentation]] autorelease];
    [result_view setImage: bitmap_image];
    free(image);
    for (i = 0; i < 3; ++i) {
        FREE(bitmap_image_buff[i]);
    }
}

@end
