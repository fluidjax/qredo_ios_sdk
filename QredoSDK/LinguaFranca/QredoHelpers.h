/* HEADER GOES HERE */

#define QREDO_MAJOR_PROTOCOL_VERSION @0
#define QREDO_MINOR_PROTOCOL_VERSION @3
#define QREDO_PATCH_PROTOCOL_VERSION @0

#define QREDO_MAJOR_RELEASE_VERSION @0
#define QREDO_MINOR_RELEASE_VERSION @3
#define QREDO_PATCH_RELEASE_VERSION @0



#define QREDO_COMPARE_OBJECT(a) {                     \
    NSComparisonResult a = [_##a compare:[other a]];  \
    if (a != NSOrderedSame) {                         \
        return a;                                     \
    }                                                 \
}

#define QREDO_COMPARE_SCALAR(a) {                     \
    NSComparisonResult a = _##a < [other a]           \
        ? NSOrderedAscending                          \
        : (_##a == [other a]) ? NSOrderedSame : NSOrderedDescending;        \
    if (a != NSOrderedSame) {                         \
        return a;                                     \
    }                                                 \
}

#define QREDO_COMPARE_SCALAR2(x, y) {                  \
    NSComparisonResult a = x < y                       \
        ? NSOrderedAscending                           \
        : (x == y) ? NSOrderedSame : NSOrderedDescending;        \
        if (a != NSOrderedSame) {                      \
            return a;                                  \
        }                                              \
}

