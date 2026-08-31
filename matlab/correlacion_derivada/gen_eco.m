function [eco t] = gen_eco(A0, fc,fs,m,T,tau,N)
%Función para generar una señal parecida a un eco de ultrasonidos
% s = A(k*ts)sin(2*pi*f(kts-tau)+ theta))
% A(k*ts) = A0((k*ts-tau)/T)^m exp(-(k*ts-tau)/T))u(k*ts - tau))

k = [0:1:N-1];
Ts = 1/fs;
t = Ts.*k;
%Se genera el eco sin desplazamiento y luego se desplaza en función a tau
eco = A0.*((t/T).^m).*exp(-t/T).*sin(2*pi*fc.*t);
%Se calcula la cantidad de puntos que hay que desplazar la señal
eco = shift(eco,ceil(tau*fs));
end