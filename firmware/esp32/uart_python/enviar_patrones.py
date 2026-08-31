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
patrones_mat = loadmat('D:\Google Drive\TESIS FM\Scrips Matlab Agua\Para control python\patrones.mat')
#patrones_mat = loadmat('D:\Google Drive\TESIS FM\Scrips Matlab Agua\Para control python\patrones_interferencia_09042025.mat')

# Ver claves disponibles (variables guardadas en MATLAB)
print(patrones_mat.keys())
#%%
#ID: UP FRIO
# Extraer la variable 'patron_esp' del diccionario patron_csv
patron_up_frio =  patrones_mat['patron_up']
# se usa flatten  si es una matriz y quieres convertirla en un vector (1D)
patron_up_frio = patron_up_frio.flatten()
#print(patron_up)
# Graficar los datos recibidos
x = np.arange(768)
plt.figure(figsize=(8, 6))
plt.plot(x,patron_up_frio)

plt.title('Patron UP frio')
plt.xlabel('Índice')
plt.ylabel('Valor')
plt.grid(True)
plt.show()
#%% Enviamos el Patron UP FRIO
print("Enviando Patron UP, comando: '2'...")
ser.reset_input_buffer()
ser.write(b'2')

# Espera a que el ESP32 responda con la señal de listo ('G')
ready = ser.read(1)
if ready != b'G':
    print("No se recibió la señal de listo ('G'). Respuesta recibida:", ready)
else:
    print("Se recibió la señal 'G'. Procediendo a enviar el vector.")
    # Empaca el vector en un bloque binario en formato little-endian ('<256f')
    data = struct.pack('<768f', *patron_up_frio)

    ser.write(data)
    print("Vector de 768 floats enviado.")

#%%
#ID: DOWN FRIO
patron_down_frio =  patrones_mat['patron_down']
# se usa flatten  si es una matriz y quieres convertirla en un vector (1D)
patron_down_frio = patron_down_frio.flatten()
# Graficar los datos recibidos
x = np.arange(768)
plt.figure(figsize=(8, 6))
plt.plot(x,patron_down_frio )

plt.title('Patron Down frio')
plt.xlabel('Índice')
plt.ylabel('Valor')
plt.grid(True)
plt.show()
#%% Enviamos el Patron DOWN FRIO
print("Enviando Patron Down, comando: '3'...")
ser.reset_input_buffer()
ser.write(b'3')

# Espera a que el ESP32 responda con la señal de listo ('G')
ready = ser.read(1)
if ready != b'G':
    print("No se recibió la señal de listo ('G'). Respuesta recibida:", ready)
else:
    print("Se recibió la señal 'G'. Procediendo a enviar el vector.")
    # Empaca el vector en un bloque binario en formato little-endian ('<256f')
    data = struct.pack('<768f', *patron_down_frio)

    ser.write(data)
    print("Vector de 768 floats enviado.")




#%%
ready = []
eco_crudo_esp = []
#ID:Eco Sub, se pide el eco submuestreado al esp
# Enviar el comando 'P' para que el ESP32 envíe el vector recibido (echo)
#print("Enviando comando 'P' para solicitar eco del vector...")
ser.reset_input_buffer()
ser.reset_output_buffer()

ser.write(b'Z')
rx_size = 768
# Tiempo de espera para que el ESP32 procese y envíe la respuesta
time.sleep(0.5)

# Leer 256 líneas, cada una con un float en formato ASCII (enviado con Serial.println)
# Crea una lista temporal para almacenar los 256 valores de esta iteración
vector_aux = []
for i in range(rx_size):
    line = ser.readline().decode('utf-8').strip()
    if line:
        try:
            vector_aux.append(float(line))
        except Exception as e:
            print(f"Error al convertir la línea a float: '{line}'. Error: {e}")
    else:
        print("Línea vacía recibida eco crudo")

#compara si los datos recibidos del eco crudo son iguales a los enviados
if len(vector_aux) != rx_size:
    print(f"Error: Se esperaban 256 valores, se recibieron {len(vector_aux)}")
else:
    # Se compara cada valor (se usa un margen pequeño de error para floats)
    coinciden = all(abs(o - e) < 1e-6 for o, e in zip(eco_crudo_esp, vector_aux))
    if coinciden:
        # print("¡Éxito! El vector recibido coincide con el enviado.")
        # Se pide al esp que envia el indice del punto identificado como tof
        # Agrega la lista de la iteración actual a la "matriz" total
        eco_crudo_esp.append(vector_aux)
        
    else:
        print("Error: Los datos recibidos no coinciden con los enviados.")

x = np.arange(rx_size)
plt.figure(figsize=(8, 6))

plt.plot(x,eco_crudo_esp[0])
plt.title('Datos recibidos del ESP32, Eco Sub')
plt.xlabel('Índice')
plt.ylabel('Valor')
plt.grid(True)
plt.show()