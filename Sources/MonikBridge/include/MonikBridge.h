//
//  MonikBridge.h
//  Monik
//

#pragma once

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <CoreGraphics/CoreGraphics.h>
#import <IOKit/IOKitLib.h>
#import <IOKit/i2c/IOI2CInterface.h>

// CoreDisplay APIs
extern CFDictionaryRef CoreDisplay_DisplayCreateInfoDictionary(CGDirectDisplayID displayID);
extern void CoreDisplay_Display_SetUserBrightness(CGDirectDisplayID displayID, double brightness);
extern double CoreDisplay_Display_GetUserBrightness(CGDirectDisplayID displayID);

// IOAVService APIs (Apple Silicon DDC over I2C)
typedef CFTypeRef IOAVService;
extern IOAVService IOAVServiceCreate(CFAllocatorRef allocator);
extern IOAVService IOAVServiceCreateWithService(CFAllocatorRef allocator, io_service_t service);
extern IOReturn IOAVServiceReadI2C(IOAVService service, uint32_t chipAddress, uint32_t offset, void* outputBuffer, uint32_t outputBufferSize);
extern IOReturn IOAVServiceWriteI2C(IOAVService service, uint32_t chipAddress, uint32_t dataAddress, void* inputBuffer, uint32_t inputBufferSize);

// SkyLight display mode struct and APIs
typedef struct {
    uint32_t modeNumber;
    uint32_t flags;
    uint32_t width;
    uint32_t height;
    uint32_t depth;
    uint8_t unknown[170];
    uint16_t freq;
    uint8_t more_unknown[16];
    float density;
} CGSDisplayMode;

extern void CGSGetCurrentDisplayMode(CGDirectDisplayID display, int* modeNum);
extern void CGSConfigureDisplayMode(CGDisplayConfigRef config, CGDirectDisplayID display, int modeNum);
extern void CGSGetNumberOfDisplayModes(CGDirectDisplayID display, int* nModes);
extern void CGSGetDisplayModeDescriptionOfLength(CGDirectDisplayID display, int idx, CGSDisplayMode* mode, int length);
extern CGError SLSSetDisplayRotation(CGDirectDisplayID display, int rotation);

// CGVirtualDisplay APIs (Virtual screen creation)
@interface CGVirtualDisplay : NSObject
@property(readonly, nonatomic) NSArray *modes;
@property(readonly, nonatomic) unsigned int hiDPI;
@property(readonly, nonatomic) unsigned int displayID;
@property(readonly, nonatomic) id terminationHandler;
@property(readonly, nonatomic) id queue;
@property(readonly, nonatomic) struct CGPoint whitePoint;
@property(readonly, nonatomic) struct CGPoint bluePrimary;
@property(readonly, nonatomic) struct CGPoint greenPrimary;
@property(readonly, nonatomic) struct CGPoint redPrimary;
@property(readonly, nonatomic) unsigned int maxPixelsHigh;
@property(readonly, nonatomic) unsigned int maxPixelsWide;
@property(readonly, nonatomic) struct CGSize sizeInMillimeters;
@property(readonly, nonatomic) NSString *name;
@property(readonly, nonatomic) unsigned int serialNum;
@property(readonly, nonatomic) unsigned int productID;
@property(readonly, nonatomic) unsigned int vendorID;

- (BOOL)applySettings:(id)arg1;
- (void)dealloc;
- (id)initWithDescriptor:(id)arg1;
@end

@interface CGVirtualDisplayDescriptor : NSObject
@property(retain, nonatomic) id queue;
@property(retain, nonatomic) NSString *name;
@property(nonatomic) struct CGPoint whitePoint;
@property(nonatomic) struct CGPoint bluePrimary;
@property(nonatomic) struct CGPoint greenPrimary;
@property(nonatomic) struct CGPoint redPrimary;
@property(nonatomic) unsigned int maxPixelsHigh;
@property(nonatomic) unsigned int maxPixelsWide;
@property(nonatomic) struct CGSize sizeInMillimeters;
@property(nonatomic) unsigned int serialNum;
@property(nonatomic) unsigned int productID;
@property(nonatomic) unsigned int vendorID;
@property(copy, nonatomic) id terminationHandler;

- (void)dealloc;
- (id)init;
- (id)dispatchQueue;
- (void)setDispatchQueue:(id)arg1;
@end

@interface CGVirtualDisplayMode : NSObject
@property(readonly, nonatomic) double refreshRate;
@property(readonly, nonatomic) unsigned int height;
@property(readonly, nonatomic) unsigned int width;
- (id)initWithWidth:(unsigned int)arg1 height:(unsigned int)arg2 refreshRate:(double)arg3;
@end

@interface CGVirtualDisplaySettings : NSObject
@property(nonatomic) unsigned int hiDPI;
@property(retain, nonatomic) NSArray *modes;
- (void)dealloc;
- (id)init;
@end
