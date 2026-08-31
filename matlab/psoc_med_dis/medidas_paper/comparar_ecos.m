
aux3 = load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\medidas_paper\ecos_digitalizados3.mat');
eco3 = aux3.ecos;
eco3_refe = squeeze(eco3(11,1,:)); % obs: el patron no debe tener ruido

aux2 = load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\medidas_paper\ecos_digitalizados2.mat');
eco2 = aux2.ecos;
eco2_refe = squeeze(eco2 (11,1,:)); % obs: el patron no debe tener ruido

figure
subplot(211)
plot(eco3_refe)
title('eco 3')
subplot(212)
plot(eco2_refe)
title('eco 2')
