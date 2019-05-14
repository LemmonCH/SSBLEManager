//
//  SSBLECenterManager.m
//  SSBLEManager
//
//  Created by 信臣健康 on 2019/4/26.
//  Copyright © 2019 信臣健康. All rights reserved.
//

#import "SSBLECenterManager.h"

@interface SSBLECenterManager ()
//扫描到的设备数组
@property (nonatomic, strong) NSMutableArray    *peripherals;
//是否正在连接
@property (nonatomic, assign) BOOL              connecting;
//是否已经连接
@property (nonatomic, assign) BOOL              connected;

@end

@implementation SSBLECenterManager

+ (instancetype)sharedInstance
{
    static SSBLECenterManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [SSBLECenterManager new];
    });
    return manager;
}

- (instancetype)init{
    if (self = [super init]) {
        self.peripherals = [NSMutableArray arrayWithCapacity:0];
        
        self.scanTime = 5.;
        
        self.connecting = NO;
        self.connected  = NO;
        self.isUpdateing = NO;
        
        //初始化中心端,开始蓝牙模块
        self.centralManager = [[CBCentralManager alloc] initWithDelegate:self
                                                                   queue:nil
                                                                 options:@{CBCentralManagerOptionShowPowerAlertKey: @NO}];
        
        [self.centralManager addObserver:self
                              forKeyPath:@"isScanning"
                                 options:NSKeyValueObservingOptionNew
                                 context:nil];
    }
    return self;
}

- (BOOL)scaning {
    return self.centralManager.isScanning;
}

- (NSString *)deviceName {
    return self.connected?self.peripheral.name:nil;
}

//扫描状态发生变化
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"isScanning"]) {
        NSNumber *value = change[NSKeyValueChangeNewKey];
        BOOL scaning = [value boolValue];
        NSLog(@"BLE scaning: %@", scaning?@"ON":@"OFF");
        if (_delegate && [_delegate respondsToSelector:@selector(bleManager:scaningDidChange:)]) {
            [self.delegate bleManager:self scaningDidChange:scaning];
        }
    }
}

//连接指定设备
- (void)startConnetPeripheral:(CBPeripheral *)peripheral{
    self.peripheral = peripheral;
    self.connecting = YES;
    [self.centralManager connectPeripheral:peripheral options:nil];

    if ([self.delegate respondsToSelector:@selector(bleManager:startToConnectToDevice:)]) {
        [self.delegate bleManager:self startToConnectToDevice:peripheral.name];
    }
}


//断开连接
- (void)disconnectPeripheral:(CBPeripheral *)peripheral
{
    self.connecting = NO;
    self.connected  = NO;
    [self.centralManager cancelPeripheralConnection:peripheral];
    
    if (_delegate && [_delegate respondsToSelector:@selector(bleManager:deviceDidDisconnected:)]) {
        [_delegate bleManager:self deviceDidDisconnected:self.peripheral.name];
    }
}

//开始扫描
- (void)startScan{
    if (self.connected || self.centralManager.state != CBManagerStatePoweredOn) {
        // 已经连接 或者蓝牙关闭状态
        return;
    }
    
    [self.peripherals removeAllObjects];
    
    [self.centralManager scanForPeripheralsWithServices:nil
                                                options:nil];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.scanTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self stopScan];
    });
}

//结束扫描
- (void)stopScan{
    [self.centralManager stopScan];
    
    if (_delegate && [_delegate respondsToSelector:@selector(bleManager:endScanPeripherals:)]) {
        [_delegate bleManager:self endScanPeripherals:self.peripherals];
    }
}

#pragma mark - VCMethod
//读数据
- (void)readFromPeripheral
{
    NSLog(@"读数据");
    [self.peripheral readValueForCharacteristic:self.characteristic];
}

//写数据
- (void)writeToPeripheralWith:(NSData *)data
{
    [self.peripheral writeValue:data forCharacteristic:self.characteristic type:CBCharacteristicWriteWithResponse];
}

//监听数据
- (void)notifyPeripheral
{
    NSLog(@"监听数据");
    [self.peripheral setNotifyValue:YES forCharacteristic:self.characteristic];
}

#pragma mark - CBCentralManagerDelegate
// 状态更新后触发
-(void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch (central.state) {
        case CBManagerStatePoweredOff:
        {
            self.connected  = NO;
            if (_delegate && [_delegate respondsToSelector:@selector(bleManager:BLEOff:)]) {
                [_delegate bleManager:self BLEOff:YES];
            }
            
            if (_delegate && [_delegate respondsToSelector:@selector(bleManager:stateDidChange:)]) {
                [_delegate bleManager:self stateDidChange:NO];
            }
        }
            break;
        case CBManagerStatePoweredOn:{
            if (_delegate && [_delegate respondsToSelector:@selector(bleManager:stateDidChange:)]) {
                [_delegate bleManager:self stateDidChange:YES];
            }
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.scanTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self stopScan];
            });
        }
            break;
        case CBManagerStateResetting:
            break;
        case CBManagerStateUnauthorized:
            break;
        case CBManagerStateUnknown:
            break;
        case CBManagerStateUnsupported:
            break;
        default:
            break;
    }

}

// 扫描到外部设备后触发的代理方法//多次调用的
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(nonnull CBPeripheral *)peripheral advertisementData:(nonnull NSDictionary<NSString *,id> *)advertisementData RSSI:(nonnull NSNumber *)RSSI
{
    NSString *name = [advertisementData objectForKey:CBAdvertisementDataLocalNameKey];
    
    if (name.length) {
        NSLog(@"%@",name);
        if (name && [name containsString:@"BLUEFETA"]) {
            NSDictionary *dict = @{
                                   @"name":name,
                                   @"db":RSSI,
                                   @"peripheral":peripheral
                                   };
            
            [self.peripherals addObject:dict];
        }
    }
    
//    if ([name isEqualToString:self.peripheral_prefix])
//    {
//        //连接外部设备
//        self.peripheral = peripheral;
//        self.connecting = YES;
//        [self.centralManager connectPeripheral:peripheral options:nil];
//
//        if ([self.delegate respondsToSelector:@selector(bleManager:startToConnectToDevice:)]) {
//            [self.delegate bleManager:self startToConnectToDevice:name];
//        }
//    }
}

//连接失败
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"连接失败");
    NSLog(@"%@",error.localizedDescription);
    self.connecting = NO;
    [self startScan];
    if (_delegate && [_delegate respondsToSelector:@selector(bleManager:didFailedConnectingToDevice:)]) {
        [_delegate bleManager:self didFailedConnectingToDevice:peripheral.name];
    }
}

// 当中心端连接上外设时触发
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"连接上外设");
    //停止搜索
    [self.centralManager stopScan];
    
    self.connecting = NO;
    self.peripheral.delegate = self;
    [peripheral discoverServices:nil];
    
    if (_delegate && [_delegate respondsToSelector:@selector(bleManager:didConnectedToDevice:)]) {
        [_delegate bleManager:self didConnectedToDevice:peripheral.name];
    }
}


//如果连接上的两个设备突然断开了，程序里面会自动回调下面的方法
-   (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"设备断开重连");
    self.connected  = NO;
    
    [self.centralManager connectPeripheral:self.peripheral options:nil];
    self.connecting = YES;

    //当断开时做缺省数据处理
    if (_delegate && [_delegate respondsToSelector:@selector(bleManager:deviceDidDisconnected:)]) {
        [_delegate bleManager:self deviceDidDisconnected:self.peripheral.name];
    }
}


#pragma mark - CBPeripheralDelegate
// 外设端发现了服务时触发
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    NSLog(@"已经发现服务");
    
    NSArray *services = nil;
    
    if (peripheral != self.peripheral) {
        NSLog(@"Wrong Peripheral.\n");
        return ;
    }
    if (error != nil) {
        NSLog(@"Error %@\n", error);
        return ;
    }
    services = [peripheral services];
    if (!services || ![services count]) {
        NSLog(@"No Services");
        return ;
    }
    for (CBService *service in services) {
        NSLog(@"service:%@",service);
        //根据你要的那个服务去发现特性
        [peripheral discoverCharacteristics:nil forService:service];
    }
}


//从服务获取特征
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    NSLog(@"已经发现服务特性service:%@",service);
    NSLog(@"characteristics:%@",[service characteristics]);
    NSArray *characteristics = [service characteristics];
    for(CBCharacteristic *characteristic in service.characteristics) {
        if([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2A23"]])
        {
            // 这里是读取Mac地址， 可不要， 数据固定， 用readValueForCharacteristic， 不用setNotifyValue:setNotifyValue
            [self.peripheral readValueForCharacteristic:characteristic];
        }
    }
    
    if (peripheral != self.peripheral) {
        NSLog(@"Wrong Peripheral.\n");
        return ;
    }
    
    if (error != nil) {
        NSLog(@"Error %@\n", error);
        return ;
    }
    if ([service.UUID.UUIDString isEqualToString:@"FFE5"]) {    //写服务
        self.characteristic = [characteristics firstObject];
    }
    if ([service.UUID.UUIDString isEqualToString:@"FFE0"]) {    //通知服务
        [self.peripheral setNotifyValue:YES forCharacteristic:[characteristics firstObject]];
    }
    if ([service.UUID.UUIDString isEqualToString:@"FFE9"]) {    //特征
        [self.peripheral setNotifyValue:YES forCharacteristic:[characteristics firstObject]];
    }
}


//收到数据
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"%@",characteristic.UUID);
    //控制器去处理
    if (self.delegate && [self.delegate respondsToSelector:@selector(bleManager:receivedValue:)])
    {
        [self.delegate bleManager:self receivedValue:characteristic.value.copy];
    }
}


//写特征值
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (!error) {
        //        dLog(@"Write Success");
    } else {
        NSLog(@"WriteVale Error = %@", error);
    }
}

//已经为特征更新通知状态
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if (error) {
        NSLog(@"订阅失败%@",error);
    }else{
        NSLog(@"订阅成功");
        self.connected = YES;
    
        if (_delegate && [_delegate respondsToSelector:@selector(bleManager:subscibeSucess:)]) {
            [self.delegate bleManager:self subscibeSucess:nil];
        }
    }
}


@end
