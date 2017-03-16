/* HEADER GOES HERE */
#import "MasterConfig.h"

#undef QREDO_HTTP_SERVICE_URL

#ifdef SERVER_LOCAL
    #define QREDO_HTTP_SERVICE_URL @"http://localhost:8080/services"
#elif defined SERVER_LOCAL_NETWORKED
    #define QREDO_HTTP_SERVICE_URL @"http://10.0.0.110:8080/services"
#elif defined SERVER_LOCAL_NETWORKED
    #define QREDO_HTTP_SERVICE_URL @"http://10.0.0.110:8080/services"
#elif defined SERVER_STAGING
    #define QREDO_HTTP_SERVICE_URL @"https://api.oderq.com:443/services"
#elif defined SERVER_PRODUCTION
    #define QREDO_HTTP_SERVICE_URL @"https://api.qredo.com:443/services"
#elif defined SERVER_PUSH_TEST
    #define QREDO_HTTP_SERVICE_URL @"https://api-push.oderq.com:443/services"

#endif
