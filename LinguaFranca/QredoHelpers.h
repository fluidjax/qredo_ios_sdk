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

