/* HEADER GOES HERE */
#import <stdint.h>
#import "QredoStreamExtensions.h"

#pragma mark - Qredo S-expression reader

typedef NSData   QredoAtom;

typedef NS_ENUM (int,QredoToken) {
    QredoTokenLParen,
    QredoTokenRParen,
    QredoTokenAtom,
    QredoTokenEnd
};

@interface QredoSExpressionReader :NSObject

@property (readonly) NSInputStream *inputStream;
@property (readonly) QredoToken lastToken;
@property (readonly) QredoAtom *lastAtom;

+(instancetype)sexpressionReaderForInputStream:(NSInputStream *)inputStream;

-(instancetype)initWithInputStream:(NSInputStream *)inputStream;

-(bool)isExhausted;
-(QredoToken)lookAhead;
-(QredoAtom *)readAtom;
-(void)readLeftParen;
-(void)readRightParen;

@end

#pragma mark - Qredo S-expression writer

@interface QredoSExpressionWriter :NSObject

@property (readonly) NSOutputStream *outputStream;

+(instancetype)sexpressionWriterForOutputStream:(NSOutputStream *)outputStream;

-(instancetype)initWithOutputStream:(NSOutputStream *)outputStream;

-(void)writeAtom:(QredoAtom *)atom;
-(void)writeLeftParen;
-(void)writeRightParen;

@end
