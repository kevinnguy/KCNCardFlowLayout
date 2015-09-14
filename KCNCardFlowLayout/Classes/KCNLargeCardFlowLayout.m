//
//  KCNLargeCardFlowLayout.m
//  Cards
//
//  Created by Kevin Nguy on 8/24/15.
//  Copyright (c) 2015 kevinnguy. All rights reserved.
//

#import "KCNLargeCardFlowLayout.h"

@implementation KCNLargeCardFlowLayout

#pragma mark - Lifecycle
- (instancetype)init {
    return [self initWithCollectionViewFrame:CGRectZero lineSpacing:0];
}

- (instancetype)initWithCollectionViewFrame:(CGRect)frame lineSpacing:(CGFloat)lineSpacing {
    self = [super init];
    if (!self) {
        NSLog(@"KCNLargeCardFlowLayout returned nil because self is nil");
        return nil;
    }
    
    if (CGRectEqualToRect(frame, CGRectZero)) {
        NSLog(@"KCNLargeCardFlowLayout returned nil because frame is CGRectZero");
        return nil;
    }
    
    self.minimumLineSpacing = lineSpacing;
    
    self.itemSize = CGSizeMake(CGRectGetWidth(frame) - (self.minimumLineSpacing * 2),
                               CGRectGetHeight(frame) - (self.minimumLineSpacing * 2));
    
    // top, left, bottom, right
    self.sectionInset = UIEdgeInsetsMake(self.minimumLineSpacing,
                                         self.minimumLineSpacing,
                                         self.minimumLineSpacing,
                                         self.minimumLineSpacing);
    
    self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    
    return self;
}

#pragma mark - UICollectionViewLayout
- (CGSize)collectionViewContentSize {
    NSUInteger count = [self.collectionView.dataSource collectionView:self.collectionView numberOfItemsInSection:0];
    
    CGSize canvasSize = self.collectionView.frame.size;
    NSUInteger rowCount = (canvasSize.height - self.itemSize.height) / (self.itemSize.height + self.minimumInteritemSpacing) + 1;
    NSUInteger columnCount = (canvasSize.width - self.itemSize.width) / (self.itemSize.width + self.minimumLineSpacing) + 1;
    NSUInteger page = ceilf((CGFloat)count / (CGFloat)(rowCount * columnCount));
    
    CGSize contentSize = self.collectionView.frame.size;
    contentSize.width = page * canvasSize.width;
    
    return contentSize;
}

- (CGRect)frameForItemAtIndexPath:(NSIndexPath *)indexPath {
    // UICollectionView align logic missing in horizontal paging scrollview: http://stackoverflow.com/a/20156486/1807446
    
    CGRect cellFrame = CGRectZero;
    cellFrame.origin.x = self.minimumLineSpacing + indexPath.item * CGRectGetWidth(self.collectionView.frame);
    cellFrame.origin.y = self.minimumLineSpacing;
    cellFrame.size.width = self.itemSize.width;
    cellFrame.size.height = self.itemSize.height;
        
    return cellFrame;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes * attr = [super layoutAttributesForItemAtIndexPath:indexPath];
    attr.frame = [self frameForItemAtIndexPath:indexPath];
    return attr;
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {    
    NSArray * originAttrs = [super layoutAttributesForElementsInRect:rect];
    NSMutableArray * attrs = [NSMutableArray array];
    
    [originAttrs enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes * attr, NSUInteger idx, BOOL *stop) {
        NSIndexPath * idxPath = attr.indexPath;
        CGRect itemFrame = [self frameForItemAtIndexPath:idxPath];
        if (CGRectIntersectsRect(itemFrame, rect))
        {
            attr = [self layoutAttributesForItemAtIndexPath:idxPath];
            [attrs addObject:attr];
        }
    }];
    
    return attrs;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)oldBounds {
    return NO;
}


@end
































