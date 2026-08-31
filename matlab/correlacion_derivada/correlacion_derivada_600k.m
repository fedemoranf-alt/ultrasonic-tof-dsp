%Realizar la medición del TOF utilizando la derivada de la envolvente
%Correlacion derivada sin submuestreo.

% SE USA UNA FRECUENCIA DE MUESTREO DE 600K

clear all
close all

%Señal canal sin viento
A0 = 10;        %amplitud de la senal
fc = 40e3;     %frecuencia de resonancia del sensor
fs = 600e3;      %frecuencia de muestreo
m = 1.5;        %indice de modulacion
T = 0.3e-3;       %ancho del pulso
tau = 2e-3;     %Ventana temporal
N = 2048;       %cantidad de puntos

eco = gen_eco(A0, fc,fs,m,T,tau,N);     %genera el pulso de referencia


%filtro analogico cero - polo frecuencia de corte superior 60000
fss = fs;     %Doble de la frecuencia de la portadora
a = 2*8e3*pi;  %Ancho de banda del transductor
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
env_y_d = filter(numd,dend,env_y);%se deriva la envolvelnte 
figure(1)
subplot(211)
plot(t,eco,t,env_y)
title('Pulso sintético y su envolvente.')
legend('Pulso', 'Envolvente')
subplot(212)
plot(env_y_d)
title('Derivada de la envolvente.')

%se selecciona cual sera el patron, esto se hace seleccionando una ventana
%temporanl en la curva de la envolventa derivada
[ind val] = ginput(2);

%Se define el patron desde la derivada
patron_d = env_y_d(1,floor(ind(1,1)):floor(ind(2,1)));
figure(2)
plot(patron_d);
title('Patron de la derivada')

%se crea una senal de canal con viento a favor
tau = tau + 1e-3;                       %se desplaza en el tiempo
eco1 = gen_eco(A0, fc,fs,m,T,tau,N);    %se genera el otro pulso desplazado

figure(3)
plot(t,eco,'b')
hold on
plot(t,eco1,'r')
title('Pulsos generados')

eco1 = awgn(eco1,40); %agregamos el ruido blanco gausiano al 2ndo pulso

%se obtiene la envolvente del segundo eco generado
env_y1 = abs(hilbert(eco1));
env_y1_d = filter(numd,dend,env_y1);%se deriva la envolvelnte 

%Se calculan los TOFs haciendo la correlación con la derivada del patrón y
%hallando el máximo

xcorr_y1 = xcorr(patron_d,env_y1_d);
xcorr_y = xcorr(patron_d,env_y_d);

[Vp TOF1] = max(xcorr_y1);

[V TOF2] = max(xcorr_y);

figure(4)
plot(xcorr_y1);
hold on
plot(xcorr_y,'r');
title('Correlacion')

%[TOF1 TOF2]
[(TOF2-TOF1)*1/fs]

%% comparar senales con diferentes valores de SNR
SNR = -20;

for i=1 : 81
    out1 = awgn(eco1,SNR);
    SNR=SNR+1;
    env_y1 = abs(hilbert(out1)); %se obtiene la envolvente
    env_y1_d = filter(numd,dend,env_y1);%se deriva la envolvente
    xcorr_y1 = xcorr(patron_d,env_y_d);
    [V TOF2] = max(xcorr_y1);
    TOF(i) = abs((TOF2-TOF1)*1/fss);
end

x = [-20:1:60];
offset = 3e-6*ones(81);
figure(6)
plot(x,offset,'r','linewidth',1)
hold on
plot(x,TOF,'--gs',...
    'LineWidth',2,...
    'MarkerSize',10,...
    'MarkerEdgeColor','b',...
    'MarkerFaceColor',[0.5,0.5,0.5])

title('Desviacion del TOF')
ylabel('Tiempo')
xlabel('SNR')


