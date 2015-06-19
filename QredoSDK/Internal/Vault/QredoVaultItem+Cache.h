/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */


#import "Qredo.h"
#import "QredoVault.h"
#import "QredoVaultPrivate.h"
#import "QredoClient.h"


@interface QredoVaultItemDescriptor (Cache)

- (NSString *)cacheKey;

@end


@interface QLFEncryptedVaultItem (Coding) <NSCoding>

@end

@interface QLFEncryptedVaultItemHeader (Coding) <NSCoding>

@end