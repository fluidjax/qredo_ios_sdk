/* HEADER GOES HERE */


/**
    These are what is used in QredoClientOptions - the server that a user would usually connect too.
    Usage:

    QredoClientOptions *options = [QredoClientOptions alloc] initLive]  // For Developers to access the live server
    QredoClientOptions *options = [QredoClientOptions alloc] initDev]   // For Developers to access the developement server
    QredoClientOptions *options = [QredoClientOptions alloc] initTest]  // For Qredo Use Only - this will use the test server
 */


#include "QredoMacros.h"


//QredoLogLevelNone     0
//QredoLogLevelError    1
//QredoLogLevelWarning  2
//QredoLogLevelInfo     3
//QredoLogLevelDebug    4
//QredoLogLevelVerbose  5
//QredoLogLevelInfo     6

#define QREDO_DEBUG_LEVEL 1


//The Live Server  [QredoClientOptions alloc] initLive]
#define     LIVE_SERVER_URL             @"api.qredo.com"
#define     LIVE_USE_HTTP               NO


//The Dev Server  use [QredoClientOptions alloc] initDev]
#define     DEV_SERVER_URL              @"api-dev.oderq.com"
#define     DEV_USE_HTTP                NO









//The Test Server [QredoClientOptions alloc] initTest]
//These are used in Testing to create an QredoClientOption object and pass it into the QredoClient init method

//Standard Test Server
#define     TEST_SERVER_URL             @"api-dev.oderq.com"
#define     TEST_USE_HTTP               NO
#define     TEST_SERVER_APP_ID          @"test"
#define     TEST_SERVER_APP_SECRET      @"a23469be8be13768c74ca0937cec47d1"
#define     TEST_HTTP_SERVICE_URL       @"https://api-dev.oderq.com:443/services"


//Live as Test
//#define     TEST_SERVER_URL             @"api.qredo.com"
//#define     TEST_USE_HTTP               NO
//#define     TEST_HTTP_SERVICE_URL       @"https://api.qredo.com:443/services"
//#define     TEST_SERVER_APP_ID          @"test"
//#define     TEST_SERVER_APP_SECRET      @"074af11737f877505167177726501aa0"


//Use these when testing on local Qreedo-in-a-jar    use:java -jar qredo-in-a-jar-0.19-SNAPSHOT.jar
//#define     TEST_SERVER_URL             @"127.0.0.1"
//#define     TEST_USE_HTTP               YES
//#define     TEST_SERVER_APP_ID          @"test"
//#define     TEST_SERVER_APP_SECRET      @"cafebabecafebabecafebabecafebabe"
//#define     TEST_HTTP_SERVICE_URL       @"http://127.0.0.1:8080/services"


//Special Test Server
//#define     TEST_SERVER_URL             @"api-ed.oderq.com"
//#define     TEST_USE_HTTP               NO
//#define     TEST_SERVER_APP_ID          @"test"
//#define     TEST_SERVER_APP_SECRET      @"a23469be8be13768c74ca0937cec47d1"
//#define     TEST_HTTP_SERVICE_URL       @"http://api-ed.oderq.com:8080/services"








//Other Test Vars
#define     TEST_SERVER_USERID          @"testUserId1"
#define     TEST_SERVER_USERSECRET      @"secret1"
#define     TEST_SERVER_USERID2         @"testUserId2"
#define     TEST_SERVER_USERSECRET2     @"secret2"
#define     TEST_APP_GROUP              @"group.com.qredo.ChrisPush1"
#define     TEST_KEYCHAIN_GROUP         @"com.qredo.ChrisPush1"

//These APP_ID & SECRETS are not stored in the produced framework, but are used in testing to check that Live & Dev are working

#define     LIVE_SERVER_APP_ID          @"test"
#define     LIVE_SERVER_APP_SECRET      @"074af11737f877505167177726501aa0"
#define     DEV_SERVER_APP_ID           @"test"
#define     DEV_SERVER_APP_SECRET       @"a23469be8be13768c74ca0937cec47d1"





