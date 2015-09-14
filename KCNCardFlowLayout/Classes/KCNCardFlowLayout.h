//
//  KCNCardFlowLayout.h
//  Cards
//
//  Created by Kevin Nguy on 8/24/15.
//  Copyright (c) 2015 kevinnguy. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KCNCardFlowLayout : UICollectionViewFlowLayout <UIGestureRecognizerDelegate>

- (instancetype)initWithCollectionViewFrame:(CGRect)frame
                                   itemSize:(CGSize)itemSize
                                lineSpacing:(CGFloat)lineSpacing
                            springResistance:(CGFloat)springIntensity;

@end
