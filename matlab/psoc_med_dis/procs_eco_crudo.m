%% medidor de distancia "NORMAL",

%tambien usa este scrip para probar el suavizador de la derivada fir_dem2

%para probar el algoritmo de de medicion en matlab pero con los datos
%digitalizados por el psoc, se utiliza el vector del eco
clear all 
close all

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
disp("Presione una tecla para tomar la referencia")
pause
eco_refe = zeros(1,longitud);
fwrite(s,'T') %solicitamos al psoc que inicie una digitalizacion 
%% Initializing variables - Primer grafico - Eco de la senhal de referencia
flushinput(s);
pause(5)
fwrite(s,'I') % se solicita al psoc que se envien los datos del eco digitalizado
%eco_refe(1)=0;
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

eco_refe(count) = str2double(fscanf(s));
tiempo(count) = count;
count = count+1;
end
eco_refe(1024)=0;

%normalizamos el eco
[max_d, max_i] = max(eco_refe );
eco_refe = (1/max_d).*eco_refe;

%% Elegimos el Patron

figure
plot(eco_refe)
title('Eco para elegir el patron.')
%hold on
%plot(env_refe_int_d_2, 'r')

disp("Enter para elegir el patron")
pause
%se selecciona cual sera el patron, esto se hace seleccionando una ventana
%temporanl en la curva de la envolventa derivada
[ind val] = ginput(2);

%Se define el patron desde la derivada
patron = eco_refe(1,floor(ind(1,1)):floor(ind(2,1)));
%patron_d = filter(patron_lp,1,patron_d_0);
figure
plot(patron);
title('Patron del eco')

%% hallamos el indice maximo de la correlacion de referencia.
%% CORRELACION DE LA SENHAL REFE (EL 1er ECO digitalizado)

correlacion =  xcorr(eco_refe,patron);
[V1 TOF1] = max(correlacion);

%% iniciamos las mediciones a partir de la referencia tomada
disp("Presione una tecla para continuar e iniciar las mediones de distancia")
pause

flag = 1;
count_med = 1;
count_dist = 1
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

            %se normaliza el eco
            [max_d, max_i] = max(eco_med );
            eco_med = (1/max_d).*eco_med;

            
            %% CORRELACION DE LA SENHAL medida (EL 2DO ECO digitalizado)
            correlacion  =  xcorr(eco_med,patron);
            [V2 TOF2] = max( correlacion );
          

            %% se calcula el tiempo de vuelo y la distancia entre los ecos con las correlaciones realizadas por partes
            %[TOF1 TOF2]
            TOF1_v(count_dist,count_med) = TOF1
            TOF2_v(count_dist,count_med) = TOF2
            flushinput(s);
            fwrite(s,'Q') %se pide la temperatura medida por el sensor am2315
            temperatura(count_dist,count_med) = str2double(fscanf(s)) 
            %Distancia(count_dist,count_med) =340000*[(TOF2-TOF1)*1/(fs)]
            Distancia(count_dist,count_med) =(331000 + 610*temperatura(count_dist,count_med))*[(TOF2-TOF1)*1/(fs)]
            count_med = count_med+1;

    end
    count_dist = count_dist + 1;
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

%% Se guardan los datos de las mediciones en un archivo.m
%save('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\normal_tia_gauss.mat','TOF1_v','TOF2_v','Distancia','temperatura')
save('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\medidas_paper\eco_crudo.mat','TOF1_v','TOF2_v','Distancia','temperatura')


%% Graficar los resultados 

%la referencia fue tomada con 30cm entre los transductores 

valor_real = [-100:10:100];

XMIN = -10;
XMAX = 10;
YMIN = -2;
YMAX = 2;
% Solo interpolacion:
aux = load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\medidas_paper\eco_crudo.mat');

i= 1;
while (i < 22)
   promedio_dist(i) = mean(aux.Distancia(i,:)); 
    sigma_dist(i) = std(aux.Distancia(i,:));
     diff_pasos(i,:) = aux.TOF2_v(i,:) - aux.TOF1_v(i,:);
     promedio_pasos(i) = mean(diff_pasos(i,:));
     sigma_pasos(i) = std(diff_pasos(i,:));
     error(i) = valor_real(i) - promedio_dist(i);
    i = i+1;
end

indice = [-10:1:10];

figure
subplot(311)
plot(indice,promedio_dist,'*')
title('Eco Crudo, Promedio Distancias')
subplot(312)
plot(indice,sigma_dist,'*')
title('Eco Crudo, STD Distancias')
subplot(313)
plot(indice,error,'*')
title('Error')
axis([XMIN XMAX YMIN YMAX])