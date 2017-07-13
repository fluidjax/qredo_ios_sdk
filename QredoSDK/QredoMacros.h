//
//  QredoMacros.h
//  QredoSDK
//
//  Created by Christopher Morris on 13/07/2017.
//  General purpose macros used accross multiple files
//  Macros specific to individual source files are defined in their own files

#ifndef QredoMacros_h
#define QredoMacros_h


//Guard against bad params begin passed into methods

#define GUARD(condition, msg) \
    if (!(condition)) { \
    @throw [NSException exceptionWithName:NSInvalidArgumentException \
    reason:[NSString stringWithFormat:(msg)] \
    userInfo:nil]; \
    }

#define GUARDF(condition, fmt, ...) \
    if (!(condition)) { \
    @throw [NSException exceptionWithName:NSInvalidArgumentException \
    reason:[NSString stringWithFormat:(fmt), __VA_ARGS__] \
    userInfo:nil]; \
    }


#endif /* QredoMacros_h */
