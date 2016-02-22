/*
 *  Copyright (c) 2011-2016 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>


@interface QredoObjectRef :NSObject
-(instancetype)initWithData:(NSData *)data;
@property (readonly) NSData *data;

@end

