%Realizar la medición del TOF utilizando la derivada de la envolvente
%Correlacion derivada sin submuestreo, con INTERPOLACION DE MUESTRAS
clear all
close all

%Señal canal sin viento
A0 = 10;        %amplitud de la senal
fc = 40e3;     %frecuencia de resonancia del sensor
fs = 400e3;      %frecuencia de muestreo
m = 1.5;        %indice de modulacion
T = 0.3e-3;       %ancho del pulso
tau = 2e-3;     %Ventana temporal
N = 4096;       %cantidad de puntos

eco = gen_eco(A0, fc,fs,m,T,tau,N);     %genera el pulso de referencia

%% deriva de amstrong 
%filtro analogico cero - polo frecuencia de corte superior 60000
fss = fc;     %Doble de la frecuencia de la portadora
a = 2*10e3*pi;  %Ancho de banda del transductor
num = [1 0];
den = [1 a]; % se usa el polo para limitar el ancho de banda de la derivada
%Se digitaliza el filtro para hallar la derivada
[numd, dend] = bilinear(num,den,fss);
derivadorS = tf(num,den);
derivadorZ = tf(numd,dend,1); % para tener la ecuacion en diferencia que va en el PSoC

Ts = 1/fs;
final = (round(max(size(eco))) - 1);
t = [0:Ts:final*Ts];

%se halla la envolvente utilizando la transformada de hilbert
env_y = abs(hilbert(eco));
%% se interpola la envolvente para obterner mas resolucion
%env_y_int = interp(env_y,5);

%primero agregamos los puntos intermedios en cada muestra
j = 1;
for i=1 : N
    env_y_0(j) = env_y(i);
    env_y_0(j+1) = env_y(i);
    env_y_0(j+2) = env_y(i);
    %env_y_0(j+3) = 0;
    j = j+3;
end

%pasamos la envolvente por un paso bajos con frecuencia de corte a 3k para
%interpolar la senhal, para esto primero disenhamos el filtro paso bajos
%neecesario:
M = 3;
fss_lp = M*fs;
fc_lp = 10e3;

lp_interpolador = fir1(60,fc_lp/(fss_lp/2)); %para que pase hasta 10k
%Se digitaliza el filtro 

env_y_int = filter(lp_interpolador,1,env_y_0);
env_y_int = M.*env_y_int;


%% interpolacion con resample

envolvente_r = resample(env_y,3,1,5,20);

% figure
% subplot(311)
% plot(env_y)
% title(' envolvente sin interpolar.')
% subplot(312)
% plot(env_y_int)
% title(' envolvente interpolada.')
% subplot(313)
% plot(envolvente_r)
% title(' envolvente resample.')

%% derivamos ambas senhales, la interpolada y la no, para compararlas
 env_y_d = filter(numd,dend,env_y);%se deriva la envolvelnte sin interpolar
 env_y_int_d = filter(numd,dend,env_y_int);%se deriva la envolvelnte interpolada
 env_r_d = filter(numd,dend,envolvente_r); %se deriva la envolvente con resample
% figure
% subplot(311)
% plot(env_y_d)
% title(' envolvente sin interpolar D.')
% subplot(312)
% plot(env_y_int_d)
% title(' envolvente interpolada D.')
% subplot(313)
% plot(env_r_d)
% title(' envolvente resample D.')

%% continua
figure
subplot(211)
plot(t,eco,t,env_y)
title('Pulso sintético y su envolvente.')
legend('Pulso', 'Envolvente')
subplot(212)
plot(env_y_int_d)
title('Derivada de la envolvente.')

%se selecciona cual sera el patron, esto se hace seleccionando una ventana
%temporanl en la curva de la envolventa derivada
[ind val] = ginput(2);

%Se define el patron desde la derivada
patron_d = env_y_int_d(1,floor(ind(1,1)):floor(ind(2,1)));
% patron_size = max(size(patron_d));
% if  rem(patron_size,2)==0
%     patron_d(1,patron_size+1) = 0;
% end

figure(2)
plot(patron_d);
title('Patron de la derivada')

%se crea una senal de canal con viento a favor
tau = tau + 1e-3;                       %se desplaza en el tiempo
eco1 = gen_eco(A0, fc,fs,m,T,tau,N);    %se genera el otro pulso desplazado

figure
plot(t,eco,'r')
hold on
plot(t,eco1,'b')
title('Pulsos generados')

eco1 = awgn(eco1,30); %agregamos el ruido blanco gausiano al 2ndo pulso

%se obtiene la envolvente del segundo eco generado
env_y1 = abs(hilbert(eco1));

%% se interpola la envolvente del segundo eco
%primero agregamos los puntos intermedios en cada muestra
j = 1;
for i=1 : N
    env_y1_0(j) = env_y1(i);
    env_y1_0(j+1) = env_y1(i);
    env_y1_0(j+2) = env_y1(i);
    %env_y1_0(j+3) = 0;
    j = j+3;
end

env_y1_int = filter(lp_interpolador,1,env_y1_0);
env_y1_int = M.*env_y1_int;

%% se deriva la envolvente interpolada del segundo eco
env_y1_int_d = filter(numd,dend,env_y1_int);

% figure
% subplot(211)
% plot(env_y1_int)
% title("Envolvente interpolada 2")
% subplot(212)
% plot(env_y1_int_d)
% title("derivada de envolvente interpolada 2")
%% Se calculan los TOFs haciendo la correlación con la derivada del patrón y hallando el máximo

xcorr_y1 = xcorr(env_y1_int_d,patron_d);
xcorr_y = xcorr(env_y_int_d,patron_d);

[V TOF2] = max(xcorr_y1);

[Vp TOF1] = max(xcorr_y);

figure
plot(xcorr_y1);
hold on
plot(xcorr_y,'r');
title('Correlacion Normal')

%[TOF1 TOF2]
TOF_xcorr =[(TOF2-TOF1)*1/(4*fs)]


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
%% CORRELACION DE LA SENHAL Y1 (EL 2DO ECO CREADO CON RUIDO Y DESPLAZADO)
 
size_tramo = max(size(env_y1_int_d))/3;
tramo_y1 = zeros(1,size_tramo);

%solo nos importan los tramos 2 y 3, desde N hasta 3N
%primer tramo, 2/4
%iniciamos por la parte A, calculomos su correlacion con el patron:
for i=1 : size_tramo
   tramo_y1(i) = env_y1_int_d(i) ;
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
   tramo_y1(i-size_tramo) = env_y1_int_d(i) ;
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
title("tramo 1")

%ahora procedemos a realizar el segundo tramo 
%guardamos la ultima parte de B para luego sumarle la primera parte de C
for i= ((size_corr)/2)+1 : size_corr
   corr_completa_y1(i-(size_corr/2)) = corr_tramo_y1(i); %se sobreescribe el vector corr_completa
end

%ahora calculamos la correlacion de la parte C para sumarla a la ultima
%parte de la correlacion de la parte B
for i= (size_tramo*2)+1 : (size_tramo*3) 
   tramo_y1(i-(size_tramo*2)) = env_y1_int_d(i) ;
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

figure
plot(corr_completa_y1)
title("tramo 2")

%hallamos el maximo entre ambos maximos:
%max_corr_y1 = max(V_t2,V_t1)
if V_t2 > V_t1 
    Vp = V_t2;
    TOF2 = TOF_t2 + (size_corr/2); % se le suma el size_corr/2 pq este indice corresponde al 2do tramo de la correlacion valida
elseif V_t1 > V_t2 
    Vp = V_t1;
    TOF2 = TOF_t1;
end

%% CORRELACION DE LA SENHAL Y (EL 1er ECO, LA REFERENCIA)
%esta parte aun esta con el algoritmo de correlacion de la version 1 para
%probar que ambos tienen el mismo resultado
%primero partimos el vector a correlacionar en 3 partes
size_tramo = max(size(env_y_int_d))/3;
tramo_y = zeros(1,size_tramo);

%solo nos importan los tramos 2 y 3, desde N hasta 3N
%primer tramo, 2/4
%iniciamos por la parte A, calculomos su correlacion con el patron:
for i=1 : size_tramo
   tramo_y(i) = env_y_int_d(i) ;
end

corr_tramo_y =  xcorr(tramo_y,patron_d);
size_corr = max((size(corr_tramo_y)));
if  rem(size_corr,2)~=0
    corr_tramo_y(1,size_corr+1) = 0;
end
size_corr = max((size(corr_tramo_y)));
%guardamos la seguda parte de la correlacion de A en el vector de
%correlacion valido:
for i= 1 :  ((size_corr)/2)
   corr_completa_y(i) = corr_tramo_y(i + ((size_corr)/2) -1);
end
% debemos de sumar la ultima parte de la correlacion de la parte A a la primera parte correlacion 
% de la parte B, calculamos la correlacion de la parte B:
for i = size_tramo+1 : (size_tramo*2)
   tramo_y(i-size_tramo) = env_y_int_d(i) ;
end

corr_tramo_y =  xcorr(tramo_y,patron_d);
size_corr = max((size(corr_tramo_y)));
if  rem(size_corr,2)~=0
    corr_tramo_y(1,size_corr+1) = 0;
end
size_corr = max((size(corr_tramo_y)));

%sumamos a la ultima parte de A la primera parte de B:
for i= 1:((size_corr)/2)
   corr_completa_y(i) = corr_completa_y(i) + corr_tramo_y(i);
end
%guardamos la ultima parte de B para luego sumarle la primera parte de C
for i= ((size_corr)/2)+1 : size_corr
   corr_completa_y(i) = corr_tramo_y(i);
end

%ahora calculamos la correlacion de la parte C para sumarla a la ultima
%parte de la correlacion de la parte B
for i= (size_tramo*2)+1 : (size_tramo*3) 
   tramo_y(i-(size_tramo*2)) = env_y_int_d(i) ;
end

corr_tramo_y =  xcorr(tramo_y,patron_d);
size_corr = max((size(corr_tramo_y)));
if  rem(size_corr,2)~=0
    corr_tramo_y(1,size_corr+1) = 0;
end
size_corr = max((size(corr_tramo_y)));

%sumamos la primera parte de C a la ultima parte de B:
for i= (size_corr/2)+1 :  size_corr 
   corr_completa_y(i) = corr_completa_y(i) + corr_tramo_y(i-(size_corr/2));
end


%% se grafican los resultados de las correlaciones

%figure
%plot( corr_completa_y,'r')
%hold on
%plot( corr_completa_y1)
%title('Correlacion OnA Valida')

%% se calcula el tiempo de vuelo y la distancia entre los ecos con las correlaciones realizadas por partes
[V TOF1] = max( corr_completa_y);
%[Vp TOF2] = max( corr_completa_y1);

%[TOF1 TOF2]
TOF_OnA =[(TOF2-TOF1)*1/(4*fs)]

