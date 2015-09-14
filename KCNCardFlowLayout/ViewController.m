//
//  ViewController.m
//  KCNCardFlowLayout
//
//  Created by Kevin Nguy on 9/14/15.
//  Copyright (c) 2015 kevinnguy. All rights reserved.
//

#import "ViewController.h"

#import "KCNCardFlowLayout.h"

@interface ViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) UICollectionView *collectionView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self setupCollectionView];
}

- (void)setupCollectionView {
    CGRect frame = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds));
    KCNCardFlowLayout *cardFlowLayout = [[KCNCardFlowLayout alloc] initWithCollectionViewFrame:frame itemSize:CGSizeMake(150, 250) lineSpacing:20.0f springResistance:1000.0f];
    self.collectionView = [[UICollectionView alloc] initWithFrame:frame
                                             collectionViewLayout:cardFlowLayout];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.backgroundColor = [UIColor clearColor];
    
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"Cell"];
    
    [self.view addSubview:self.collectionView];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor blueColor];
    
    return cell;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 20;
}

@end
