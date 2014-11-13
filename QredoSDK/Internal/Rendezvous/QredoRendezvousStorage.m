#import "QredoRendezvousStorage.h"
#import "QredoSimpleVault.h"
#import "QredoPrimitiveMarshallers.h"
#import "QredoClientMarshallers.h"

#define QREDO_RENDEZVOUS_VAULTITEMTYPE @"com.qredo.rendezvous"

@implementation QredoRendezvousStorage {
    QredoSimpleVault *_vault;
}

+ (instancetype)storageWithServiceURL:(NSURL *)serviceURL
                              vaultId:(QredoVaultId *)vaultId
                           sequenceId:(QredoVaultSequenceId *)sequenceId {
    return [[self alloc] initWithServiceURL:serviceURL
                                    vaultId:vaultId
                                 sequenceId:sequenceId];
}

- (instancetype)initWithServiceURL:(NSURL *)serviceURL
                           vaultId:(QredoVaultId *)vaultId
                        sequenceId:(QredoVaultSequenceId *)sequenceId  {
    self = [super init];
    if (self) {
        _serviceURL = serviceURL;
        _sequenceId = sequenceId;
        _vaultId    = vaultId;
        _vault      = [QredoSimpleVault vaultWithServiceURL:serviceURL
                                                    vaultId:vaultId
                                                 sequenceId:sequenceId];
    }
    return self;
}

- (QredoRendezvousDescriptor *)load:(NSString *)tag {
    return nil;
}

- (void)save:(QredoRendezvousDescriptor *)descriptor
    completionHandler:(void(^)(BOOL result))completionHandler {

    QredoVaultItemId *itemId = [_vault generateItemIdWithName:[descriptor tag]
                                                     dataType:QREDO_RENDEZVOUS_VAULTITEMTYPE];

    NSData *serializedDescriptor = [QredoPrimitiveMarshallers marshalObject:descriptor
                                                                 marshaller:[QredoClientMarshallers rendezvousDescriptorMarshaller]];

    [_vault putWithItemId:itemId
                 dataType:QREDO_RENDEZVOUS_VAULTITEMTYPE
              accessLevel:@0
            summaryValues:[NSSet new]
                     data:serializedDescriptor
        completionHandler:^(BOOL result) {
            completionHandler(result);
        }];

}

@end