//
// Copyright 2011 Jeff Verkoeyen
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "NIDeviceInfo.h"

#ifdef DEBUG

#import <mach/mach.h>
#import <mach/mach_host.h>

static BOOL                 sIsCaching = NO;
static BOOL                 sLastUpdateResult = NO;
static vm_size_t            sPageSize = 0;
static vm_statistics_data_t sVMStats;
static NSDictionary*        sFileSystem = nil;


///////////////////////////////////////////////////////////////////////////////////////////////////
NSString* NIStringFromBytes(unsigned long long bytes) {
  static const void* sOrdersOfMagnitude[] = {
    @"bytes", @"KBs", @"MBs", @"GBs"
  };

  // Determine what magnitude the number of bytes is by shifting off 10 bits at a time
  // (equivalent to dividing by 1024).
  NSInteger magnitude = 0;
  unsigned long long highbits = bytes;
  unsigned long long inverseBits = ~((unsigned long long)0x3FF);
  while ((highbits & inverseBits)
         && magnitude + 1 < (sizeof(sOrdersOfMagnitude) / sizeof(void *))) {
    // Shift off an order of magnitude.
    highbits >>= 10;
    magnitude++;
  }

  if (magnitude > 0) {
    unsigned long long dividend = 1024 << (magnitude - 1) * 10;
    double result = ((double)bytes / (double)(dividend));
    return [NSString stringWithFormat:@"%.2f %@",
            result,
            sOrdersOfMagnitude[magnitude]];

  } else {
    // We don't need to bother with dividing bytes.
    return [NSString stringWithFormat:@"%lld %@", bytes, sOrdersOfMagnitude[magnitude]];
  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation NIDeviceInfo


///////////////////////////////////////////////////////////////////////////////////////////////////
+ (void)initialize {
  [[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];
  memset(&sVMStats, 0, sizeof(sVMStats));
}


///////////////////////////////////////////////////////////////////////////////////////////////////
+ (BOOL)updateHostStatistics {
  mach_port_t host_port = mach_host_self();
  mach_msg_type_number_t host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
  host_page_size(host_port, &sPageSize);
  return (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&sVMStats, &host_size)
          == KERN_SUCCESS);
}


///////////////////////////////////////////////////////////////////////////////////////////////////
+ (BOOL)updateFileSystemAttributes {
  NI_RELEASE_SAFELY(sFileSystem);

	NSError* error = nil;
	NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	sFileSystem =
  [[[NSFileManager defaultManager] attributesOfFileSystemForPath: [paths lastObject]
                                                           error: &error] retain];
  return (nil == error);
}


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Public Methods


///////////////////////////////////////////////////////////////////////////////////////////////////
+ (unsigned long long)bytesOfFreeMemory {
  if (!sIsCaching && [self updateHostStatistics]) {
    return 0;
  }
  unsigned long long mem_free = ((unsigned long long)sVMStats.free_count
                                 * (unsigned long long)sPageSize);
  return mem_free;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
+ (unsigned long long)bytesOfTotalDiskSpace {
  if (!sIsCaching && [self updateFileSystemAttributes]) {
    return 0;
  }
	unsigned long long bytes = 0;

  NSNumber* number = [sFileSystem objectForKey:NSFileSystemSize];
  bytes = [number unsignedLongLongValue];

  return bytes;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
+ (unsigned long long)bytesOfFreeDiskSpace {
  if (!sIsCaching && [self updateFileSystemAttributes]) {
    return 0;
  }
	unsigned long long bytes = 0;

  NSNumber* number = [sFileSystem objectForKey:NSFileSystemFreeSize];
	bytes = [number unsignedLongLongValue];

  return bytes;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
+ (CGFloat)batteryLevel {
  return [[UIDevice currentDevice] batteryLevel];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
+ (UIDeviceBatteryState)batteryState {
  return [[UIDevice currentDevice] batteryState];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Caching


///////////////////////////////////////////////////////////////////////////////////////////////////
+ (BOOL)beginCachedDeviceInfo {
  if (!sIsCaching) {
    sIsCaching = YES;

    sLastUpdateResult = [self updateHostStatistics];
    sLastUpdateResult = ([self updateFileSystemAttributes] && sLastUpdateResult);
  }

  return sLastUpdateResult;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
+ (void)endCachedDeviceInfo {
  sIsCaching = NO;
}


@end

#endif