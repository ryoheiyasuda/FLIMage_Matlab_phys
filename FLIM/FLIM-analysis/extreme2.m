function [xymax,smax,xymin,smin] = extreme2(xy,varargin)
% [xymax,smax,xymin,smin] = EXTREME2(xy) Encuentra todos los valores 
%       extremos (mínimos y máximos) de una matriz, con respecto a todos
%       los elementos en su fila, columna y diagonales.
%
% [xymax,smax,xymin,smin] = EXTREME2(xy,1) - Determina los extremos sólo
%        por columnas y filas, es decir, sin tomar en cuenta si son 
%        extremos diagonalmente. (Se obtienen más puntos)
%
% SALIDAS:
% xymax - valores máximos en orden descendente. Vector columna.
% smax  - índice lineal de los máximos. Vector columna.
% xymin - valores mínimos en orden ascendente. Vector columna.
% smin  - índice lineal de mínimos. Vector columna.
%
% EJEMPLO (luce complicado, mas todo sea por editar la figura):
%   [x,y] = meshgrid(-2:.2:2,3:-.2:-2);
%   z = x.*exp(-x.^2-y.^2);
%   surf(x,y,z), shading interp
%   [maxim, imaxim, minim, iminim] = extreme2(z);
%   %
%   % Extremos en la figura:
%    hold on  
%    % Puntos:
%    plot3(x(imaxim),y(imaxim),maxim,'bo','Markerface','b')
%    plot3(x(iminim),y(iminim),minim,'ro','Markerface','r')
%    % Texto:
%    [extremos,a] = sort([maxim;minim]);
%    E = length(extremos);
%    title(['Número de extremos: ' int2str(E)])
%    indices = [imaxim; iminim]; indices = indices(a);
%    for i = 1:E
%     text(x(indices(i)),y(indices(i)),extremos(i), ...
%     [num2str(E-i+1) '^o'], ...
%     'HorizontalAlignment','right', 'VerticalAlignment','bottom',...
%     'BackgroundColor',[.7 .9 .7])
%    end
%    hold off
%
% NOTA: Para cambiar de un índice a dos índices, usar 
%       [imax,jmax] = ind2sub(size(xy),smax);
%       [imin,jmin] = ind2sub(size(xy),smin);
%
% Utiliza EXTREME.M
% 
%
% Programa creado por
% Carlos Adrián Vargas Aguilera
% Lic. en Física
% Maestría en Oceanografía Física
% UNIVERSIDAD DE GUADALAJARA 
% México, 2005
%
% nubeobscura@hotmail.com

M = size(xy);
if length(M) ~= 2
 disp('ERROR: the entry is not a matrix!')
 return
end
N = M(2);
M = M(1);

% Extremos por columnas
[smaxcol,smincol] = extremos(xy);

% Extremos por filas, donde hubo extremos en columnas
im = unique([smaxcol(:,1);smincol(:,1)]); % Filas con extremos en columnas
[smaxfil,sminfil] = extremos(xy(im,:).');

% Conversion de 2 indices a 1:
smaxcol = sub2ind([M,N],smaxcol(:,1),smaxcol(:,2));
smincol = sub2ind([M,N],smincol(:,1),smincol(:,2));
smaxfil = sub2ind([M,N],im(smaxfil(:,2)),smaxfil(:,1));
sminfil = sub2ind([M,N],im(sminfil(:,2)),sminfil(:,1));

% Extremos tanto en fila como en columna:
smax = intersect(smaxcol,smaxfil);
smin = intersect(smincol,sminfil);

% Extremos diagonales?
if nargin==1
 % Extremos en las diagonales positivas:
 [iext,jext] = ind2sub([M,N],unique([smax;smin]));
 [sextmax,sextmin] = extremos_diag(iext,jext,xy,1);

 % Extremos en filas, columnas y diagonal:
 smax = intersect(smax,[M; (N*M-M); sextmax]);
 smin = intersect(smin,[M; (N*M-M); sextmin]);

 % Extremos en las diagonales negativas:
 [iext,jext] = ind2sub([M,N],unique([smax;smin]));
 [sextmax,sextmin] = extremos_diag(iext,jext,xy,-1);

 % Extremos en filas, columnas y diagonales:
 smax = intersect(smax,[1; N*M; sextmax]);
 smin = intersect(smin,[1; N*M; sextmin]);
end

% Valores:
xymax = xy(smax);
xymin = xy(smin);

% Orden ascendente
[a,inmax] = sort(-xymax);
xymax = xymax(inmax);
smax = smax(inmax);
[xymin,inmin] = sort(xymin);
smin = smin(inmin);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [smax,smin] = extremos(matriz)
% extremos por columna o fila

smax = [];
smin = [];

for n = 1:length(matriz(1,:))
 [a,imaxfil,b,iminfil] = extreme(matriz(:,n));
 if ~isempty(imaxfil)     % Indice de maximos
  imaxcol = repmat(n,length(imaxfil),1);
  smax = [smax; imaxfil imaxcol];
 end
 if ~isempty(iminfil)     % Indice de minimos
  imincol = repmat(n,length(iminfil),1);
  smin = [smin; iminfil imincol];
 end
end


function [sextmax,sextmin] = extremos_diag(iext,jext,xy,A)
% Extremos por las diagonales (negativas A=-1)

[M,N] = size(xy);
if A==-1
 iext = M-iext+1;
end
[iini,jini] = cruce(iext,jext,1,1);
[iini,jini] = ind2sub([M,N],unique(sub2ind([M,N],iini,jini)));
[ifin,jfin] = cruce(iini,jini,M,N);
sextmax = [];
sextmin = [];
for n = 1:length(iini)
 ises = iini(n):ifin(n);
 jses = jini(n):jfin(n);
 if A==-1
  ises = M-ises+1;
 end
 s = sub2ind([M,N],ises,jses);
 [vmax,imax,vmin,imin] = extreme(xy(s));
 sextmax = [sextmax; s(imax)'];
 sextmin = [sextmin; s(imin)'];
end


function [i,j] = cruce(i0,j0,I,J)
% Cruce diagonal del elemento io,jo con los extremos izquierda/superior 
% (I=1,J=1) o derecha/inferior (I=M,J=N) de una matriz de MxN. 

arriba = 2*(I*J==1)-1;

si = (arriba*(j0-J) > arriba*(i0-I));
i = (I - (J+i0-j0)).*si + J+i0-j0;
j = (I+j0-i0-(J)).*si + J;


% Carlos Adrián Vargas Aguilera. nubeobscura@hotmail.com