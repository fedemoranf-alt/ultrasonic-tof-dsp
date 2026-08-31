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
a = 2*0.5e3*pi;  %Ancho de banda del transductor
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
fc = fs/(2*3);

lp_interpolador = fir1(60,fc/1200000);
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
title('Correlacion')

%[TOF1 TOF2]
TOF_xcorr =[(TOF2-TOF1)*1/(4*fs)]

%% correlacion realizada por partes "Overlap and Add"
%% CORRELACION DE LA SENHAL Y1 (EL 2DO ECO CREADO CON RUIDO Y DESPLAZADO)
%primero partimos el vector a correlacionar en 3 partes
size_partes = max(size(env_y1_int_d))/3;
derivada_y1_A = zeros(1,size_partes);
derivada_y1_B = zeros(1,size_partes);
derivada_y1_C = zeros(1,size_partes);

for i=1 : size_partes
   derivada_y1_A(i) = env_y1_int_d(i) ;
end
for i = size_partes+1 : (size_partes*2)
   derivada_y1_B(i-size_partes) = env_y1_int_d(i) ;
end
for i= (size_partes*2)+1 : (size_partes*3) 
   derivada_y1_C(i-(size_partes*2)) = env_y1_int_d(i) ;
end

corr_A_y1 =  xcorr(derivada_y1_A,patron_d);
corr_B_y1 =  xcorr(derivada_y1_B,patron_d);
corr_C_y1 =  xcorr(derivada_y1_C,patron_d);
size_corr = max((size(corr_A_y1)));

if  rem(size_corr,2)~=0
    corr_A_y1(1,size_corr+1) = 0;
    corr_B_y1(1,size_corr+1) = 0;
    corr_C_y1(1,size_corr+1) = 0;
end
size_corr = max((size(corr_A_y1)));
%ahora se deben de solapar y sumar las correlaciones 
for i= 1 :  ((size_corr)/2)
   corr_completa_y1(i) = corr_A_y1(i);
end
for i= (size_corr/2)+1 :  size_corr
   corr_completa_y1(i) = corr_A_y1(i) + corr_B_y1(i-(size_corr/2));
end
for i= (size_corr)+1 :  size_corr + (size_corr/2)
   corr_completa_y1(i) = corr_B_y1(i-(size_corr/2)) + corr_C_y1(i-size_corr);
end
for i= size_corr + (size_corr/2)+1 :  size_corr*2
   corr_completa_y1(i) = corr_C_y1(i-(size_corr + (size_corr/2)));
end


% solo es valida la parte del medio de la suma de las correlaciones, desde el indice max hasta
% el indice max*3
for i= ((size_corr/2)+1) :((size_corr/2)*3) 
   corr_val_y1(i-(size_corr/2)) = corr_completa_y1(i);
end

%% CORRELACION DE LA SENHAL Y (EL 1ER ECO, LA REFERENCIA)
%primero partimos el vector a correlacionar en 3 partes
size_partes = max(size(env_y_int_d))/3;
derivada_y_A = zeros(1,size_partes);
derivada_y_B = zeros(1,size_partes);
derivada_y_C = zeros(1,size_partes);

for i=1 : size_partes
   derivada_y_A(i) = env_y_int_d(i) ;
end
for i = size_partes+1 : (size_partes*2)
   derivada_y_B(i-size_partes) = env_y_int_d(i) ;
end
for i= (size_partes*2)+1 : (size_partes*3) 
   derivada_y_C(i-(size_partes*2)) = env_y_int_d(i) ;
end

corr_A_y =  xcorr(derivada_y_A,patron_d);
corr_B_y =  xcorr(derivada_y_B,patron_d);
corr_C_y =  xcorr(derivada_y_C,patron_d);
size_corr = max((size(corr_A_y)));

if  rem(size_corr,2)~=0
    corr_A_y(1,size_corr+1) = 0;
    corr_B_y(1,size_corr+1) = 0;
    corr_C_y(1,size_corr+1) = 0;
end
size_corr = max((size(corr_A_y)));
%ahora se deben de solapar y sumar las correlaciones 
for i= 1 :  ((size_corr)/2)
   corr_completa_y(i) = corr_A_y(i);
end
for i= (size_corr/2)+1 :  size_corr
   corr_completa_y(i) = corr_A_y(i) + corr_B_y(i-(size_corr/2));
end
for i= (size_corr)+1 :  size_corr + (size_corr/2)
   corr_completa_y(i) = corr_B_y(i-(size_corr/2)) + corr_C_y(i-size_corr);
end
for i= size_corr + (size_corr/2)+1 :  size_corr*2
   corr_completa_y(i) = corr_C_y(i-(size_corr + (size_corr/2)));
end


% solo es valida la parte del medio de la suma de las correlaciones, desde el indice max hasta
% el indice max*3
for i= ((size_corr/2)+1) :((size_corr/2)*3) 
   corr_val_y(i-(size_corr/2)) = corr_completa_y(i);
end

%% se grafican los resultados de las correlaciones
figure
subplot(311)
plot(corr_A_y1)
title('Parte A')
subplot(312)
plot(corr_B_y1)
title('Parte B')
subplot(313)
plot(corr_C_y1)
title('Parte C')

figure
plot(corr_completa_y,'r')
hold on
plot(corr_completa_y1)
title('Correlacion OnA Completa')

figure
plot(corr_val_y,'r')
hold on
plot(corr_val_y1)
title('Correlacion OnA Valida')

%% se calcula el tiempo de vuelo y la distancia entre los ecos con las correlaciones realizadas por partes
[V TOF1] = max(corr_val_y);
[Vp TOF2] = max(corr_val_y1);

%[TOF1 TOF2]
TOF_OnA =[(TOF2-TOF1)*1/(4*fs)]

