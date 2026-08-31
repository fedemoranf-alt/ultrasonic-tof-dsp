%% medidor de distancia, 
%para probar el algoritmo de de medicion en matlab pero con los datos
%digitalizados por el psoc, se utiliza el vector del eco
clear all 
close all

fc = 40e3;     %frecuencia de resonancia del sensor
fs = 400e3;      %frecuencia de muestreo
N = 1024;
M = 0.01; %intervalo entre puntos para la interpolacion de la recta ajustada
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


%% filtro demodulador

% fir_dem = [ 0.0043,    0.0052,    0.0073,    0.0109,    0.0157,    0.0217,    0.0285,    0.0359,    0.0435,    0.0508,    0.0574,    0.0631,    0.0673,...
%             0.0700,    0.0709,    0.0700,    0.0673,    0.0631,    0.0574,    0.0508,    0.0435,    0.0359,    0.0285,    0.0217,    0.0157,    0.0109,...
%             0.0073,    0.0052,    0.0043  ];

fir_dem = fir1(65,0.1,blackman(66));


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

% figure
% plot(eco_refe)
% title('Eco y su envolvente, Referencia')
% hold on
% plot(env_refe)

%% Hallaremos una recta entre el 90% y el 10% de valor maximo de la envolvente utilizando el ajuste de minimos cuadrados y luego la intersectaremos con el punto de valor Vmax/2 de la envolvente para obtener el TOF

%se halla el valor maximo de la envolvente:
[env_refe_max_v env_refe_max_i ] = max(env_refe);
env_refe_max_90_v = 0.75*env_refe_max_v; % el valor del 90% del max de la envolvente
%se busca que punto de la envolvente posee el valor del 90% de la misma:
% se resta el valor de env_max_90 con cada punto de la envolvente y busca el que posee el menor error para identificar donde se encuentra el valor de 90% de la envolvente  
error = 1;
for i= 1 : env_refe_max_i
   aux = abs(env_refe_max_90_v - env_refe(i));
   if (aux < error) 
        error = aux;
        env_refe_max_90_i = i; 
   end
end

% se realiza el mismo procedimiento para hallar la ubicacion del valor del
% 10% del maximo de la envolvente
env_refe_max_10_v = 0.25*env_refe_max_v;
error = 1;
for i = 1 : env_refe_max_i
   aux = (abs(env_refe_max_10_v - env_refe(i)) + 0.001*abs(i - env_refe_max_i));
   if (aux < error)
      error = aux;
      env_refe_max_10_i = i;
   end
end

%% armamos el vector de datos que vamos a ajustar, este va desde env_max_10_i hasta env_max_90_i
voltajes_pa = env_refe(env_refe_max_10_i : env_refe_max_90_i);
indices_pa = [env_refe_max_10_i : 1 : env_refe_max_90_i];
% figure
% plot(indices_pa,voltajes_pa)
% title("Seccion de la envolvente a ajustar, Referencia")

%% procedemos a ajustar los datos a un polinomio de 1er orden, una recta.
% y = a*x + b
coef_refe = polyfit(indices_pa,voltajes_pa,1);
cruce_0_refe = -(coef_refe(2)/coef_refe(1));   % si y=0, -> x = -b/a
indices_pa = [floor(cruce_0_refe) : 1: env_refe_max_90_i];
recta_ajustada_refe = polyval(coef_refe,indices_pa);

% figure
% plot(indices_pa,recta_ajustada_refe)
% title("Recta ajustada, Referencia")

%% ahora debemos de hallar la interseccion de la recta con el valor de Vmax/2 de la envolvente, este punto sera el TOF de referencia

%para mejorar aca se debe de interpolar la recta antes de hallar la interseccion para mejor resolucion 
%% Interpolacion de la recta ajustada
indices_int = [cruce_0_refe : 0.01 : env_refe_max_90_i]; 
recta_ajustada_refe_int = interp1(indices_pa,recta_ajustada_refe,indices_int);
% figure
% plot(indices_int,recta_ajustada_refe_int)
% title("recta ajustada interpolada, Referencia")
%%
longitud_recta_int = max(size(recta_ajustada_refe_int));
error = 1;
for i= 1 : longitud_recta_int
   aux = abs((env_refe_max_v/2)- recta_ajustada_refe_int(i));
   if (aux < error) 
        error = aux;
        interseccion_recta_refe = indices_int(i); 
   end
end

recta_Vmax2_refe = ones(longitud);
recta_Vmax2_refe = (env_refe_max_v/2).*recta_Vmax2_refe; % solo para graficar

figure
subplot(211)
plot(eco_refe)
title('Eco y su envolvente, Referencia')
hold on
plot(env_refe)
hold on
plot(indices_pa,recta_ajustada_refe,'r')
subplot(212)
plot(env_refe)
hold on
plot(indices_int,recta_ajustada_refe_int)
hold on
plot(recta_Vmax2_refe)
hold on
plot(interseccion_recta_refe,env_refe_max_v/2,'*')
hold on
plot(cruce_0_refe,0,'*')
title("Interseccion Referencia")

TOF1 = interseccion_recta_refe;
TOF1_0 = cruce_0_refe;

%% iniciamos las mediciones a partir de la referencia tomada
disp("Presione una tecla para continuar e iniciar las mediones de distancia")
pause

flag = 1;
count_med = 1;
flushinput(s);

while(count_med < 100)
        %% Se pide al psoc una nueva medicion del eco
        fwrite(s,'T')
        pause(5)
        
        MaxDeviation = 3;%Maximum Allowable Change from one value to next 
        TimeInterval=0.001;%time interval between each input.
        tiempo = 0;
        eco_med = 0;

%         % Se configura el gráfico 
%         figureHandle = figure('NumberTitle','off',...
%             'Name','Señal de Eco medido',...
%             'Color',[0 0 0],'Visible','off');
%         % Set axes
%         axesHandle = axes('Parent',figureHandle,...
%             'YGrid','on',...
%             'YColor',[0.9725 0.9725 0.9725],...
%             'XGrid','on',...
%             'XColor',[0.9725 0.9725 0.9725],...
%             'Color',[0 0 0]);
%         hold on;
% 
%         plotHandle = plot(axesHandle,tiempo,eco_med,'Marker','.','LineWidth',1,'Color',[0 1 0]);
%         % Create xlabel
%         xlabel('Tiempo(seg)','FontWeight','bold','FontSize',14,'Color',[1 1 0]);
%         % Create ylabel
%         ylabel('Tensión(Voltios)','FontWeight','bold','FontSize',14,'Color',[1 1 0]);
%         % Create title
%         msg = ['Muestras=',num2str(longitud),'   Fs=',num2str(fs), ' Hz'];
%         title(msg,'FontSize',15,'Color',[1 1 0]);

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
%         set(plotHandle,'YData',eco_med,'XData',tiempo);
%         set(figureHandle,'Visible','on');
         count = count+1;
        end
        eco_med(1024)=0;
        
        %% se halla la envolvente utilizando la transformada de hilbert
        env_r = abs(hilbert(eco_med));
        env_med = filter(fir_dem,1,env_r);

%         figure
%         plot(eco_med)
%         title('Eco y su envolvente, Medida')
%         hold on
%         plot(env_med)

        %% Hallaremos una recta entre el 90% y el 10% de valor maximo de la envolvente utilizando el ajuste de minimos cuadrados y luego la intersectaremos con el punto de valor Vmax/2 de la envolvente para obtener el TOF

        %se halla el valor maximo de la envolvente:
        [env_med_max_v env_med_max_i ] = max(env_med);
        env_med_max_90_v = 0.75*env_med_max_v; % el valor del 90% del max de la envolvente
        %se busca que punto de la envolvente posee el valor del 90% de la misma:
        % se resta el valor de env_max_90 con cada punto de la envolvente y busca el que posee el menor error para identificar donde se encuentra el valor de 90% de la envolvente  
        error = 1;
        for i= 1 : env_med_max_i
           aux = abs(env_med_max_90_v - env_med(i));
           if (aux < error) 
                error = aux;
                env_med_max_90_i = i; 
           end
        end

        % se realiza el mismo procedimiento para hallar la ubicacion del valor del
        % 10% del maximo de la envolvente
        env_med_max_10_v = 0.25*env_med_max_v;
        error = 1;
        for i = 1 : env_med_max_i
           aux = (abs(env_med_max_10_v - env_med(i)) + 0.001*abs(i - env_med_max_i));
           if (aux < error)
              error = aux;
              env_med_max_10_i = i;
           end
        end

        %% armamos el vector de datos que vamos a ajustar, este va desde env_max_10_i hasta env_max_90_i
        voltajes_pa_med = env_med(1,env_med_max_10_i : env_med_max_90_i);
        indices_pa_med = [env_med_max_10_i : 1: env_med_max_90_i];
%         figure
%         plot(indices_pa_med,voltajes_pa_med)
%         title("Seccion de la envolvente a ajustar, Medida")

        %% procedemos a ajustar los datos a un polinomio de 1er orden, una recta.
        % y = a*x + b
        coef_med = polyfit(indices_pa_med,voltajes_pa_med,1);
        cruce_0_med = -(coef_med(2)/coef_med(1));   % si y=0, -> x = -b/a
        indices_pa_med = [floor(cruce_0_med) : 1: env_med_max_90_i];
        recta_ajustada_med = polyval(coef_med,indices_pa_med);

%         figure
%         plot(indices_pa_med,recta_ajustada_med)
%         title("Recta ajustada, Medida")

        %% ahora debemos de hallar la interseccion de la recta con el valor de Vmax/2 de la envolvente, este punto sera el TOF de medrencia

        %para mejorar aca se debe de interpolar la recta antes de hallar la interseccion para mejor resolucion 
        %% Interpolacion de la recta ajustada
        indices_int = [cruce_0_med : 0.01 : env_med_max_90_i]; 
        recta_ajustada_med_int = interp1(indices_pa_med,recta_ajustada_med,indices_int);
%         figure
%         plot(indices_int,recta_ajustada_med_int)
%         title("recta ajustada interpolada, Medida")
        %%
        longitud_recta_int = max(size(recta_ajustada_med_int));
        error = 1;
        for i= 1 : longitud_recta_int
           aux = abs((env_med_max_v/2)- recta_ajustada_med_int(i));
           if (aux < error) 
                error = aux;
                interseccion_recta_med = indices_int(i); 
           end
        end

        recta_Vmax2_med = ones(longitud);
        recta_Vmax2_med = (env_med_max_v/2).*recta_Vmax2_med; % solo para graficar

%         figure
%         subplot(211)
%         plot(eco_med)
%         title('Eco y su envolvente, Medida')
%         hold on
%         plot(env_med)
%         hold on
%         plot(indices_pa_med,recta_ajustada_med,'r')
%         subplot(212)
%         plot(env_med)
%         hold on
%         plot(indices_int,recta_ajustada_med_int)
%         hold on
%         plot(recta_Vmax2_med)
%         hold on
%         plot(interseccion_recta_med,env_med_max_v/2,'*')
%         hold on
%         plot(cruce_0_med,0,'*')
%         title("Interseccion Medida")

        TOF2 = interseccion_recta_med;
        TOF2_0 = cruce_0_med;



        %% se calcula el tiempo de vuelo y la distancia entre los ecos con las correlaciones realizadas por partes
        %[TOF1 TOF2]
        TOF1_v(count_med) = TOF1
        Vmax2_refe(count_med) = env_refe_max_v/2
        TOF2_v(count_med) = TOF2
        Vmax2_med(count_med) = env_med_max_v/2 
        Distancia(count_med) =340000*[(TOF2-TOF1)*1/(fs)]
        
        TOF1_0_v(count_med) = TOF1_0
        TOF2_0_v(count_med) = TOF2_0 
        Distancia_0(count_med) =340000*[(TOF2_0 - TOF1_0)*1/(fs)]
        
        count_med = count_med+1;
    
%     prompt = 'Presione Enter para medir de nuevo, introduzca otro caracter para terminar de medir. ';
%     txt = input(prompt);
%     if isempty(txt)
%         txt = 'Y';
%     end
%    if ~isequal(txt,'Y') 
%        flag = 0;        
%    end
end

%% Clean up the serial port
flushinput(s);
fclose(s);
delete(s);
clear s;
disp("Puerto serial cerrado")

%% Se guardan los datos de las mediciones en un archivo.m
save('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\min_cua3.mat','TOF1_v','TOF2_v','Distancia','TOF1_0_v','TOF2_0_v','Distancia_0')

