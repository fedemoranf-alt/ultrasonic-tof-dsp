%% graficos finales para el paper



SNR1 = 5; SNR2 = 15; SNR3 = 25; SNR4 = 35;
aux_eco_crudo= load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\comp_SNR\eco_crudo2.mat');
aux_env = load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\comp_SNR\envolvente2.mat');
aux_deriv = load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\comp_SNR\env_int2.mat');
aux_deriv_prom= load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\comp_SNR\env_int_prom2.mat');
aux_deriv_eco_int= load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\comp_SNR\eco_int2.mat');
aux_AIC  = load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\comp_SNR\AIC2.mat');

valor_real = [-100:10:100];

i= 1;
while (i < 22)
    
    %% Eco crudo
   %SNR1
   promedio_dist_SNR1_eco_crudo(i) = mean(aux_eco_crudo.Distancia_SNR1(i,:)); 
   sigma_dist_SNR1_eco_crudo(i) = std(aux_eco_crudo.Distancia_SNR1(i,:));
   error_SNR1_eco_crudo(i) = valor_real(i) - promedio_dist_SNR1_eco_crudo(i);
   %SNR2
   promedio_dist_SNR2_eco_crudo(i) = mean(aux_eco_crudo.Distancia_SNR2(i,:)); 
   sigma_dist_SNR2_eco_crudo(i) = std(aux_eco_crudo.Distancia_SNR2(i,:));
   error_SNR2_eco_crudo(i) = valor_real(i) - promedio_dist_SNR2_eco_crudo(i);
   %SNR3
   promedio_dist_SNR3_eco_crudo(i) = mean(aux_eco_crudo.Distancia_SNR3(i,:)); 
   sigma_dist_SNR3_eco_crudo(i) = std(aux_eco_crudo.Distancia_SNR3(i,:));
   error_SNR3_eco_crudo(i) = valor_real(i) - promedio_dist_SNR3_eco_crudo(i);
   %SNR4
   promedio_dist_SNR4_eco_crudo(i) = mean(aux_eco_crudo.Distancia_SNR4(i,:)); 
   sigma_dist_SNR4_eco_crudo(i) = std(aux_eco_crudo.Distancia_SNR4(i,:));
   error_SNR4_eco_crudo(i) = valor_real(i) - promedio_dist_SNR4_eco_crudo(i); 
   
   %% Envolvente
   %SNR1
   promedio_dist_SNR1_env(i) = mean(aux_env.Distancia_SNR1(i,:)); 
   sigma_dist_SNR1_env(i) = std(aux_env.Distancia_SNR1(i,:));
   error_SNR1_env(i) = valor_real(i) - promedio_dist_SNR1_env(i);
   %SNR2
   promedio_dist_SNR2_env(i) = mean(aux_env.Distancia_SNR2(i,:)); 
   sigma_dist_SNR2_env(i) = std(aux_env.Distancia_SNR2(i,:));
   error_SNR2_env(i) = valor_real(i) - promedio_dist_SNR2_env(i);
   %SNR3
   promedio_dist_SNR3_env(i) = mean(aux_env.Distancia_SNR3(i,:)); 
   sigma_dist_SNR3_env(i) = std(aux_env.Distancia_SNR3(i,:));
   error_SNR3_env(i) = valor_real(i) - promedio_dist_SNR3_env(i);
   %SNR4
   promedio_dist_SNR4_env(i) = mean(aux_env.Distancia_SNR4(i,:)); 
   sigma_dist_SNR4_env(i) = std(aux_env.Distancia_SNR4(i,:));
   error_SNR4_env(i) = valor_real(i) - promedio_dist_SNR4_env(i); 
   
   %% Derivada de la envolvente interpolada
      %SNR1
   promedio_dist_SNR1_deriv(i) = mean(aux_deriv.Distancia_SNR1(i,:)); 
   sigma_dist_SNR1_deriv(i) = std(aux_deriv.Distancia_SNR1(i,:));
   error_SNR1_deriv(i) = valor_real(i) - promedio_dist_SNR1_deriv(i);
   %SNR2
   promedio_dist_SNR2_deriv(i) = mean(aux_deriv.Distancia_SNR2(i,:)); 
   sigma_dist_SNR2_deriv(i) = std(aux_deriv.Distancia_SNR2(i,:));
   error_SNR2_deriv(i) = valor_real(i) - promedio_dist_SNR2_deriv(i);
   %SNR3
   promedio_dist_SNR3_deriv(i) = mean(aux_deriv.Distancia_SNR3(i,:)); 
   sigma_dist_SNR3_deriv(i) = std(aux_deriv.Distancia_SNR3(i,:));
   error_SNR3_deriv(i) = valor_real(i) - promedio_dist_SNR3_deriv(i);
   %SNR4
   promedio_dist_SNR4_deriv(i) = mean(aux_deriv.Distancia_SNR4(i,:)); 
   sigma_dist_SNR4_deriv(i) = std(aux_deriv.Distancia_SNR4(i,:));
   error_SNR4_deriv(i) = valor_real(i) - promedio_dist_SNR4_deriv(i); 
   
   %% Derivada de la envolvente interpolada con promediado del patron
   %SNR1
   promedio_dist_SNR1_deriv_prom(i) = mean(aux_deriv_prom.Distancia_SNR1(i,:)); 
   sigma_dist_SNR1_deriv_prom(i) = std(aux_deriv_prom.Distancia_SNR1(i,:));
   error_SNR1_deriv_prom(i) = valor_real(i) - promedio_dist_SNR1_deriv_prom(i);
   %SNR2
   promedio_dist_SNR2_deriv_prom(i) = mean(aux_deriv_prom.Distancia_SNR2(i,:)); 
   sigma_dist_SNR2_deriv_prom(i) = std(aux_deriv_prom.Distancia_SNR2(i,:));
   error_SNR2_deriv_prom(i) = valor_real(i) - promedio_dist_SNR2_deriv_prom(i);
   %SNR3
   promedio_dist_SNR3_deriv_prom(i) = mean(aux_deriv_prom.Distancia_SNR3(i,:)); 
   sigma_dist_SNR3_deriv_prom(i) = std(aux_deriv_prom.Distancia_SNR3(i,:));
   error_SNR3_deriv_prom(i) = valor_real(i) - promedio_dist_SNR3_deriv_prom(i);
   %SNR4
   promedio_dist_SNR4_deriv_prom(i) = mean(aux_deriv_prom.Distancia_SNR4(i,:)); 
   sigma_dist_SNR4_deriv_prom(i) = std(aux_deriv_prom.Distancia_SNR4(i,:));
   error_SNR4_deriv_prom(i) = valor_real(i) - promedio_dist_SNR4_deriv_prom(i); 
   
   %% Derivada de la envolvente del eco interpolado
   %SNR1
   promedio_dist_SNR1_deriv_eco_int(i) = mean(aux_deriv_eco_int.Distancia_SNR1(i,:)); 
   sigma_dist_SNR1_deriv_eco_int(i) = std(aux_deriv_eco_int.Distancia_SNR1(i,:));
   error_SNR1_deriv_eco_int(i) = valor_real(i) - promedio_dist_SNR1_deriv_eco_int(i);
   %SNR2
   promedio_dist_SNR2_deriv_eco_int(i) = mean(aux_deriv_eco_int.Distancia_SNR2(i,:)); 
   sigma_dist_SNR2_deriv_eco_int(i) = std(aux_deriv_eco_int.Distancia_SNR2(i,:));
   error_SNR2_deriv_eco_int(i) = valor_real(i) - promedio_dist_SNR2_deriv_eco_int(i);
   %SNR3
   promedio_dist_SNR3_deriv_eco_int(i) = mean(aux_deriv_eco_int.Distancia_SNR3(i,:)); 
   sigma_dist_SNR3_deriv_eco_int(i) = std(aux_deriv_eco_int.Distancia_SNR3(i,:));
   error_SNR3_deriv_eco_int(i) = valor_real(i) - promedio_dist_SNR3_deriv_eco_int(i);
   %SNR4
   promedio_dist_SNR4_deriv_eco_int(i) = mean(aux_deriv_eco_int.Distancia_SNR4(i,:)); 
   sigma_dist_SNR4_deriv_eco_int(i) = std(aux_deriv_eco_int.Distancia_SNR4(i,:));
   error_SNR4_deriv_eco_int(i) = valor_real(i) - promedio_dist_SNR4_deriv_eco_int(i); 
   
   %% AIC Method
   %SNR1
   promedio_dist_SNR1_AIC(i) = mean(aux_AIC.Distancia_SNR1(i,:)); 
   sigma_dist_SNR1_AIC(i) = std(aux_AIC.Distancia_SNR1(i,:));
   error_SNR1_AIC(i) = valor_real(i) - promedio_dist_SNR1_AIC(i);
   %SNR2
   promedio_dist_SNR2_AIC(i) = mean(aux_AIC.Distancia_SNR2(i,:)); 
   sigma_dist_SNR2_AIC(i) = std(aux_AIC.Distancia_SNR2(i,:));
   error_SNR2_AIC(i) = valor_real(i) - promedio_dist_SNR2_AIC(i);
   %SNR3
   promedio_dist_SNR3_AIC(i) = mean(aux_AIC.Distancia_SNR3(i,:)); 
   sigma_dist_SNR3_AIC(i) = std(aux_AIC.Distancia_SNR3(i,:));
   error_SNR3_AIC(i) = valor_real(i) - promedio_dist_SNR3_AIC(i);
   %SNR4
   promedio_dist_SNR4_AIC(i) = mean(aux_AIC.Distancia_SNR4(i,:)); 
   sigma_dist_SNR4_AIC(i) = std(aux_AIC.Distancia_SNR4(i,:));
   error_SNR4_AIC(i) = valor_real(i) - promedio_dist_SNR4_AIC(i); 
   
   %%
    i = i+1;
end

indice = [-10:1:10];

figure('Units', 'centimeters', 'Position', [10, 10, 35, 20])
%subplot(211)
errorbar(valor_real,error_SNR4_AIC, sigma_dist_SNR4_AIC,'r')
hold on 
errorbar(valor_real,error_SNR4_eco_crudo, sigma_dist_SNR4_eco_crudo,'black')
hold on
errorbar(valor_real,error_SNR4_deriv_eco_int, sigma_dist_SNR4_deriv_eco_int,'b')
hold on 
title(['SNR=',int2str(SNR4),' dB'])
xlabel('Distancia (mm)')
ylabel('Error (mm)')
legend('Método AIC','Correlación del eco','Correlacion de la derivada de la envolvente')

figure('Units', 'centimeters', 'Position', [10, 10, 35, 20])
%subplot(212)
errorbar(valor_real,error_SNR1_AIC, sigma_dist_SNR1_AIC,'r')
hold on 
errorbar(valor_real,error_SNR1_eco_crudo, sigma_dist_SNR1_eco_crudo,'black')
hold on
errorbar(valor_real,error_SNR1_deriv_eco_int, sigma_dist_SNR1_deriv_eco_int,'b')
hold on 
title(['SNR=',int2str(SNR1),' dB'])
xlabel('Distancia (mm)')
ylabel('Error (mm)')
legend('Método AIC','Correlación del eco','Correlacion de la derivada de la envolvente')



figure('Units', 'centimeters', 'Position', [10, 10, 35, 20])
errorbar(valor_real,error_SNR1_deriv_eco_int, sigma_dist_SNR1_deriv_eco_int,'r')
hold on 
errorbar(valor_real,error_SNR2_deriv_eco_int, sigma_dist_SNR2_deriv_eco_int,'black')
hold on 
errorbar(valor_real,error_SNR3_deriv_eco_int, sigma_dist_SNR3_deriv_eco_int,'m')
hold on 
errorbar(valor_real,error_SNR4_deriv_eco_int, sigma_dist_SNR4_deriv_eco_int,'b')
hold on 

xlabel('Distancia (mm)')
ylabel('Error (mm)')
legend(['SNR = ',int2str(SNR1),' dB'],['SNR = ',int2str(SNR2),' dB'],['SNR = ',int2str(SNR3),' dB'],['SNR = ',int2str(SNR4),' dB'])

%% comparacion de la correlacion con y sin intereferencia

SNR1 = 5; SNR2 = 15; SNR3 = 25; SNR4 = 35;
aux_eco_crudo_0 = load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\comp_SNR\eco_crudo_en_cero.mat')
aux_eco_crudo_no_interf_0 = load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\comp_SNR\eco_crudo_no_interf_en_cero.mat')


figure('Units', 'centimeters', 'Position', [10, 10, 35, 20])
stem(aux_eco_crudo_0.Distancia_SNR1(1,:),'squareblack','LineWidth', 2)
hold on
stem(aux_eco_crudo_no_interf_0.Distancia_SNR1(1,:),'og','LineWidth', 2)
legend('Correlación del eco con interferencia','Correlación del eco')
title(['SNR = ',int2str(SNR1),' dB'])
xlabel('Medida')
ylabel('Error(mm)')

figure('Units', 'centimeters', 'Position', [10, 10, 35, 20])
stem(aux_eco_crudo_0.Distancia_SNR4(1,:),'squareblack','LineWidth', 2)
hold on
stem(aux_eco_crudo_no_interf_0.Distancia_SNR4(1,:),'ob','LineWidth', 2)
legend('Correlación del eco con interferencia','Correlación del eco')
title(['SNR = ',int2str(SNR4),' dB'])
xlabel('Medida')
ylabel('Error(mm)')

%% comparacion de metodos en 100 puntos a una misma distancia 

aux_aic_0 = load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\comp_SNR\AIC_en_cero.mat')
aux_deriv_env_int_0 =  load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\comp_SNR\env_int_en_cero.mat')
aux_eco_crudo_0 = load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\comp_SNR\eco_crudo_en_cero.mat')
aux_deriv_eco_int_0 =  load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\comp_SNR\eco_int_en_cero.mat')

figure('Units', 'centimeters', 'Position', [10, 10, 35, 20])
plot(aux_aic_0.Distancia_SNR1(1,:),'*r')
hold on
plot(aux_eco_crudo_0.Distancia_SNR1(1,:),'squareblack','LineWidth', 2)
hold on
plot(aux_deriv_eco_int_0.Distancia_SNR1(1,:),'ob','LineWidth', 2)
legend('Método AIC','Correlación del eco','Correlacion de la derivada de la envolvente')
title(['SNR = ',int2str(SNR1),' dB'])
xlabel('Medida')
ylabel('Error(mm)')

figure('Units', 'centimeters', 'Position', [10, 10, 35, 20])
plot(aux_aic_0.Distancia_SNR4(1,:),'*r')
hold on
plot(aux_eco_crudo_0.Distancia_SNR4(1,:),'squareblack')
hold on
plot(aux_deriv_eco_int_0.Distancia_SNR4(1,:),'ob')
legend('Método AIC','Correlación del eco','Correlacion de la derivada de la envolvente')
title(['SNR = ',int2str(SNR4),' dB'])
xlabel('Medida')
ylabel('Error(mm)')


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all

fc = 40e3;     %frecuencia de resonancia del sensor
fs = 400e3;      %frecuencia de muestreo
N = 1024;
%% deriva de amstrong 
%filtro analogico cero - polo frecuencia de corte superior 60000
fss = fc;     %Doble de la frecuencia de la portadora
a = 2*20e3*pi;  %Ancho de banda del transductor
num = 100.*[1 0];
den = [1 a]; % se usa el polo para limitar el ancho de banda de la derivada
%Se digitaliza el filtro para hallar la derivada
[numd, dend] = bilinear(num,den,fss);
derivadorS = tf(num,den);
derivadorZ = tf(numd,dend,1); % para tener la ecuacion en diferencia que va en el PSoC

%% filtro demodulador
fir_dem = fir1(65,0.1,blackman(66));
fir_dem2 = fir1(65,0.025,blackman(66));

%%  
%Longitud del vector de datos
longitud = 1024;
%Frecuencia de muestreo
fs=0.4e6;
Ts=1/fs;

%% Tomaremos como referencia el eco que esta en la mitad del trayecto medido.
% los ecos se empezaron a digitalizar a una distancia de 20cm entre los
% transductores y finalizo a una distancia de 40cm con intervalos de 1cm
% por lo que nuestra referencia sera el eco tomado en el medio, el eco en
% la posicion del indice 11 del vector de ecos.

aux = load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\medidas_paper\ecos_digitalizados2.mat');
eco = aux.ecos;
temperatura = aux.temperatura;

eco_refe = squeeze(eco(11,1,:));

%% se halla la envolvente utilizando la transformada de hilbert
env_r = abs(hilbert(eco_refe));
env_refe = filter(fir_dem,1,env_r);

figure
plot(eco_refe)
title('Eco y su envolvente, INT')
hold on
plot(env_refe)

%% derivamos al envolvente 
env_refe_d = filter(numd,dend,env_refe);%se deriva la envolvelnte interpolada

%se normaliza la derivada
[max_d, max_i] = max(env_refe_d );
env_refe_d = (1/max_d).*env_refe_d;

%% Elegimos el patron

indice_tiempo = [1:1:1024];
indice_tiempo = Ts.*indice_tiempo;

figure
subplot(311)
plot(indice_tiempo,eco_refe)
title('Echo')
xlabel('Time (ms)')
ylabel('Amplitude')
subplot(312)
plot(indice_tiempo,env_refe)
title('Envelope')
xlabel('Time (ms)')
ylabel('Amplitude')
subplot(313)
plot(indice_tiempo,env_refe_d)
title('Derivative')
xlabel('Time (ms)')
ylabel('Amplitude')

figure
plot(env_refe_d)
title('Derivada de la envolvente referencia. INT')

disp("Enter para elegir el patron")
pause
%se selecciona cual sera el patron, esto se hace seleccionando una ventana
%temporanl en la curva de la envolventa derivada
[ind val] = ginput(2);

%Se define el patron desde la derivada
patron = env_refe_d(floor(ind(1,1)):floor(ind(2,1)),1);

figure
plot(patron);
title('patron de la derivada')

patron_0 = zeros(floor(ind(1,1)),1);
patron_02 = zeros(1024-1-floor(ind(2,1)),1);
patron_f = [patron_0' patron' patron_02']

figure
subplot(411)
plot(indice_tiempo,eco_refe)
title('Echo')
xlabel('Time (ms)')
ylabel('Amplitude')
subplot(412)
plot(indice_tiempo,env_refe)
title('Envelope')
xlabel('Time (ms)')
ylabel('Amplitude')
subplot(413)
plot(indice_tiempo,env_refe_d)
title('Derivative')
xlabel('Time (ms)')
ylabel('Amplitude')
subplot(414)
plot(indice_tiempo,patron_f)
title('Segment for Correlation Pattern')
xlabel('Time (ms)')
ylabel('Amplitude')