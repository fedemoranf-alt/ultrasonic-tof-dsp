#include <Arduino.h>

//sistema de archivos para guardar datos en la flash del esp 
#include "SPIFFS.h"

#include <WiFi.h>
#include <ThingSpeak.h>
//para el sensor de temperatura DS18B20
#include <OneWire.h>
#include <DallasTemperature.h>

// Declaraciones y funciones para el filtro interpolador
#define NUM_TAPS_interpolador 128
#define BLOCK_SIZE_int 32
#define M 25
#define min_ventana (35)
#define max_ventana (105)
#define TOTAL_SAMPLES_INTERPOLADO (1750) //((max_ventana - min_ventana)*M) //cantidad de datos de ventana por M
#define NUM_TAPS_hilbert (61)
#define SIZE_INDICES_PATRON (10) 
#define CANTIDAD_MEDIDAS_STD (10) //cantidad de medidas a ser tomadas de seguido para calcular la std 
#define SIZE_CORRELACION (2517) //TOTAL_SAMPLES_INTERPOLADO + PATRON_MAX_SIZE -1

#define ECO_SIZE 256                   // Número de floats a recibir
#define ECO_SIZE_BYTES (256*sizeof(float))         // Número de floats a recibir
#define PATRON_MAX_SIZE (768)
#define PATRON_SIZE_BYTES (768*sizeof(float))

#define TXD_PIN GPIO_NUM_17
#define RXD_PIN GPIO_NUM_16

// Pin donde está conectado el pin de datos del DS18B20
#define ONE_WIRE_BUS 4
// Configuración del bus OneWire y del sensor DS18B20
OneWire oneWire(ONE_WIRE_BUS);
DallasTemperature sensors(&oneWire);
float temperatura_up[CANTIDAD_MEDIDAS_STD] = {0.0};
float temperatura_down[CANTIDAD_MEDIDAS_STD] = {0.0};
float temperatura_media = 0.0;


//buffers para recepcion de datos por el UART
uint8_t buffer[PATRON_SIZE_BYTES];               // Buffer para almacenar los datos binarios recibidos de la pc
uint8_t buffer_psoc[ECO_SIZE * 4]; //buffer para el uart psoc

//para sistema de archivos de la flash
const char* path_patron_up = "/parton_up.bin";  // Nombre del archivo
const char* path_patron_down = "/parton_down.bin";  // Nombre del archivo
File file;

//variables globales
float eco_float[ECO_SIZE];
float eco_reconstruido[(TOTAL_SAMPLES_INTERPOLADO + NUM_TAPS_interpolador)];
float envolvente_derivada[(TOTAL_SAMPLES_INTERPOLADO)];
float eco_interpolado[(TOTAL_SAMPLES_INTERPOLADO + NUM_TAPS_interpolador)];
//correlacion
float correlacion[SIZE_CORRELACION];
float indice_referencia =0;
float indice_medida=0;
float indice_upstream[CANTIDAD_MEDIDAS_STD] ={0};
float indice_downstream[CANTIDAD_MEDIDAS_STD] ={0};
float media = 0;
float std_upstream =0.0;
float std_downstream =0.0;
uint8_t count_tof =  0; //CONTADOR PARA TOMAR VARIAS MEDIDAS PARA PODES CALCULAR LA MEDIA Y LA STD 
float v_onda;
float v_flujo;
float L =  0.0643; //0.091*cos(pi/4), la distancia entre los transductores es 0.091 metros(9.1cm)

float TOF_up[CANTIDAD_MEDIDAS_STD] = {0.0};
float TOF_down[CANTIDAD_MEDIDAS_STD] = {0.0};
float TOF_moda_up = 0.0;
float TOF_moda_down = 0.0;
float delta_tof = 0.0; 
float distancia_up[CANTIDAD_MEDIDAS_STD] = {0.0};
float distancia_down[CANTIDAD_MEDIDAS_STD] = {0.0};
float distancia_media_up = 0.0;
float distancia_media_down = 0.0;


//Patron
float patron_up[PATRON_MAX_SIZE];
float patron_down[PATRON_MAX_SIZE];
uint16_t indice_inicial_patron = 0;
uint16_t indice_final_patron = 0;
char indices_patron[10];
// Declaración de punteros para las variables dinamicas
//float *eco_interpolado;
float eco_hilbert[(TOTAL_SAMPLES_INTERPOLADO + NUM_TAPS_interpolador)];
float aux_vector[(TOTAL_SAMPLES_INTERPOLADO + NUM_TAPS_interpolador)];

hw_timer_t * timer = NULL;
portMUX_TYPE timerMux = portMUX_INITIALIZER_UNLOCKED;
volatile bool ejecutar_medicion_automatica = false;
uint8_t count_medida =0;



// ThingSpeak channel where the statistical data (mean, std, TOF, flow velocity) is sent.
// Replace with your own channel number and Write API key. Do NOT commit real values.
unsigned long myChannelNumber = 0;                       // <-- your ThingSpeak channel ID
const char* myWriteAPIKey = "YOUR_THINGSPEAK_WRITE_API_KEY";

// WiFi credentials -- replace with your own. Do NOT commit real credentials.
const char* ssid     = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";

long rssi;
WiFiClient client;

// Configuración del servidor NTP
const char* ntpServer = "pool.ntp.org";
long gmtOffset_sec = -14400;  // GMT-4 (Paraguay estándar)
int daylightOffset_sec = 3600; // 1 hora extra en horario de verano (GMT-3)


  //filtro reconstructor sintonizado entre 0.085 y 0.12, con ganancia de 1000 PARA MUESTREO A 800KHz
  const float firCoeffs32_interpolador[NUM_TAPS_interpolador] = { 
    0.0085,   -0.0777,   -0.1312,   -0.1488,   -0.1316,   -0.0856,   -0.0231,    0.0380,
    0.0750,    0.0635,   -0.0183,   -0.1835,   -0.4308,   -0.7393,   -1.0666,   -1.3497,
   -1.5114,   -1.4707,   -1.1575,   -0.5287,    0.4161,    1.6232,    2.9796,    4.3175,
    5.4288,    6.0898,    6.0932,    5.2838,    3.5929,    1.0655,   -2.1255,   -5.6819,
   -9.2021,  -12.2213,  -14.2674,  -14.9253,  -13.9022,  -11.0841,   -6.5741,   -0.7053,
    5.9761,   12.7587,   18.8412,   23.4264,   25.8241,   25.5486,   22.3974,   16.4998,
    8.3252,   -1.3506,  -11.5209,  -21.0581,  -28.8443,  -33.9084,  -35.5503,  -33.4383,
  -27.6628,  -18.7416,   -7.5708,    4.6711,   16.6564,   27.0621,   34.7267,   38.7883,
   38.7883,   34.7267,   27.0621,   16.6564,    4.6711,   -7.5708,  -18.7416,  -27.6628,
  -33.4383,  -35.5503,  -33.9084,  -28.8443,  -21.0581,  -11.5209,   -1.3506,    8.3252,
   16.4998,   22.3974,   25.5486,   25.8241,   23.4264,   18.8412,   12.7587,    5.9761,
   -0.7053,   -6.5741,  -11.0841,  -13.9022,  -14.9253,  -14.2674,  -12.2213,   -9.2021,
   -5.6819,   -2.1255,    1.0655,    3.5929,    5.2838,    6.0932,    6.0898,    5.4288,
    4.3175,    2.9796,    1.6232,    0.4161,   -0.5287,   -1.1575,   -1.4707,   -1.5114,
   -1.3497,   -1.0666,   -0.7393,   -0.4308,   -0.1835,   -0.0183,    0.0635,    0.0750,
    0.0380,   -0.0231,   -0.0856,   -0.1316,   -0.1488,   -0.1312,   -0.0777,    0.0085};


const float firCoeffs_hilbert[NUM_TAPS_hilbert] = {
    -0.0000,   -0.0067,   -0.0000,   -0.0088,   -0.0000,   -0.0112,   -0.0000,   -0.0141,
   -0.0000,   -0.0175,   -0.0000,   -0.0215,   -0.0000,   -0.0264,   -0.0000,   -0.0325,
   -0.0000,   -0.0402,   -0.0000,   -0.0503,   -0.0000,   -0.0644,   -0.0000,   -0.0860,
   -0.0000,   -0.1237,   -0.0000,   -0.2100,   -0.0000,   -0.6359,         0,    0.6359,
    0.0000,    0.2100,    0.0000,    0.1237,    0.0000,    0.0860,    0.0000,    0.0644,
    0.0000,    0.0503,    0.0000,    0.0402,    0.0000,    0.0325,    0.0000,    0.0264,
    0.0000,    0.0215,    0.0000,    0.0175,    0.0000,    0.0141,    0.0000,    0.0112,
    0.0000,    0.0088,    0.0000,    0.0067,    0.0000,};



const float firCoeffs_suavizador_env[NUM_TAPS_hilbert] = {0.0022,
    0.0023,    0.0025,    0.0029,    0.0034,    0.0040,    0.0048,    0.0057,    0.0068,
    0.0079,    0.0091,    0.0105,    0.0119,    0.0134,    0.0149,    0.0164,    0.0180,
    0.0195,    0.0210,    0.0225,    0.0239,    0.0252,    0.0265,    0.0276,    0.0286,
    0.0295,    0.0302,    0.0308,    0.0312,    0.0314,    0.0315,    0.0314,    0.0312,
    0.0308,    0.0302,    0.0295,    0.0286,    0.0276,    0.0265,    0.0252,    0.0239,
    0.0225,    0.0210,    0.0195,    0.0180,    0.0164,    0.0149,    0.0134,    0.0119,
    0.0105,    0.0091,    0.0079,    0.0068,    0.0057,    0.0048,    0.0040,    0.0034,
    0.0029,    0.0025,    0.0023,    0.0022 };

//para la funcion find max
typedef struct {
  uint16_t indice;
  float valor;
} struct_max;
struct_max pico_max;

// Función para encontrar el valor del pico máximo de una secuencia
struct_max find_max(float *sequence, uint16_t length, uint16_t inicio) {
  struct_max maximo;
  maximo.valor= sequence[inicio];
  maximo.indice = inicio;
  uint16_t i;
  for ( i = inicio + 1; i < length; i++) {
      if (sequence[i] > maximo.valor) {
          maximo.valor = sequence[i];
          maximo.indice = i;
      }
  }
  return maximo;
}

void apply_fir_filter(float *input, float *output, int input_len, int firCoeff_len, const float *firCoeff) {
  uint16_t i;
  for (i = 0; i < (input_len + firCoeff_len - 1); i++) {
      output[i] = 0.0;
  }
  for (int i = 0; i < input_len; i++) {
      for (int j = 0; j < firCoeff_len; j++) {
          output[i + j] += input[i] * firCoeff[j];
      }
  }
}


// Función para calcular la correlación cruzada con vectores de tipo float
/*void correlacion_cruzada(float *x_patron, float *y) {
    int16_t lag, i, j;
    uint16_t N = PATRON_MAX_SIZE;
    uint16_t M_corr = TOTAL_SAMPLES_INTERPOLADO;
    uint16_t L = SIZE_CORRELACION;
    // Inicializar la correlación en cero
    for (i = 0; i < L; i++) {
        correlacion[i] = 0.0;
    }

    // Calcular la correlación cruzada de manera simétrica
    for (lag = -(N - 1); lag < M_corr; lag++) { // Considera desplazamientos negativos y positivos
        for (i = 0; i < N; i++) {
            j = lag + i; // Índice en el segundo vector
            
            if (j >= 0 && j < M_corr) { // Verificar límites de y
                correlacion[L - (lag + (N - 1)) - 1] += x_patron[i] * y[j];              
              //  Serial.println((L - (lag + (N - 1)) - 1));
                if((L - (lag + (N - 1)) - 1) > SIZE_CORRELACION || (L - (lag + (N - 1)) - 1) < 0){
                  Serial.println("Error en la correlaccion");
                  Serial.println((L - (lag + (N - 1)) - 1));
                }
                
            }
          }

    }  
}*/

/*
// Función para calcular la correlación cruzada con vectores de tipo float
void correlacion_cruzada(float *x_patron, float *y) {
  int16_t lag, i, j;
  uint16_t N = PATRON_MAX_SIZE;             // Tamaño del patrón
  uint16_t M_corr = TOTAL_SAMPLES_INTERPOLADO;   // Tamaño de la señal larga
  uint16_t L = SIZE_CORRELACION;            // Tamaño del resultado: N + M - 1

  // Inicializar la correlación en cero
  for (i = 0; i < L; i++) {
      correlacion[i] = 0.0f;
  }

  // Calcular la correlación cruzada
  for (lag = -(N - 1); lag <= (M_corr - 1); lag++) {
      for (i = 0; i < N; i++) {
          j = lag + i;

          // Verificar que j esté dentro de los límites válidos
          if (j >= 0 && j < M_corr) {
              int16_t index = lag + (N - 1);               // índice estilo MATLAB
              int16_t mirrored_index = L - 1 - index;      // reflejar para igualar a xcorr(x, y)
              
              if (mirrored_index >= 0 && mirrored_index < L) {
                  correlacion[mirrored_index] += x_patron[i] * y[j];
              }
          }
      }
  }
}*/

void correlacion_cruzada(float *y, float *x) {  // y: señal, x: patrón
  int16_t lag, i, j;
  uint16_t N = PATRON_MAX_SIZE;              // Tamaño del patrón x
  uint16_t M_corr = TOTAL_SAMPLES_INTERPOLADO;    // Tamaño de la señal y
  uint16_t L = SIZE_CORRELACION;             // N + M - 1

  for (int i = 0; i < L; i++) {
      correlacion[i] = 0.0f;
  }

  for (lag = -(N - 1); lag <= (M_corr - 1); lag++) {
      for (i = 0; i < N; i++) {
          j = lag + i;
          if (j >= 0 && j < M_corr) {
              int16_t index = lag + (N - 1);
              if (index >= 0 && index < L) {
                  correlacion[index] += x[i] * y[j];
              }
          }
      }
  }
}



/**
 * Función para calcular la media de un vector
 */
float calcularMedia(float *datos, int16_t longitud) {
  float suma = 0;
  for(uint16_t i = 0; i < longitud; i++) {
      suma += datos[i];
  }
  return suma / longitud; 
}

// Función para calcular la moda de un conjunto de datos flotantes (convertidos a int16_t)
int16_t moda_histograma_int(float *datos, int n) {
  int i;
  int16_t min = INT16_MAX, max = INT16_MIN;

  // Encontrar mínimo y máximo en los datos (casteo a int16_t)
  for (i = 0; i < n; i++) {
      int16_t valor = (int16_t)datos[i];  // Casteo seguro
      if (valor < min) min = valor;
      if (valor > max) max = valor;
  }

  int rango = max - min + 1; // Tamaño del histograma basado en valores enteros

  // Validar que el rango no sea demasiado grande
  if (rango > 10000) {  // Ajusta este límite según tu sistema
      printf("Error: Rango de valores demasiado grande para manejarlo eficientemente.\n");
      return -1;
  }

  // Asignar memoria dinámicamente al histograma
  int *histograma = (int *)calloc(rango, sizeof(int));
  if (!histograma) {
      printf("Error al asignar memoria\n");
      return -1;
  }

  // Construcción del histograma
  for (i = 0; i < n; i++) {
      int16_t valor = (int16_t)datos[i];  // Casteo seguro
      histograma[valor - min]++;
  }

  // Encontrar el valor con mayor frecuencia (moda)
  int max_freq = 0;
  int16_t moda_valor = min;
  for (i = 0; i < rango; i++) {
      if (histograma[i] > max_freq) {
          max_freq = histograma[i];
          moda_valor = min + i; // Convertir índice a valor original
      }
  }

  free(histograma); // Liberar memoria dinámica
  return moda_valor;
}



/**
* Función para calcular la desviación estándar muestral.
* 
*/
float calcularDesviacionEstandar(float *datos,int16_t longitud) {
  float media = calcularMedia(datos, longitud);
  float sumaCuadrados = 0.0;
  float diferencia = 0;
  for(uint16_t i = 0; i < longitud; i++) {
      diferencia = datos[i] - media;
      sumaCuadrados += diferencia * diferencia;
  }

  // Desviación estándar muestral: dividir entre (n - 1) y hacer raíz cuadrada
  return sqrtf(sumaCuadrados / (longitud - 1)); 
}

// PROCESAMIENTO 
float signalProcessing(float *patron_sigproc) {
  uint16_t indexx = 0;
  uint16_t j,i;
  float indice_medida_sp = 0.0;
  float promedio = 0.0;
      //para sacar el voltaje de continua(Valor medio):
      promedio = 0.0;
      for (i = 0; i < ECO_SIZE; i++) {
          promedio += eco_float[i];
      }
      promedio = promedio / ECO_SIZE;
      for (i = 0; i < ECO_SIZE; i++) {
          eco_float[i] = eco_float[i] - promedio;
      }

      //Normalicemos el array de datos digitalizados a 1 antes de realizar la interpolacion
      pico_max = find_max(eco_float, ECO_SIZE,min_ventana);
      for (int16_t i = 1; i < ECO_SIZE; ++i) {
          eco_float[i] = eco_float[i]/pico_max.valor;
      } 

      for (i = 0; i < (TOTAL_SAMPLES_INTERPOLADO + NUM_TAPS_interpolador); i++) { //aqui se toma una ventana 
        eco_interpolado[i] = 0.0;
      }

      //se interpola el eco con un retenedor de orden cero con M=25
      for (i = min_ventana,  indexx = 0; i <= max_ventana; i++, indexx += M) { 
          eco_interpolado[indexx] = eco_float[i];  // Fija el valor en el lugar correcto
      }
      
      
      //se reconstruye el eco con un filro low pass 
      apply_fir_filter(eco_interpolado,eco_reconstruido, (TOTAL_SAMPLES_INTERPOLADO), NUM_TAPS_interpolador, firCoeffs32_interpolador);
      //aplicamos el filtro de hilbert al eco reconstruido para obtener la señal en cuadratura (desfasada 90 grados)
      apply_fir_filter(eco_reconstruido,aux_vector, (TOTAL_SAMPLES_INTERPOLADO), NUM_TAPS_hilbert, firCoeffs_hilbert);
      //compensamos el retardo de grupo introducido por el filtro fir
      memcpy(eco_hilbert, aux_vector + (30), (TOTAL_SAMPLES_INTERPOLADO)*sizeof(float));
      
      //calculamos la envolvente del eco reconstruido
      for (i = 0; i < TOTAL_SAMPLES_INTERPOLADO; i++) {
          envolvente_derivada[i] = sqrtf(powf(eco_reconstruido[i],2) + powf(eco_hilbert[i],2));
      } 


      // antes de realizar la derivada realizamos un filtrado a la envolvente para suavizarla, con un filtro fir paso bajos de 61 taps con frecuencia de corte de 100k:
      apply_fir_filter(envolvente_derivada,aux_vector, (TOTAL_SAMPLES_INTERPOLADO), NUM_TAPS_hilbert, firCoeffs_suavizador_env);

      //ahora derivamos la envolvente
      envolvente_derivada[0] = 0.0;
      for(j=1; j<TOTAL_SAMPLES_INTERPOLADO; j++) {
        envolvente_derivada[j] = 0.9907*aux_vector[j] - 0.9907*aux_vector[j-1] + 0.9813*envolvente_derivada[j-1]; 
      }
      
      //luego realizamos le correlacion de la derivada de la envolvente con el patron seleccionado previamente
      //correlacion_cruzada(patron_sigproc,envolvente_derivada);
      correlacion_cruzada(envolvente_derivada,patron_sigproc);
      //hayamos el pico maximo de la correlacion para luego calcular el tiempo de vuelo
      pico_max = find_max(correlacion,SIZE_CORRELACION,0);
      int16_t lag = pico_max.indice - (PATRON_MAX_SIZE - 1); // lag relativo, puede ser positivo o negativo

      //indice_medida_sp = (float)pico_max.indice;
      indice_medida_sp = lag;
      return indice_medida_sp;
}



//Funcion de servicio a la interrupcion del timer, pone en true la variable logica que
// inicia la medicion automatica de datos cada 10 minutos
//la idea es que se realice una tanda de 10 medidas cada 10 minutos
void IRAM_ATTR onTimer() {
  portENTER_CRITICAL_ISR(&timerMux);
  ejecutar_medicion_automatica = true;
  portEXIT_CRITICAL_ISR(&timerMux);
}

/*  INITWIFI:
    -Funcion que se encaarga de inicializar el modulo wifi y de conectar el modulo a la red especificada en el ssid con su respectivo password
*/
void initWiFi() {
  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi ..");
  while (WiFi.status() != WL_CONNECTED) {
  Serial.print('.');
  delay(1000);
  }
  Serial.println(WiFi.localIP());
}

/*  ENVIAR_DATOS_THINGSPEAK ACA ENVIMOS A UN CANAL CON DATOS ESTADISTICOS 
    -Esta funcion se encarga de enviar el dato en la variable TOF a la nube de thingSpeak
*/
void enviar_datos_ThingSpeak(){
  const int MAX_REINTENTOS = 3;
  int intento = 0;
  int statusCode = -1;
  // Liberar memoria para evitar problemas de overflow
  //ThingSpeak.clearFields();

  // Enviar datos a ThingSpeak

  //statusCode = ThingSpeak.writeField(myChannelNumber, 1, media, myWriteAPIKey); //se envia el dato dentro de la varible TOF
    // Asignamos cada valor a un campo
  ThingSpeak.setField(1, TOF_moda_up);
  ThingSpeak.setField(2, temperatura_media);
  ThingSpeak.setField(3, TOF_moda_down);
  ThingSpeak.setField(4, std_upstream);
  ThingSpeak.setField(5, std_downstream);
  ThingSpeak.setField(6, (TOF_moda_up - TOF_moda_down));
  ThingSpeak.setField(7, v_flujo);
  ThingSpeak.setField(8, v_onda);
  // Enviamos todos los campos en una sola llamada
  while (intento < MAX_REINTENTOS) {
    statusCode = ThingSpeak.writeFields(myChannelNumber, myWriteAPIKey);

    if (statusCode == 200) {
      Serial.println("Datos enviados correctamente a ThingSpeak");
      break; // Salimos del bucle si se envió correctamente
    } else {
      Serial.print("Error en ThingSpeak (código ");
      Serial.print(statusCode);
      Serial.println("), reintentando...");
      intento++;
      delay(3000); // Esperar un poco antes de reintentar
    }
  }

  if (statusCode != 200) {
    Serial.println("No se pudo enviar datos a ThingSpeak tras varios intentos.");
  }

}

void setup() {
  Serial.begin(115200);
  Serial2.begin(115200, SERIAL_8N1, RXD_PIN, TXD_PIN);
  Serial2.setTimeout(3000);  // 3 segundos
  // Espera a que el puerto serial se inicialice
  while (!Serial) {
      vTaskDelay(10 / portTICK_PERIOD_MS);
  }

  // Iniciar el sensor DS18B20
  sensors.begin();
  // Ajusta la resolución a 12 bits para todos los dispositivos conectados
  sensors.setResolution(12);

  // Inicializar SPIFFS
  if (!SPIFFS.begin(true)) {
    Serial.println("Error al montar SPIFFS");
    return;
  }

  // Leer el vector PATRON_UP de la memoria flash
  file = SPIFFS.open(path_patron_up, FILE_READ);
  if (file) {
      file.read((uint8_t*)patron_up, sizeof(patron_up));
      file.close();
   //   Serial.println("Vector de floats leído de SPIFFS:");
  } else {
      Serial.println("Error al abrir el archivo para leer.");
  }

   // Leer el vector PATRON_DOWN de la memoria flash
   file = SPIFFS.open(path_patron_down, FILE_READ);
   if (file) {
       file.read((uint8_t*)patron_down, sizeof(patron_down));
       file.close();
    //   Serial.println("Vector de floats leído de SPIFFS:");
   } else {
       Serial.println("Error al abrir el archivo para leer.");
   }

  initWiFi();
  rssi = WiFi.RSSI();
  Serial.print("RRSI: ");
  Serial.println(rssi);
  Serial.println(" dBm");
  Serial.println("Conectado al WiFi");
  ThingSpeak.begin(client);  // Inicializar ThingSpeak
  analogReadResolution(12); // Resolución ADC de 12 bits (0-4095)


  // Timer 0, prescaler de 80 → 1 tick = 1 microsegundo
  timer = timerBegin(0, 80, true);  

  // Llama a onTimer cada 600,000,000 microsegundos (10 minutos)
  timerAttachInterrupt(timer, &onTimer, true);
  timerAlarmWrite(timer, 300000000, true); // true → modo repetitivo
  //600000000 us = 10min , 60000000 us = 1min
  timerAlarmEnable(timer);

}

String obtenerFechaHora() {
  struct tm timeinfo;
  if (!getLocalTime(&timeinfo)) {
      return "00/00/0000 00:00:00";  // Si falla, devuelve un valor por defecto
  }
  
  char buffer[20];
  strftime(buffer, sizeof(buffer), "%d/%m/%Y %H:%M:%S", &timeinfo);
  return String(buffer);
}


void uartDatalogger_up(uint indice) {
  int16_t j;
  String fechaHora;
  
  fechaHora = obtenerFechaHora();
  Serial.println("Start_Measurement");
  Serial.println("Fecha_Hora: " + fechaHora);  // Enviar fecha y hora
  Serial.print("Count_tof: ");
  Serial.println(count_tof);
  Serial.println("Start_Float_up");
  for ( j = 0; j < ECO_SIZE; j++) Serial.println(eco_float[j]);
  Serial.println("End_Float_up");

  Serial.println("Start_Reconstruido_up");
  for ( j = 0; j < TOTAL_SAMPLES_INTERPOLADO; j++) Serial.println(eco_reconstruido[j]);
  Serial.println("End_Reconstruido_up");

  Serial.println("Start_Envolvente_up");
  for ( j = 0; j < TOTAL_SAMPLES_INTERPOLADO; j++) Serial.println(envolvente_derivada[j]);
  Serial.println("End_Envolvente_up");

  Serial.println("Start_Correlacion_up");
  for ( j = 0; j < (SIZE_CORRELACION) - 1; j++) Serial.println(correlacion[j]);
  Serial.println("End_Correlacion_up");

  Serial.println("Start_Temp_up");
  Serial.println(temperatura_up[indice]);
  Serial.println("End_Temp_up");

  Serial.println("Start_Tof_up");
  Serial.println(indice_upstream[indice]);
  Serial.println("End_Tof_up");

  Serial.println("End_up");
}

void uartDatalogger_down(uint indice) {
    int16_t j;

Serial.println("Start_Float_down");
for ( j = 0; j < ECO_SIZE; j++) Serial.println(eco_float[j]);
Serial.println("End_Float_down");

Serial.println("Start_Reconstruido_down");
for (j = 0; j < TOTAL_SAMPLES_INTERPOLADO; j++) Serial.println(eco_reconstruido[j]);
Serial.println("End_Reconstruido_down");

Serial.println("Start_Envolvente_down");
for ( j = 0; j < TOTAL_SAMPLES_INTERPOLADO; j++) Serial.println(envolvente_derivada[j]);
Serial.println("End_Envolvente_down");

Serial.println("Start_Correlacion_down");
for ( j = 0; j < (SIZE_CORRELACION) - 1; j++) Serial.println(correlacion[j]);
Serial.println("End_Correlacion_down");

Serial.println("Start_Temp_down");
Serial.println(temperatura_down[indice]);
Serial.println("End_Temp_down");

Serial.println("Start_Tof_down");
Serial.println(indice_downstream[indice]);
Serial.println("End_Tof_down");

Serial.println("End_down");

Serial.println("End_Measurement");
}

void loop() {
  u_int16_t i;
  char command2;
  // Si hay datos disponibles en el puerto serial
  if (Serial.available()) {
    char command = Serial.read();
    
      if (command == '1') { //se recibe un ECO, ESTO ES SOLO PARA SIMULACIONES 
          // Comando para recibir un vector de 256 floats
          // Envía la señal de "listo" al host
          Serial.println("G");
          Serial.flush();  // Se asegura que la señal se envíe antes de leer datos
          
          int bytes_received = 0;
          // Lee hasta que se hayan recibido todos los bytes esperados
          while (bytes_received < ECO_SIZE_BYTES) {
              if (Serial.available()) {
                  int to_read = Serial.available();
                  if (to_read > (ECO_SIZE_BYTES - bytes_received)) {
                  to_read = ECO_SIZE_BYTES - bytes_received;
                  }
                  int n = Serial.readBytes(buffer + bytes_received, to_read);
                  bytes_received += n;
              }
              vTaskDelay(10 / portTICK_PERIOD_MS);
          }
          
          // Copia los datos binarios al vector de floats
          memcpy(eco_float, buffer, ECO_SIZE_BYTES);
          signalProcessing(patron_up);
      
          
      }else if (command == '2') { //PARTON UP
          // Comando para recibir un vector de 768 floats, el patron 
          // Envía la señal de "listo" al host
          Serial.println("G");
          Serial.flush();  // Se asegura que la señal se envíe antes de leer datos
          
          int bytes_received = 0;
          // Lee hasta que se hayan recibido todos los bytes esperados
          while (bytes_received < PATRON_SIZE_BYTES) {
              if (Serial.available()) {
                  int to_read = Serial.available();
                  if (to_read > (PATRON_SIZE_BYTES - bytes_received)) {
                  to_read = PATRON_SIZE_BYTES - bytes_received;
                  }
                  int n = Serial.readBytes(buffer + bytes_received, to_read);
                  bytes_received += n;
              }
              vTaskDelay(10 / portTICK_PERIOD_MS);
          }
          
          // Copia los datos binarios al vector de floats
          memcpy(patron_up, buffer, PATRON_SIZE_BYTES);
          //aqui se procede a guardar en la flash el patron para la correlacion 
          // Guardar el vector en la memoria flash
          file = SPIFFS.open(path_patron_up, FILE_WRITE);
          if (file) {
              file.write((uint8_t*)patron_up, sizeof(patron_up));
              file.close();
            //  Serial.println("Vector guardado en SPIFFS.");
          } else {
              Serial.println("Error al abrir el archivo para escribir.");
          }

        }else if (command == '3') { //PARTON DOWN
          // Comando para recibir un vector de 768 floats, el patron 
          // Envía la señal de "listo" al host
          Serial.println("G");
          Serial.flush();  // Se asegura que la señal se envíe antes de leer datos
          
          int bytes_received = 0;
          // Lee hasta que se hayan recibido todos los bytes esperados
          while (bytes_received < PATRON_SIZE_BYTES) {
              if (Serial.available()) {
                  int to_read = Serial.available();
                  if (to_read > (PATRON_SIZE_BYTES - bytes_received)) {
                  to_read = PATRON_SIZE_BYTES - bytes_received;
                  }
                  int n = Serial.readBytes(buffer + bytes_received, to_read);
                  bytes_received += n;
              }
              vTaskDelay(10 / portTICK_PERIOD_MS);
          }
          
          // Copia los datos binarios al vector de floats
          memcpy(patron_down, buffer, PATRON_SIZE_BYTES);
          //aqui se procede a guardar en la flash el patron para la correlacion 
          // Guardar el vector en la memoria flash
          file = SPIFFS.open(path_patron_down, FILE_WRITE);
          if (file) {
              file.write((uint8_t*)patron_down, sizeof(patron_down));
              file.close();
            //  Serial.println("Vector guardado en SPIFFS.");
          } else {
              Serial.println("Error al abrir el archivo para escribir.");
          }

      }else if (command == '4') {
        timerAlarmDisable(timer); //desabilita la alarma para la interrupcion del timer 
        Serial.println("Timer desabilitado");
      }else if (command == '5') {
        timerWrite(timer, 0);          // Reinicia el contador
        timerAlarmEnable(timer);       // Habilita la alarma nuevamente
        Serial.println("Timer Habilitado");
      }else if (command == '9') {
        timerAlarmDisable(timer); //desabilita la alarma para la interrupcion del timer 
        ejecutar_medicion_automatica = true;
        Serial.println("Timer desabilitado, Iniciando Tanda de medicion de datos.");
      }else if (command == 'P') {
          // Comando para enviar de vuelta el vector recibido (eco)
          for ( i = 0; i < ECO_SIZE; i++) {
          Serial.println(eco_float[i]);
          }
      }else if (command == 'X') {
          // Comando para enviar el patron up
          for ( i = 0; i < PATRON_MAX_SIZE; i++) {
          Serial.println(patron_up[i]);
          }
      }else if (command == 'Z') {
          // Comando para enviar el patron down
          for ( i = 0; i < PATRON_MAX_SIZE; i++) {
          Serial.println(patron_down[i]);
          }
      }else if (command == 'C') {
          // Comando para enviar de el eco reconstruido
          for ( i = 0; i < TOTAL_SAMPLES_INTERPOLADO; i++) {
          Serial.println(eco_reconstruido[i]);
          
          }
      }else if (command == 'D') {
          // Comando para enviar la envolvente interpolada
          for ( i = 0; i < TOTAL_SAMPLES_INTERPOLADO; i++) {
          Serial.println(envolvente_derivada[i]);
          
          }
      }else if (command == 'V') {
          // Comando para enviar la correlacion 
          for ( i = 0; i < SIZE_CORRELACION; i++) {
          Serial.println(correlacion[i]);
          }
      }else if (command == 'K') {
          // Comando para enviar los resultados de las medidas de tof 
          for ( i = 0; i < CANTIDAD_MEDIDAS_STD; i++) {
            Serial.println(indice_upstream[i]);
          }
          for ( i = 0; i < CANTIDAD_MEDIDAS_STD; i++) {
            Serial.println(indice_downstream[i]);
          }
      }else if (command == 'B') {
          // Comando para enviar el eco interpolado
          for ( i = 0; i < TOTAL_SAMPLES_INTERPOLADO; i++) {
            Serial.println(eco_interpolado[i]);
          }
          //COMANDOS PARA EL PSOC
      }else if (command == 'T') {
          //pide al psoc que emita un pulso e inicie el muestreo, luego pase los datos al esp
          Serial2.print('T');
          
          int n = Serial2.readBytes(&command2, 1);// Bloqueante: espera 1 bytes o hasta timeout;

          if (command2 == 'H') { //acknowledge para el psoc
              // Comando para recibir un vector de 256 floats
              // Envía la señal de "listo" al host
            //  Serial.println("Recibido aviso del PSoC.");
              Serial2.print("G"); //a
              Serial2.flush();  // Se asegura que la señal se envíe antes de leer datos
              
              int bytes_received2 = 0;
              // Lee hasta que se hayan recibido todos los bytes esperados
              while (bytes_received2 < ECO_SIZE_BYTES) {
                  if (Serial2.available()) {
                      int to_read2 = Serial2.available();
                      if (to_read2 > (ECO_SIZE_BYTES - bytes_received2)) {
                      to_read2 = ECO_SIZE_BYTES - bytes_received2;
                      }
                      int n2 = Serial2.readBytes(buffer_psoc + bytes_received2, to_read2);
                      bytes_received2 += n2;
                  }
                  vTaskDelay(10 / portTICK_PERIOD_MS);
              }
              
              // Copia los datos binarios al vector de floats
              memcpy(eco_float, buffer_psoc, ECO_SIZE_BYTES);
              indice_medida = signalProcessing(patron_up);
              Serial.println("H"); //se avisa a la pc que se tiene la medida lista para ser enviada 
            }
        }else if (command == 'L') {
          // Comando para enviar a la pc el tof de la ultima medida unica realizada
          Serial.println(indice_medida);
          //COMANDOS PARA EL PSOC
        }else if (command == 'Q') {
          // pide al psoc que realice el switcheo de los canales de los multiplexores
          Serial2.print('Q');
        }else if (command == 'W') {
          // para setear el lado del mux que es upstream
          Serial2.print('W');
        }else if (command == 'R') {
          // Comando para enviar a la pc la temperatura actual
          sensors.requestTemperatures();
          // Leer la temperatura en grados Celsius:
          Serial.println(sensors.getTempCByIndex(0));
        }
    }  

    if (ejecutar_medicion_automatica) {
      portENTER_CRITICAL(&timerMux);
      ejecutar_medicion_automatica = false;
      portEXIT_CRITICAL(&timerMux);
     
      
      
      for ( count_medida = 0; count_medida < CANTIDAD_MEDIDAS_STD ; count_medida++)
      {
        //SE REALIZA LA MEDIDA UPSTREAM:

        Serial2.print('W'); //seteamos el mux del lado upstream
        vTaskDelay(100 / portTICK_PERIOD_MS);

        //pide al psoc que emita un pulso e inicie el muestreo, luego pase los datos al esp
        Serial2.print('T');
        int n = Serial2.readBytes(&command2, 1);// Bloqueante: espera 1 bytes o hasta timeout;
        //el psoc envia el char H cuando ya tiene el dato listo para enviar
        if (command2 == 'H') { //acknowledge para el psoc
            Serial2.print("G"); //El esp le pide al psoc que envie los datos de la medida
            Serial2.flush();  // Se asegura que la señal se envíe antes de leer datos
            //El esp queda a la espera de los datos:
            int bytes_received2 = 0;
            // Lee hasta que se hayan recibido todos los bytes esperados
            while (bytes_received2 < ECO_SIZE_BYTES) {
                if (Serial2.available()) {
                    int to_read2 = Serial2.available();
                    if (to_read2 > (ECO_SIZE_BYTES - bytes_received2)) {
                    to_read2 = ECO_SIZE_BYTES - bytes_received2;
                    }
                    int n2 = Serial2.readBytes(buffer_psoc + bytes_received2, to_read2);
                    bytes_received2 += n2;
                }
                vTaskDelay(10 / portTICK_PERIOD_MS);
            }
            
            // Copia los datos binarios al vector de floats
            memcpy(eco_float, buffer_psoc, ECO_SIZE_BYTES);
            //una vez que tenemos todos los datos iniciamos el procesamiento de las señales
            indice_upstream[count_medida] = signalProcessing(patron_up);
            
            // Solicitar la temperatura del sensor:
            sensors.requestTemperatures();
            // Leer la temperatura en grados Celsius:
            temperatura_up[count_medida] = sensors.getTempCByIndex(0);
            uartDatalogger_up(count_medida);
          }
          

          //SE REALIZA LA MEDIDA DOWNSTREAM:
          // pide al psoc que realice el switcheo de los canales de los multiplexores
          Serial2.print('Q');
          vTaskDelay(100 / portTICK_PERIOD_MS);
        //pide al psoc que emita un pulso e inicie el muestreo, luego pase los datos al esp
        Serial2.print('T');
          n = Serial2.readBytes(&command2, 1);// Bloqueante: espera 1 bytes o hasta timeout;
         //el psoc envia el char H cuando ya tiene el dato listo para enviar
         if (command2 == 'H') { //acknowledge para el psoc
             Serial2.print("G"); //El esp le pide al psoc que envie los datos de la medida
             Serial2.flush();  // Se asegura que la señal se envíe antes de leer datos
             //El esp queda a la espera de los datos:
             int bytes_received2 = 0;
             // Lee hasta que se hayan recibido todos los bytes esperados
             while (bytes_received2 < ECO_SIZE_BYTES) {
                 if (Serial2.available()) {
                     int to_read2 = Serial2.available();
                     if (to_read2 > (ECO_SIZE_BYTES - bytes_received2)) {
                     to_read2 = ECO_SIZE_BYTES - bytes_received2;
                     }
                     int n2 = Serial2.readBytes(buffer_psoc + bytes_received2, to_read2);
                     bytes_received2 += n2;
                 }
                 vTaskDelay(10 / portTICK_PERIOD_MS);
             }
             
             // Copia los datos binarios al vector de floats
             memcpy(eco_float, buffer_psoc, ECO_SIZE_BYTES);
             //una vez que tenemos todos los datos iniciamos el procesamiento de las señales
             indice_downstream[count_medida] = signalProcessing(patron_down);
            // Solicitar la temperatura del sensor:
            sensors.requestTemperatures();
            // Leer la temperatura en grados Celsius:
            temperatura_down[count_medida] = sensors.getTempCByIndex(0);
            uartDatalogger_down(count_medida);
           }   
      }
     // TOF_moda_up = (float)moda_histograma_int(indice_upstream,CANTIDAD_MEDIDAS_STD);
     // TOF_moda_down = (float)moda_histograma_int(indice_downstream,CANTIDAD_MEDIDAS_STD);
      TOF_moda_up = calcularMedia(indice_upstream,CANTIDAD_MEDIDAS_STD);
      TOF_moda_down = calcularMedia(indice_downstream,CANTIDAD_MEDIDAS_STD);
      temperatura_media = calcularMedia(temperatura_up,CANTIDAD_MEDIDAS_STD);
      std_downstream = calcularDesviacionEstandar(indice_downstream,CANTIDAD_MEDIDAS_STD);
      std_upstream = calcularDesviacionEstandar(indice_upstream,CANTIDAD_MEDIDAS_STD);

      //se calcula la velocidad de la onda acustica en el medio a partir de la temperatura:
      // temperatureC = 25.0; //para realizar las pruebas sin el sensor de temperatura
      v_onda = 1412.0
      + 4.21 * temperatura_media
      - 0.037 * (temperatura_media  * temperatura_media )
      + 0.00022 * (temperatura_media  * temperatura_media * temperatura_media );

      delta_tof = (TOF_moda_up - TOF_moda_down) / 20000000; //para poner el tof en segundos 
      //se calcula la velocidad del flujo:
      v_flujo = ((v_onda * v_onda) * (delta_tof)) / (2.0*L);
                     
      enviar_datos_ThingSpeak();
    }
}
