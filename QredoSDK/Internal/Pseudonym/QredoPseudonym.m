//
//  QredoPseudonym.m
//  QredoSDK
//
//  Created by Christopher Morris on 14/08/2017.
//
//

#import "QredoPseudonym.h"

@implementation QredoPseudonym


+ (QredoPseudonym *)create:(NSString *)localName{
   return nil;
}


+ (void)destroy:(QredoPseudonym *)pseudonym{
}


+ (bool)exists:(NSString *)localName{
   return nil;
}


+ (QredoPseudonym *)get:(NSString *)localName{
   return nil;
}

+ (NSArray *)list{
    return nil;
}


+ (void)put:(QredoPseudonym *)pseudonym{
}

- (NSString *)localName{
    return nil;
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
