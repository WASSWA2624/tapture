#include "whisper.h"

static bool compute(int n_threads) {
    return n_threads > 0;
}

int whisper_fixture(void) {
    return compute(4) ? 0 : 1;
}
