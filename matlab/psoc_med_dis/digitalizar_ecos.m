
%% Digitalizar Ecos

% se iniciara a digitalizar los eco a una distancia de 20cm entre los
% transductores, con intervalos de 1cm hasta una distancia de 40cm entre
% los mismos.

% clear all 
% close all

fc = 40e3;     %frecuencia de resonancia del sensor
fs = 400e3;      %frecuencia de muestreo
N = 1024;


%%  pedimos al psoc el primer eco que usaremos como referencia, se abre el puerto serial:
%Longitud del vector de datos
longitud = 1024;
%Frecuencia de muestreo
fs=0.4e6;
Ts=1/fs;
%Se configura el puerto serial y se abre el canal
delete(instrfind);
SerialPort='COM10'; %serial port
fincad = 'CR/LF';
baudios = 115200;
s = serial(SerialPort);
set(s,'BaudRate',baudios,'DataBits', 8, 'Parity', 'none','StopBits', 1,'FlowControl', 'none','Timeout',1);
set(s,'Terminator',fincad);
set(s, 'InputBufferSize',512*4);
flushinput(s);
s.BytesAvailableFcnCount = longitud;
s.BytesAvailableFcnMode = 'byte';
%Se abre el puerto de comunicación
fopen(s);

%% se piden las primeras mediciones para tomar una referencia para elegir el patron
%Se inicia la digitalización en el PSoC

fwrite(s,'V') %para que no se envie la correlacion
fwrite(s,'T')
%la primera vez siempre tiene un pico al inicio por culpa de que se prende
%el ADC y realiza la digitalizacion por primera vez, entonces volvemos a
%pedir que digitalice otra tanda de datos
disp("Presione una tecla para empezar a digitalizar")
pause

%% Initializing variables - Primer grafico - Eco de la senhal de referencia
flag = 1;
count_med = 1;
count_dist = 1;
flushinput(s);

while(count_dist < 22)
    while(count_med < 11)
            %% Se pide al psoc una nueva medicion del eco
            fwrite(s,'T')
            pause(5)

            MaxDeviation = 3;%Maximum Allowable Change from one value to next 
            TimeInterval=0.001;%time interval between each input.
            tiempo = 0;
            eco_med = 0;


            %% Initializing variables - Primer grafico - Eco de la senhal de referencia
            flushinput(s);
            pause(5)
            fwrite(s,'I')
            eco_med(1)=0;
            tiempo(1)=0;
            count = 1;
            k=0;

            while ~isequal(count,longitud)
             %%Re creating Serial port before timeout  
                k=k+1;  
                if k==longitud
                    fclose(s);
                    delete(s);
                    clear s;        
                    s = serial(SerialPort);
                    set(s,'Terminator',fincad);
                    set(s,'BaudRate',baudios,'Parity','none');
                    fopen(s)     
                    k=0;
                end

            eco_med(count) = str2double(fscanf(s));
            tiempo(count) = count;
            count = count+1;
            end
            eco_med(1024)=0;
            
            %una vez que tenemos el eco lo guardamos en una matriz de 3 dimensiones
            ecos(count_dist,count_med,:) = eco_med(:);
            flushinput(s);
            fwrite(s,'Q') %se pide la temperatura medida por el sensor am2315
            temperatura(count_dist,count_med) = str2double(fscanf(s)); 
            
            count_med = count_med + 1

    end
    
    
    count_dist = count_dist + 1
    count_med = 1;
    disp("Mueva el Receptor y presione Enter para la siguiete medida")
    pause
    
end

%% Clean up the serial port
flushinput(s);
fclose(s);
delete(s);
clear s;
disp("Puerto serial cerrado")

%% guardar los datos
save('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\medidas_paper\ecos_digitalizados3.mat','ecos','temperatura')


