//
//  SerialGATT.h
//  HMSoft
//
//  Created by fixed
//  Copyright (c) 2015 arwin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>


@protocol BLEDelegate
//实现4个委托，并导入coreBluetooth库
@optional
//发现新设备后将调用此方法
- (void) peripheralFound:(CBPeripheral *)peripheral periphernalMac :(NSString *)mac;
//接收数据返回
- (void) serialGATTCharValueUpdated: (NSString *)UUID value: (NSData *)data;

//写数据回调
- (void)didWriteValue;
//连接后调用的委托
- (void) setConnect;
//断开蓝牙后调用的委托
- (void) setDisconnect;
@end

@interface BLE : NSObject<CBCentralManagerDelegate, CBPeripheralDelegate> {
    
}

@property (nonatomic, assign) id <BLEDelegate> delegate;
@property (strong, nonatomic) NSMutableArray *peripherals;

@property (strong, nonatomic) CBPeripheral *activePeripheral;

//先调用此setup方法
-(void) setup; //controller setup
-(void) stopScan;
//扫描设备，并设置超时
-(int) findBLEPeripherals:(int)timeout;
//连接设备
-(void) connect: (CBPeripheral *)peripheral;
//断开设备
-(void) disconnect: (CBPeripheral *)peripheral;
//连通第一路继电器
-(BOOL) firstRelayOn: (NSString *)password;
//连通第二路继电器
-(BOOL) secondRelayOn: (NSString *)password;
//断开第一路继电器
-(BOOL) firstRelayOff: (NSString *)password;
//断开第二路继电器
-(BOOL) secondRelayOff: (NSString *)password;
//更改密码
-(BOOL) changePassword: (NSString *)oldPassword newPassword :(NSString *) newPassword;
-(void) write:(CBPeripheral *)peripheral data:(NSData *)data;
@end
