
%% Hay 7 variaciones del algoritmo original:


% normal                                                    Y
% filtrado de la derivada con fir_dem2                      Y
% promediado de la derivada                                 Y
% interpolado                                               Y
% interpolado con filtrado de la derivada con fir_dem2      Y
% interpolado con promediado de la derivada                 YF	
% interpolado con promediado de la derivada y dem2          YF
% por recta con ajustes de minimos cuadrados 				YF

close all

%% Graficar los resultados 

% NORMAL:
aux = load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\normal3.mat');
figure
subplot(211)
plot(aux.Distancia)
title('Distancias Normal')
subplot(212)
error = aux.TOF2_v- aux.TOF1_v;
plot(error, '*')
title('Error en pasos, Normal')

promedio_normal = mean(error);
std_normal = std(error);
normal_pasos = [promedio_normal std_normal]

promedio_normal = mean(aux.Distancia);
std_normal = std(aux.Distancia);
normal_dist = [promedio_normal std_normal]

% normal con filtrado de la derivada con fir_dem2
aux = load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\normal_dem27.mat');
figure
subplot(211)
plot(aux.Distancia)
title('Distancias Normal dem2')
subplot(212)
error = aux.TOF2_v- aux.TOF1_v;
plot(error, '*')
title('Error en pasos, Normal dem2')

promedio_normal_dem2 = mean(error);
std_normal_dem2 = std(error);
normal_dem2_pasos = [promedio_normal_dem2 std_normal_dem2]

promedio_normal_dem2 = mean(aux.Distancia);
std_normal_dem2 = std(aux.Distancia);
normal_dem2_dist = [promedio_normal_dem2 std_normal_dem2]

% normal con promediado de la derivada
aux = load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\normal_prom3.mat');
figure
subplot(211)
plot(aux.Distancia)
title('Distancias Normal Prom')
subplot(212)
error = aux.TOF2_v- aux.TOF1_v;
plot(error, '*')
title('Error en pasos, Normal Prom')
promedio_normal_prom = mean(error);
std_normal_prom = std(error);

normal_prom_pasos = [promedio_normal_prom std_normal_prom]

promedio_normal_prom = mean(aux.Distancia);
std_normal_prom = std(aux.Distancia);

normal_prom_dist = [promedio_normal_prom std_normal_prom]

% interpolacion 
aux = load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\int3.mat');
figure
subplot(211)
plot(aux.Distancia)
title('Distancias Int')
subplot(212)
error = aux.TOF2_v- aux.TOF1_v;
plot(error, '*')
title('Error en pasos, Int')
promedio_int = mean(error);
std_int = std(error);

int_pasos = [promedio_int std_int]
promedio_int = mean(aux.Distancia);
std_int = std(aux.Distancia);

int_dist = [promedio_int std_int]

% interpolacion con filtro para suavizar la derivada, fir_dem2
aux = load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\int_dem23.mat');
figure
subplot(211)
plot(aux.Distancia)
title('Distancias Int con dem2')
subplot(212)
error = aux.TOF2_v- aux.TOF1_v;
plot(error, '*')
title('Error en pasos, Int con dem2')
promedio_int_dem2 = mean(error);
std_int_dem2 = std(error);

int_dem2_pasos = [promedio_int_dem2 std_int_dem2]
promedio_int_dem2 = mean(aux.Distancia);
std_int_dem2 = std(aux.Distancia);

int_dem2_dist = [promedio_int_dem2 std_int_dem2]


% interpolacion con promediado de la derivada
aux = load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\int_prom3.mat');
figure
subplot(211)
plot(aux.Distancia)
title('Distancias Int con Promedio')
subplot(212)
error = aux.TOF2_v- aux.TOF1_v;
plot(error, '*')
title('Error en pasos, Int con Promedio')
promedio_int_prom = mean(error);
std_int_prom = std(error);

int_prom_pasos = [promedio_int_prom std_int_prom]

promedio_int_prom = mean(aux.Distancia);
std_int_prom = std(aux.Distancia);

int_prom_dist = [promedio_int_prom std_int_prom]


% interpolacion con promediado de la derivada y filtro para suavizar la
% derivda, fir_dem2
aux = load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\int_prom_dem23.mat');
figure
subplot(211)
plot(aux.Distancia)
title('Distancias Int con Promedio y dem2')
subplot(212)
error = aux.TOF2_v- aux.TOF1_v;
plot(error, '*')
title('Error en pasos, Int con Promedio y dem2')
promedio_int_prom_dem2 = mean(error);
std_int_prom_dem2 = std(error);

int_prom_dem2_pasos = [promedio_int_prom_dem2 std_int_prom_dem2]

promedio_int_prom_dem2 = mean(aux.Distancia);
std_int_prom_dem2 = std(aux.Distancia);

int_prom_dem2_dist = [promedio_int_prom_dem2 std_int_prom_dem2]

% por recta con ajuste de minimos cuadrados con cruce por Vmax/2
aux = load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\min_cua2.mat');
figure
subplot(211)
plot(aux.Distancia)
title('Distancias Min Cua por Vmax/2')
subplot(212)
error = aux.TOF2_v- aux.TOF1_v;
plot(error, '*')
title('Error en pasos, Min cua por Vmax/2')
promedio_min_vmax = mean(error);
std_min_vmax = std(error);
min_vmax_pasos = [promedio_min_vmax std_min_vmax]
promedio_min_vmax = mean(aux.Distancia);
std_min_vmax = std(aux.Distancia);
min_vmax_dist = [promedio_min_vmax std_min_vmax]
% por recta con ajuste de minimos cuadrados con cruce por cero
figure
subplot(211)
plot(aux.Distancia_0)
title('Distancias Min Cua por Cero')
subplot(212)
error = aux.TOF2_0_v- aux.TOF1_0_v;
plot(error, '*')
title('Error en pasos, Min cua por Cero')
promedio_min_cero = mean(error);
std_min_cero = std(error);
min_cero = [promedio_min_cero std_min_cero]
promedio_min_cero = mean(aux.Distancia);
std_min_cero = std(aux.Distancia);
min_cero_dist = [promedio_min_cero std_min_cero]
