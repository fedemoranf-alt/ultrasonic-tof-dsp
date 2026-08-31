function [v_out] = shift(v_int,n)
%Funcion para efectuar desplazamientos en un vector
%function [v_out] = shift(v_int,n)
%n es el numero de muestras que se quiere desplazar.
[a b] = size(v_int);
if (a ~= 1) & (b ~= 1)
error('El parámetro de entrada debe ser un vector.');
end

if a == 1
	if n < 0
	%Se desplaza a la izq.
		n = abs(n);
		v_out = [v_int(n+1:length(v_int)) zeros(1,n)];
	else
		v_out = [zeros(1,n) v_int(1:length(v_int)- n)];
	end
end

if b == 1
	if n < 0
		n = abs(n);
		v_out = [v_int(n+1:length(v_int));zeros(n,1)];
	else
		v_out = [zeros(1,n); v_int(1:length(v_int)- n)];
	end
end