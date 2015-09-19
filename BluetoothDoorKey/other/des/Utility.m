//
//  Utitls.m
//  Crypto
//
//  Created by 李响 on 15/7/23.
//  Copyright (c) 2015年 Littocats. All rights reserved.
//

#import "Utility.h"

@implementation Utility
+(NSData*) parseHexToByteArray:(NSString*) hexString
{
    int j=0;
    Byte bytes[hexString.length];
    for(int i=0;i<[hexString length];i++)
    {
        int int_ch;  /// 两位16进制数转化后的10进制数
        unichar hex_char1 = [hexString characterAtIndex:i]; ////两位16进制数中的第一位(高位*16)
        int int_ch1;
        if(hex_char1 >= '0' && hex_char1 <='9')
            int_ch1 = (hex_char1-48)*16;   //// 0 的Ascll - 48
        else if(hex_char1 >= 'A' && hex_char1 <='F')
            int_ch1 = (hex_char1-55)*16; //// A 的Ascll - 65
        else
            int_ch1 = (hex_char1-87)*16; //// a 的Ascll - 97
        i++;
        unichar hex_char2 = [hexString characterAtIndex:i]; ///两位16进制数中的第二位(低位)
        int int_ch2;
        if(hex_char2 >= '0' && hex_char2 <='9')
            int_ch2 = (hex_char2-48); //// 0 的Ascll - 48
        else if(hex_char2 >= 'A' && hex_char1 <='F')
            int_ch2 = hex_char2-55; //// A 的Ascll - 65
        else
            int_ch2 = hex_char2-87; //// a 的Ascll - 97
        
        int_ch = int_ch1+int_ch2;
        bytes[j] = int_ch;  ///将转化后的数放入Byte数组里
        j++;
    }
    
    NSData *newData = [[NSData alloc] initWithBytes:bytes length:hexString.length/2];
    return newData;
}
+(void)shakeView:(UIView*)view
{
    CABasicAnimation* shake = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    
    //设置抖动幅度
    shake.fromValue = [NSNumber numberWithFloat:-0.1];
    
    shake.toValue = [NSNumber numberWithFloat:+0.1];
    
    shake.duration = 0.1;
    
    shake.autoreverses = YES; //是否重复
    
    shake.repeatCount = 4;
    
    [view.layer addAnimation:shake forKey:@"imageView"];
    
    view.alpha = 1.0;
    
    [UIView animateWithDuration:2.0 delay:2.0 options:UIViewAnimationOptionCurveEaseIn animations:nil completion:nil];
}

+(BOOL)copyFileFrom:(NSString*)srcPath ToTargetPath:(NSString*)tarPath
{
    NSFileManager *fileManager=[NSFileManager defaultManager];
    BOOL success=[fileManager createFileAtPath:tarPath contents:nil attributes:nil];
    if (success) {
        NSLog(@"文件创建成功");
        
        NSFileHandle *inFile=[NSFileHandle fileHandleForReadingAtPath:srcPath];
        NSFileHandle *outFile=[NSFileHandle fileHandleForWritingAtPath:tarPath];
        
        NSDictionary   *fileAttu=[fileManager attributesOfItemAtPath:srcPath error:nil];
        NSNumber *fileSizeNum=[fileAttu objectForKey:NSFileSize];
        
        int n=0;
        
        BOOL isEnd=YES;
        NSInteger readSize=0;//已经读取的数量
        NSInteger fileSize=[fileSizeNum longValue];//文件的总长度
        while (isEnd) {
            
            
            
            NSInteger subLength=fileSize-readSize;
            NSData *data=nil;
            if (subLength<5000) {
                isEnd=NO;
                data=[inFile readDataToEndOfFile];
            }else{
                data=[inFile readDataOfLength:5000];
                readSize+=5000;
                [inFile seekToFileOffset:readSize];
            }
            [outFile writeData:data];
            n++;
        }
        
        [inFile closeFile];
        [outFile closeFile];
        return YES;
    }
    else{
        return NO;
    }
}
@end
