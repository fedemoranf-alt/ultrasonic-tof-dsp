%% Prueba del promedio de las derivadas para obtener un mejor patron para las correlaciones

%% medidor de distancia, 
%para probar el algoritmo de de medicion en matlab pero con los datos
%digitalizados por el psoc, se utiliza el vector del eco
clear all 
close all

fc = 40e3;     %frecuencia de resonancia del sensor
fs = 400e3;      %frecuencia de muestreo
N = 1024;
%% deriva de amstrong 
%filtro analogico cero - polo frecuencia de corte superior 60000
fss = fc;     %Doble de la frecuencia de la portadora
a = 2*20e3*pi;  %Ancho de banda del transductor
num = [1 0];
den = [1 a]; % se usa el polo para limitar el ancho de banda de la derivada
%Se digitaliza el filtro para hallar la derivada
[numd, dend] = bilinear(num,den,fss);
derivadorS = tf(num,den);
derivadorZ = tf(numd,dend,1); % para tener la ecuacion en diferencia que va en el PSoC

%% fir derivada
b_diff = [-1, 6, -27, 104,0,  -104, 27, -6, 1];
% [B,W] = freqz(b);
% figure
% plot(W./pi , abs(B))
% filtro = tf(b,1,1);
% figure
% pzmap(filtro)
% figure
% freqz(b)

%% filtro demodulador

% fir_dem = [ 0.0043,    0.0052,    0.0073,    0.0109,    0.0157,    0.0217,    0.0285,    0.0359,    0.0435,    0.0508,    0.0574,    0.0631,    0.0673,...
%             0.0700,    0.0709,    0.0700,    0.0673,    0.0631,    0.0574,    0.0508,    0.0435,    0.0359,    0.0285,    0.0217,    0.0157,    0.0109,...
%             0.0073,    0.0052,    0.0043  ];
%filtro paso bajos con corte en 20k

%disenhar otro para cortar en 15 o 10 k, para atenuar el rudio de 40k, ver
%con freqz. la idea no es bajar el ancho de banda, solo atenuar mas los
%40k, no hace falta bajar la frecuencia de corte de 20k solo atenuar mas el
%40k

fir_dem = fir1(65,0.1,blackman(66));
figure
freqz(fir_dem)
title('fir dem 2')

%% filtro paso bajos para suavizar el patron
%patron_lp = fir1(30,100e3/600e3);

%% filtro low pass reconstructor
%pasamos la envolvente por un paso bajos con frecuencia de corte a 3k para
%interpolar la senhal, para esto primero disenhamos el filtro paso bajos
%neecesario:
M = 3;
fss_lp = M*fs;
fc_lp = 20e3;

lp_interpolador = fir1(60,fc_lp/(fss_lp/2)); %para que pase hasta 10k


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

eco_refe = zeros(1,longitud); %inicializacion de la variable 
env_refe_d = zeros(1,longitud);
prom_count = 0; % 
while (prom_count < 10) %promediaremos 10 medidas
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
    
    %% se halla la envolvente utilizando la transformada de hilbert
    env_r = abs(hilbert(eco_refe));
    env_refe = filter(fir_dem,1,env_r);
    
    %% derivamos al envolvente 
    env_refe_d_aux = filter(numd,dend,env_refe);%se deriva la envolvelnte interpolada, derivada de amstrong
    %env_refe_d = filter(fir_dem2,1,env_refe_d);
    
    %% sumamos las derivadas de la envolvente
    for i = 1 : longitud
        env_refe_d(i) = env_refe_d(i) + env_refe_d_aux(i);
    end
    prom_count = prom_count +1;
    disp(prom_count)
    figure
    plot(env_refe_d_aux)
    title(prom_count)
end
disp("Enter para mostrar el promedio y cerrar las demas ventanas")
pause

%% Elegimos el Patron

figure
plot(env_refe_d)
title('Derivada de la envolvente referencia promediada.')
%hold on
%plot(env_refe_int_d_2, 'r')

disp("Enter para elegir el patron")
pause
%se selecciona cual sera el patron, esto se hace seleccionando una ventana
%temporanl en la curva de la envolventa derivada
[ind val] = ginput(2);

%Se define el patron desde la derivada
patron_d = env_refe_d(1,floor(ind(1,1)):floor(ind(2,1)));
%patron_d = filter(patron_lp,1,patron_d_0);
figure
plot(patron_d);
title('Patron de la derivada')