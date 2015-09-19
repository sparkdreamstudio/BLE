//
//  YQZCubeAnimationView.h
//  YQZ
//
//  Created by lvlin on 15/1/27.
//  Copyright (c) 2015年 融信信息. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol YQZCubeAnimationViewDelegate <NSObject>

-(void)cubeAnimationViewDelegateClick:(NSInteger)index;

@end

@interface YQZCubeAnimationView : UIView
@property (weak,nonatomic) id<YQZCubeAnimationViewDelegate> delegate;
- (void)loadData:(NSMutableArray *)dataArray;

@end
