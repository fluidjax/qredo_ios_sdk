/* HEADER GOES HERE */
#import <Foundation/Foundation.h>

static NSString *const QredoAuthenticatedRendezvousTagErrorDomain = @"QredoAuthenticatedRendezvousTagErrorDomain";

typedef NS_ENUM (NSUInteger,QredoAuthenticatedRendezvousTagError) {
    QredoAuthenticatedRendezvousTagErrorUnknown = 0,
    QredoAuthenticatedRendezvousTagErrorMissingTag,
    QredoAuthenticatedRendezvousTagErrorMalformedTag,
};

@interface QredoAuthenticatedRendezvousTag :NSObject

-(instancetype)initWithFullTag:(NSString *)fullTag error:(NSError **)error;
-(instancetype)initWithPrefix:(NSString *)prefix authenticationTag:(NSString *)authenticationTag error:(NSError **)error;

@property (nonatomic,readonly,copy) NSString *fullTag;
@property (nonatomic,readonly,copy) NSString *prefix;
@property (nonatomic,readonly,copy) NSString *authenticationTag;

+(BOOL)isAuthenticatedTag:(NSString *)tag;

@end
