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

fir_dem = [ 0.0043,    0.0052,    0.0073,    0.0109,    0.0157,    0.0217,    0.0285,    0.0359,    0.0435,    0.0508,    0.0574,    0.0631,    0.0673,...
            0.0700,    0.0709,    0.0700,    0.0673,    0.0631,    0.0574,    0.0508,    0.0435,    0.0359,    0.0285,    0.0217,    0.0157,    0.0109,...
            0.0073,    0.0052,    0.0043  ];

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
SerialPort='COM18'; %serial port
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
fwrite(s,'T')

%% Graficamos la primera tanda de datos para usarla de referencia, el eco, la envolvente y su derivada
%% Se configura la primera figura, para el eco 
MaxDeviation = 3;%Maximum Allowable Change from one value to next 
TimeInterval=0.001;%time interval between each input.
tiempo = 0;
eco_refe = 0;

% Se configura el gráfico 
figureHandle = figure('NumberTitle','off',...
    'Name','Señal de Eco de Referencia',...
    'Color',[0 0 0],'Visible','off');
% Set axes
axesHandle = axes('Parent',figureHandle,...
    'YGrid','on',...
    'YColor',[0.9725 0.9725 0.9725],...
    'XGrid','on',...
    'XColor',[0.9725 0.9725 0.9725],...
    'Color',[0 0 0]);
hold on;

plotHandle = plot(axesHandle,tiempo,eco_refe,'Marker','.','LineWidth',1,'Color',[0 1 0]);
% Create xlabel
xlabel('Tiempo(seg)','FontWeight','bold','FontSize',14,'Color',[1 1 0]);
% Create ylabel
ylabel('Tensión(Voltios)','FontWeight','bold','FontSize',14,'Color',[1 1 0]);
% Create title
msg = ['Muestras=',num2str(longitud),'   Fs=',num2str(fs), ' Hz'];
title(msg,'FontSize',15,'Color',[1 1 0]);

%% Initializing variables - Primer grafico - Eco de la senhal de referencia
flushinput(s);
pause(5)
fwrite(s,'I')
eco_refe(1)=0;
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
set(plotHandle,'YData',eco_refe,'XData',tiempo);
set(figureHandle,'Visible','on');
 count = count+1;
end
eco_refe(1024)=0;

%% se halla la envolvente utilizando la transformada de hilbert
env_r = abs(hilbert(eco_refe));
env_refe = filter(fir_dem,1,env_r);

figure
plot(eco_refe)
title('Eco y su envolvente')
hold on
plot(env_refe)

%% se interpola la envolvente para obterner mas resolucion
%primero agregamos los puntos intermedios en cada muestra
j = 1;
for i=1 : N
    env_y_0(j) = env_refe(i);
    env_y_0(j+1) = env_refe(i);
    env_y_0(j+2) = env_refe(i);
    j = j+3;
end

%pasamos la senhal por el filtro low pass reconstructor:
env_refe_int = filter(lp_interpolador,1,env_y_0);
env_refe_int = M.*env_refe_int;

figure
subplot(211)
plot(env_refe)
title(' envolvente sin interpolar.')
subplot(212)
plot(env_refe_int)
title(' envolvente interpolada.')

%% derivamos al envolvente 
env_refe_int_d = filter(numd,dend,env_refe_int);%se deriva la envolvelnte interpolada
%env_refe_int_d = filter(b_diff,1,env_refe_int);

%% Elegimos el Patron

figure
plot(env_refe_int_d)
title('Derivada de la envolvente referencia.')
%hold on
%plot(env_refe_int_d_2, 'r')

disp("Enter para elegir el patron")
pause
%se selecciona cual sera el patron, esto se hace seleccionando una ventana
%temporanl en la curva de la envolventa derivada
[ind val] = ginput(2);

%Se define el patron desde la derivada
patron_d = env_refe_int_d(1,floor(ind(1,1)):floor(ind(2,1)));
%patron_d = filter(patron_lp,1,patron_d_0);
figure
plot(patron_d);
title('Patron de la derivada')

%% hallamos el indice maximo de la correlacion de referencia.
%% CORRELACION DE LA SENHAL REFE (EL 1er ECO digitalizado)
 
size_tramo = max(size(env_refe_int_d))/3;
tramo_y1 = zeros(1,size_tramo);

%solo nos importan los tramos 2 y 3, desde N hasta 3N
%primer tramo, 2/4
%iniciamos por la parte A, calculomos su correlacion con el patron:
for i=1 : size_tramo
   tramo_y1(i) = env_refe_int_d(i) ;
end

corr_tramo_y1 =  xcorr(tramo_y1,patron_d);
size_corr = max((size(corr_tramo_y1)));
if  rem(size_corr,2)~=0
    corr_tramo_y1(1,size_corr+1) = 0;
end
size_corr = max((size(corr_tramo_y1)));
%guardamos la seguda parte de la correlacion de A en el vector de
%correlacion valida:
for i= 1 :  ((size_corr)/2)
   corr_completa_y1(i) = corr_tramo_y1(i + ((size_corr)/2) -1);
end
% debemos de sumar la ultima parte de la correlacion de la parte A a la primera parte correlacion 
% de la parte B, calculamos la correlacion de la parte B:
for i = size_tramo+1 : (size_tramo*2)
   tramo_y1(i-size_tramo) = env_refe_int_d(i) ;
end

corr_tramo_y1 =  xcorr(tramo_y1,patron_d);
size_corr = max((size(corr_tramo_y1)));
if  rem(size_corr,2)~=0
    corr_tramo_y1(1,size_corr+1) = 0;
end
size_corr = max((size(corr_tramo_y1)));

%sumamos a la ultima parte de A la primera parte de B:
for i= 1:((size_corr)/2)
   corr_completa_y1(i) = corr_completa_y1(i) + corr_tramo_y1(i);
end

%%%%%%%%%%%%%%%%%%%%%
%aqui ya tenemos realizado el primer tramo, procedemos a hallar el maximo:
[V_t1 TOF_t1] = max( corr_completa_y1);

figure
plot(corr_completa_y1)
title("tramo 1 refe")

%ahora procedemos a realizar el segundo tramo 
%guardamos la ultima parte de B para luego sumarle la primera parte de C
for i= ((size_corr)/2)+1 : size_corr
   corr_completa_y1(i-(size_corr/2)) = corr_tramo_y1(i); %se sobreescribe el vector corr_completa
end

%ahora calculamos la correlacion de la parte C para sumarla a la ultima
%parte de la correlacion de la parte B
for i= (size_tramo*2)+1 : (size_tramo*3) 
   tramo_y1(i-(size_tramo*2)) = env_refe_int_d(i) ;
end

corr_tramo_y1 =  xcorr(tramo_y1,patron_d);
size_corr = max((size(corr_tramo_y1)));
if  rem(size_corr,2)~=0
    corr_tramo_y1(1,size_corr+1) = 0;
end
size_corr = max((size(corr_tramo_y1)));

%sumamos la primera parte de C a la ultima parte de B:
for i= 1 :  (size_corr/2)
   corr_completa_y1(i) = corr_completa_y1(i) + corr_tramo_y1(i);
end

%ahora hallamos el maximo de la 2da parte de la correlacion valida
[V_t2 TOF_t2] = max( corr_completa_y1);

% figure
% plot(corr_completa_y1)
% title("tramo 2 refe")

%hallamos el maximo entre ambos maximos:
%max_corr_y1 = max(V_t2,V_t1)
if V_t2 > V_t1 
    Vp = V_t2;
    TOF1 = TOF_t2 + (size_corr/2); % se le suma el size_corr/2 pq este indice corresponde al 2do tramo de la correlacion valida
elseif V_t1 > V_t2 
    Vp = V_t1;
    TOF1 = TOF_t1;
end

%% iniciamos las mediciones a partir de la referencia tomada
disp("Presione una tecla para continuar e iniciar las mediones de distancia")
pause

flag = 1;
count_med = 1;
flushinput(s);

while(flag)
        %% Se pide al psoc una nueva medicion del eco
        fwrite(s,'T')
        pause(5)
        
        MaxDeviation = 3;%Maximum Allowable Change from one value to next 
        TimeInterval=0.001;%time interval between each input.
        tiempo = 0;
        eco_med = 0;

        % Se configura el gráfico 
        figureHandle = figure('NumberTitle','off',...
            'Name','Señal de Eco medido',...
            'Color',[0 0 0],'Visible','off');
        % Set axes
        axesHandle = axes('Parent',figureHandle,...
            'YGrid','on',...
            'YColor',[0.9725 0.9725 0.9725],...
            'XGrid','on',...
            'XColor',[0.9725 0.9725 0.9725],...
            'Color',[0 0 0]);
        hold on;

        plotHandle = plot(axesHandle,tiempo,eco_med,'Marker','.','LineWidth',1,'Color',[0 1 0]);
        % Create xlabel
        xlabel('Tiempo(seg)','FontWeight','bold','FontSize',14,'Color',[1 1 0]);
        % Create ylabel
        ylabel('Tensión(Voltios)','FontWeight','bold','FontSize',14,'Color',[1 1 0]);
        % Create title
        msg = ['Muestras=',num2str(longitud),'   Fs=',num2str(fs), ' Hz'];
        title(msg,'FontSize',15,'Color',[1 1 0]);

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
        set(plotHandle,'YData',eco_med,'XData',tiempo);
        set(figureHandle,'Visible','on');
         count = count+1;
        end
        eco_med(1024)=0;
        %% se obtiene la envolvente del segundo eco generado
        env_m = abs(hilbert(eco_med));
        env_med = filter(fir_dem,1,env_m);
        
        figure
        plot(eco_med)
        title('Eco y su envolvente medida')
        hold on
        plot(env_med)


        %% se interpola la envolvente del segundo eco
        %primero agregamos los puntos intermedios en cada muestra
        j = 1;
        for i=1 : N
            env_y1_0(j) = env_med(i);
            env_y1_0(j+1) = env_med(i);
            env_y1_0(j+2) = env_med(i);
            j = j+3;
        end

        env_med_int = filter(lp_interpolador,1,env_y1_0);
        env_med_int = M.*env_med_int;
        
        figure
        plot(env_med_int)
        title("Env Int medida")

        %% se deriva la envolvente interpolada del segundo eco
        env_med_int_d = filter(numd,dend,env_med_int);
        %env_med_int_d = filter(b_diff,1,env_med_int);
        
        figure
        plot(env_med_int_d)
        title("Derivada de la medicion")

        %% correlacion realizada por partes "Overlap and Add" VERSION 2 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %en esta version se intenta reducir el uso de la memoria para que el
        %algoritmo quepa mejor en el psoc, la idea es tenes un vector de la
        %correlacion final que solo posea la mitad de puntos de la correlacion
        %valida, la correlacion valida posee dos tramos, el inicial que corresponde
        %al solapamiento de la segunda parte de la correlacion de la parte A con la
        %primera parte de la correlacion de la parte B, y el tramo final que
        %corresponde al solapamiento de la ultima parte de la correlacion de B con
        %la primera parte de la correlacion de C.
        %La idea es realizar primero solo el primer tramo, hallar su punto maximo y
        %guardarlo, luego realizar el segundo tramo reescribiendo la misma variable
        %anterior y hallar su maximo, luego comparar ambos maximos para obtener el
        %maximo real de la correlacion total valida. De esta manera el vector de la
        %correlacion final valida podria tener la mitad del tamaño.
        %% CORRELACION DE LA SENHAL medida (EL 2DO ECO digitalizado)

        size_tramo = max(size(env_med_int_d))/3;
        tramo_y1 = zeros(1,size_tramo);

        %solo nos importan los tramos 2 y 3, desde N hasta 3N
        %primer tramo, 2/4
        %iniciamos por la parte A, calculomos su correlacion con el patron:
        for i=1 : size_tramo
           tramo_y1(i) = env_med_int_d(i) ;
        end

        corr_tramo_y1 =  xcorr(tramo_y1,patron_d);
        size_corr = max((size(corr_tramo_y1)));
        if  rem(size_corr,2)~=0
            corr_tramo_y1(1,size_corr+1) = 0;
        end
        size_corr = max((size(corr_tramo_y1)));
        %guardamos la seguda parte de la correlacion de A en el vector de
        %correlacion valida:
        for i= 1 :  ((size_corr)/2)
           corr_completa_y1(i) = corr_tramo_y1(i + ((size_corr)/2) -1);
        end
        % debemos de sumar la ultima parte de la correlacion de la parte A a la primera parte correlacion 
        % de la parte B, calculamos la correlacion de la parte B:
        for i = size_tramo+1 : (size_tramo*2)
           tramo_y1(i-size_tramo) = env_med_int_d(i) ;
        end

        corr_tramo_y1 =  xcorr(tramo_y1,patron_d);
        size_corr = max((size(corr_tramo_y1)));
        if  rem(size_corr,2)~=0
            corr_tramo_y1(1,size_corr+1) = 0;
        end
        size_corr = max((size(corr_tramo_y1)));

        %sumamos a la ultima parte de A la primera parte de B:
        for i= 1:((size_corr)/2)
           corr_completa_y1(i) = corr_completa_y1(i) + corr_tramo_y1(i);
        end

        %%%%%%%%%%%%%%%%%%%%%
        %aqui ya tenemos realizado el primer tramo, procedemos a hallar el maximo:
        [V_t1 TOF_t1] = max( corr_completa_y1);

        figure
        plot(corr_completa_y1)
        title("tramo 1 med")

        %ahora procedemos a realizar el segundo tramo 
        %guardamos la ultima parte de B para luego sumarle la primera parte de C
        for i= ((size_corr)/2)+1 : size_corr
           corr_completa_y1(i-(size_corr/2)) = corr_tramo_y1(i); %se sobreescribe el vector corr_completa
        end

        %ahora calculamos la correlacion de la parte C para sumarla a la ultima
        %parte de la correlacion de la parte B
        for i= (size_tramo*2)+1 : (size_tramo*3) 
           tramo_y1(i-(size_tramo*2)) = env_med_int_d(i) ;
        end

        corr_tramo_y1 =  xcorr(tramo_y1,patron_d);
        size_corr = max((size(corr_tramo_y1)));
        if  rem(size_corr,2)~=0
            corr_tramo_y1(1,size_corr+1) = 0;
        end
        size_corr = max((size(corr_tramo_y1)));

        %sumamos la primera parte de C a la ultima parte de B:
        for i= 1 :  (size_corr/2)
           corr_completa_y1(i) = corr_completa_y1(i) + corr_tramo_y1(i);
        end

        %ahora hallamos el maximo de la 2da parte de la correlacion valida
        [V_t2 TOF_t2] = max( corr_completa_y1);

%         figure
%         plot(corr_completa_y1)
%         title("tramo 2 med")

        %hallamos el maximo entre ambos maximos:
        %max_corr_y1 = max(V_t2,V_t1)
        if V_t2 > V_t1 
            Vp = V_t2;
            TOF2 = TOF_t2 + (size_corr/2); % se le suma el size_corr/2 pq este indice corresponde al 2do tramo de la correlacion valida
        elseif V_t1 > V_t2 
            Vp = V_t1;
            TOF2 = TOF_t1;
        end



        %% se calcula el tiempo de vuelo y la distancia entre los ecos con las correlaciones realizadas por partes
        %[TOF1 TOF2]
        TOF1_v(count_med) = TOF1
        TOF2_v(count_med) = TOF2
        Distancia(count_med) =340000*[(TOF2-TOF1)*1/(3*fs)]

        count_med = count_med+1;
    
    prompt = 'Presione Enter para medir de nuevo, introduzca otro caracter para terminar de medir. ';
    txt = input(prompt);
    if isempty(txt)
        txt = 'Y';
    end
    if ~isequal(txt,'Y')
        flag = 0;        
    end
end

%% Clean up the serial port
flushinput(s);
fclose(s);
delete(s);
clear s;
disp("Puerto serial cerrado")
