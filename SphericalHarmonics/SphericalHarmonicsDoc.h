//
//  SphericalHarmonicsDoc.h
//  SphericalHarmonics
//
//  Created by Ichi Kanaya on Tue Dec 16 2003.
//  Copyright (c) 2003 Ichi Kanaya. All rights reserved.
//


#import <Cocoa/Cocoa.h>

@interface SphericalHarmonicsDoc : NSDocument
{
    IBOutlet id coeff_view;
    IBOutlet id result_view;
    IBOutlet id source_view;
	IBOutlet id transform_gage;
	IBOutlet id inverse_transform_gage;
	IBOutlet id sampling_points_slider;
	IBOutlet id sampling_bands_slider;
	IBOutlet id presampling_points_slider;
	IBOutlet id presampling_bands_slider;
	IBOutlet id importance_sampling_checkbox;
	IBOutlet id autoscaling_checkbox;
	IBOutlet id half_size_checkbox;
	IBOutlet id transform_button;
	IBOutlet id inverse_transform_button;
	int n_bands;
	double *coeffs;
}
- (IBAction)load_source:(id)sender;
- (IBAction)trnasform:(id)sender;
- (IBAction)inverse_transform:(id)sender;
@end
