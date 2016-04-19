/*
 *  Copyright (c) 2011-2016 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>

/** The class that `QredoRendezvousRef`and `QredoConversationRef` derive from
 Objects of this class are not created directly
 */
@interface QredoObjectRef :NSObject

/** Used internally */
-(instancetype)initWithData:(NSData *)data;

/** Developers should not rely on the contents of this property */
@property (readonly) NSData *data;

@end

