

%% CORRELACION DE LA SENHAL REFE 
%% Overlap en Add version 1
size_tramo = floor((max(size(env_refe_d))/3));
tramo_y1 = zeros(1,size_tramo);

%solo nos importan los tramos 2 y 3, desde N hasta 3N
%primer tramo, 2/4
%iniciamos por la parte A, calculomos su correlacion con el patron:
for i=1 : size_tramo
   tramo_y1(i) = env_refe_d(i) ;
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
   tramo_y1(i-size_tramo) = env_refe_d(i) ;
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
   tramo_y1(i-(size_tramo*2)) = env_refe_d(i) ;
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



%% %% correlacion realizada por partes "Overlap and Add" VERSION 2 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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

        size_tramo = floor(max(size(env_med_d))/3);
        tramo_y1 = zeros(1,size_tramo);

        %solo nos importan los tramos 2 y 3, desde N hasta 3N
        %primer tramo, 2/4
        %iniciamos por la parte A, calculomos su correlacion con el patron:
        for i=1 : size_tramo
           tramo_y1(i) = env_med_d(i) ;
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
           tramo_y1(i-size_tramo) = env_med_d(i) ;
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
           tramo_y1(i-(size_tramo*2)) = env_med_d(i) ;
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