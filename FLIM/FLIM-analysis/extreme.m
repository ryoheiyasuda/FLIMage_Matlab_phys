function [xmax,imax,xmin,imin] = extreme(x)
% [xmax,imax,xmin,imin] = EXTREME(x) Encuentra todos los m�ximos y m�nimos 
%    de un vector.
%
% ENTRADAS:
% x - Vector real
% 
% SALIDAS:
% xmax - valores m�ximos en orden ascendente
% imax - �ndices de m�ximos
% xmin - valores m�nimos en orden descendente
% imin - �ndices de m�nimos
%
% Ver tambi�n EXTREME2.M
% 
% Programa creado por
% Carlos Adri�n Vargas Aguilera
% Lic. en F�sica
% Maestr�a en Oceanograf�a F�sica
% UNIVERSIDAD DE GUADALAJARA 
% M�xico, 2004
%
% nubeobscura@hotmail.com

% Inicializacion:
xmax = [];
imax = [];
xmin = [];
imin = [];

Nt = size(x);
if (length(Nt) ~= 2) || isempty(find(Nt==1)) 
 disp('ERROR: the entry is not a vector!')
 return
end

% Longitud de la serie
Nt = prod(Nt);

% Un solo valor?
if Nt == 1
 return
end

% Diferencias entre valores subsecuentes
dx = diff(x);

% Linea horizontal?
if ~any(dx)
 return
end

% Picos chatos? Poner el valor en el centro
a = find(dx~=0);              % Indices de x donde cambian los valores
lm = find(diff(a)~=1) + 1;    % Indices de a donde el pico es chato  
d = a(lm) - a(lm-1);          % Numero de elementos del pico chato
a(lm) = a(lm) - floor(d/2);   % Elemento central del pico chato 
a(end+1) = Nt;

% Picos?
xa  = x(a);             % Serie sin picos chatos
b = (diff(xa) > 0);     % 1  =>  pendiente positiva (comienzan en minimos)  
                        % 0  =>  pendiente negativa (comienzan en maximos)
xb  = diff(b);          % -1 =>  indice del maximo (menos uno) 
                        % +1 =>  indice del minimo (menos uno)
imax = find(xb == -1) + 1; % �ndices de maximos
imin = find(xb == +1) + 1; % indices de minimos
imax = a(imax);
imin = a(imin);

nmaxi = length(imax);
nmini = length(imin);                

% maximo o minimo en los extremos si fue una linea?
if (nmaxi==0) & (nmini==0)
 if x(1) > x(Nt)
  xmax = x(1);
  imax = 1;
  xmin = x(Nt);
  imin = Nt;
 elseif x(1) < x(Nt)
  xmax = x(Nt);
  imax = Nt;
  xmin = x(1);
  imin = 1;
 end
 return
end

% maximo o minimo en los extremos si hubo picos?
if (nmaxi==0) 
 imax(1:2) = [1 Nt];
elseif (nmini==0)
 imin(1:2) = [1 Nt];
else
 if imax(1) < imin(1)
  imin(2:nmini+1) = imin;
  imin(1) = 1;
 else
  imax(2:nmaxi+1) = imax;
  imax(1) = 1;
 end
 if imax(end) > imin(end)
  imin(end+1) = Nt;
 else
  imax(end+1) = Nt;
 end
end
xmax = x(imax);
xmin = x(imin);
imax = reshape(imax,size(xmax));
imin = reshape(imin,size(xmin));

% Orden ascendente
[a,inmax] = sort(-xmax);
xmax = xmax(inmax);
imax = imax(inmax);
[xmin,inmin] = sort(xmin);
imin = imin(inmin);


% Carlos Adri�n. nubeobscura@hotmail.com