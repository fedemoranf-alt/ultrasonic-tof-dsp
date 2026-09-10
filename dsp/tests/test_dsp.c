/* ============================================================================
 * test_dsp.c - unit tests for the DSP kernels in dsp/dsp.c
 *
 * Every expected value in this file is either derivable by hand in one line,
 * or a property that must hold for any correct implementation (the impulse
 * response of an FIR is its own coefficients; the envelope of a quadrature
 * pair is its amplitude). Nothing here was produced by running the code and
 * writing down whatever came out - that would only lock in today's bugs.
 * ========================================================================= */
#include "check.h"
#include "../dsp.h"

#include <math.h>
#include <stdio.h>
#include <stdint.h>

static const double PI = 3.14159265358979323846;

/* --------------------------------------------------------------------------
 * 1. The impulse response of an FIR filter is its coefficients.
 *
 * Feed a unit impulse, and the output has to be the tap vector followed by
 * zeros. If this fails, the filter is broken - no interpretation needed.
 * ----------------------------------------------------------------------- */
static void test_fir_impulse_response(void)
{
    static const float taps[4] = { 0.25f, -0.50f, 0.75f, 1.00f };
    static const float impulse[5] = { 1.0f, 0.0f, 0.0f, 0.0f, 0.0f };
    float out[5 + 4 - 1];
    size_t i;

    check_begin("fir_impulse_response");

    dsp_fir(impulse, 5u, taps, 4u, out);

    for (i = 0u; i < 4u; i++) {
        CHECK_NEAR_AT(out[i], taps[i], 1e-6, i);
    }
    for (i = 4u; i < 8u; i++) {
        CHECK_NEAR_AT(out[i], 0.0f, 1e-6, i);
    }

    check_end();
}

/* --------------------------------------------------------------------------
 * 2. A 4-tap moving average whose taps sum to 1 must pass DC through with
 *    unity gain, after a 3-sample transient - and must ring down with a
 *    matching 3-sample tail.
 *
 * This is the test that catches off-by-one errors in the accumulation loop,
 * which the impulse test above cannot see.
 * ----------------------------------------------------------------------- */
static void test_fir_dc_gain_and_transients(void)
{
    static const float taps[4] = { 0.25f, 0.25f, 0.25f, 0.25f };
    float ones[16];
    float out[16 + 4 - 1];
    size_t i;

    check_begin("fir_dc_gain_and_transients");

    for (i = 0u; i < 16u; i++) {
        ones[i] = 1.0f;
    }

    dsp_fir(ones, 16u, taps, 4u, out);

    /* Leading transient: 1/4, 2/4, 3/4. */
    CHECK_NEAR(out[0], 0.25f, 1e-6);
    CHECK_NEAR(out[1], 0.50f, 1e-6);
    CHECK_NEAR(out[2], 0.75f, 1e-6);

    /* Steady state: unity gain at DC. */
    for (i = 3u; i <= 15u; i++) {
        CHECK_NEAR_AT(out[i], 1.0f, 1e-6, i);
    }

    /* Trailing tail, mirror of the leading transient. */
    CHECK_NEAR(out[16], 0.75f, 1e-6);
    CHECK_NEAR(out[17], 0.50f, 1e-6);
    CHECK_NEAR(out[18], 0.25f, 1e-6);

    check_end();
}

/* --------------------------------------------------------------------------
 * 3. Cross-correlation against a case small enough to do on paper.
 *
 *   y = [1 2 3], x = [1 1],  out[k] = sum_i x[i] * y[k - (2-1) + i]
 *
 *   k=0 (lag -1):            x[1]*y[0]  = 1
 *   k=1 (lag  0): x[0]*y[0] + x[1]*y[1] = 1 + 2 = 3
 *   k=2 (lag  1): x[0]*y[1] + x[1]*y[2] = 2 + 3 = 5
 *   k=3 (lag  2): x[0]*y[2]             = 3
 *
 * If the lag convention ever drifts, this test fails before dsp_tof_lag()
 * starts returning plausible-looking but wrong distances.
 * ----------------------------------------------------------------------- */
static void test_xcorr_hand_computed(void)
{
    static const float y[3] = { 1.0f, 2.0f, 3.0f };
    static const float x[2] = { 1.0f, 1.0f };
    static const float expected[4] = { 1.0f, 3.0f, 5.0f, 3.0f };
    float out[4];
    size_t i;

    check_begin("xcorr_hand_computed");

    dsp_xcorr(y, 3u, x, 2u, out);

    for (i = 0u; i < 4u; i++) {
        CHECK_NEAR_AT(out[i], expected[i], 1e-6, i);
    }

    check_end();
}

/* --------------------------------------------------------------------------
 * 4. End-to-end delay estimation: hide a known burst inside noise at a known
 *    offset and check the estimator finds exactly that offset.
 *
 * The noise comes from a fixed-seed generator, not rand(), so this test gives
 * the same answer on your PC and on the CI machine. A test that fails once a
 * fortnight is worse than no test at all.
 *
 * Two things are asserted, and they check different failure modes:
 *
 *   (a) the estimated lag is exactly TRUE_DELAY;
 *   (b) the peak stands at least 1.3x above anything further than 8 samples
 *       away from it.
 *
 * (b) is the robustness check: it says we locked onto the burst rather than
 * onto noise or onto the sidelobe one carrier period away. (a) is the precise
 * one, and it is deliberately tight - with this pattern the correlation peak
 * is broad, and the neighbouring sample at lag+1 sits only about 4% below the
 * maximum. That is not a defect of the test, it is the reason the real
 * instrument interpolates by 25 before correlating: at the raw sample rate,
 * one sample of ambiguity is a large distance error.
 * ----------------------------------------------------------------------- */
#define SIGNAL_LEN   512u
#define PATTERN_LEN   64u
#define TRUE_DELAY   137L
#define SIGNAL_AMP   0.70f
#define NOISE_AMP    0.30f

static uint32_t rng_state = 2025u;

static float rng_bipolar(void)
{
    /* Numerical Recipes LCG; the exact constants do not matter, only that it
     * is deterministic and portable. */
    rng_state = (uint32_t)(rng_state * 1664525u + 1013904223u);
    return ((float)((rng_state >> 8) & 0xFFFFu) / 32767.5f) - 1.0f;
}

static void test_tof_lag_recovers_known_delay(void)
{
    float pattern[PATTERN_LEN];
    float signal[SIGNAL_LEN];
    float scratch[SIGNAL_LEN + PATTERN_LEN - 1u];
    long lag;
    size_t i;

    check_begin("tof_lag_recovers_known_delay");

    rng_state = 2025u;

    /* A Hann-windowed four-cycle burst: roughly the shape of the envelope
     * derivative the real instrument correlates against. */
    for (i = 0u; i < PATTERN_LEN; i++) {
        double t = (double)i / (double)PATTERN_LEN;
        double window = 0.5 - 0.5 * cos(2.0 * PI * t);
        pattern[i] = (float)(window * sin(2.0 * PI * 4.0 * t));
    }

    for (i = 0u; i < SIGNAL_LEN; i++) {
        signal[i] = NOISE_AMP * rng_bipolar();
    }
    for (i = 0u; i < PATTERN_LEN; i++) {
        signal[(size_t)TRUE_DELAY + i] += SIGNAL_AMP * pattern[i];
    }

    lag = dsp_tof_lag(signal, SIGNAL_LEN, pattern, PATTERN_LEN, scratch);

    if (CHECK_LONG_EQ(lag, TRUE_DELAY) == 0) {
        /* Show the neighbourhood of the peak that was actually chosen, so the
         * failure says whether we locked onto a sidelobe (off by one carrier
         * period) or onto noise somewhere else entirely. */
        size_t peak = (size_t)(lag + (long)(PATTERN_LEN - 1u));
        check_dump("xcorr", scratch, SIGNAL_LEN + PATTERN_LEN - 1u, peak, 3u);
    }

    /* (b) The peak has to dominate everything outside its own main lobe. */
    {
        size_t corr_len = SIGNAL_LEN + PATTERN_LEN - 1u;
        size_t peak = dsp_argmax(scratch, corr_len, 0u);
        float peak_value = scratch[peak];
        float best_far = 0.0f;
        size_t far_index = 0u;

        for (i = 0u; i < corr_len; i++) {
            size_t distance = (i > peak) ? (i - peak) : (peak - i);
            if (distance > 8u && scratch[i] > best_far) {
                best_far = scratch[i];
                far_index = i;
            }
        }

        if (CHECK_TRUE(peak_value > 1.3f * best_far) == 0) {
            printf("        peak      : %.4f at index %lu (lag %ld)\n",
                   (double)peak_value, (unsigned long)peak,
                   (long)peak - (long)(PATTERN_LEN - 1u));
            printf("        runner-up : %.4f at index %lu (lag %ld)\n",
                   (double)best_far, (unsigned long)far_index,
                   (long)far_index - (long)(PATTERN_LEN - 1u));
            printf("        ratio     : %.3f   (needs to exceed 1.300)\n",
                   (best_far != 0.0f) ? (double)(peak_value / best_far) : 0.0);
        }
    }

    check_end();
}

/* --------------------------------------------------------------------------
 * 5. The envelope of a quadrature pair is its amplitude, everywhere.
 *
 *   sqrt( (A cos w n)^2 + (A sin w n)^2 ) = A
 *
 * Exact for any frequency and any phase. A ripple here means the Hilbert
 * branch is misaligned, which in the real system shows up as an envelope
 * that wobbles at twice the carrier.
 * ----------------------------------------------------------------------- */
static void test_envelope_of_quadrature_pair(void)
{
    float in_phase[128];
    float quadrature[128];
    float envelope[128];
    const float amplitude = 0.37f;
    size_t n;

    check_begin("envelope_of_quadrature_pair");

    for (n = 0u; n < 128u; n++) {
        double w = 2.0 * PI * 7.0 / 128.0;
        in_phase[n]   = (float)((double)amplitude * cos(w * (double)n));
        quadrature[n] = (float)((double)amplitude * sin(w * (double)n));
    }

    dsp_envelope(in_phase, quadrature, 128u, envelope);

    for (n = 0u; n < 128u; n++) {
        CHECK_NEAR_AT(envelope[n], amplitude, 1e-5, n);
    }

    check_end();
}

/* --------------------------------------------------------------------------
 * 6. Removing the DC component leaves a block with zero mean, and shifts
 *    every sample by the same amount.
 * ----------------------------------------------------------------------- */
static void test_remove_dc(void)
{
    float in[64];
    float out[64];
    double sum = 0.0;
    size_t i;

    check_begin("remove_dc");

    /* A ramp riding on a 2.5 V offset: mean = 2.5 + (0+63)/2 * 0.01 */
    for (i = 0u; i < 64u; i++) {
        in[i] = 2.5f + 0.01f * (float)i;
    }

    dsp_remove_dc(in, 64u, out);

    for (i = 0u; i < 64u; i++) {
        sum += (double)out[i];
    }
    CHECK_NEAR(sum / 64.0, 0.0, 1e-5);

    /* Same shift applied to every sample: differences are preserved. */
    for (i = 1u; i < 64u; i++) {
        CHECK_NEAR_AT(out[i] - out[i - 1u], 0.01f, 1e-5, i);
    }

    check_end();
}

/* --------------------------------------------------------------------------
 * 7. The zero-stuffing upsampler puts the input samples on the multiples of M
 *    and zeros everywhere else, and reports the right output length.
 * ----------------------------------------------------------------------- */
static void test_upsample_zero_stuffing(void)
{
    static const float in[3] = { 1.0f, 2.0f, 3.0f };
    float out[16];
    size_t out_len;
    size_t i;

    check_begin("upsample_zero_stuffing");

    out_len = dsp_upsample(in, 3u, 4u, out);

    /* (3 - 1) * 4 + 1 = 9 */
    CHECK_LONG_EQ((long)out_len, 9L);

    CHECK_NEAR(out[0], 1.0f, 1e-6);
    CHECK_NEAR(out[4], 2.0f, 1e-6);
    CHECK_NEAR(out[8], 3.0f, 1e-6);

    for (i = 0u; i < 9u; i++) {
        if ((i % 4u) != 0u) {
            CHECK_NEAR_AT(out[i], 0.0f, 1e-6, i);
        }
    }

    check_end();
}

/* --------------------------------------------------------------------------
 * 8. argmax must return the FIRST index on a tie, because the firmware's
 *    find_max() does, and the lag arithmetic downstream assumes it.
 * ----------------------------------------------------------------------- */
static void test_argmax_tie_goes_to_first(void)
{
    static const float v[5] = { 1.0f, 5.0f, 5.0f, 2.0f, 0.0f };

    check_begin("argmax_tie_goes_to_first");

    CHECK_LONG_EQ((long)dsp_argmax(v, 5u, 0u), 1L);

    /* Starting past the first maximum finds the second one. */
    CHECK_LONG_EQ((long)dsp_argmax(v, 5u, 2u), 2L);

    check_end();
}

/* --------------------------------------------------------------------------
 * 9. Normalising by the peak scales the block so the peak becomes 1, and
 *    leaves an all-zero block alone instead of producing infinities.
 *
 * The firmware divides by the peak unconditionally. On a frame where the
 * transducer did not fire, that is a division by zero and every sample
 * downstream becomes NaN - which then propagates silently through the
 * correlation and comes out as a plausible-looking distance.
 * ----------------------------------------------------------------------- */
static void test_normalize_peak(void)
{
    static const float in[4] = { 0.5f, 2.0f, -1.0f, 1.0f };
    static const float zeros[4] = { 0.0f, 0.0f, 0.0f, 0.0f };
    float out[4];
    size_t i;

    check_begin("normalize_peak");

    dsp_normalize_peak(in, 4u, 0u, out);

    CHECK_NEAR(out[0], 0.25f, 1e-6);
    CHECK_NEAR(out[1], 1.00f, 1e-6);
    CHECK_NEAR(out[2], -0.50f, 1e-6);
    CHECK_NEAR(out[3], 0.50f, 1e-6);

    /* A silent frame must come out silent, not full of NaN. */
    dsp_normalize_peak(zeros, 4u, 0u, out);
    for (i = 0u; i < 4u; i++) {
        CHECK_NEAR_AT(out[i], 0.0f, 1e-6, i);
        CHECK_TRUE(out[i] == out[i]); /* false only for NaN */
    }

    check_end();
}

int main(void)
{
    printf("DSP unit tests - ultrasonic-tof-dsp\n\n");

    test_fir_impulse_response();
    test_fir_dc_gain_and_transients();
    test_xcorr_hand_computed();
    test_tof_lag_recovers_known_delay();
    test_envelope_of_quadrature_pair();
    test_remove_dc();
    test_upsample_zero_stuffing();
    test_argmax_tie_goes_to_first();
    test_normalize_peak();

    return check_report();
}
