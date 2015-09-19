//
//  SerialGATT.m
//  HMSoft
//
//  Created by fixed
//  Copyright (c) 2015 arwin. All rights reserved.
//

#import "SerialGATT.h"

@interface BLE () {
    
}
@property (strong, nonatomic) CBCentralManager *manager;

@end
@implementation BLE

@synthesize delegate;
@synthesize peripherals;
@synthesize manager;
@synthesize activePeripheral;

#define SERVICE_UUID     0xFFE0
#define CHAR_UUID        0xFFE1

/*!
 *  @method swap:
 *
 *  @param s Uint16 value to byteswap
 *
 *  @discussion swap byteswaps a UInt16
 *
 *  @return Byteswapped UInt16
 */

-(UInt16) swap:(UInt16)s {
    UInt16 temp = s << 8;
    temp |= (s >> 8);
    return temp;
}

/*
 * (void) setup
 * enable CoreBluetooth CentralManager and set the delegate for SerialGATT
 *
 */

-(void) setup
{
    manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

/*
 * -(int) findHMSoftPeripherals:(int)timeout
 *
 */
-(int) findBLEPeripherals:(int)timeout
{
    if ([manager state] != CBCentralManagerStatePoweredOn) {
        printf("CoreBluetooth is not correctly initialized !\n");
        return -1;
    }
    
    [NSTimer scheduledTimerWithTimeInterval:(float)timeout target:self selector:@selector(scanTimer:) userInfo:nil repeats:NO];
    
    //[manager scanForPeripheralsWithServices:[NSArray arrayWithObject:serviceUUID] options:0]; // start Scanning
    [manager scanForPeripheralsWithServices:nil options:0];
    return 0;
}

/*
 * scanTimer
 * when findHMSoftPeripherals is timeout, this function will be called
 *
 */
-(void) scanTimer:(NSTimer *)timer
{
    [manager stopScan];
}

/*
 *  @method printPeripheralInfo:
 *
 *  @param peripheral Peripheral to print info of
 *
 *  @discussion printPeripheralInfo prints detailed info about peripheral
 *
 */
- (void) printPeripheralInfo:(CBPeripheral*)peripheral {
    CFStringRef s = CFUUIDCreateString(NULL, (__bridge CFUUIDRef )peripheral.identifier);
    printf("------------------------------------\r\n");
    printf("Peripheral Info :\r\n");
    printf("UUID : %s\r\n",CFStringGetCStringPtr(s, 0));
    printf("RSSI : %d\r\n",[peripheral.RSSI intValue]);
    printf("Name : %s\r\n",[peripheral.name cStringUsingEncoding:NSStringEncodingConversionAllowLossy]);
    printf("isConnected : %d\r\n",peripheral.state == CBPeripheralStateConnected);
    printf("-------------------------------------\r\n");
    
}

/*
 * connect
 * connect to a given peripheral
 *
 */
-(void) connect:(CBPeripheral *)peripheral
{
    if (!(peripheral.state == CBPeripheralStateConnected)) {
        [manager connectPeripheral:peripheral options:nil];
    }
}

-(void) stopScan
{
    [manager stopScan];
}

/*
 * disconnect
 * disconnect to a given peripheral
 *
 */
-(void) disconnect:(CBPeripheral *)peripheral
{
    //    [self cleanup];
    //    manager = nil;
    [manager cancelPeripheralConnection:peripheral];
    
}

- (void)cleanup
{
    // Don't do anything if we're not connected
    if (activePeripheral.state != CBPeripheralStateConnected) {
        return;
    }
    
    // See if we are subscribed to a characteristic on the peripheral
    if (activePeripheral.services != nil) {
        NSLog(@"turn off service");
        for (CBService *service in activePeripheral.services) {
            if (service.characteristics != nil) {
                for (CBCharacteristic *characteristic in service.characteristics) {
                    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"0xFFE1"]]) {
                        if (characteristic.isNotifying) {
                            // It is notifying, so unsubscribe
                            [activePeripheral setNotifyValue:NO forCharacteristic:characteristic];
                            
                            // And we're done.
                            return;
                        }
                    }
                }
            }
        }
    }
}
#pragma mark - basic operations for SerialGATT service
-(void) write:(CBPeripheral *)peripheral data:(NSData *)data
{
    [self writeValue:SERVICE_UUID characteristicUUID:CHAR_UUID p:peripheral data:data];
}

-(void) read:(CBPeripheral *)peripheral
{
    printf("begin reading\n");
    //[peripheral readValueForCharacteristic:dataRecvrCharacteristic];
    printf("now can reading......\n");
}

-(void) notify: (CBPeripheral *)peripheral on:(BOOL)on
{
    [self notification:SERVICE_UUID characteristicUUID:CHAR_UUID p:peripheral on:YES];
}


#pragma mark - CBCentralManager Delegates

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    NSLog(@"1111111111111");
    //TODO: to handle the state updates
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    printf("Now we found device\n");
    NSLog(@"advertisementData %@",advertisementData);
    if (!peripherals) {
        peripherals = [[NSMutableArray alloc] initWithObjects:peripheral, nil];
        for (int i = 0; i < [peripherals count]; i++) {
            if ([self describeDictonary:advertisementData]) {
                NSString * macs = [self getMacAddress:advertisementData];
                
                [delegate peripheralFound:peripheral periphernalMac:macs];
            }
        }
    }
    
    
    {
        if((__bridge CFUUIDRef )peripheral.identifier == NULL) return;
        //if(peripheral.name == NULL) return;
        //if(peripheral.name == nil) return;
        if(peripheral.name.length < 1) return;
        // Add the new peripheral to the peripherals array
        for (int i = 0; i < [peripherals count]; i++) {
            CBPeripheral *p = [peripherals objectAtIndex:i];
            if((__bridge CFUUIDRef )p.identifier == NULL) continue;
            CFUUIDBytes b1 = CFUUIDGetUUIDBytes((__bridge CFUUIDRef )p.identifier);
            CFUUIDBytes b2 = CFUUIDGetUUIDBytes((__bridge CFUUIDRef )peripheral.identifier);
            if (memcmp(&b1, &b2, 16) == 0) {
                // these are the same, and replace the old peripheral information
                [peripherals replaceObjectAtIndex:i withObject:peripheral];
                printf("Duplicated peripheral is found...\n");
                //[delegate peripheralFound: peripheral];
                return;
            }
        }
        if ([self describeDictonary:advertisementData]) {
            NSString * macs = [self getMacAddress:advertisementData];
            printf("New peripheral is found...\n");
            [peripherals addObject:peripheral];
            [delegate peripheralFound:peripheral periphernalMac:macs];
        }
        
        
        //        printf("New peripheral is found...\n");
        //        [peripherals addObject:peripheral];
        //        [delegate peripheralFound:peripheral];
        return;
    }
    //    printf("%s\n", __FUNCTION__);
}
///////////////////////////////////////////////////////////////////////////////////////
- (Boolean)describeDictonary: (NSDictionary *) dict
{
    NSArray *keys;
    id key;
    keys = [dict allKeys];
    for(int i = 0; i < [keys count]; i++)
    {
        key = [keys objectAtIndex:i];
        //        NSLog(@"111111111%@",key);
        if([key isEqualToString:@"kCBAdvDataManufacturerData"])
        {
            NSLog(@"soft1");
            NSData *tempValue = [dict objectForKey:key];
            NSLog(@"soft1 data %@",tempValue);
            const Byte *tempByte = [tempValue bytes];
            if([tempValue length] == 8 && tempByte[0] == 0x48 && tempByte[1] == 0x4D){
                NSLog(@"HMSOFT1");
                return true;
            }
            
        }
        if([key isEqualToString:@"kCBAdvDataServiceData"])
        {
            NSDictionary *temp = [dict objectForKey:key];
            NSLog(@"soft2 temp %@",temp.allKeys);
            NSData *tempValue = [temp objectForKey:[temp.allKeys objectAtIndex:0]];
            NSLog(@"soft2 data %@",tempValue);
            if (tempValue.length==6) {
                NSLog(@"HMSOFT2");
                return true;
            }
            else{
                
            }
            
            //there is name
            //NSString *szName = [dict objectForKey: key];
        }
    }
    return false;
}
-(NSString *) getMacAddress:(NSDictionary *) dict{
    NSArray *keys;
    id key;
    keys = [dict allKeys];
    for(int i = 0; i < [keys count]; i++)
    {
        key = [keys objectAtIndex:i];
        if([key isEqualToString:@"kCBAdvDataServiceData"])
        {
            NSDictionary *temp = [dict objectForKey:key];
            NSData *tempValue = [temp objectForKey:[temp.allKeys objectAtIndex:0]];
            if (tempValue !=NULL && tempValue.length==6) {
                NSLog(@"bytes %@",tempValue);
                const Byte *tempByte = [tempValue bytes];
                NSString * macS = [[NSString alloc] initWithFormat:@"%@:%@:%@:%@:%@:%@",[self byteTo16String:tempByte[0]],[self byteTo16String:tempByte[1]],[self byteTo16String:tempByte[2]],[self byteTo16String:tempByte[3]],[self byteTo16String:tempByte[4]],[self byteTo16String:tempByte[5]]];
                NSLog(@"111111111%@",macS);
                return macS;
            }
            
            
            //there is name
            //NSString *szName = [dict objectForKey: key];
        }
        
        
        else if([key isEqualToString:@"kCBAdvDataManufacturerData"])
        {
            NSData *tempValue = [dict objectForKey:key];
            const Byte *tempByte = [tempValue bytes];
            
            //            if([tempValue length] == 8 && tempByte[0] == 0x48 && tempByte[1] == 0x4D)
            //            {
            NSString * macS = [[NSString alloc] initWithFormat:@"%@:%@:%@:%@:%@:%@",[self byteTo16String:tempByte[2]],[self byteTo16String:tempByte[3]],[self byteTo16String:tempByte[4]],[self byteTo16String:tempByte[5]],[self byteTo16String:tempByte[6]],[self byteTo16String:tempByte[7]]];
            NSLog(@"222222222%@",macS);
            return macS;
            
        }
        
    }
    return false;
}
-(NSString *) byteTo16String:(Byte)by{
    
    NSString *hexStr=@"";
    
    NSString *newHexStr = [NSString stringWithFormat:@"%x",by&0xff]; ///16进制数
    if([newHexStr length]==1)
        hexStr = [NSString stringWithFormat:@"%@0%@",hexStr,newHexStr];
    else
        hexStr = [NSString stringWithFormat:@"%@%@",hexStr,newHexStr];
    //    NSLog(@"bytes 的16进制数为:%@",hexStr);
    return hexStr;
    
}
-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    activePeripheral = peripheral;
    activePeripheral.delegate = self;
    
    [activePeripheral discoverServices:nil];
    //[self notify:peripheral on:YES];
    
    [self printPeripheralInfo:peripheral];
    
    printf("connected to the active peripheral\n");
}

-(void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    printf("disconnected to the active peripheral\n");
    if(activePeripheral != nil)
        [delegate setDisconnect];
    activePeripheral = nil;
    
}

-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"failed to connect to peripheral %@: %@\n", [peripheral name], [error localizedDescription]);
}

#pragma mark - CBPeripheral delegates

-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    printf("in updateValueForCharacteristic function\n");
    
    if (error) {
        printf("updateValueForCharacteristic failed\n");
        return;
    }
    [delegate serialGATTCharValueUpdated:@"FFE1" value:characteristic.value];
    
    
}

//////////////////////////////////////////////////////////////////////////////////////////////

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error
{
    
}

- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error
{
    
}

/*
 *  @method getAllCharacteristicsFromKeyfob
 *
 *  @param p Peripheral to scan
 *
 *
 *  @discussion getAllCharacteristicsFromKeyfob starts a characteristics discovery on a peripheral
 *  pointed to by p
 *
 */
-(void) getAllCharacteristicsFromKeyfob:(CBPeripheral *)p{
    for (int i=0; i < p.services.count; i++) {
        CBService *s = [p.services objectAtIndex:i];
        printf("Fetching characteristics for service with UUID : %s\r\n",[self CBUUIDToString:s.UUID]);
        [p discoverCharacteristics:nil forService:s];
    }
}

/*
 *  @method didDiscoverServices
 *
 *  @param peripheral Pheripheral that got updated
 *  @error error Error message if something went wrong
 *
 *  @discussion didDiscoverServices is called when CoreBluetooth has discovered services on a
 *  peripheral after the discoverServices routine has been called on the peripheral
 *
 */

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    if (!error) {
        printf("Services of peripheral with UUID : %s found\r\n",[self UUIDToString:(__bridge CFUUIDRef )peripheral.identifier]);
        [self getAllCharacteristicsFromKeyfob:peripheral];
    }
    else {
        printf("Service discovery was unsuccessfull !\r\n");
    }
}

/*
 *  @method didDiscoverCharacteristicsForService
 *
 *  @param peripheral Pheripheral that got updated
 *  @param service Service that characteristics where found on
 *  @error error Error message if something went wrong
 *
 *  @discussion didDiscoverCharacteristicsForService is called when CoreBluetooth has discovered
 *  characteristics on a service, on a peripheral after the discoverCharacteristics routine has been called on the service
 *
 */

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if (!error) {
        printf("Characteristics of service with UUID : %s found\r\n",[self CBUUIDToString:service.UUID]);
        for(int i = 0; i < service.characteristics.count; i++) { //Show every one
            CBCharacteristic *c = [service.characteristics objectAtIndex:i];
            printf("Found characteristic %s\r\n",[ self CBUUIDToString:c.UUID]);
        }
        
        char t[16];
        t[0] = (SERVICE_UUID >> 8) & 0xFF;
        t[1] = SERVICE_UUID & 0xFF;
        NSData *data = [[NSData alloc] initWithBytes:t length:16];
        CBUUID *uuid = [CBUUID UUIDWithData:data];
        //CBService *s = [peripheral.services objectAtIndex:(peripheral.services.count - 1)];
        if([self compareCBUUID:service.UUID UUID2:uuid]) {
            printf("Try to open notify\n");
            [self notify:peripheral on:YES];
        }
    }
    else {
        printf("Characteristic discorvery unsuccessfull !\r\n");
    }
}



- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (!error) {
        printf("Updated notification state for characteristic with UUID %s on service with  UUID %s on peripheral with UUID %s\r\n",[self CBUUIDToString:characteristic.UUID],[self CBUUIDToString:characteristic.service.UUID],[self UUIDToString:(__bridge CFUUIDRef )peripheral.identifier]);
        [delegate setConnect];
    }
    else {
        printf("Error in setting notification state for characteristic with UUID %s on service with  UUID %s on peripheral with UUID %s\r\n",[self CBUUIDToString:characteristic.UUID],[self CBUUIDToString:characteristic.service.UUID],[self UUIDToString:(__bridge CFUUIDRef )peripheral.identifier]);
        printf("Error code was %s\r\n",[[error description] cStringUsingEncoding:NSStringEncodingConversionAllowLossy]);
    }
}

/*
 *  @method CBUUIDToString
 *
 *  @param UUID UUID to convert to string
 *
 *  @returns Pointer to a character buffer containing UUID in string representation
 *
 *  @discussion CBUUIDToString converts the data of a CBUUID class to a character pointer for easy printout using printf()
 *
 */
-(const char *) CBUUIDToString:(CBUUID *) UUID {
    return [[UUID.data description] cStringUsingEncoding:NSStringEncodingConversionAllowLossy];
}


/*
 *  @method UUIDToString
 *
 *  @param UUID UUID to convert to string
 *
 *  @returns Pointer to a character buffer containing UUID in string representation
 *
 *  @discussion UUIDToString converts the data of a CFUUIDRef class to a character pointer for easy printout using printf()
 *
 */
-(const char *) UUIDToString:(CFUUIDRef)UUID {
    if (!UUID) return "NULL";
    CFStringRef s = CFUUIDCreateString(NULL, UUID);
    return CFStringGetCStringPtr(s, 0);
    
}

/*
 *  @method compareCBUUID
 *
 *  @param UUID1 UUID 1 to compare
 *  @param UUID2 UUID 2 to compare
 *
 *  @returns 1 (equal) 0 (not equal)
 *
 *  @discussion compareCBUUID compares two CBUUID's to each other and returns 1 if they are equal and 0 if they are not
 *
 */

-(int) compareCBUUID:(CBUUID *) UUID1 UUID2:(CBUUID *)UUID2 {
    char b1[16];
    char b2[16];
    [UUID1.data getBytes:b1];
    [UUID2.data getBytes:b2];
    if (memcmp(b1, b2, UUID1.data.length) == 0)return 1;
    else return 0;
}


/*
 *  @method findServiceFromUUID:
 *
 *  @param UUID CBUUID to find in service list
 *  @param p Peripheral to find service on
 *
 *  @return pointer to CBService if found, nil if not
 *
 *  @discussion findServiceFromUUID searches through the services list of a peripheral to find a
 *  service with a specific UUID
 *
 */
-(CBService *) findServiceFromUUIDEx:(CBUUID *)UUID p:(CBPeripheral *)p {
    for(int i = 0; i < p.services.count; i++) {
        CBService *s = [p.services objectAtIndex:i];
        if ([self compareCBUUID:s.UUID UUID2:UUID]) return s;
    }
    return nil; //Service not found on this peripheral
}

/*
 *  @method findCharacteristicFromUUID:
 *
 *  @param UUID CBUUID to find in Characteristic list of service
 *  @param service Pointer to CBService to search for charateristics on
 *
 *  @return pointer to CBCharacteristic if found, nil if not
 *
 *  @discussion findCharacteristicFromUUID searches through the characteristic list of a given service
 *  to find a characteristic with a specific UUID
 *
 */
-(CBCharacteristic *) findCharacteristicFromUUIDEx:(CBUUID *)UUID service:(CBService*)service {
    for(int i=0; i < service.characteristics.count; i++) {
        CBCharacteristic *c = [service.characteristics objectAtIndex:i];
        if ([self compareCBUUID:c.UUID UUID2:UUID]) return c;
    }
    return nil; //Characteristic not found on this service
}


/*!
 *  @method notification:
 *
 *  @param serviceUUID Service UUID to read from (e.g. 0x2400)
 *  @param characteristicUUID Characteristic UUID to read from (e.g. 0x2401)
 *  @param p CBPeripheral to read from
 *
 *  @discussion Main routine for enabling and disabling notification services. It converts integers
 *  into CBUUID's used by CoreBluetooth. It then searches through the peripherals services to find a
 *  suitable service, it then checks that there is a suitable characteristic on this service.
 *  If this is found, the notfication is set.
 *
 */
-(void) notification:(int)serviceUUID characteristicUUID:(int)characteristicUUID p:(CBPeripheral *)p on:(BOOL)on {
    UInt16 s = [self swap:serviceUUID];
    UInt16 c = [self swap:characteristicUUID];
    NSData *sd = [[NSData alloc] initWithBytes:(char *)&s length:2];
    NSData *cd = [[NSData alloc] initWithBytes:(char *)&c length:2];
    CBUUID *su = [CBUUID UUIDWithData:sd];
    CBUUID *cu = [CBUUID UUIDWithData:cd];
    CBService *service = [self findServiceFromUUIDEx:su p:p];
    if (!service) {
        printf("Could not find service with UUID %s on peripheral with UUID %s\r\n",[self CBUUIDToString:su],[self UUIDToString:(__bridge CFUUIDRef )p.identifier]);
        return;
    }
    CBCharacteristic *characteristic = [self findCharacteristicFromUUIDEx:cu service:service];
    if (!characteristic) {
        printf("Could not find characteristic with UUID %s on service with UUID %s on peripheral with UUID %s\r\n",[self CBUUIDToString:cu],[self CBUUIDToString:su],[self UUIDToString:(__bridge CFUUIDRef )p.identifier]);
        return;
    }
    [p setNotifyValue:on forCharacteristic:characteristic];
}


/*!
 *  @method writeValue:
 *
 *  @param serviceUUID Service UUID to write to (e.g. 0x2400)
 *  @param characteristicUUID Characteristic UUID to write to (e.g. 0x2401)
 *  @param data Data to write to peripheral
 *  @param p CBPeripheral to write to
 *
 *  @discussion Main routine for writeValue request, writes without feedback. It converts integer into
 *  CBUUID's used by CoreBluetooth. It then searches through the peripherals services to find a
 *  suitable service, it then checks that there is a suitable characteristic on this service.
 *  If this is found, value is written. If not nothing is done.
 *
 */

-(void) writeValue:(int)serviceUUID characteristicUUID:(int)characteristicUUID p:(CBPeripheral *)p data:(NSData *)data {
    UInt16 s = [self swap:serviceUUID];
    UInt16 c = [self swap:characteristicUUID];
    NSData *sd = [[NSData alloc] initWithBytes:(char *)&s length:2];
    NSData *cd = [[NSData alloc] initWithBytes:(char *)&c length:2];
    CBUUID *su = [CBUUID UUIDWithData:sd];
    CBUUID *cu = [CBUUID UUIDWithData:cd];
    CBService *service = [self findServiceFromUUIDEx:su p:p];
    if (!service) {
        printf("Could not find service with UUID %s on peripheral with UUID %s\r\n",[self CBUUIDToString:su],[self UUIDToString:(__bridge CFUUIDRef )p.identifier]);
        return;
    }
    CBCharacteristic *characteristic = [self findCharacteristicFromUUIDEx:cu service:service];
    if (!characteristic) {
        printf("Could not find characteristic with UUID %s on service with UUID %s on peripheral with UUID %s\r\n",[self CBUUIDToString:cu],[self CBUUIDToString:su],[self UUIDToString:(__bridge CFUUIDRef )p.identifier]);
        return;
    }
    
    if(characteristic.properties & CBCharacteristicPropertyWriteWithoutResponse)
    {
        [p writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
    }else
    {
        [p writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
    }
}


/*!
 *  @method readValue:
 *
 *  @param serviceUUID Service UUID to read from (e.g. 0x2400)
 *  @param characteristicUUID Characteristic UUID to read from (e.g. 0x2401)
 *  @param p CBPeripheral to read from
 *
 *  @discussion Main routine for read value request. It converts integers into
 *  CBUUID's used by CoreBluetooth. It then searches through the peripherals services to find a
 *  suitable service, it then checks that there is a suitable characteristic on this service.
 *  If this is found, the read value is started. When value is read the didUpdateValueForCharacteristic
 *  routine is called.
 *
 *  @see didUpdateValueForCharacteristic
 */

-(void) readValue: (int)serviceUUID characteristicUUID:(int)characteristicUUID p:(CBPeripheral *)p {
    printf("In read Value");
    UInt16 s = [self swap:serviceUUID];
    UInt16 c = [self swap:characteristicUUID];
    NSData *sd = [[NSData alloc] initWithBytes:(char *)&s length:2];
    NSData *cd = [[NSData alloc] initWithBytes:(char *)&c length:2];
    CBUUID *su = [CBUUID UUIDWithData:sd];
    CBUUID *cu = [CBUUID UUIDWithData:cd];
    CBService *service = [self findServiceFromUUIDEx:su p:p];
    if (!service) {
        printf("Could not find service with UUID %s on peripheral with UUID %s\r\n",[self CBUUIDToString:su],[self UUIDToString:(__bridge CFUUIDRef )p.identifier]);
        return;
    }
    CBCharacteristic *characteristic = [self findCharacteristicFromUUIDEx:cu service:service];
    if (!characteristic) {
        printf("Could not find characteristic with UUID %s on service with UUID %s on peripheral with UUID %s\r\n",[self CBUUIDToString:cu],[self CBUUIDToString:su],[self UUIDToString:(__bridge CFUUIDRef )p.identifier]);
        return;
    }
    [p readValueForCharacteristic:characteristic];
}
-(BOOL) firstRelayOn: (NSString *)password{
    if (password.length==8) {
        NSMutableArray * mta = [[NSMutableArray alloc] initWithCapacity:8];
        int a = 10;
        for (int i = 0 ; i<password.length; i++) {
            NSString *s = [password substringWithRange:NSMakeRange(i, 1)];
            [mta addObject:s];
        }
        
        for (int i = 0 ; i<mta.count; i++) {
            a =[[mta objectAtIndex:i] intValue];
            if (a==10) {
                return NO;
            }
            switch (a) {
                case 0:
                    [mta replaceObjectAtIndex:i withObject:@"30"];
                    break;
                case 1:
                    [mta replaceObjectAtIndex:i withObject:@"31"];
                    break;
                case 2:
                    [mta replaceObjectAtIndex:i withObject:@"32"];
                    break;
                case 3:
                    [mta replaceObjectAtIndex:i withObject:@"33"];
                    break;
                case 4:
                    [mta replaceObjectAtIndex:i withObject:@"34"];
                    break;
                case 5:
                    [mta replaceObjectAtIndex:i withObject:@"35"];
                    break;
                case 6:
                    [mta replaceObjectAtIndex:i withObject:@"36"];
                    break;
                case 7:
                    [mta replaceObjectAtIndex:i withObject:@"37"];
                    break;
                case 8:
                    [mta replaceObjectAtIndex:i withObject:@"38"];
                    break;
                case 9:
                    [mta replaceObjectAtIndex:i withObject:@"39"];
                    break;
                default:
                    break;
            }
        }
        Byte bytes[11] ;
        bytes[0] =[self getA16Hex:@"c5"];
        bytes[1] =[self getA16Hex:@"04"];
        
        bytes[2] =[self getA16Hex:[mta objectAtIndex:0]];
        bytes[3] =[self getA16Hex:[mta objectAtIndex:1]];
        bytes[4] =[self getA16Hex:[mta objectAtIndex:2]];
        bytes[5] =[self getA16Hex:[mta objectAtIndex:3]];
        bytes[6] =[self getA16Hex:[mta objectAtIndex:4]];
        bytes[7] =[self getA16Hex:[mta objectAtIndex:5]];
        bytes[8] =[self getA16Hex:[mta objectAtIndex:6]];
        bytes[9] =[self getA16Hex:[mta objectAtIndex:7]];
        
        bytes[10] =[self getA16Hex:@"aa"];
        NSData *newData = [[NSData alloc] initWithBytes:bytes length:11];
        [self write:activePeripheral data:newData];
        
        return YES;
    }
    else{
        return NO;
    }
    
}
-(BOOL) secondRelayOn: (NSString *)password{
    
    if (password.length==8) {
        NSMutableArray * mta = [[NSMutableArray alloc] initWithCapacity:8];
        int a = 10;
        for (int i = 0 ; i<password.length; i++) {
            NSString *s = [password substringWithRange:NSMakeRange(i, 1)];
            [mta addObject:s];
        }
        
        for (int i = 0 ; i<mta.count; i++) {
            a =[[mta objectAtIndex:i] intValue];
            if (a==10) {
                return NO;
            }
            switch (a) {
                case 0:
                    [mta replaceObjectAtIndex:i withObject:@"30"];
                    break;
                case 1:
                    [mta replaceObjectAtIndex:i withObject:@"31"];
                    break;
                case 2:
                    [mta replaceObjectAtIndex:i withObject:@"32"];
                    break;
                case 3:
                    [mta replaceObjectAtIndex:i withObject:@"33"];
                    break;
                case 4:
                    [mta replaceObjectAtIndex:i withObject:@"34"];
                    break;
                case 5:
                    [mta replaceObjectAtIndex:i withObject:@"35"];
                    break;
                case 6:
                    [mta replaceObjectAtIndex:i withObject:@"36"];
                    break;
                case 7:
                    [mta replaceObjectAtIndex:i withObject:@"37"];
                    break;
                case 8:
                    [mta replaceObjectAtIndex:i withObject:@"38"];
                    break;
                case 9:
                    [mta replaceObjectAtIndex:i withObject:@"39"];
                    break;
                default:
                    break;
            }
        }
        Byte bytes[11] ;
        bytes[0] =[self getA16Hex:@"c5"];
        bytes[1] =[self getA16Hex:@"05"];
        
        bytes[2] =[self getA16Hex:[mta objectAtIndex:0]];
        bytes[3] =[self getA16Hex:[mta objectAtIndex:1]];
        bytes[4] =[self getA16Hex:[mta objectAtIndex:2]];
        bytes[5] =[self getA16Hex:[mta objectAtIndex:3]];
        bytes[6] =[self getA16Hex:[mta objectAtIndex:4]];
        bytes[7] =[self getA16Hex:[mta objectAtIndex:5]];
        bytes[8] =[self getA16Hex:[mta objectAtIndex:6]];
        bytes[9] =[self getA16Hex:[mta objectAtIndex:7]];
        
        bytes[10] =[self getA16Hex:@"aa"];
        NSData *newData = [[NSData alloc] initWithBytes:bytes length:11];
        [self write:activePeripheral data:newData];
        
        return YES;
    }
    else{
        return NO;
    }
}

-(BOOL) firstRelayOff: (NSString *)password{
    
    if (password.length==8) {
        NSMutableArray * mta = [[NSMutableArray alloc] initWithCapacity:8];
        int a = 10;
        for (int i = 0 ; i<password.length; i++) {
            NSString *s = [password substringWithRange:NSMakeRange(i, 1)];
            [mta addObject:s];
        }
        
        for (int i = 0 ; i<mta.count; i++) {
            a =[[mta objectAtIndex:i] intValue];
            if (a == 10) {
                return NO;
            }
            switch (a) {
                case 0:
                    [mta replaceObjectAtIndex:i withObject:@"30"];
                    break;
                case 1:
                    [mta replaceObjectAtIndex:i withObject:@"31"];
                    break;
                case 2:
                    [mta replaceObjectAtIndex:i withObject:@"32"];
                    break;
                case 3:
                    [mta replaceObjectAtIndex:i withObject:@"33"];
                    break;
                case 4:
                    [mta replaceObjectAtIndex:i withObject:@"34"];
                    break;
                case 5:
                    [mta replaceObjectAtIndex:i withObject:@"35"];
                    break;
                case 6:
                    [mta replaceObjectAtIndex:i withObject:@"36"];
                    break;
                case 7:
                    [mta replaceObjectAtIndex:i withObject:@"37"];
                    break;
                case 8:
                    [mta replaceObjectAtIndex:i withObject:@"38"];
                    break;
                case 9:
                    [mta replaceObjectAtIndex:i withObject:@"39"];
                    break;
                default:
                    break;
            }
        }
        Byte bytes[11] ;
        bytes[0] =[self getA16Hex:@"c5"];
        bytes[1] =[self getA16Hex:@"06"];
        
        bytes[2] =[self getA16Hex:[mta objectAtIndex:0]];
        bytes[3] =[self getA16Hex:[mta objectAtIndex:1]];
        bytes[4] =[self getA16Hex:[mta objectAtIndex:2]];
        bytes[5] =[self getA16Hex:[mta objectAtIndex:3]];
        bytes[6] =[self getA16Hex:[mta objectAtIndex:4]];
        bytes[7] =[self getA16Hex:[mta objectAtIndex:5]];
        bytes[8] =[self getA16Hex:[mta objectAtIndex:6]];
        bytes[9] =[self getA16Hex:[mta objectAtIndex:7]];
        
        bytes[10] =[self getA16Hex:@"aa"];
        NSData *newData = [[NSData alloc] initWithBytes:bytes length:11];
        [self write:activePeripheral data:newData];
        
        return YES;
    }
    else{
        return NO;
    }
    
}
-(BOOL) secondRelayOff: (NSString *)password{
    
    if (password.length==8) {
        NSMutableArray * mta = [[NSMutableArray alloc] initWithCapacity:8];
        int a = 10;
        for (int i = 0 ; i<password.length; i++) {
            NSString *s = [password substringWithRange:NSMakeRange(i, 1)];
            [mta addObject:s];
        }
        
        for (int i = 0 ; i<mta.count; i++) {
            a =[[mta objectAtIndex:i] intValue];
            if (a==10) {
                return NO;
            }
            switch (a) {
                case 0:
                    [mta replaceObjectAtIndex:i withObject:@"30"];
                    break;
                case 1:
                    [mta replaceObjectAtIndex:i withObject:@"31"];
                    break;
                case 2:
                    [mta replaceObjectAtIndex:i withObject:@"32"];
                    break;
                case 3:
                    [mta replaceObjectAtIndex:i withObject:@"33"];
                    break;
                case 4:
                    [mta replaceObjectAtIndex:i withObject:@"34"];
                    break;
                case 5:
                    [mta replaceObjectAtIndex:i withObject:@"35"];
                    break;
                case 6:
                    [mta replaceObjectAtIndex:i withObject:@"36"];
                    break;
                case 7:
                    [mta replaceObjectAtIndex:i withObject:@"37"];
                    break;
                case 8:
                    [mta replaceObjectAtIndex:i withObject:@"38"];
                    break;
                case 9:
                    [mta replaceObjectAtIndex:i withObject:@"39"];
                    break;
                default:
                    break;
            }
        }
        Byte bytes[11] ;
        bytes[0] =[self getA16Hex:@"c5"];
        bytes[1] =[self getA16Hex:@"07"];
        
        bytes[2] =[self getA16Hex:[mta objectAtIndex:0]];
        bytes[3] =[self getA16Hex:[mta objectAtIndex:1]];
        bytes[4] =[self getA16Hex:[mta objectAtIndex:2]];
        bytes[5] =[self getA16Hex:[mta objectAtIndex:3]];
        bytes[6] =[self getA16Hex:[mta objectAtIndex:4]];
        bytes[7] =[self getA16Hex:[mta objectAtIndex:5]];
        bytes[8] =[self getA16Hex:[mta objectAtIndex:6]];
        bytes[9] =[self getA16Hex:[mta objectAtIndex:7]];
        
        bytes[10] =[self getA16Hex:@"aa"];
        NSData *newData = [[NSData alloc] initWithBytes:bytes length:11];
        [self write:activePeripheral data:newData];
        
        return YES;
    }
    else{
        return NO;
    }
    
}

-(BOOL) changePassword: (NSString *)oldPassword newPassword :(NSString *) newPassword{
    
    if (oldPassword.length==8&&newPassword.length==8) {
        NSMutableArray * mta = [[NSMutableArray alloc] initWithCapacity:8];
        int a = 10;
        for (int i = 0 ; i<oldPassword.length; i++) {
            NSString *s = [oldPassword substringWithRange:NSMakeRange(i, 1)];
            [mta addObject:s];
        }
        for (int i = 0 ; i<newPassword.length; i++) {
            NSString *s = [newPassword substringWithRange:NSMakeRange(i, 1)];
            [mta addObject:s];
        }
        for (int i = 0 ; i<mta.count; i++) {
            a =[[mta objectAtIndex:i] intValue];
            if (a==10) {
                return NO;
            }
            switch (a) {
                case 0:
                    [mta replaceObjectAtIndex:i withObject:@"30"];
                    break;
                case 1:
                    [mta replaceObjectAtIndex:i withObject:@"31"];
                    break;
                case 2:
                    [mta replaceObjectAtIndex:i withObject:@"32"];
                    break;
                case 3:
                    [mta replaceObjectAtIndex:i withObject:@"33"];
                    break;
                case 4:
                    [mta replaceObjectAtIndex:i withObject:@"34"];
                    break;
                case 5:
                    [mta replaceObjectAtIndex:i withObject:@"35"];
                    break;
                case 6:
                    [mta replaceObjectAtIndex:i withObject:@"36"];
                    break;
                case 7:
                    [mta replaceObjectAtIndex:i withObject:@"37"];
                    break;
                case 8:
                    [mta replaceObjectAtIndex:i withObject:@"38"];
                    break;
                case 9:
                    [mta replaceObjectAtIndex:i withObject:@"39"];
                    break;
                default:
                    break;
            }
        }
        Byte bytes[18] ;
        bytes[0] =[self getA16Hex:@"c5"];
        
        bytes[1] =[self getA16Hex:[mta objectAtIndex:0]];
        bytes[2] =[self getA16Hex:[mta objectAtIndex:1]];
        bytes[3] =[self getA16Hex:[mta objectAtIndex:2]];
        bytes[4] =[self getA16Hex:[mta objectAtIndex:3]];
        bytes[5] =[self getA16Hex:[mta objectAtIndex:4]];
        bytes[6] =[self getA16Hex:[mta objectAtIndex:5]];
        bytes[7] =[self getA16Hex:[mta objectAtIndex:6]];
        bytes[8] =[self getA16Hex:[mta objectAtIndex:7]];
        
        bytes[9] =[self getA16Hex:[mta objectAtIndex:8]];
        bytes[10] =[self getA16Hex:[mta objectAtIndex:9]];
        bytes[11] =[self getA16Hex:[mta objectAtIndex:10]];
        bytes[12] =[self getA16Hex:[mta objectAtIndex:11]];
        bytes[13] =[self getA16Hex:[mta objectAtIndex:12]];
        bytes[14] =[self getA16Hex:[mta objectAtIndex:13]];
        bytes[15] =[self getA16Hex:[mta objectAtIndex:14]];
        bytes[16] =[self getA16Hex:[mta objectAtIndex:15]];
        
        bytes[17] =[self getA16Hex:@"aa"];
        NSData *newData = [[NSData alloc] initWithBytes:bytes length:18];
        [self write:activePeripheral data:newData];
        
        return YES;
    }
    else{
        return NO;
    }
    
}
- (int) getA16Hex:(NSString *) hexString{
    for(int i=0;i<[hexString length];i++)
    {
        int int_ch; /// 两位16进制数转化后的10进制数
        
        unichar hex_char1 = [hexString characterAtIndex:i]; ////两位16进制数中的第一位(高位*16)
        int int_ch1;
        if(hex_char1 >= '0' && hex_char1 <='9')
            int_ch1 = (hex_char1-48)*16; //// 0 的Ascll - 48
        else if(hex_char1 >= 'A' && hex_char1 <='F')
            int_ch1 = (hex_char1-55)*16; //// A 的Ascll - 65
        else
            int_ch1 = (hex_char1-87)*16; //// a 的Ascll - 97
        i++;
        
        unichar hex_char2 = [hexString characterAtIndex:i]; ///两位16进制数中的第二位(低位)
        int int_ch2;
        if(hex_char2 >= '0' && hex_char2 <='9')
            int_ch2 = (hex_char2-48); //// 0 的Ascll - 48
        else if(hex_char1 >= 'A' && hex_char1 <='F')
            int_ch2 = hex_char2-55; //// A 的Ascll - 65
        else
            int_ch2 = hex_char2-87; //// a 的Ascll - 97
        
        int_ch = int_ch1+int_ch2;
        NSLog(@"int_ch=%d",int_ch);
        return int_ch;
    }
    return 0;
}
@end