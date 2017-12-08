/* HEADER GOES HERE */


#import "QredoPseudonym.h"
#import "QredoKeyPair.h"
#import "Qredo.h"


@interface QredoPseudonym()
@property (strong,readwrite) NSString *localName;
@property (assign) UInt64 *counter;
@property (strong) QredoKeyPair *keyPair;


@end


@implementation QredoPseudonym

-(instancetype)initWithLocalName:(NSString*)localName qredoClient:(QredoClient*)client{
    self = [super init];
    if (self){
        
    }
    return self;
}

- (QredoSignedKey *)pubKey{
   return nil;
    
}
- (QredoRevocation *)revoke{
    return nil;
}

- (QredoPseudonym *)rotate:(QredoPseudonym *)old{
    return nil;
}

- (NSData *)sign:(NSData *)data{
    return nil;
}

- (bool)verify:(NSData *)data signature:(NSData *)signature{
    return nil;
}

@end
