/* HEADER GOES HERE */
#import <Foundation/Foundation.h>

@interface QredoSecKeyRefPair :NSObject

@property (nonatomic,assign,readonly) SecKeyRef publicKeyRef;
@property (nonatomic,assign,readonly) SecKeyRef privateKeyRef;

-(instancetype)initWithPublicKeyRef:(SecKeyRef)publicKeyRef privateKeyRef:(SecKeyRef)privateKeyRef;

@end