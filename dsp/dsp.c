/* ============================================================================
 * dsp.c - see dsp.h for the contract of each function.
 *
 * Extracted from firmware/esp32/src/main.cpp. Where the firmware version and
 * this one differ, the difference is marked with a NOTE comment and is always
 * either (a) removing a hard-coded size, or (b) improving the accuracy of an
 * accumulator. The observable behaviour is otherwise the same.
 * ========================================================================= */
#include "dsp.h"

#include <math.h>

void dsp_fir(const float *in, size_t in_len,
             const float *taps, size_t n_taps,
             float *out)
{
    size_t i, j, out_len;

    if (in_len == 0u || n_taps == 0u) {
        return;
    }

    out_len = in_len + n_taps - 1u;
    for (i = 0u; i < out_len; i++) {
        out[i] = 0.0f;
    }

    for (i = 0u; i < in_len; i++) {
        for (j = 0u; j < n_taps; j++) {
            out[i + j] += in[i] * taps[j];
        }
    }
}

void dsp_remove_dc(const float *in, size_t len, float *out)
{
    size_t i;
    double sum = 0.0;
    float mean;

    if (len == 0u) {
        return;
    }

    /* NOTE: the firmware accumulates the sum in float. Here it is a double.
     * Over 1750 samples a float accumulator loses roughly a bit of mantissa
     * per doubling of the sample count; a double costs nothing on the host
     * and nothing measurable on the ESP32 for a once-per-frame operation. */
    for (i = 0u; i < len; i++) {
        sum += (double)in[i];
    }
    mean = (float)(sum / (double)len);

    for (i = 0u; i < len; i++) {
        out[i] = in[i] - mean;
    }
}

void dsp_normalize_peak(const float *in, size_t len, size_t start, float *out)
{
    size_t i;
    size_t peak;
    float scale;

    if (len == 0u) {
        return;
    }

    peak = dsp_argmax(in, len, start);
    scale = in[peak];

    if (scale == 0.0f) {
        /* Nothing to normalise against: copy through untouched rather than
         * producing infinities. The firmware would divide by zero here. */
        if (out != in) {
            for (i = 0u; i < len; i++) {
                out[i] = in[i];
            }
        }
        return;
    }

    for (i = 0u; i < len; i++) {
        out[i] = in[i] / scale;
    }
}

size_t dsp_upsample(const float *in, size_t len, size_t M, float *out)
{
    size_t i, k, out_len;

    if (len == 0u || M == 0u) {
        return 0u;
    }

    out_len = (len - 1u) * M + 1u;
    for (i = 0u; i < out_len; i++) {
        out[i] = 0.0f;
    }

    for (i = 0u, k = 0u; i < len; i++, k += M) {
        out[k] = in[i];
    }

    return out_len;
}

void dsp_envelope(const float *i_sig, const float *q_sig, size_t len,
                  float *out)
{
    size_t n;

    /* NOTE: the firmware writes sqrtf(powf(x,2) + powf(y,2)). Same value,
     * but powf() is a general-purpose call; x*x is a single multiply. */
    for (n = 0u; n < len; n++) {
        out[n] = sqrtf(i_sig[n] * i_sig[n] + q_sig[n] * q_sig[n]);
    }
}

void dsp_xcorr(const float *y, size_t y_len,
               const float *x, size_t x_len,
               float *out)
{
    size_t k, i, out_len;

    if (y_len == 0u || x_len == 0u) {
        return;
    }

    out_len = y_len + x_len - 1u;

    /* NOTE: the firmware scatters (loops over lag, adds into out[index]).
     * This gathers instead (one output sample per iteration of k), which is
     * the same arithmetic, keeps the accumulator in a register, and makes the
     * lag-to-index mapping visible on one line. */
    for (k = 0u; k < out_len; k++) {
        long lag = (long)k - (long)(x_len - 1u);
        double acc = 0.0;

        for (i = 0u; i < x_len; i++) {
            long j = lag + (long)i;

            if (j >= 0 && (size_t)j < y_len) {
                acc += (double)x[i] * (double)y[(size_t)j];
            }
        }

        out[k] = (float)acc;
    }
}

size_t dsp_argmax(const float *v, size_t len, size_t start)
{
    size_t i, best;

    if (start >= len) {
        return start;
    }

    best = start;
    for (i = start + 1u; i < len; i++) {
        if (v[i] > v[best]) {
            best = i;
        }
    }

    return best;
}

long dsp_tof_lag(const float *y, size_t y_len,
                 const float *x, size_t x_len,
                 float *scratch)
{
    size_t out_len;
    size_t peak;

    if (y_len == 0u || x_len == 0u) {
        return 0;
    }

    out_len = y_len + x_len - 1u;

    dsp_xcorr(y, y_len, x, x_len, scratch);
    peak = dsp_argmax(scratch, out_len, 0u);

    return (long)peak - (long)(x_len - 1u);
}
