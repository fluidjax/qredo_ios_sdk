//
//  QredoUserInitialization.h
//  QredoSDK
//
//  Created by Christopher Morris on 10/11/2015.
//
//

#import <Foundation/Foundation.h>


@interface QredoUserInitialization : NSObject

+(instancetype)sharedInstance;

-(void)setAppId:(NSString*)appId userId:(NSString*)userId userSecure:(NSString*)userSecure;
-(NSData*)userUnlockKey;
-(NSData*)masterKey;

@end
