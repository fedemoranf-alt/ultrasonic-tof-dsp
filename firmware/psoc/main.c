/* ============================================================================
 * Ultrasonic Time-of-Flight - PSoC 5LP firmware
 *
 * Real-time echo acquisition (ADC + DMA) and sub-sample time-delay estimation
 * by cross-correlation using the ARM CMSIS-DSP library.
 *
 * Part of "Design and Implementation of a Low-Cost IoT-Based Ultrasonic
 * Flowmeter" - Federico D. Moran Fretes. Released under the MIT License.
 * ============================================================================
 */
#include "project.h"
#include <stdio.h>
#include <common.h>
#include <math.h>
#include "arm_math.h"
#include "math_helper.h"

#include <stdlib.h>
#include <string.h>


#define OFFSET 2.04
#define LONGITUD 256

#if defined (__GNUC__)
    asm (".global _printf_float");
#endif


//variables de las senhales

// LA CORRELACION SE HACE A PARTIR DE LAS SENHALES INTERPOLADAS POR LO QUE REQUIERE QUE SE MULTIPLIQUE LONGITUD*M, DONDE M=3
//float32_t correlacion[2*(LONGITUD*3)-1];
uint16 memA[LONGITUD];
float32_t aux;

//variables del sistema
uint8 flag = '0';
uint8 errorStatus = 0u;
uint j;

//DMA PARA IR DIRECTO DEL ADC A LA MEMORIA, SIN PASAR POR LOS FILTROS 
    /* Defines for DMA_ADC_CHA */
/*#define DMA_ADC_CHA_BYTES_PER_BURST 2
#define DMA_ADC_CHA_REQUEST_PER_BURST 1
#define DMA_ADC_CHA_SRC_BASE (CYDEV_PERIPH_BASE)
#define DMA_ADC_CHA_DST_BASE (CYDEV_SRAM_BASE)*/
    /* Defines for DMA_ADC_CHA */
#define DMA_ADC_CHA_BYTES_PER_BURST 2
#define DMA_ADC_CHA_REQUEST_PER_BURST 1
#define DMA_ADC_CHA_SRC_BASE (CYDEV_PERIPH_BASE)
#define DMA_ADC_CHA_DST_BASE (CYDEV_SRAM_BASE)

/* Variable declarations for DMA_ADC_CHA */
/* Move these variable declarations to the top of the function */
uint8 DMA_ADC_CHA_Chan;
uint8 DMA_ADC_CHA_TD[1];
/* Variable declarations for DMA_ADC_CHA */
/* Move these variable declarations to the top of the function */
//uint8 DMA_ADC_CHA_Chan;
//uint8 DMA_ADC_CHA_TD[1];


//Rutinas de interrupciones:
CY_ISR(Adquisicion);
CY_ISR(RxIsr);
//CY_ISR(socADC);
 
//Declaracion de funciones:
void my_Start(void);
void DMA_Config(void);


int main(void)
{
    /* Place your initialization/startup code here (e.g. MyInst_Start()) */
    my_Start();         /*Rutina para inicializar los componentes*/
     /* Configure DMA to transfer ADC output to Memory*/
    DMA_Config();        
   
    //Punteros a la rutinas de interrupción  
    #if(INTERRUPT_CODE_ENABLED == ENABLED)   
    isr_rx_StartEx(RxIsr);
    isr_1_StartEx(Adquisicion);   
    //isr_soc_StartEx(socADC);

    #endif /* INTERRUPT_CODE_ENABLED == ENABLED */
    
    CyDelay(50);  
    CyGlobalIntEnable; /* Enable global interrupts. */
    isr_rx_Enable();
    isr_1_Disable();
  //  isr_soc_Enable();
      
    for(;;)
    {
    // Place your application code here. 
    switch (flag)
        {
        case '0':
            
            break;
        
        case '1': //se realiza la adquisision de datos 
            //Cuando se recibe una "T" por el puerto serial, se habilita la adquisición            
    
            isr_1_Enable(); 
            CyDmaChEnable(DMA_ADC_CHA_Chan, 1);
            Reg_pulser_Write(1u); //se habilita la emision del pulso
            
            ADC_SAR_1_StartConvert();
            //Control_Reg_ADC_Write(1u);
            //Led_Write(~Led_Read());
            flag = '0';
            break;       

        
        case '2': //Rx: T, se guardan los vectores yi e yq, se calcula la envolvente, la derivada, la correlacion, los puntos maximos y el tiempo de vuelo
            //Se desarma el trigger
            
 
           // Reg_pulser_Write(0u); //se deshabilita la emision del pulso
            ADC_SAR_1_StopConvert();
            //Control_Reg_ADC_Write(0u);
            CyDmaChDisable(DMA_ADC_CHA_Chan);
            isr_1_Disable();        
            Led_Write(~Led_Read());
            //avisamos al esp32 que estamos listos para enviarle los datos
            UART_PutChar('H');
            flag = '0';
            break;
            
        case '3': //Rx: G
            Led_Write(~Led_Read());
            //Se imprime en el puerto UART la señal del eco en BINARIO
            for(j=0; j<(sizeof(memA)/sizeof(memA[0])); j++)
            { 
                aux = ADC_SAR_1_CountsTo_Volts(memA[j]); 
                Chart_2_Plot(aux);
            }  
            flag = '0';
            break;   
        }
    }
    
}


void my_Start(){
  //Se instancian los componentes analogicos 
    ADC_SAR_1_Start();    
    Opamp_1_Start();
    Clock_Pulser_Start();
    Clock_Adq_Start(); 
  
    UART_Start();  
   

}



CY_ISR(Adquisicion){   
    //Se ingresa a esta rutina cuando los DMA terminan sus transacciones     
    flag = '2'; 
   // Reg_pulser_Write(0u); //se deshabilita la emision del pulso
   ADC_SAR_1_StopConvert();
     //Control_Reg_ADC_Write(0u);
   // isr_1_ClearPending();  
    isr_1_Disable();  
   
}

/*******************************************************************************
* Function Name: RxIsr
********************************************************************************
*
* Summary:
*  Interrupt Service Routine for RX portion of the UART
*
* Parameters:
*  None.
*
* Return:
*  None.
*
*******************************************************************************/

CY_ISR(RxIsr)
{
    uint8 rxStatus;
    //uint8 rx_count;
    char rxData;
    
    do
    {
        //Read receiver status register 
        rxStatus = UART_RXSTATUS_REG;

        if((rxStatus & (UART_RX_STS_BREAK      | UART_RX_STS_PAR_ERROR |
                        UART_RX_STS_STOP_ERROR | UART_RX_STS_OVERRUN)) != 0u)
        {
            // ERROR handling. 
            errorStatus |= rxStatus & ( UART_RX_STS_BREAK      | UART_RX_STS_PAR_ERROR | 
                                        UART_RX_STS_STOP_ERROR | UART_RX_STS_OVERRUN);
        }
        
        if((rxStatus & UART_RX_STS_FIFO_NOTEMPTY) != 0u)
        {
            // Read data from the RX data register 
            rxData = UART_RXDATA_REG;
                if (rxData == 'T') // adquisicion de datos y posterior calculo de la envolvente y su impresion en el puerto UART
                {
                    flag = '1';
                }
                if (rxData == 'G') // se imprime en el puerto UART el eco submuestreado en BINARIO
                {
                    flag = '3';
                }
                if (rxData == 'O') // se imprime en el puerto UART el eco submuestreado en ascii
                {
                    for(j=0; j<(sizeof(memA)/sizeof(memA[0])); j++)
                    { 
                        aux = ADC_SAR_1_CountsTo_Volts(memA[j]); 
                        Chart_1_Plot(aux);
                    }  
                }
                if (rxData == 'Q') //para cambiar canales 
                {
                    flag = '0';
                    Control_Reg_Mux_Write(~Control_Reg_Mux_Read());   
                    Led_Write(~Led_Read());
                }
                if (rxData == 'W') //para cambiar canales 
                {
                    flag = '0';
                    Control_Reg_Mux_Write(0);   
                    Led_Write(~Led_Read());
                }
           /* if(errorStatus == 0u)
            {
                //Send data backward 
                UART_TXDATA_REG = rxData;
            }*/
            
        }
    }while((rxStatus & UART_RX_STS_FIFO_NOTEMPTY) != 0u);
    //isr_rx_ClearPending(); 
}



void DMA_Config(){
    

/* DMA Configuration for DMA_ADC_CHA - DMA PARA IR DEL ADC DIRECTO A MEMORIA, SIN PASAR POR LOS FILTROS*/ 
/*DMA_ADC_CHA_Chan = DMA_ADC_CHA_DmaInitialize(DMA_ADC_CHA_BYTES_PER_BURST, DMA_ADC_CHA_REQUEST_PER_BURST, 
    HI16(DMA_ADC_CHA_SRC_BASE), HI16(DMA_ADC_CHA_DST_BASE));
DMA_ADC_CHA_TD[0] = CyDmaTdAllocate();
CyDmaTdSetConfiguration(DMA_ADC_CHA_TD[0], 2*LONGITUD, DMA_ADC_CHA_TD[0], DMA_ADC_CHA__TD_TERMOUT_EN | CY_DMA_TD_INC_DST_ADR);
CyDmaTdSetAddress(DMA_ADC_CHA_TD[0], LO16((uint32)ADC_SAR_1_SAR_WRK0_PTR), LO16((uint32)memA));
CyDmaChSetInitialTd(DMA_ADC_CHA_Chan, DMA_ADC_CHA_TD[0]);
CyDmaChEnable(DMA_ADC_CHA_Chan, 1);*/



/* DMA Configuration for DMA_ADC_CHA */
/*DMA_ADC_CHA_Chan = DMA_ADC_CHA_DmaInitialize(DMA_ADC_CHA_BYTES_PER_BURST, DMA_ADC_CHA_REQUEST_PER_BURST, 
    HI16(DMA_ADC_CHA_SRC_BASE), HI16(DMA_ADC_CHA_DST_BASE));
DMA_ADC_CHA_TD[0] = CyDmaTdAllocate();
CyDmaTdSetConfiguration(DMA_ADC_CHA_TD[0], LONGITUD, DMA_ADC_CHA_TD[0], DMA_ADC_CHA__TD_TERMOUT_EN | CY_DMA_TD_INC_DST_ADR);
CyDmaTdSetAddress(DMA_ADC_CHA_TD[0], LO16((uint32)ADC_SAR_1_SAR_WRK0_PTR), LO16((uint32)memA));
CyDmaChSetInitialTd(DMA_ADC_CHA_Chan, DMA_ADC_CHA_TD[0]);
CyDmaChEnable(DMA_ADC_CHA_Chan, 1);*/
    


/* DMA Configuration for DMA_ADC_CHA */
DMA_ADC_CHA_Chan = DMA_ADC_CHA_DmaInitialize(DMA_ADC_CHA_BYTES_PER_BURST, DMA_ADC_CHA_REQUEST_PER_BURST, 
    HI16(DMA_ADC_CHA_SRC_BASE), HI16(DMA_ADC_CHA_DST_BASE));
DMA_ADC_CHA_TD[0] = CyDmaTdAllocate();
CyDmaTdSetConfiguration(DMA_ADC_CHA_TD[0], 2*LONGITUD, DMA_ADC_CHA_TD[0], DMA_ADC_CHA__TD_TERMOUT_EN | CY_DMA_TD_INC_DST_ADR);
CyDmaTdSetAddress(DMA_ADC_CHA_TD[0], LO16((uint32)ADC_SAR_1_SAR_WRK0_PTR), LO16((uint32)memA));
CyDmaChSetInitialTd(DMA_ADC_CHA_Chan, DMA_ADC_CHA_TD[0]);
CyDmaChEnable(DMA_ADC_CHA_Chan, 1);


}


/* [] END OF FILE */
