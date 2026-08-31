
%% Graficamos los resultados del script comp_SNR 
clear all
close all

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

figure
%subplot(411)
errorbar(valor_real,error_SNR1_AIC, sigma_dist_SNR1_AIC,'r')
hold on 
errorbar(valor_real,error_SNR1_eco_crudo, sigma_dist_SNR1_eco_crudo,'black')
hold on
% errorbar(valor_real,error_SNR1_env, sigma_dist_SNR1_env)
% hold on
% errorbar(valor_real,error_SNR1_deriv, sigma_dist_SNR1_deriv)
% hold on
% errorbar(valor_real,error_SNR1_deriv_prom, sigma_dist_SNR1_deriv_prom)
% hold on
errorbar(valor_real,error_SNR1_deriv_eco_int, sigma_dist_SNR1_deriv_eco_int,'b')
hold on 
title(['SNR=',int2str(SNR1)])
xlabel('Distance (mm)')
ylabel('Error (mm)')
%legend('Eco Crudo','Envolvente','Derivada int','Derivada int prom','Derivada eco int')
%legend('Derivada int','Derivada int prom','Derivada eco int')
legend('AIC Method','Cross-Correlation of the Eco signal','Cross-Correlation of the Derivative of the Envelope')


figure
%subplot(411)
errorbar(valor_real,error_SNR2_AIC, sigma_dist_SNR2_AIC,'r')
hold on 
errorbar(valor_real,error_SNR2_eco_crudo, sigma_dist_SNR2_eco_crudo,'black')
hold on
% errorbar(valor_real,error_SNR2_env, sigma_dist_SNR2_env)
% hold on
% errorbar(valor_real,error_SNR2_deriv, sigma_dist_SNR2_deriv)
% hold on
% errorbar(valor_real,error_SNR2_deriv_prom, sigma_dist_SNR2_deriv_prom)
% hold on
errorbar(valor_real,error_SNR2_deriv_eco_int, sigma_dist_SNR2_deriv_eco_int,'b')
hold on 
title(['SNR=',int2str(SNR2)])
xlabel('Distance (mm)')
ylabel('Error (mm)')
%legend('Eco Crudo','Envolvente','Derivada int','Derivada int prom','Derivada eco int')
%legend('Derivada int','Derivada int prom','Derivada eco int')
legend('AIC Method','Cross-Correlation of the Eco signal','Cross-Correlation of the Derivative of the Envelope')


figure
%subplot(411)
errorbar(valor_real,error_SNR3_AIC, sigma_dist_SNR3_AIC,'r')
hold on 
errorbar(valor_real,error_SNR3_eco_crudo, sigma_dist_SNR3_eco_crudo,'black')
hold on
% errorbar(valor_real,error_SNR3_env, sigma_dist_SNR3_env)
% hold on
% errorbar(valor_real,error_SNR3_deriv, sigma_dist_SNR3_deriv)
% hold on
% errorbar(valor_real,error_SNR3_deriv_prom, sigma_dist_SNR3_deriv_prom)
% hold on
errorbar(valor_real,error_SNR3_deriv_eco_int, sigma_dist_SNR3_deriv_eco_int,'b')
hold on 
title(['SNR=',int2str(SNR3)])
xlabel('Distance (mm)')
ylabel('Error (mm)')
%legend('Eco Crudo','Envolvente','Derivada int','Derivada int prom','Derivada eco int')
%legend('Derivada int','Derivada int prom','Derivada eco int')
legend('AIC Method','Cross-Correlation of the Eco signal','Cross-Correlation of the Derivative of the Envelope')

figure
%subplot(411)
errorbar(valor_real,error_SNR4_AIC, sigma_dist_SNR4_AIC,'r')
hold on 
errorbar(valor_real,error_SNR4_eco_crudo, sigma_dist_SNR4_eco_crudo,'black')
hold on
% errorbar(valor_real,error_SNR4_env, sigma_dist_SNR4_env)
% hold on
% errorbar(valor_real,error_SNR4_deriv, sigma_dist_SNR4_deriv)
% hold on
% errorbar(valor_real,error_SNR4_deriv_prom, sigma_dist_SNR4_deriv_prom)
% hold on
errorbar(valor_real,error_SNR4_deriv_eco_int, sigma_dist_SNR4_deriv_eco_int,'b')
hold on 
title(['SNR=',int2str(SNR4)])
xlabel('Distance (mm)')

% Cambiar etiquetas del eje x sin cambiar los datos
new_labels = 400:10:600;
set(gca, 'XTick', valor_real)
set(gca, 'XTickLabel', new_labels)
ylabel('Error (mm)')
%legend('Eco Crudo','Envolvente','Derivada int','Derivada int prom','Derivada eco int')
%legend('Derivada int','Derivada int prom','Derivada eco int')
legend('AIC Method','Cross-Correlation of the Eco signal','Cross-Correlation of the Derivative of the Envelope')

%% %%%%%%%%%%%%%%%%%%%%%%
figure
subplot(211)
errorbar(valor_real,error_SNR4_AIC, sigma_dist_SNR4_AIC,'r')
hold on 
errorbar(valor_real,error_SNR4_eco_crudo, sigma_dist_SNR4_eco_crudo,'black')
hold on
errorbar(valor_real,error_SNR4_deriv_eco_int, sigma_dist_SNR4_deriv_eco_int,'b')
hold on 
title(['SNR=',int2str(SNR4),' dB'])
xlabel('Distance (mm)')
ylabel('Error (mm)')
legend('AIC Method','Cross-Correlation of the Eco signal','Cross-Correlation of the Derivative of the Envelope')


subplot(212)
errorbar(valor_real,error_SNR1_AIC, sigma_dist_SNR1_AIC,'r')
hold on 
errorbar(valor_real,error_SNR1_eco_crudo, sigma_dist_SNR1_eco_crudo,'black')
hold on
errorbar(valor_real,error_SNR1_deriv_eco_int, sigma_dist_SNR1_deriv_eco_int,'b')
hold on 
title(['SNR=',int2str(SNR1),' dB'])
xlabel('Distance (mm)')
ylabel('Error (mm)')

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% estos son los que van a ir a en el paper
aux_aic_0 = load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\comp_SNR\AIC_en_cero.mat')
aux_deriv_env_int_0 =  load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\comp_SNR\env_int_en_cero.mat')
aux_eco_crudo_0 = load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\comp_SNR\eco_crudo_en_cero.mat')
aux_deriv_eco_int_0 =  load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\comp_SNR\eco_int_en_cero.mat')

figure
plot(aux_aic_0.Distancia_SNR1(1,:),'*r')
hold on
plot(aux_eco_crudo_0.Distancia_SNR1(1,:),'squareblack')
hold on
plot(aux_deriv_eco_int_0.Distancia_SNR1(1,:),'ob')
legend('AIC Method','Cross-Correlation of the Eco signal','Cross-Correlation of the Derivative of the Envelope')
title(['SNR = ',int2str(SNR1),' dB'])
xlabel('Measurement')
ylabel('Error(mm)')

figure
plot(aux_aic_0.Distancia_SNR4(1,:),'*r')
hold on
plot(aux_eco_crudo_0.Distancia_SNR4(1,:),'squareblack')
hold on
plot(aux_deriv_eco_int_0.Distancia_SNR4(1,:),'ob')
legend('AIC Method','Cross-Correlation of the Eco signal','Cross-Correlation of the Derivative of the Envelope')
title(['SNR = ',int2str(SNR4),' dB'])
xlabel('Measurement')
ylabel('Error(mm)')


figure
plot(aux_deriv_eco_int_0.Distancia_SNR1(1,:),'*black')
hold on
plot(aux_deriv_env_int_0.Distancia_SNR1(1,:),'ob')
title(['SNR = ',int2str(SNR1),'Db'])
xlabel('Measurement ')
ylabel('Error(mm)')

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% % 
SNR1 = 5; SNR2 = 15; SNR3 = 25; SNR4 = 35;

aux_eco_crudo= load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\comp_SNR\eco_crudo2.mat');
aux_env = load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\comp_SNR\envolvente2.mat');
aux_deriv = load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\comp_SNR\env_int2.mat');
aux_deriv_prom= load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\comp_SNR\env_int_prom2.mat');
aux_deriv_eco_int= load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\comp_SNR\eco_int2.mat');
aux_AIC  = load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\comp_SNR\AIC2.mat');

valor_real = [-100:10:100];


figure
plot(aux_AIC.Distancia_SNR4(12,:),'*r')
hold on
plot(aux_eco_crudo.Distancia_SNR4(12,:),'+black')
hold on
plot(aux_deriv.Distancia_SNR4(12,:),'ob')
hold on 
legend('AIC Method','Cross-Correlation of the Eco signal','Cross-Correlation of the Derivative of the Envelope')
title(['SNR=',int2str(SNR4)])

figure
plot(aux_deriv.Distancia_SNR3(17,:),'r')
hold on
plot(aux_deriv_prom.Distancia_SNR3(17,:),'black')
hold on
plot(aux_deriv_eco_int.Distancia_SNR3(17,:),'b')
hold on 
legend('deriv','deriv prom','eco int')

