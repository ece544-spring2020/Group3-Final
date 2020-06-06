

/***************************** Include Files *******************************/
#include "pitch_shifter.h"

/******************************* Variables *********************************/
static u32 PitchShifterBaseAddr;
static int32_t last_rq_shifted_bins;
/************************** Function Definitions ***************************/

XStatus PitchShifter_initialize(u32 baseaddress)
{
	PitchShifterBaseAddr = BaseAddr;
    last_rq_shifted_bins = 0;
    return PITCH_SHIFTER_Reg_SelfTest(PitchShifterBaseAddr);
}

XStatus PitchShifter_set_shift_en(bool enabled) {
    if(enabled) {
        PitchShifter_set_n_bins_to_shift(last_rq_shifted_bins);
    } else {
        PitchShifter_set_n_bins_to_shift(0);
    }
    return XST_SUCCESS;
}

XStatus PitchShifter_set_n_bins_to_shift(int32_t n_bins) {
    PITCH_SHIFTER_mWriteReg(PitchShifterBaseAddr, 0, n_bins);
    last_rq_shifted_bins = n_bins;
    return XST_SUCCESS;
}