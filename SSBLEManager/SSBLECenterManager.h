//
//  SSBLECenterManager.h
//  SSBLEManager
//
//  Created by 信臣健康 on 2019/4/26.
//  Copyright © 2019 信臣健康. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

NS_ASSUME_NONNULL_BEGIN

@class SSBLECenterManager;
@protocol SSBLECenterManagerDelegate <NSObject>
@required

// 扫描完成,返回所有扫描到的设备
- (void)bleManager:(SSBLECenterManager *)manager endScanPeripherals:(NSArray*)peripherals;

// 蓝牙硬件开启/关闭
- (void)bleManager:(SSBLECenterManager *)manager stateDidChange:(BOOL)state;

// 扫描状态改变通知
- (void)bleManager:(SSBLECenterManager *)manager scaningDidChange:(BOOL)scaning;

// 设备连接成功
- (void)bleManager:(SSBLECenterManager *)manager didConnectedToDevice:(NSString *)name;

// 蓝牙设备断开连接
- (void)bleManager:(SSBLECenterManager *)manager deviceDidDisconnected:(NSString *)name;

// 收到的数据
- (void)bleManager:(SSBLECenterManager *)manager receivedValue:(NSData *)data;

@optional

// 开始连接设备
- (void)bleManager:(SSBLECenterManager *)manager startToConnectToDevice:(NSString *)name;

// 设备连接失败
- (void)bleManager:(SSBLECenterManager *)manager didFailedConnectingToDevice:(NSString *)name;

// 手机蓝牙未开启/被关闭  控制器处理弹窗
- (void)bleManager:(SSBLECenterManager *)manager BLEOff:(BOOL)state;
@end

@interface SSBLECenterManager : NSObject<CBCentralManagerDelegate, CBPeripheralDelegate>
//代理
@property (nonatomic, weak) id<SSBLECenterManagerDelegate> delegate;
//中心
@property (nonatomic, strong) CBCentralManager *centralManager;
//外设
@property (nonatomic, strong) CBPeripheral *peripheral;
//特征
@property (nonatomic, strong) CBCharacteristic *characteristic;

// 扫描中
@property (nonatomic, readonly) BOOL                scaning;
// 连接中
@property (nonatomic, readonly) BOOL                connecting;
// 连接状态
@property (nonatomic, readonly) BOOL                connected;
// BLE 设备名称
@property (nonatomic, readonly) NSString            *deviceName;

/* 以下为可选配置参数 */
//扫描时长
@property (nonatomic, assign)   NSInteger           scanTime;                   //默认10s
//是否扫描到设备后自动连接
@property (nonatomic, assign)   BOOL                autoConnect;                //默认为NO
//连接失败后是否自动重连
@property (nonatomic, assign)   BOOL                autoConnect_Failed;         //默认为NO
//设备异常断开后,自动重连
@property (nonatomic, assign)   BOOL                autoConnect_error;          //默认YES
//外设名称前缀
@property (nonatomic, copy)     NSString            *peripheral_prefix;         //例如:BLUEFETA_
//服务UUID名称
@property (nonatomic, copy)     NSString            *UUID_Name;                 //不填即没有
//读特征名称
@property (nonatomic, copy)     NSString            *read_characteristic;       //不填即没有
//写特征名称
@property (nonatomic, copy)     NSString            *write_characteristic;      //不填即没有
//订阅特征名称
@property (nonatomic, copy)     NSString            *subscibe_characteristic;   //不填即没有

//初始化
+ (instancetype)sharedInstance;
//连接指定设备
- (void)startConnetPeripheral:(CBPeripheral *)peripheral;
//断开连接
- (void)endConnect;
//读数据
- (void)readFromPeripheral;
//写数据
- (void)writeToPeripheralWith:(NSString *)name;
//监听数据
- (void)notifyPeripheral;


@end

NS_ASSUME_NONNULL_END
