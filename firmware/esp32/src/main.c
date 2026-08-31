
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/queue.h"
#include "esp_system.h"
#include "driver/uart.h"
#include "driver/gpio.h"
#include "string.h"
#include <stdint.h>
#include <stdlib.h>

#define UART_NUM_PC UART_NUM_0   // UART para comunicación con PC
#define UART_NUM_PSoC UART_NUM_2 // UART para comunicación con PSoC

//pins para el uart del psoc
#define TXD_PIN GPIO_NUM_17
#define RXD_PIN GPIO_NUM_16

#define BUF_SIZE (8192)
#define eco_size (512)
#define vref_adc (5.0) //voltaje maximo que puede digitalizar el adc del psoc (buscar en el datasheet)

///////// VARIABLES GLOBALES ////////////////

static QueueHandle_t uart0_queue;
static QueueHandle_t uart2_queue;

int16_t eco_16[eco_size];
static float eco_float[eco_size] __attribute__((aligned(4)));;
u_int8_t flag=0; //bandera para controlar la maquina de estados de main

///////// DECLARACIONES Y FUNCIONES PARA EL FILTRO INTERPOLADOR ///////////////////////
#define NUM_TAPS_interpolador           128 // Número de coeficientes del filtro
#define BLOCK_SIZE_int            32
#define TOTAL_SAMPLES       512 // Número total de muestras en la señal de entrada
#define M 25 //indice de tamanho de la interpolacion

static float eco_reconstruido[TOTAL_SAMPLES * M] __attribute__((aligned(4))); 

typedef struct {
    float *coeffs;    // Puntero a los coeficientes del filtro
    float *state;     // Puntero al estado del filtro (buffer de delay + muestras anteriores)
    int L;            // Factor de interpolación
    int numTaps;      // Número de coeficientes del filtro
} FIR_Interpolate_Instance_f32;


static float firStateF32_interpolador[BLOCK_SIZE_int + NUM_TAPS_interpolador - 1] __attribute__((aligned(4))); // Buffer de estado
float firCoeffs32_interpolador[NUM_TAPS_interpolador] __attribute__((aligned(4))) = {    0.0020,
    0.0020,    0.0018,    0.0015,    0.0011,    0.0004,   -0.0003,   -0.0011,   -0.0020,   -0.0028,   -0.0035,   -0.0039,   -0.0040,   -0.0037,   -0.0030,   -0.0018,   -0.0002,
    0.0016,    0.0036,    0.0056,    0.0073,    0.0084,    0.0089,    0.0086,    0.0073,    0.0052,    0.0023,   -0.0012,   -0.0050,   -0.0087,   -0.0120,   -0.0144,   -0.0156,
   -0.0155,   -0.0139,   -0.0108,   -0.0064,   -0.0010,    0.0048,    0.0105,    0.0157,    0.0197,    0.0222,    0.0227,    0.0211,    0.0175,    0.0121,    0.0053,   -0.0022,
   -0.0099,   -0.0169,   -0.0226,   -0.0264,   -0.0279,   -0.0270,   -0.0235,   -0.0179,   -0.0105,   -0.0021,    0.0067,    0.0149,    0.0218,    0.0269,    0.0295,    0.0295,
    0.0269,    0.0218,    0.0149,    0.0067,   -0.0021,   -0.0105,   -0.0179,   -0.0235,   -0.0270,   -0.0279,   -0.0264,   -0.0226,   -0.0169,   -0.0099,   -0.0022,    0.0053,
    0.0121,    0.0175,    0.0211,    0.0227,    0.0222,    0.0197,    0.0157,    0.0105,    0.0048,   -0.0010,   -0.0064,   -0.0108,   -0.0139,   -0.0155,   -0.0156,   -0.0144,
    -0.0120,   -0.0087,   -0.0050,  -0.0012,    0.0023,    0.0052,    0.0073,   0.0086,    0.0089,    0.0084,    0.0073,   0.0056,    0.0036,    0.0016,   -0.0002,   -0.0018,
    -0.0030,   -0.0037,   -0.0040,  -0.0039,    -0.0035,   -0.0028,   -0.0020,  -0.0011,    -0.0003,    0.0004,    0.0011,  0.0015,    0.0018,    0.0020,    0.0020, };


void fir_interpolate_init_f32(FIR_Interpolate_Instance_f32 *S, int L, int numTaps, float *pCoeffs, float *pState) {
    S->L = L;
    S->numTaps = numTaps;
    S->coeffs = pCoeffs;
    S->state = pState;

    // Inicializar el estado del filtro a cero
    for (int i = 0; i < (numTaps + L - 1); i++) {
        pState[i] = 0.0f;
    }
}

void fir_interpolate_f32(FIR_Interpolate_Instance_f32 *S, float *pSrc, float *pDst, int blockSize) {
    float *pState = S->state;
    float *pCoeffs = S->coeffs;
    int L = S->L;
    int numTaps = S->numTaps;

    for (int i = 0; i < blockSize; i++) {
        // Insertar la muestra de entrada en el estado manteniendo la cadencia por el factor de interpolación
        for (int j = (numTaps + L - 2); j >= L; j--) {
            pState[j] = pState[j - L];
        }

        pState[0] = pSrc[i];

        // Realizar el filtro FIR para cada punto interpolado
        for (int k = 0; k < L; k++) {
            float acc = 0.0f;
            for (int j = 0; j < numTaps; j++) {
                acc += pState[j + k] * pCoeffs[j];
            }
            pDst[i * L + k] = acc;
        }
    }
}



////////////////////////////////// FUNCIONES GENERALES //////////////////////////////

void reconstruccion (){
    FIR_Interpolate_Instance_f32 S; //se instancia el struc del filtro
    float  *input_int, *output_int;  
    /* Initialize input and output buffer pointers */
    input_int = &eco_float[0];
    output_int = &eco_reconstruido[0];   

    fir_interpolate_init_f32(&S, M, NUM_TAPS_interpolador, firCoeffs32_interpolador, firStateF32_interpolador); //inicializamos el filtro
    fir_interpolate_f32(&S, input_int, output_int, BLOCK_SIZE_int);

}

float adc_to_voltage(int16_t digital_value, float v_ref) {
    float voltage;
    if (digital_value >= 0) {
        voltage = (float)digital_value / 32767.0 * v_ref;
    } else {
        voltage = (float)digital_value / 32768.0 * v_ref;
    }
    return voltage;
}


// Esta función se llama cada vez que ocurre un evento en UART PC,
//Esta funcion modifica la bandera que se utiliza para controlar la maquina de estados del main dependiento de que instrucciones recibe por el puerto uart.
static void uart_PC_event_task(void *pvParameters) {
    
    uart_event_t event;
    QueueHandle_t *uart_queue = (QueueHandle_t *)pvParameters;
    char* dtmp = (char*) malloc(BUF_SIZE);

    for(;;) {
        // Esperar indefinidamente por un evento de UART
        if(xQueueReceive(*uart_queue, (void*)&event, portMAX_DELAY)) {
            switch(event.type) {
                // Manejar diferentes tipos de eventos aquí
                case UART_DATA:
                    uart_read_bytes(UART_NUM_PC, dtmp, event.size, portMAX_DELAY);
                    
                    //uart_write_bytes(UART_NUM_PSoC, dtmp, 1);
                    // Aquí podrías procesar los datos recibidos
                    if ((*dtmp)=='T'){ //pide al psoc que digitalize un eco
                        uart_write_bytes(UART_NUM_PSoC, dtmp, 1);
                    }
                    if ((*dtmp)=='I'){ //pide al psoc que mande el eco digitalizado, ahora esta en int16
                        uart_write_bytes(UART_NUM_PSoC, dtmp, 1);
                    }
                    if ((*dtmp)=='O'){ //el esp envia a por el puerto uart PC el eco recibido del psoc en formato int16
                        flag = 'O';
                    }  
                    if ((*dtmp)=='P'){ //el esp manda a a la pc el eco en formato float
                        flag = 'P';
                    }
                    if ((*dtmp)=='R'){ //el esp manda a a la pc el eco en formato float
                        flag = 'R';
                    }    

                    break;
                case UART_BUFFER_FULL:
                     // Tal vez registrar o tomar alguna acción para manejar el buffer lleno.
                    break;
                default:
                    // Opción para manejar cualquier caso no especificado.
                    break;
            }
        }
    }
    free(dtmp);
    dtmp = NULL;
    vTaskDelete(NULL);
    vTaskDelay(1 / portTICK_PERIOD_MS); // Espera al menos 1 tick para permitir que la tarea IDLE se ejecute

}

// Esta función se llama cada vez que ocurre un evento en UART PSoc
static void uart_PSOC_event_task(void *pvParameters) {
    
    uart_event_t event;
    QueueHandle_t *uart_queue = (QueueHandle_t *)pvParameters;
    size_t buffered_size;
    size_t i=0;
    // Asegúrate de que el buffer es suficientemente grande para el vector de 512 floats
    uint8_t* dtmp = (uint8_t*) malloc(eco_size*4); // 512 int16 * 2 bytes por int16

    for(;;) {
        // Esperar indefinidamente por un evento de UART
        if(xQueueReceive(*uart_queue, (void*)&event, portMAX_DELAY)) {
            switch(event.type) {
                case UART_DATA:
                    buffered_size = uart_read_bytes(UART_NUM_2, dtmp, eco_size*4, portMAX_DELAY);
                    // Asegúrate de haber recibido todos los bytes esperados
                    if (buffered_size == (eco_size*4)) {
                        // Aquí, dtmp contiene 2048 bytes de datos binarios, son 512 datos floats pero cada byte es recibido individualmente
                        // Copiamos los datos de dtmp a la posicion de memoria de eco_float para asi tener en eco_float los 512 datos en formato float
                        memcpy(eco_float, dtmp, (eco_size*4)); // Copiar datos a floatData

                        //ahora necesitamos convertir los datos de int16 a float
                       /* for (size_t j = 0; j < eco_size; j++)
                        {
                            eco_float[j] = adc_to_voltage(eco_16[j], vref_adc);
                        } */

                        printf("Datos leídos: esperados %d, recibidos %d, veces recibidas %d\n", eco_size * 4, buffered_size, i);
                        i++; //para saber cuantas veces se entro en este loop

                        // Ahora puedes procesar floatData que contiene los 512 floats
                       // uart_write_bytes(UART_NUM_PC, dtmp, (eco_size*4));
                    }
                    
                    break;
                case UART_BUFFER_FULL:
                    // Tal vez registrar o tomar alguna acción para manejar el buffer lleno.
                    break;
                default:
                    // Opción para manejar cualquier caso no especificado.
                    break;
            }
        }
    }
    free(dtmp);
    dtmp = NULL;
    vTaskDelete(NULL);
    vTaskDelay(1 / portTICK_PERIOD_MS); // Espera al menos 1 tick para permitir que la tarea IDLE se ejecute
}


void uart_setup(void) {
    // Configuración para PC
    uart_config_t uart_config_pc = {
        .baud_rate = 115200,
        .data_bits = UART_DATA_8_BITS,
        .parity = UART_PARITY_DISABLE,
        .stop_bits = UART_STOP_BITS_1,
        .flow_ctrl = UART_HW_FLOWCTRL_DISABLE,
    };
    uart_param_config(UART_NUM_PC, &uart_config_pc);
    //uart_driver_install(UART_NUM_PC, BUF_SIZE * 2, 0, 0, NULL, 0);
    uart_driver_install(UART_NUM_PC, BUF_SIZE, BUF_SIZE, 12, &uart0_queue, 0);

    // Configuración para PSoC
    uart_config_t uart_config_psoc = {
        .baud_rate = 115200,
        .data_bits = UART_DATA_8_BITS,
        .parity = UART_PARITY_DISABLE,
        .stop_bits = UART_STOP_BITS_1,
        .flow_ctrl = UART_HW_FLOWCTRL_DISABLE,
    };
    uart_param_config(UART_NUM_PSoC, &uart_config_psoc);
    //uart_driver_install(UART_NUM_PSoC, BUF_SIZE * 2, 0, 0, NULL, 0);
    uart_driver_install(UART_NUM_PSoC, BUF_SIZE, BUF_SIZE, 12, &uart2_queue, 0);
    uart_set_pin(UART_NUM_PSoC, TXD_PIN, RXD_PIN, UART_PIN_NO_CHANGE, UART_PIN_NO_CHANGE);

    // Configura aquí los pines específicos si no estás usando los predeterminados
    // Por ejemplo, para UART_NUM_1 y UART_NUM_2, puedes necesitar configurar los pines manualmente

    // Crear un manejador de eventos para cada UART
    xTaskCreate(uart_PC_event_task, "uart_event_task0", BUF_SIZE, (void*)&uart0_queue, 12, NULL);
    xTaskCreate(uart_PSOC_event_task, "uart_event_task2", BUF_SIZE, (void*)&uart2_queue, 12, NULL);

}

void app_main(void) {
    uart_setup(); // Configuramos los UARTs

    while (1) {

        switch (flag)
        {
        case 'O': //se enviar por el puerto uart PC el eco recibido del psoc en formato int16
            //uart_write_bytes(UART_NUM_PC, eco_16, (eco_size));
            for (size_t j = 0; j < eco_size; j++)
            {
                printf("%hd\r\n", eco_16[j]);
            }
            flag = '0';
            break;

        case 'P': //se enviar por el puerto uart PC el eco recibido del psoc en formato float
            for (size_t j = 0; j < eco_size; j++)
            {
                printf("%f\r\n", eco_float[j]);
            }
            flag = '0';
            break;

        case 'R': //se enviar por el puerto uart PC el eco reconstruido

            reconstruccion();

            for (size_t j = 0; j < eco_size*M; j++)
            {
                printf("%f\r\n", eco_reconstruido[j]);
            }
            flag = '0';
            break;
        
        default:
            break;
        }


        vTaskDelay(pdMS_TO_TICKS(100)); // Espera de 100 ms, para que no se triggere el watchdog de los task al pedo
        
    }
}
