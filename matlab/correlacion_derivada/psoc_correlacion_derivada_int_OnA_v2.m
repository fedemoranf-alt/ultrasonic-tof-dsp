
patron_d = patron;
patron_d(740) = 0.0;

env_y1_int_d = voltageD;
env_y1_int_d (3072) = 0;

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
figure
plot(corr_tramo_y1)
title("corr tramo C m")

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
tramo1_m = corr_completa_y1; %solo para graficar


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
tramo2_m = corr_completa_y1; % solo para graficar

%hallamos el maximo entre ambos maximos:
%max_corr_y1 = max(V_t2,V_t1)
if V_t2 > V_t1 
    Vp = V_t2;
    TOF2 = TOF_t2 + (size_corr/2); % se le suma el size_corr/2 pq este indice corresponde al 2do tramo de la correlacion valida
elseif V_t1 > V_t2 
    Vp = V_t1;
    TOF2 = TOF_t1;
end


corr12_m = horzcat(tramo1_m,tramo2_m);
figure
plot(corr12_m)
title("Corr12 matlab")


% corr12 = horzcat(tramo1',tramo2');
% figure
% plot(corr12)
% title("Corr12 psoc")

%% PRUEBA DE LA CORRELACION DEL TRAMO A REALIZADO POR EL PSOC
