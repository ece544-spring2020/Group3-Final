#ifndef PITCH_SHIFTER_H
#define PITCH_SHIFTER_H

#include "pitch_shifter_l.h"
#include "xil_types.h"
#include "xstatus.h"
#include "stdbool.h"

extern XStatus PitchShifter_initialize(u32 baseaddress);

extern XStatus PitchShifter_set_shift_en(bool enabled);

extern XStatus PitchShifter_set_n_bins_to_shift(int32_t n_bins);

#endif // PITCH_SHIFTER_H