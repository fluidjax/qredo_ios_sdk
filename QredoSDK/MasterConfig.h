/* HEADER GOES HERE */



//Use this file to specify the Server
//Note: For Tests the  AppID,AppSecret, & UserID are all specified in the file "QredoXCTestCase.m"



//#define SERVER_LOCAL
#define SERVER_LOCAL_NETWORKED
//define SERVER_LOCAL_NETWORKED2
//#define SERVER_STAGING
//#define SERVER_PRODUCTION




#ifdef SERVER_LOCAL
    #undef      QREDO_SERVER_URL
    #define     QREDO_SERVER_URL    @"localhost"
    #define     SERVER_APPID        @"test"
    #define     SERVER_APPSECRET    @"cafebabe"
    #define     SERVER_USERID       @"testUserId"
    #define     USE_HTTP            @"YES"
    #define     QREDO_HTTP_SERVICE_URL @"http://localhost:8080/services"

#elif defined SERVER_LOCAL_NETWORKED
    #undef      QREDO_SERVER_URL
    #define     QREDO_SERVER_URL    @"10.0.0.110"
    #define     SERVER_APPID        @"test"
    #define     SERVER_APPSECRET    @"cafebabe"
    #define     SERVER_USERID       @"testUserId1"
    #define     SERVER_USERSECRET   @"secret1"
    #define     SERVER_USERID2      @"testUserId2"
    #define     SERVER_USERSECRET2  @"secret2"
    #define     USE_HTTP            @"YES"
    #define QREDO_HTTP_SERVICE_URL @"http://10.0.0.110:8080/services"

#elif defined SERVER_LOCAL_NETWORKED2
    #undef      QREDO_SERVER_URL
    #define     QREDO_SERVER_URL    @"192.168.0.50"
    #define     SERVER_APPID        @"test"
    #define     SERVER_APPSECRET    @"cafebabe"
    #define     SERVER_USERID       @"testUserId"
    #define     USE_HTTP            @"YES"
    #define QREDO_HTTP_SERVICE_URL @"http://192.168.0.50:8080/services"

#elif defined SERVER_STAGING
    #undef      QREDO_SERVER_URL
    #define     QREDO_SERVER_URL    @"api.oderq.com"
    #define     SERVER_APPID        @"6e50b259-942d-499e-b4e2-6ceeb3d25990"
    #define     SERVER_APPSECRET    @"e2b104fdb1cb4f36b467ceabd8935b40"
    #define     SERVER_USERID       @"testUserId"
    #define     USE_HTTP            @"NO"
    #define QREDO_HTTP_SERVICE_URL @"https://api.oderq.com:443/services"

#elif defined SERVER_PRODUCTION
    #undef      QREDO_SERVER_URL
    #define     QREDO_SERVER_URL    @"api.qredo.com"
    #define     SERVER_APPID        @"com.qredo.device.ios.test"
    #define     SERVER_APPSECRET    @"074af11737f877505167177726501aa0"
    #define     SERVER_USERID       @"testUserId"
    #define     USE_HTTP            @"NO"
    #define QREDO_HTTP_SERVICE_URL @"https://api.qredo.com:443/services"

#endif


