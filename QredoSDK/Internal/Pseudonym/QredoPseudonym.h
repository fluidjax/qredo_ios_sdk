/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/



//  Note: Public Pseudoymn methods in Qredo.h  - (get,list,exists,create,destroy)  @implementation QredoClient (Pseudonym)


@class QredoSignedKey;
@class QredoRevocation;

#import <Foundation/Foundation.h>

@interface QredoPseudonym : NSObject

@property (strong,readonly) NSString *localName;


-(NSString *)localName;
-(QredoSignedKey *)pubKey;
-(QredoRevocation *)revoke;
-(QredoPseudonym *)rotate:(QredoPseudonym *)old;
-(NSData *)sign:(NSData *)data;
-(bool)verify:(NSData *)data signature:(NSData *)signature;

@end
