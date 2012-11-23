/*
 *  MersenneTwister.h
 *  SphericalHarmonics
 *
 *  Created by Ichi Kanaya on Thu Jan 08 2004.
 *  Copyright (c) 2004 Ichi Kanaya. All rights reserved.
 *  Based on Mersenne Twister Copyright (c) 1997-2002 Makoto Matsumoto and Takuji Nishimura.
 *
 */

#ifndef __MERSENNETWISTER_H
#define __MERSENNETWISTER_H

void init_mersenne_twister(long seed);
double random_number_closed(void);  /* [0,1] */
double random_number_half_closed(void);  /* [0,1) */

#endif