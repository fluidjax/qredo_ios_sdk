/* HEADER GOES HERE */

#ifndef config_h
#define config_h



//Use this file to specify the Server
//Note: For Tests the  AppID,AppSecret, & UserID are all specified in the file "QredoXCTestCase.m"

#ifdef QREDO_SERVER_URL
#undef QREDO_SERVER_URL
#endif


//#define QREDO_SERVER_URL @"api.oderq.com" //dev staging
#define QREDO_SERVER_URL @"api.qredo.com" //production


//staging for   @"api.oderq.com"
#define     STAGING_TEST_APPID          @"com.qredo.device.ios.test"
#define     STAGING_TEST_APPSECRET      @"a23469be8be13768c74ca0937cec47d1"
#define     STAGING_TEST_USERID         @"testUserId"

//PRODUCTION for @"api.qredo.com"
#define     PRODUCTION_TEST_APPID       @"com.qredo.device.ios.test"
#define     PRODUCTION_TEST_APPSECRET   @"074af11737f877505167177726501aa0"
#define     PRODUCTION_TEST_USERID      @"testUserId"



#endif /* config_h */
