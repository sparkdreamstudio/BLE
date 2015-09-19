//
//  YQZCubeAnimationView.m
//  YQZ
//
//  Created by lvlin on 15/1/27.
//  Copyright (c) 2015年 融信信息. All rights reserved.
//

#import "YQZCubeAnimationView.h"
#import <QuartzCore/QuartzCore.h>

@interface YQZCubeAnimationView()

@property (nonatomic, strong) NSMutableArray *textArray;

@property (nonatomic, strong) UILabel *sLabel;
@property (nonatomic, strong) UILabel *dLabel;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) NSInteger index;
@end

@implementation YQZCubeAnimationView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        if (self.sLabel == nil)
        {
            self.sLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, frame.size.width - 5, 30)];
            [self.sLabel setClipsToBounds:YES];
            [self.sLabel setFont:[UIFont systemFontOfSize:13]];
            self.sLabel.textColor = [UIColor colorWithRed:0x2e/255.f green:0x3e/255.f blue:0x54/255.f alpha:1];
            self.sLabel.backgroundColor = [UIColor whiteColor];
            [self.sLabel setNumberOfLines:0];
            [self.sLabel setText:@"欢迎使用摇开门!"];
            [self addSubview:self.sLabel];
            
            self.dLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, frame.size.width - 5, 30)];
            [self.dLabel setClipsToBounds:YES];
            [self.dLabel setFont:[UIFont systemFontOfSize:13]];
            self.dLabel.textColor = [UIColor colorWithRed:0x2e/255.f green:0x3e/255.f blue:0x54/255.f alpha:1];
            self.dLabel.backgroundColor = [UIColor whiteColor];
            [self.dLabel setNumberOfLines:0];
            [self.dLabel setText:@"欢迎使用摇开门!"];
            [self addSubview:self.dLabel];
        }
        self.backgroundColor = [UIColor clearColor];
        self.textArray = [NSMutableArray array];
        self.index = 0;
        UITapGestureRecognizer* gesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(gesture:)];
        self.userInteractionEnabled = YES;
        [self addGestureRecognizer:gesture];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (self.timer != nil && [self.timer isValid])
    {
        [self.timer invalidate];
        self.timer = nil;
    }
}

//获取数据
- (void)loadData:(NSMutableArray *)dataArray
{
    if (dataArray.count == 0) {
        [dataArray addObject:@"欢迎使用摇开门!"];
    }
    self.textArray = dataArray;
    if (dataArray.count > 0)
    {
        if (self.timer == nil) {
            self.timer = [NSTimer timerWithTimeInterval: 4.0
                                                 target: self
                                               selector: @selector(handleTimer:)
                                               userInfo: nil
                                                repeats: YES];
            NSRunLoop *runloop = [NSRunLoop currentRunLoop];
            [runloop addTimer:self.timer forMode:NSRunLoopCommonModes];        //使用该模式在屏幕上下滑动时，文字仍然滚动
        }
    }
}

-(void)handleTimer:(id)sender
{
    if (self.index >= [self.textArray count]) {
        self.index = 0;
    }
    NSString *text = [self.textArray objectAtIndex:self.index];
    if (self.index % 2 == 0) {
        self.sLabel.text = text;
        self.sLabel.hidden = NO;
        self.dLabel.hidden = YES;
    } else {
        self.dLabel.text = text;
        self.dLabel.hidden = NO;
        self.sLabel.hidden = YES;
    }
    
    CATransition *animation = [CATransition animation];
    animation.delegate = self;
    animation.duration = 0.3;
    animation.timingFunction = UIViewAnimationCurveEaseInOut;
    animation.type = @"cube";
    animation.subtype = kCATransitionFromTop;
    
    NSUInteger sIndex = [[self subviews] indexOfObject:self.sLabel];
    NSUInteger dIndex = [[self subviews] indexOfObject:self.dLabel];
    [self exchangeSubviewAtIndex:sIndex withSubviewAtIndex:dIndex];
    
    [[self layer] addAnimation:animation forKey:@"animation"];
    
    self.index++;
}


-(void)gesture:(UITapGestureRecognizer*)ges
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(cubeAnimationViewDelegateClick:)]) {
        if (self.index != 0) {
            [self.delegate cubeAnimationViewDelegateClick:self.index-1];
        }
        else{
            [self.delegate cubeAnimationViewDelegateClick:0];
        }
        
    }
}

@end
