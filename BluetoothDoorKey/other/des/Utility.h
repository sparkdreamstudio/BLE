//
//  Utitls.h
//  Crypto
//
//  Created by 李响 on 15/7/23.
//  Copyright (c) 2015年 Littocats. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface Utility : NSObject
+(NSData*) parseHexToByteArray:(NSString*) hexString;
+(void)shakeView:(UIView*)view;
+(BOOL)copyFileFrom:(NSString*)sourcePath ToTargetPath:(NSString*)targetPath;
@end
