//
//  KCNCardFlowLayout.m
//  Cards
//
//  Created by Kevin Nguy on 8/24/15.
//  Copyright (c) 2015 kevinnguy. All rights reserved.
//

#import "KCNCardFlowLayout.h"

@interface KCNCardFlowLayout () 

@property (nonatomic, strong) NSMutableArray *deleteIndexPaths;
@property (nonatomic, strong) NSMutableArray *insertIndexPaths;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;

// Cell animation
@property (nonatomic, strong) UIDynamicAnimator *dynamicAnimator;
@property (nonatomic) CGFloat latestDelta;
@property (nonatomic) CGFloat springResistance;

// Tilt cell pan gesture
@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizer;


@end

@implementation KCNCardFlowLayout

#pragma mark - Lifecycle
- (instancetype)init {
    return [self initWithCollectionViewFrame:CGRectZero itemSize:CGSizeZero lineSpacing:0 springResistance:0];
}

- (instancetype)initWithCollectionViewFrame:(CGRect)frame itemSize:(CGSize)itemSize lineSpacing:(CGFloat)lineSpacing springResistance:(CGFloat)springIntensity {
    self = [super init];
    if (!self) {
        NSLog(@"KCNCardFlowLayout returned nil because self is nil");
        return nil;
    }
    
    if (CGRectEqualToRect(frame, CGRectZero)) {
        NSLog(@"KCNCardFlowLayout returned nil because frame is CGRectZero");
        return nil;
    }
    
    NSInteger itemWidth = itemSize.width;
    NSInteger itemHeight = itemSize.height;
    
    self.minimumLineSpacing = lineSpacing;
    
    self.itemSize = CGSizeMake(itemWidth, itemHeight);
    self.sectionInset = UIEdgeInsetsMake(CGRectGetHeight(frame) - itemHeight - self.minimumLineSpacing,
                                         self.minimumLineSpacing,
                                         self.minimumLineSpacing,
                                         self.minimumLineSpacing);

    self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    
    self.springResistance = springIntensity;
    
//    [self addObserver:self forKeyPath:@"collectionView" options:NSKeyValueObservingOptionNew context:nil];

    return self;
}

- (void)dealloc {
//    [self removeObserver:self forKeyPath:@"collectionView"];
}

- (void)setupCollectionView {
    self.panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    self.panGestureRecognizer.delegate = self;
    [self.collectionView addGestureRecognizer:self.panGestureRecognizer];
}

#pragma mark - KVC
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"collectionView"] && self.collectionView) {
        [self setupCollectionView];
    } else  {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Gesture recognizers
- (void)handlePanGesture:(UIPanGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        self.selectedIndexPath = [self.collectionView indexPathForItemAtPoint:[recognizer locationInView:self.collectionView]];
        UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:self.selectedIndexPath];
        
        [UIView animateWithDuration:0.2f animations:^{
            cell.layer.transform = [self transformCell:cell withGestureRecognizer:recognizer];
            cell.layer.shadowOffset = CGSizeZero;
            cell.layer.shadowRadius = 10;
            cell.layer.shadowOpacity = 1;
            cell.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.5f].CGColor;
        }];
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:self.selectedIndexPath];
        cell.layer.transform = [self transformCell:cell withGestureRecognizer:recognizer];
    } else if (recognizer.state == UIGestureRecognizerStateCancelled || recognizer.state == UIGestureRecognizerStateEnded) {
        UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:self.selectedIndexPath];
        
        CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
        anim.fromValue = @1;
        anim.toValue = @0;
        anim.duration = 0.5f;
        [cell.layer addAnimation:anim forKey:@"shadowOpacity"];
        cell.layer.shadowOpacity = 0;
        
        [UIView animateWithDuration:0.2f animations:^{
            cell.layer.transform = CATransform3DIdentity;
        }];

        self.selectedIndexPath = nil;
    }
}

- (CATransform3D)transformCell:(UICollectionViewCell *)cell withGestureRecognizer:(UIGestureRecognizer *)recognizer {
    // Get point and set its max to cell size's width
    CGPoint point = [recognizer locationInView:cell];
    point = CGPointMake(MAX(0, MIN(point.x, self.itemSize.width)), MAX(0, MIN(point.y, self.itemSize.height)));
    
    // Get cell's center
    CGPoint cellCenter = CGPointMake(self.itemSize.width / 2, self.itemSize.height / 2);
    
    // Start transformation
    CATransform3D transformation = CATransform3DIdentity;
    transformation.m11 = 1.12f;
    transformation.m22 = 1.12f;
    
    CGFloat tiltPerspective = 0.0004;
    if (point.x <= cellCenter.x) {
        // As finger pans left, m14 increases negatively
        transformation.m14 = -tiltPerspective * (cellCenter.x - point.x) / cellCenter.x;
    } else {
        // As finger pans right, m14 increases positively
        transformation.m14 = tiltPerspective * (point.x - cellCenter.x) / cellCenter.x;
    }
    
    if (point.y <= cellCenter.y) {
        // As finger pans up, m24 increases negatively
        transformation.m24 = -tiltPerspective * (cellCenter.y - point.y) / cellCenter.y;
    } else {
        // As finger pans down, m24 increases positively
        transformation.m24 = tiltPerspective * (point.y - cellCenter.y) / cellCenter.y;
    }
    
    return transformation;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

#pragma mark - UICollectionViewLayout
- (void)prepareLayout {
    [super prepareLayout];
    [self setupCellScrollBounce];
}

- (void)setupCellScrollBounce {
    // Calculate spring behavior for all items
    NSMutableArray *attributes = [NSMutableArray new];
    
    NSInteger sectionCount = [self.collectionView numberOfSections];
    for (int j = 0; j < sectionCount; j++) {
        NSInteger itemCount = [self.collectionView numberOfItemsInSection:j];
        for (int k = 0; k < itemCount; k++) {
            UICollectionViewLayoutAttributes *attribute = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:[NSIndexPath indexPathForItem:k inSection:j]];
            attribute.frame = CGRectMake((self.itemSize.width * k) + (self.sectionInset.left * (k + 1)), self.sectionInset.top, self.itemSize.width, self.itemSize.height);
            [attributes addObject:attribute];
        }
    }
    
    if (self.dynamicAnimator.behaviors.count == attributes.count) {
        return;
    }
    
    self.dynamicAnimator = [[UIDynamicAnimator alloc] initWithCollectionViewLayout:self];
    
    CGPoint touchLocation = [self.collectionView.panGestureRecognizer locationInView:self.collectionView];
    
    [attributes enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes *item, NSUInteger idx, BOOL *stop) {
        CGPoint center = item.center;
        UIAttachmentBehavior *springBehaviour = [[UIAttachmentBehavior alloc] initWithItem:item attachedToAnchor:center];
        
        springBehaviour.length = 0.0f;
        springBehaviour.damping = 0.8f; // how bouncy: 0 is bounciest, 1 is no bounce
        springBehaviour.frequency = 1.0f; // speed: 0 is slowest, 1 is normal
        
        // If our touchLocation is not (0,0), we'll need to adjust our item's center "in flight"
        if (!CGPointEqualToPoint(CGPointZero, touchLocation)) {
            CGFloat yDistanceFromTouch = fabs(touchLocation.y - springBehaviour.anchorPoint.y);
            CGFloat xDistanceFromTouch = fabs(touchLocation.x - springBehaviour.anchorPoint.x);
            CGFloat scrollResistance = (yDistanceFromTouch + xDistanceFromTouch) / 1500.0f;
            
            if (self.latestDelta < 0) {
                center.x += MAX(self.latestDelta, self.latestDelta * scrollResistance);
            } else {
                center.x += MIN(self.latestDelta, self.latestDelta * scrollResistance);
            }
            item.center = center;
        }
        
        [self.dynamicAnimator addBehavior:springBehaviour];
    }];
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    return [self.dynamicAnimator itemsInRect:rect];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self.dynamicAnimator layoutAttributesForCellAtIndexPath:indexPath];
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)oldBounds {
    // Update cell bounce animation when scrolling
    
    UIScrollView *scrollView = self.collectionView;
    CGFloat delta = oldBounds.origin.x - scrollView.bounds.origin.x;
    
    self.latestDelta = delta;
    
    CGPoint touchLocation = [self.collectionView.panGestureRecognizer locationInView:self.collectionView];
    
    [self.dynamicAnimator.behaviors enumerateObjectsUsingBlock:^(UIAttachmentBehavior *springBehaviour, NSUInteger idx, BOOL *stop) {
        CGFloat yDistanceFromTouch = fabs(touchLocation.y - springBehaviour.anchorPoint.y);
        CGFloat xDistanceFromTouch = fabs(touchLocation.x - springBehaviour.anchorPoint.x);
        CGFloat scrollResistance = (yDistanceFromTouch + xDistanceFromTouch) / self.springResistance;
        
        UICollectionViewLayoutAttributes *item = [springBehaviour.items firstObject];
        CGPoint center = item.center;
        if (delta < 0) {
            center.x += MAX(delta, delta*scrollResistance);
        } else {
            center.x += MIN(delta, delta*scrollResistance);
        }
        item.center = center;
        
        [self.dynamicAnimator updateItemUsingCurrentState:item];
    }];
    
    return NO;
}

- (void)prepareForCollectionViewUpdates:(NSArray *)updateItems {
    // Keep track of insert and delete index paths
    [super prepareForCollectionViewUpdates:updateItems];
    
    self.deleteIndexPaths = [NSMutableArray new];
    self.insertIndexPaths = [NSMutableArray new];
    
    for (UICollectionViewUpdateItem *update in updateItems) {
        if (update.updateAction == UICollectionUpdateActionDelete) {
            [self.deleteIndexPaths addObject:update.indexPathBeforeUpdate];
        } else if (update.updateAction == UICollectionUpdateActionInsert) {
            [self.insertIndexPaths addObject:update.indexPathAfterUpdate];
        }
    }
}

- (void)finalizeCollectionViewUpdates {
    [super finalizeCollectionViewUpdates];
    
    // Release the insert and delete index paths
    self.deleteIndexPaths = nil;
    self.insertIndexPaths = nil;
}

- (UICollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath *)itemIndexPath {
    // When adding item, animate cell "popping out"
    UICollectionViewLayoutAttributes *attributes = [super initialLayoutAttributesForAppearingItemAtIndexPath:itemIndexPath];
    if ([self.insertIndexPaths containsObject:itemIndexPath]) {
        if (!attributes) {
            attributes = [self layoutAttributesForItemAtIndexPath:itemIndexPath];
        }
        
        attributes.transform = CGAffineTransformScale(CGAffineTransformMakeScale(0.01f, 0.01f), 1, 1);
    }
    
    return attributes;
}

- (UICollectionViewLayoutAttributes *)finalLayoutAttributesForDisappearingItemAtIndexPath:(NSIndexPath *)itemIndexPath {
    // When removing item, animate cell "shrinking" to its center
    UICollectionViewLayoutAttributes *attributes = [super finalLayoutAttributesForDisappearingItemAtIndexPath:itemIndexPath];
    if ([self.deleteIndexPaths containsObject:itemIndexPath]) {
        if (!attributes) {
            attributes = [self layoutAttributesForItemAtIndexPath:itemIndexPath];
        }

        attributes.transform = CGAffineTransformScale(CGAffineTransformMakeScale(0.01f, 0.01f), 1, 1);
    }
    
    return attributes;
}

@end

