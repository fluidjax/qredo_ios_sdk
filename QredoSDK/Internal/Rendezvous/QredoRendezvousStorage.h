#import <Foundation/Foundation.h>
#import "QredoClient.h"

@interface QredoRendezvousStorage : NSObject

@property (readonly) NSURL *serviceURL;
@property (readonly) QredoVaultSequenceId *sequenceId;
@property (readonly) QredoVaultId *vaultId;

+ (instancetype)storageWithServiceURL:(NSURL *)serviceURL
                              vaultId:(QredoVaultId *)vaultId
                           sequenceId:(QredoVaultSequenceId *)sequenceId;

- (instancetype)initWithServiceURL:(NSURL *)serviceURL
                           vaultId:(QredoVaultId *)vaultId
                        sequenceId:(QredoVaultSequenceId *)sequenceId;

- (QredoRendezvousDescriptor *)load:(NSString *)tag;
- (void)save:(QredoRendezvousDescriptor *)descriptor
        completionHandler:(void(^)(BOOL result))completionHandler;

@end