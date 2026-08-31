#%%
import serial
import csv
from datetime import datetime
import time

# Configura el puerto serial según tu sistema (ejemplo: 'COM3' en Windows o '/dev/ttyUSB0' en Linux)
#ser = serial.Serial('COM10', 115200, timeout=1)

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


#%%

from datetime import datetime
CANTIDAD_MEDIDAS = 10

def parse_measurement():
    """
    Lee líneas desde el puerto serial hasta recibir "End_Measurement".
    Retorna un diccionario con la estructura:
    {
      "Fecha_Hora": <dato>, 
      "Count_tof": <dato>,
      "up": {
          "Float_up": [valores...],
          "Reconstruido_up": [valores...],
          "Envolvente_up": [valores...],
          "Correlacion_up": [valores...],
          "Temp_up": [valores...]
      },
      "down": {
          "Float_down": [valores...],
          "Reconstruido_down": [valores...],
          "Envolvente_down": [valores...],
          "Correlacion_down": [valores...],
          "Temp_down": [valores...]
      }
    }
    """
    measurement_data = {"Fecha_Hora": None, "Count_tof": None, "up": {}, "down": {}}
    current_section = None  # Nombre de la sección en curso
    data_section = None     # Indica si se trata de 'up' o 'down'
    
    while True:
        try:
            line = ser.readline().decode('utf-8').strip()
        except Exception as e:
            print("Error al leer del puerto:", e)
            continue
        
        if not line:
            continue
        
        print("Recibido:", line)
        
        # Inicio de la medición
        if line.startswith("Start_Measurement"):
            measurement_data = {"Fecha_Hora": None, "Count_tof": None, "up": {}, "down": {}}
        
        # Registro de fecha y hora enviada desde el ESP32
        elif line.startswith("Fecha_Hora:"):
            measurement_data["Fecha_Hora"] = line.split("Fecha_Hora:")[1].strip()
        
        # Registro del contador (Count_tof)
        elif line.startswith("Count_tof:"):
            measurement_data["Count_tof"] = line.split("Count_tof:")[1].strip()
        
        # Secciones para datos "up"
        elif line.startswith("Start_Float_up"):
            current_section = "Float_up"
            data_section = "up"
            measurement_data["up"][current_section] = []
        elif line.startswith("End_Float_up"):
            current_section = None
        elif line.startswith("Start_Reconstruido_up"):
            current_section = "Reconstruido_up"
            data_section = "up"
            measurement_data["up"][current_section] = []
        elif line.startswith("End_Reconstruido_up"):
            current_section = None
        elif line.startswith("Start_Envolvente_up"):
            current_section = "Envolvente_up"
            data_section = "up"
            measurement_data["up"][current_section] = []
        elif line.startswith("End_Envolvente_up"):
            current_section = None
        elif line.startswith("Start_Correlacion_up"):
            current_section = "Correlacion_up"
            data_section = "up"
            measurement_data["up"][current_section] = []
        elif line.startswith("End_Correlacion_up"):
            current_section = None
        elif line.startswith("Start_Temp_up"):
            current_section = "Temp_up"
            data_section = "up"
            measurement_data["up"][current_section] = []
        elif line.startswith("End_Temp_up"):
            current_section = None
        elif line.startswith("Start_Tof_up"):
            current_section = "Tof_up"
            data_section = "up"
            measurement_data["up"][current_section] = []
        elif line.startswith("End_Tof_up"):
            current_section = None
        elif line.startswith("End_up"):
            # Fin de sección "up"
            pass
        
        # Secciones para datos "down"
        elif line.startswith("Start_Float_down"):
            current_section = "Float_down"
            data_section = "down"
            measurement_data["down"][current_section] = []
        elif line.startswith("End_Float_down"):
            current_section = None
        elif line.startswith("Start_Reconstruido_down"):
            current_section = "Reconstruido_down"
            data_section = "down"
            measurement_data["down"][current_section] = []
        elif line.startswith("End_Reconstruido_down"):
            current_section = None
        elif line.startswith("Start_Envolvente_down"):
            current_section = "Envolvente_down"
            data_section = "down"
            measurement_data["down"][current_section] = []
        elif line.startswith("End_Envolvente_down"):
            current_section = None
        elif line.startswith("Start_Correlacion_down"):
            current_section = "Correlacion_down"
            data_section = "down"
            measurement_data["down"][current_section] = []
        elif line.startswith("End_Correlacion_down"):
            current_section = None
        elif line.startswith("Start_Temp_down"):
            current_section = "Temp_down"
            data_section = "down"
            measurement_data["down"][current_section] = []
        elif line.startswith("End_Temp_down"):
            current_section = None
        elif line.startswith("Start_Tof_down"):
            current_section = "Tof_down"
            data_section = "down"
            measurement_data["down"][current_section] = []
        elif line.startswith("End_Tof_down"):
            current_section = None
        elif line.startswith("End_down"):
            pass
        
        # Fin de la medición completa
        elif line.startswith("End_Measurement"):
            return measurement_data
        
        else:
            # Si estamos dentro de una sección, añadimos el dato leído
            if current_section:
                try:
                    valor = float(line)
                except ValueError:
                    valor = line
                measurement_data[data_section][current_section].append(valor)

def guardar_csv_batch(accumulated_data, data_type, batch_time):
    """
    Guarda en un archivo CSV los 10 ciclos acumulados para 'up' o 'down'.
    Cada fila del CSV corresponde a un ciclo de medición.
    Cada celda contiene la lista de valores (convertida a cadena) de la sección correspondiente.
    """
    filename = f"datalogger_{data_type}_{batch_time}.csv"
    if not accumulated_data:
        print(f"No hay datos acumulados para {data_type}")
        return

    # Se asume que todas las mediciones tienen las mismas secciones.
    headers = list(accumulated_data[0].keys())
    
    with open(filename, "w", newline="") as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(headers)
        for measurement in accumulated_data:
            row = []
            for sec in headers:
                # Convertir la lista de valores a una cadena separada por punto y coma
                value_str = ";".join(str(v) for v in measurement.get(sec, []))
                row.append(value_str)
            writer.writerow(row)
    print(f"Datos '{data_type}' guardados en: {filename}")

def main():
    # Acumuladores para 50 ciclos completos de datos
    accumulated_up = []
    accumulated_down = []
    measurement_count = 0

    #ser.write(b'5') #se habilita el timer para la medicion automatica
    ser.write(b'9') #se desabilita el timer y se realiza una tanda de mediciones para el datalogger
    

    while True:
        print("Esperando nuevo ciclo de medición...")
        measurement_data = parse_measurement()

        # Se pueden acumular datos "up" y "down" si existen en el ciclo
        if measurement_data["up"]:
            accumulated_up.append(measurement_data["up"])
        if measurement_data["down"]:
            accumulated_down.append(measurement_data["down"])

        measurement_count += 1
        print(f"Ciclos recibidos: {measurement_count}")

        # Una vez acumulados 50 ciclos, se guarda el CSV
        if measurement_count >= CANTIDAD_MEDIDAS:
            # Se usa la hora actual para nombrar el archivo (puedes usar otro criterio, por ejemplo, la hora del primer ciclo)
            batch_time = datetime.now().strftime("%d%m%Y_%H%M%S")
            if accumulated_up:
                guardar_csv_batch(accumulated_up, "up", batch_time)
            if accumulated_down:
                guardar_csv_batch(accumulated_down, "down", batch_time)
            # Reiniciar acumuladores y contador para la siguiente tanda
            measurement_count = 0
            accumulated_up = []
            accumulated_down = []

        # Pequeña pausa (ajusta si es necesario)
        #time.sleep(0.5)

if __name__ == "__main__":
    main()

#%% Celda 6: Cerrar el puerto serial
ser.close()
print("Puerto serial cerrado.")