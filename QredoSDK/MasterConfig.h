/* HEADER GOES HERE */



//Use this file to specify the Server
//Note: For Tests the  AppID,AppSecret, & UserID are all specified in the file "QredoXCTestCase.m"


//#define SERVER_LOCAL
//#define SERVER_PUSH_TEST
//#define SERVER_LOCAL_NETWORKED
//#define SERVER_LOCAL_NETWORKED2
#define SERVER_STAGING
//#define SERVER_PRODUCTION




//This is what is used as the default ClientOptions - the server that a user would usually connect to
#define     DEFAULT_SERVER_URL      @"api.qredo.com"
#define     DEFAULT_USE_HTTP        NO



//These values are used in the initDefaults (which is swizzled with initTest in QredoClientOptions when we are testing)

#define     TEST_SERVER_URL          @"api-push.oderq.com"
#define     TEST_USE_HTTP            NO
#define     TEST_SERVER_APPID        @"test"
#define     TEST_SERVER_APPSECRET    @"a23469be8be13768c74ca0937cec47d1"
#define     TEST_SERVER_USERID       @"testUserId1"
#define     TEST_SERVER_USERSECRET   @"secret1"
#define     TEST_SERVER_USERID2      @"testUserId2"
#define     TEST_SERVER_USERSECRET2  @"secret2"
#define     TEST_APP_GROUP           @"group.com.qredo.ChrisPush1"
#define     TEST_KEYCHAIN_GROUP      @"com.qredo.ChrisPush1"





//#ifdef SERVER_LOCAL
//    #define     QREDO_SERVER_URL    @"localhost"
//    #define     SERVER_APPID        @"test"
//    #define     SERVER_APPSECRET    @"cafebabe"
//    #define     SERVER_USERID       @"testUserId"
//    #define     USE_HTTP            @"YES"
//    #define     QREDO_HTTP_SERVICE_URL @"http://localhost:8080/services"
//
//#elif defined SERVER_PUSH_TEST
//    #define     QREDO_SERVER_URL    @"api-push.oderq.com"
//    #define     SERVER_APPID        @"test"
//    #define     SERVER_APPSECRET    @"a23469be8be13768c74ca0937cec47d1"
//    #define     SERVER_USERID       @"testUserId1"
//    #define     SERVER_USERSECRET   @"secret1"
//    #define     SERVER_USERID2      @"testUserId2"
//    #define     SERVER_USERSECRET2  @"secret2"
//    #define     USE_HTTP            @"NO"
//
//
////This one at Qredo/Office
//#elif defined SERVER_LOCAL_NETWORKED
//    #define     QREDO_SERVER_URL    @"10.0.0.105"
//    #define     SERVER_APPID        @"test"
//    #define     SERVER_APPSECRET    @"cafebabe"
//    #define     SERVER_USERID       @"testUserId1"
//    #define     SERVER_USERSECRET   @"secret1"
//    #define     SERVER_USERID2      @"testUserId2"
//    #define     SERVER_USERSECRET2  @"secret2"
//    #define     USE_HTTP            @"YES"
//    #define     QREDO_HTTP_SERVICE_URL @"http://10.0.0.105:8080/services"
//
//
////This one a Home
//#elif defined SERVER_LOCAL_NETWORKED2
//    #define     QREDO_SERVER_URL    @"192.168.0.35"
//    #define     SERVER_APPID        @"test"
//    #define     SERVER_APPSECRET    @"cafebabe"
//    #define     SERVER_USERID       @"testUserId1"
//    #define     SERVER_USERSECRET   @"secret1"
//    #define     SERVER_USERID2      @"testUserId2"
//    #define     SERVER_USERSECRET2  @"secret2"
//    #define     USE_HTTP            @"YES"
//    #define QREDO_HTTP_SERVICE_URL @"http://192.168.0.35∫:8080/services"
//
//#elif defined SERVER_STAGING
//    #define     QREDO_SERVER_URL    @"api.oderq.com"
//    #define     SERVER_APPID        @"6e50b259-942d-499e-b4e2-6ceeb3d25990"
//    #define     SERVER_APPSECRET    @"e2b104fdb1cb4f36b467ceabd8935b40"
//    #define     SERVER_USERSECRET   @"secret1"
//    #define     SERVER_USERID       @"testUserId"
//    #define     SERVER_USERID2      @"testUserId2"
//    #define     SERVER_USERSECRET2  @"secret2"
//    #define     USE_HTTP            @"NO"
//    #define QREDO_HTTP_SERVICE_URL @"https://api.oderq.com:443/services"
//
//#elif defined SERVER_PRODUCTION
//    #define     QREDO_SERVER_URL    @"api.qredo.com"
//    #define     SERVER_APPID        @"com.qredo.device.ios.test"
//    #define     SERVER_APPSECRET    @"074af11737f877505167177726501aa0"
//    #define     SERVER_USERID       @"testUserId"
//    #define     USE_HTTP            @"NO"
//    #define QREDO_HTTP_SERVICE_URL @"https://api.qredo.com:443/services"
//
//#endif
//
//
//#define DEFAULT_SERVER              QREDO_SERVER_URL
//
