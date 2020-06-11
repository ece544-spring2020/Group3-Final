#include "platform.h"
#include "xparameters.h"
#include "xstatus.h"

#include "FreeRTOS.h"
#include "queue.h"
#include "task.h"
#include "nexys4IO.h"
#include "xil_types.h"
#include "input.h"
#include "pitch_shifter.h"

///////////////////////////////////////
//
//
//      Function Prototype
//
//
////////////////////////////////////////
void input_task(void *pvParameters);
void display_task(void *pvParameters);
int8_t setup_displays();



////////////////////////////////////////
//
//
//          DECLARATION
//
//
/////////////////////////////////////////

#define NX4IO_BADDR	XPAR_NEXYS4IO_0_S00_AXI_BASEADDR
#define PITCH_SHIFTER_BADDR  XPAR_PITCH_SHIFTER_0_S00_AXI_BASEADDR

typedef struct INPUTS_HANDOFF_STRUCT{
	EncoderState rotenc;
	int shiftVal;
} InputsHandoff;

volatile QueueHandle_t InputsHandoffQueue;
void display_task(void * pvParameters);
XStatus disp_pitch_shifting(uint16_t direction);



int main(void)
{
    XStatus sts;
    BaseType_t ret;

    init_platform();

    	
	xil_printf("Hello from Final Project !\r\n");

    // General Setup
    sts = NX4IO_initialize(NX4IO_BADDR);
	if(sts == XST_FAILURE) {
		xil_printf("Couldnt initialize NX4IO ... Exiting.\n\r");
		return -1;	
	}

    sts = PitchShifter_initialize(PITCH_SHIFTER_BADDR);;
	if(sts == XST_FAILURE) {
		xil_printf("Couldnt initialize Pitch Shifter ... Exiting.\n\r");
		return -1;	
	}   

    setup_displays();
	setup_inputs();


    InputsHandoffQueue = xQueueCreate(1, sizeof(InputsHandoff));
    xil_printf("Post queue 1: %d bytes\n\r",xPortGetFreeHeapSize());


    //Create Input Task
    ret =  xTaskCreate(input_task,
				    "Input task",
				    2048,
				    NULL,
				    1,
				    NULL);

	if(ret != pdPASS) 
    {
        xil_printf("Input task task allocation failed\n\r");
    }
    xil_printf("Post Input task: %d bytes\n\r",xPortGetFreeHeapSize());

    //Create Display Task 
	ret = xTaskCreate(display_task,
				"Display Task",
				2048,
				NULL,
				2,
				NULL);

    if(ret != pdPASS) 
    {
        xil_printf("Display task allocation failed\n\r",xPortGetFreeHeapSize());
    } 

    xil_printf("Starting scheduler with %d tasks.\n\r", uxTaskGetNumberOfTasks());
	vTaskStartScheduler();
    xil_printf("Ending!\n\r");
    return -1;
}


void input_task(void * pvParameters)
{
    TickType_t xLastWakeTime;

    // Setup Variable
    EncoderState rotenc;


    xil_printf("Setting up %s\n\r", pcTaskGetName(NULL));
    // Name is confusing, its the struct that holds the
    // outputs of this 1ms input handling task
    InputsHandoff inputs_output;
    inputs_output.shiftVal = 0;

    // Initialise the xLastWakeTime variable with the current time.
    xLastWakeTime = xTaskGetTickCount();
    for( ;; )
    {
        // Reading the Switch Values
        SwitchInputs current_sw_value = get_switch_inputs();

        // Wait for the next cycle.
        vTaskDelayUntil(&xLastWakeTime, 10);

        rotenc = get_enc_state();  

        // Put the input of rotary encoder in the Queue
        inputs_output.rotenc = rotenc;
        inputs_output.shiftVal += inputs_output.rotenc.rot_dir;
        xQueueOverwrite(InputsHandoffQueue, &inputs_output);       
    }

    // Better not get here, if so, at least call delete to clean up
    vTaskDelete(NULL);
    return;
}

void display_task(void * pvParameters)
{
    TickType_t xLastWakeTime;

    InputsHandoff control_inputs;

    int8_t err = 0;
    int8_t rand = 0;

    PitchShifter_set_shift_en(1);
    // Initialise the xLastWakeTime variable with the current time.
    xLastWakeTime = xTaskGetTickCount();

    // Wait up to one 20ms task cycletime for the inputs to populate 
    if(xQueuePeek(InputsHandoffQueue, &control_inputs, 200) == pdFALSE) {
        //vTaskDelete(NULL);
    }
    for( ;; )
    {
        // Wait for the next cycle.
        vTaskDelayUntil(&xLastWakeTime, 200);

        if(xQueuePeek(InputsHandoffQueue, &control_inputs, 0) == pdFALSE) 
        {
        	err++;
        }

        PitchShifter_set_n_bins_to_shift(control_inputs.shiftVal);
        disp_pitch_shifting((uint16_t)control_inputs.shiftVal);
        rand++;
        xil_printf("%d", control_inputs.shiftVal + rand);
    }

}

XStatus disp_pitch_shifting(uint16_t direction) {
    uint8_t bcd[5];
    
   
    bin2bcd16(direction, bcd);

    // Note: BCD is coded such that most significant digit is in lower index.
    // Therefore least significant digit is in fifth byte (index 4) since a 16bit
    // value could be up to 65535.  Our display only shows 4 digits of speed, so
    // we always throw away bcd[0].

    NX410_SSEG_setAllDigits(SSEGLO, bcd[1], bcd[2], bcd[3], bcd[4], DP_NONE);

	return XST_SUCCESS;
}

int8_t setup_displays() 
{
    // Turn all of the LEDs off
    NX4IO_setLEDs(0);

    // Turn off the high seven seg
	NX410_SSEG_setAllDigits(SSEGHI, CC_BLANK, CC_BLANK, CC_BLANK, CC_BLANK, DP_NONE);
	
    // Turn off the low seven seg
    NX410_SSEG_setAllDigits(SSEGLO, CC_0, CC_0, CC_0, CC_0, DP_NONE);

    return XST_SUCCESS;

}


void bin2bcd16(uint16_t bin, uint8_t bcd[])
{
	#define DIM(a)  (sizeof(a) / sizeof(a[0]))

    static const uint16_t pow_ten_tbl[] = {
        10000,
        1000,
        100,
        10,
        1
    };
    uint16_t pow_ten;
    uint8_t digit;
    uint8_t i;

    for (i = 0; i != DIM(pow_ten_tbl); i++) {
        digit = 0;
        pow_ten = pow_ten_tbl[i];

        while (bin >= pow_ten) {
            bin -= pow_ten;
            digit++;
        }
        *bcd++ = digit;
    }
}
