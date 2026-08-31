
%graficos para el paper 

%Necesitamos:
%--Grafico para mostrar la resolucion -> 
%--Grafico para mostrar la precision -> Calibracion
%--Grafico para mostrar la robustez -> SNR

%Consultas: 
%-Con que SNR hacer los graficos para poner en el paper? 

aux_eco_crudo = load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\comp_SNR\eco_crudo2.mat');

aux_env = load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\comp_SNR\envolvente2.mat');

aux_deriv = load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\comp_SNR\int2.mat');

aux_deriv_prom = load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\comp_SNR\int_prom2.mat');


valor_real = [-100:10:100];

i= 1;
while (i < 22)
   %SNR4
   promedio_dist_eco_crudo(i) = mean(aux_eco_crudo.Distancia_SNR4(i,:)); 
   promedio_dist_env(i) = mean(aux_env.Distancia_SNR4(i,:)); 
   promedio_dist_deriv(i) = mean(aux_deriv.Distancia_SNR4(i,:));
   promedio_dist_deriv_prom(i) = mean(aux_deriv_prom.Distancia_SNR4(i,:)); 
   i = i+1;
end

figure
plot(valor_real(1,10:14),promedio_dist_eco_crudo(1,10:14),'x')
hold on
plot(valor_real(1,10:14),promedio_dist_env(1,10:14),'o')
hold on
plot(valor_real(1,10:14),promedio_dist_deriv(1,10:14),'x')
hold on
plot(valor_real(1,10:14),promedio_dist_deriv_prom(1,10:14),'o')

