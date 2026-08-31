#%%
ready = []
eco_crudo_esp = []
ser.write(b'T')

while(ready != b'H'):
    ready = ser.read(1)
print("Se ha recibido la el aviso de finalizacion de procesamiento",ready)

#ID:Eco Sub, se pide el eco submuestreado al esp
# Enviar el comando 'P' para que el ESP32 envíe el vector recibido (echo)
#print("Enviando comando 'P' para solicitar eco del vector...")
ser.reset_input_buffer()
ser.reset_output_buffer()

ser.write(b'C')
cantidad_datos = 1750
# Tiempo de espera para que el ESP32 procese y envíe la respuesta
time.sleep(0.5)

# Leer 256 líneas, cada una con un float en formato ASCII (enviado con Serial.println)
# Crea una lista temporal para almacenar los 256 valores de esta iteración
vector_aux = []
for i in range(cantidad_datos):
    line = ser.readline().decode('utf-8').strip()
    if line:
        try:
            vector_aux.append(float(line))
        except Exception as e:
            print(f"Error al convertir la línea a float: '{line}'. Error: {e}")
    else:
        print("Línea vacía recibida eco crudo")

#compara si los datos recibidos del eco crudo son iguales a los enviados
if len(vector_aux) != cantidad_datos:
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

x = np.arange(cantidad_datos)
plt.figure(figsize=(8, 6))

plt.plot(x,eco_crudo_esp[0])
plt.title('Datos recibidos del ESP32, Eco Sub')
plt.xlabel('Índice')
plt.ylabel('Valor')
plt.grid(True)
plt.show()
#%%
ser.write(b'L')
line = ser.readline().decode('utf-8').strip()
print(line)