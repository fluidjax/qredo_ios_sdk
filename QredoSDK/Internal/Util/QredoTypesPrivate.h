/* HEADER GOES HERE */
@class QredoVaultItemDescriptor;
@class QredoVault;

@interface QredoObjectRef ()

typedef int32_t   QredoAccessLevel; //for now just an integer, but probably needs enum values

typedef NS_ENUM (NSUInteger,QredoRendezvousAuthenticationType) {
    QredoRendezvousAuthenticationTypeAnonymous = 0,                 //The tag is just a string, has no cryptographic identity
};

typedef NS_ENUM (NSUInteger,QredoVaultType) {
    QredoDefaultVault,
    QredoSystemVault
};

typedef NSData * (^signDataBlock)(NSData *data,QredoRendezvousAuthenticationType authenticationType);

@property QredoVaultItemDescriptor *vaultItemDescriptor;
@property (readwrite) NSData *data;

-(instancetype)initWithVaultItemDescriptor:(QredoVaultItemDescriptor *)vaultItemDescriptor vault:(QredoVault *)vault;

@end