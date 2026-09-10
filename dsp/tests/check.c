#include "check.h"

#include <math.h>
#include <stdio.h>

/* After this many failures inside one test, stop printing and just count.
 * Without it, one broken loop buries the terminal in 1750 identical lines. */
#define MAX_REPORTED_PER_TEST 5

static const char *current_test = "(none)";
static int current_failures = 0;
static int total_tests = 0;
static int total_failed_tests = 0;
static int total_checks = 0;

void check_begin(const char *test_name)
{
    current_test = test_name;
    current_failures = 0;
    total_tests++;
}

int check_end(void)
{
    if (current_failures == 0) {
        printf("ok    %s\n", current_test);
        return 0;
    }

    total_failed_tests++;
    if (current_failures > MAX_REPORTED_PER_TEST) {
        printf("\n");
        printf("        ... %d further failures in this test not printed\n",
               current_failures - MAX_REPORTED_PER_TEST);
    }
    printf("FAIL  %s  (%d failed check%s)\n\n",
           current_test, current_failures,
           (current_failures == 1) ? "" : "s");
    return 1;
}

int check_report(void)
{
    printf("\n");
    printf("--------------------------------------------------------------\n");
    printf("  %d test%s, %d passed, %d failed, %d individual checks\n",
           total_tests, (total_tests == 1) ? "" : "s",
           total_tests - total_failed_tests, total_failed_tests, total_checks);
    printf("--------------------------------------------------------------\n");

    if (total_failed_tests == 0) {
        printf("ALL TESTS PASSED\n");
        return 0;
    }

    printf("FAILED\n");
    return 1;
}

/* Returns 0 when this failure should be printed, 1 when it is over the cap. */
static int note_failure(const char *file, int line)
{
    current_failures++;
    if (current_failures > MAX_REPORTED_PER_TEST) {
        return 1;
    }

    printf("\n  FAIL  %s:%d   (in test: %s)\n", file, line, current_test);
    return 0;
}

int check_true_(const char *file, int line, int cond, const char *expr)
{
    total_checks++;
    if (cond) {
        return 1;
    }

    if (note_failure(file, line) == 0) {
        printf("        expression : %s\n", expr);
        printf("        expected   : true\n");
        printf("        actual     : false\n");
    }
    return 0;
}

static int near_impl(const char *file, int line, double actual, double expected,
                     double tol, const char *expr, const char *index_name,
                     long index, int have_index)
{
    double diff;

    total_checks++;

    /* An actual of NaN makes every comparison false, so it lands here. That
     * is the behaviour we want: NaN must never pass silently. */
    diff = fabs(actual - expected);
    if (diff <= tol) {
        return 1;
    }

    if (note_failure(file, line) == 0) {
        if (have_index) {
            printf("        expression : %s        with %s = %ld\n",
                   expr, index_name, index);
        } else {
            printf("        expression : %s\n", expr);
        }
        printf("        expected   : %.9g\n", expected);
        printf("        actual     : %.9g\n", actual);
        if (actual != actual) {
            printf("        difference : n/a - actual is NaN\n");
        } else {
            printf("        difference : %.9g   (tolerance %.9g)\n", diff, tol);
        }
    }
    return 0;
}

int check_near_(const char *file, int line, double actual, double expected,
                double tol, const char *expr)
{
    return near_impl(file, line, actual, expected, tol, expr, NULL, 0L, 0);
}

int check_near_at_(const char *file, int line, double actual, double expected,
                   double tol, const char *expr, const char *index_name,
                   long index)
{
    return near_impl(file, line, actual, expected, tol, expr, index_name,
                     index, 1);
}

int check_long_eq_(const char *file, int line, long actual, long expected,
                   const char *expr)
{
    total_checks++;
    if (actual == expected) {
        return 1;
    }

    if (note_failure(file, line) == 0) {
        printf("        expression : %s\n", expr);
        printf("        expected   : %ld\n", expected);
        printf("        actual     : %ld\n", actual);
        printf("        difference : %ld\n", actual - expected);
    }
    return 0;
}

void check_dump(const char *label, const float *v, size_t len,
                size_t around, size_t radius)
{
    size_t first, last, i;

    if (len == 0u) {
        printf("        %s: (empty)\n", label);
        return;
    }

    if (around >= len) {
        first = 0u;
        last = (len < (2u * radius + 1u)) ? (len - 1u) : (2u * radius);
    } else {
        first = (around > radius) ? (around - radius) : 0u;
        last = around + radius;
        if (last >= len) {
            last = len - 1u;
        }
    }

    printf("        %s[%lu..%lu]:\n", label,
           (unsigned long)first, (unsigned long)last);
    for (i = first; i <= last; i++) {
        printf("          [%5lu] % .6f%s\n", (unsigned long)i, (double)v[i],
               (i == around) ? "   <-- here" : "");
    }
}
