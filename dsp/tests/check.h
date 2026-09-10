/* ============================================================================
 * check.h - a 150-line test harness.
 *
 * No framework, no dependencies. Enough to say precisely what failed, where,
 * and by how much, and to return a non-zero exit code so CI notices.
 * ========================================================================= */
#ifndef CHECK_H
#define CHECK_H

#include <stddef.h>

/* Start / finish a named test. check_end() returns 1 if it failed. */
void check_begin(const char *test_name);
int  check_end(void);

/* Print the summary. Returns the process exit code: 0 all good, 1 failures. */
int  check_report(void);

/* Implementations behind the macros below. Return 1 on pass, 0 on fail. */
int check_true_(const char *file, int line, int cond, const char *expr);
int check_near_(const char *file, int line, double actual, double expected,
                double tol, const char *expr);
int check_near_at_(const char *file, int line, double actual, double expected,
                   double tol, const char *expr, const char *index_name,
                   long index);
int check_long_eq_(const char *file, int line, long actual, long expected,
                   const char *expr);

/* Print `radius` samples either side of index `around`, for context after a
 * failure. Pass len for `around` to dump from the start. */
void check_dump(const char *label, const float *v, size_t len,
                size_t around, size_t radius);

#define CHECK_TRUE(cond) \
    check_true_(__FILE__, __LINE__, (cond), #cond)

#define CHECK_NEAR(actual, expected, tol) \
    check_near_(__FILE__, __LINE__, (double)(actual), (double)(expected), \
                (double)(tol), #actual)

/* Same, but for checks inside a loop: also reports the value of the loop
 * variable, so the failure says WHICH sample was wrong and not just that one
 * of them was. Use this any time the check sits inside a for(). */
#define CHECK_NEAR_AT(actual, expected, tol, index) \
    check_near_at_(__FILE__, __LINE__, (double)(actual), (double)(expected), \
                   (double)(tol), #actual, #index, (long)(index))

#define CHECK_LONG_EQ(actual, expected) \
    check_long_eq_(__FILE__, __LINE__, (long)(actual), (long)(expected), \
                   #actual)

#endif /* CHECK_H */
