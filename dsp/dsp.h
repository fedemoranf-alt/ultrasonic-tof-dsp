/* ============================================================================
 * dsp.h - Hardware-independent DSP kernels for the ultrasonic ToF platform.
 *
 * These are the same routines that run on the ESP32 in
 * firmware/esp32/src/main.cpp, extracted from the firmware so they can be
 * compiled and tested on a host PC without a board attached.
 *
 * Design rules for everything in here:
 *   - no globals: every buffer is passed in by the caller;
 *   - no hardware headers, no Arduino, no printf;
 *   - lengths are parameters, not compile-time #defines;
 *   - output buffers must not overlap input buffers unless stated otherwise.
 *
 * Part of "Design and Implementation of a Low-Cost IoT-Based Ultrasonic
 * Flowmeter" - Federico D. Moran Fretes. Released under the MIT License.
 * ========================================================================= */
#ifndef DSP_H
#define DSP_H

#include <stddef.h>

/* ---------------------------------------------------------------------------
 * dsp_fir - full linear convolution of `in` with the FIR taps.
 *
 * `out` receives (in_len + n_taps - 1) samples: the transient at the start,
 * the steady-state region, and the tail. This is the same "full" convention
 * as MATLAB's conv(), and the same one apply_fir_filter() uses in the
 * firmware.
 *
 * `out` must not alias `in`.
 * ------------------------------------------------------------------------ */
void dsp_fir(const float *in, size_t in_len,
             const float *taps, size_t n_taps,
             float *out);

/* ---------------------------------------------------------------------------
 * dsp_remove_dc - subtract the mean of the block.
 *
 * `out` may alias `in` (safe in place).
 * ------------------------------------------------------------------------ */
void dsp_remove_dc(const float *in, size_t len, float *out);

/* ---------------------------------------------------------------------------
 * dsp_normalize_peak - divide the block by the largest value found from
 * `start` onwards. Does nothing if that value is zero.
 *
 * `out` may alias `in`.
 * ------------------------------------------------------------------------ */
void dsp_normalize_peak(const float *in, size_t len, size_t start, float *out);

/* ---------------------------------------------------------------------------
 * dsp_upsample - zero-stuffing upsampler (rate M).
 *
 * out[i*M] = in[i], every other sample is zero. This is the "zero-order
 * expander" step; the image rejection is done afterwards by dsp_fir() with
 * the interpolator low-pass taps.
 *
 * `out` must have room for (len - 1) * M + 1 samples.
 * Returns the number of samples written.
 * ------------------------------------------------------------------------ */
size_t dsp_upsample(const float *in, size_t len, size_t M, float *out);

/* ---------------------------------------------------------------------------
 * dsp_envelope - magnitude of the analytic signal: sqrt(i^2 + q^2).
 *
 * `q` is normally the Hilbert-filtered version of `i`, group-delay aligned.
 * `out` may alias `i` or `q`.
 * ------------------------------------------------------------------------ */
void dsp_envelope(const float *i_sig, const float *q_sig, size_t len,
                  float *out);

/* ---------------------------------------------------------------------------
 * dsp_xcorr - cross-correlation of signal `y` with pattern `x`.
 *
 * `out` receives (y_len + x_len - 1) samples. The lag of out[k] is
 *
 *     lag = k - (x_len - 1)
 *
 * so out[x_len - 1] is lag zero, lower indices are negative lags, and
 * out[k] = sum_i  x[i] * y[k - (x_len - 1) + i]  over the valid range of i.
 *
 * This is the convention correlacion_cruzada() uses in the firmware; keep it,
 * because the lag arithmetic in dsp_tof_lag() depends on it.
 *
 * `out` must not alias `x` or `y`.
 * ------------------------------------------------------------------------ */
void dsp_xcorr(const float *y, size_t y_len,
               const float *x, size_t x_len,
               float *out);

/* ---------------------------------------------------------------------------
 * dsp_argmax - index of the largest sample in [start, len).
 *
 * On ties the first (lowest) index wins, matching find_max() in the firmware.
 * Returns `start` if the range is empty.
 * ------------------------------------------------------------------------ */
size_t dsp_argmax(const float *v, size_t len, size_t start);

/* ---------------------------------------------------------------------------
 * dsp_tof_lag - integer time-delay estimate, in samples, of pattern `x`
 * inside signal `y`.
 *
 * Correlates, takes the peak, converts the peak index into a lag. This is the
 * estimator itself; the sub-sample resolution of the instrument comes from
 * running it on the interpolated (x25) signal, not from this function.
 *
 * `scratch` must have room for (y_len + x_len - 1) floats.
 * ------------------------------------------------------------------------ */
long dsp_tof_lag(const float *y, size_t y_len,
                 const float *x, size_t x_len,
                 float *scratch);

#endif /* DSP_H */
