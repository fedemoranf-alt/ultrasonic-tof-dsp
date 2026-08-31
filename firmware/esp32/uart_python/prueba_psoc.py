#%% Celda 1: Configuración del puerto serial
import serial
import struct
import time
import matplotlib.pyplot as plt
import pandas as pd
import numpy as np

#%% Configura el puerto serial. Cambia 'COM10' por el puerto que uses en tu sistema
port = 'COM10'
baudrate = 115200

try:
    ser = serial.Serial(port, baudrate, timeout=2)
    # Pausa para que el puerto se inicialice
    time.sleep(2)
    print(f"Puerto {port} abierto a {baudrate} baud.")
except Exception as e:
    print(f"Error al abrir el puerto {port}: {e}")



#%% Celda 3: Enviar PATRON de 768 floats (caso comando '2')
# Enviar el comando '2' para que el ESP32 se prepare a recibir el vector
from scipy.io import loadmat # para poder cargar archivos .mat

# Cargar el archivo .mat
patron_csv = loadmat('D:\Google Drive\TESIS FM\Scrips Matlab Agua\datalogger\datos_python\PATRON_ESP_14_03_2025')

# Extraer la variable 'patron_esp' del diccionario patron_csv
patron_aux = patron_csv['patron_esp']

# se usa flatten  si es una matriz y quieres convertirla en un vector (1D)
patron = patron_aux.flatten()
#delimitemos el patron a solo la primera parte, el patron up, los primero 768 valores
# Mostrar el vector
patron = patron[767:1535] #tomamos la parte del patron correspondiente al sentido DownStream
print(patron)

# Enviamos el Patron para la correlacion al esp
print("Enviando comando '2'...")
ser.reset_input_buffer()

ser.write(b'2')

# Espera a que el ESP32 responda con la señal de listo ('G')
ready = ser.read(1)
if ready != b'G':
    print("No se recibió la señal de listo ('G'). Respuesta recibida:", ready)
else:
    print("Se recibió la señal 'G'. Procediendo a enviar el vector.")
    # Empaca el vector en un bloque binario en formato little-endian ('<256f')
    data = struct.pack('<768f', *patron)

    ser.write(data)
    print("Vector de 768 floats enviado.")



#%%
ser.reset_input_buffer()
ser.reset_output_buffer()

#ACA PODRIA INICIAR EL LOOP 
#ID:LOOP
indice_tof = []
eco_crudo_esp = []
eco_interpolado_esp =[]
eco_reconstruido_esp = []
envolvente_derivada_esp = []
correlacion_esp = []
temperatura = []
ready = []
#%% para ver el eco del psoc
for i in range(0, 10, 1): 
    
    print("Se inicia la medida")

    ser.write(b'T')
    time.sleep(0.5)
    while(ready != b'H'):
        ready = ser.read(1)
        print("while")
    print("Se ha recibido la el aviso de finalizacion de procesamiento",ready)
    print("iteracion:",i)

    #%%
    time.sleep(0.5)
    #ID:Eco Sub, se pide el eco submuestreado al esp
    # Enviar el comando 'P' para que el ESP32 envíe el vector recibido (echo)
    #print("Enviando comando 'P' para solicitar eco del vector...")
    ser.reset_input_buffer()
    ser.reset_output_buffer()
    time.sleep(1)
    
    ser.write(b'P')
    # Tiempo de espera para que el ESP32 procese y envíe la respuesta
    time.sleep(0.5)

    # Leer 256 líneas, cada una con un float en formato ASCII (enviado con Serial.println)
    # Crea una lista temporal para almacenar los 256 valores de esta iteración
    vector_aux = []
    for i in range(256):
        line = ser.readline().decode('utf-8').strip()
        if line:
            try:
                vector_aux.append(float(line))
            except Exception as e:
                print(f"Error al convertir la línea a float: '{line}'. Error: {e}")
        else:
            print("Línea vacía recibida eco crudo")

    #compara si los datos recibidos del eco crudo son iguales a los enviados
    if len(vector_aux) != 256:
        print(f"Error: Se esperaban 256 valores, se recibieron {len(vector_aux)}")
    eco_crudo_esp.append(vector_aux)

    # ID:ECO INTERPOLADO, SE PIDE EL ECO RECONSTURIDO AL ESP
    ser.reset_input_buffer()
    ser.reset_output_buffer()
    time.sleep(1)
    ser.write(b'B')
    # Tiempo de espera para que el ESP32 procese y envíe la respuesta
    time.sleep(0.5)
    vector_aux = []
    for i in range(1750):
        line = ser.readline().decode('utf-8').strip()
        if line:
            try:
                vector_aux.append(float(line))
            except Exception as e:
                print(f"Error al convertir la línea a float: '{line}'. Error: {e}")
        else:
            print("Línea vacía recibida eco reconstruido.")
    # comprobamos que hemos recibido todos los datos pedidos
    if len(vector_aux) != 1750:
        print("Se recibieron menos valores en el eco rec")
    else:
        eco_interpolado_esp.append(vector_aux)

    time.sleep(1)
    # ID:ECO RECONSTRUIDO, SE PIDE EL ECO RECONSTURIDO AL ESP
    ser.reset_input_buffer()
    ser.reset_output_buffer()

    ser.write(b'C')
    # Tiempo de espera para que el ESP32 procese y envíe la respuesta
    time.sleep(0.5)
    vector_aux = []
    for i in range(1750):
        line = ser.readline().decode('utf-8').strip()
        if line:
            try:
                vector_aux.append(float(line))
            except Exception as e:
                print(f"Error al convertir la línea a float: '{line}'. Error: {e}")
        else:
            print("Línea vacía recibida eco reconstruido.")
    # comprobamos que hemos recibido todos los datos pedidos
    if len(vector_aux) != 1750:
        print("Se recibieron menos valores en el eco rec")
    else:
        eco_reconstruido_esp.append(vector_aux)

    time.sleep(1)
    # ID:ENVOLVENTE DERIVADA
    ser.reset_input_buffer()
    ser.reset_output_buffer()

    ser.write(b'D')
    # Tiempo de espera para que el ESP32 procese y envíe la respuesta
    time.sleep(0.5)
    vector_aux = []
    for i in range(1750):
        line = ser.readline().decode('utf-8').strip()
        if line:
            try:
                vector_aux.append(float(line))
            except Exception as e:
                print(f"Error al convertir la línea a float: '{line}'. Error: {e}")
        else:
            print("Línea vacía recibida envolvente.")
    # comprobamos que hemos recibido todos los datos pedidos
    if len(vector_aux) != 1750:
        print("Se recibieron menos valores en la envolvente")
    else:
        envolvente_derivada_esp.append(vector_aux)

    time.sleep(1)
    # ID:CORRELACION
    ser.reset_input_buffer()
    ser.reset_output_buffer()

    ser.write(b'V')
    # Tiempo de espera para que el ESP32 procese y envíe la respuesta
    time.sleep(0.5)
    vector_aux = []
    for i in range(2517):
        line = ser.readline().decode('utf-8').strip()
        if line:
            try:
                vector_aux.append(float(line))
            except Exception as e:
                print(f"Error al convertir la línea a float: '{line}'. Error: {e}")
        else:
            print("Línea vacía recibida correlacion.")
    # comprobamos que hemos recibido todos los datos pedidos
    if len(vector_aux) != 2517:
        print("Se recibieron menos valores en la correlacion")
    else:
        correlacion_esp.append(vector_aux)

    #Se pide el indice del TOF calculado por el esp:
    ser.reset_input_buffer()
    ser.reset_output_buffer()
    ser.write(b'K')
    # Lee una línea completa del puerto UART
    indice_tof.append(ser.readline().decode('utf-8').strip())
    print(indice_tof)
    #guardamos la temperatura de cada medicion, simplemente para luego copiarla al nuevo set de datos


#%%
#ID:PATRON ESP
ser.reset_input_buffer()
ser.reset_output_buffer()
patron_esp = []
ser.write(b'X')
# Tiempo de espera para que el ESP32 procese y envíe la respuesta
time.sleep(0.5)
vector_aux = []
for i in range(768):
    line = ser.readline().decode('utf-8').strip()
    if line:
        try:
            vector_aux.append(float(line))
        except Exception as e:
            print(f"Error al convertir la línea a float: '{line}'. Error: {e}")
    else:
        print("Línea vacía recibida correlacion.")
# comprobamos que hemos recibido todos los datos pedidos
if len(vector_aux) != 768:
    print("Se recibieron menos valores el patron")
else:
    patron_esp.append(vector_aux)
    

#%% 
# para guardar en un .mat
from scipy.io import savemat
savemat('prueba_psoc2.mat', {
    'eco_sub_esp': eco_crudo_esp,
    'eco_interpolado_esp': eco_interpolado_esp,
    'eco_recontruido_esp': eco_reconstruido_esp,
    'envolvente_derivada_esp': envolvente_derivada_esp,
    'correlacion_esp': correlacion_esp,
    'tof': indice_tof,
    'patron' : patron_esp
})

#%% GUARDAR DATOS EN UN CSV PARA LAS PRUBEAS DE C EN LA PC
df_medida = pd.DataFrame({
    'eco_sub': eco_crudo_esp,
})
# Guardar a CSV
df_medida.to_csv('eco_sub_tanda1.csv', index=False)

#%% Celda 6: Cerrar el puerto serial
ser.close()
print("Puerto serial cerrado.")

#%% Graficar los datos recibidos
x = np.arange(768)
plt.figure(figsize=(8, 6))
plt.plot(x,patron_esp[0])
plt.title('Datos recibidos del ESP32')
plt.xlabel('Índice')
plt.ylabel('Valor')
plt.grid(True)
plt.show()
#%% Graficar los datos recibidos
x = np.arange(256)
plt.figure(figsize=(12, 10))
for i in range(0, 2, 1):  # De 0 a 10 en pasos de 1
    plt.plot(x,eco_crudo_esp[i])

plt.title('Datos recibidos del ESP32, Eco Sub')
plt.xlabel('Índice')
plt.ylabel('Valor')
plt.grid(True)
plt.show()
