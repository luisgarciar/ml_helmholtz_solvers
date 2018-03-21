function [fovA,eigvA,m,M]=parallel_sfov(A,AH,v0max,N,k)
%% parallel_sfov
%  [fovA,eigvA,m,M]= sfov(A,AH, k) computes the field of values of the sparse
%  matrix A and approximations to the inner numerical radius and
%  numerical radius using the method  of Johnson
%
%  INPUT
%  A:  function handle that computes  A*x
%  AH: function handle that computes  A'*x (Hermitian transpose)
%  N = size(A)
%  k: number of angles

%  OUTPUT
%  m: Inner numerical radius of A (distance of the fov to zero)
%  M: Numerical radius of A
%  fv, eigvA: Field of values and eigenvalues of A
%
% Author: Luis Garcia Ramos, TU Berlin
%         Based on a routine of Nick Higham (Matrix Toolbox)
%          % version 0.1 - Apr 2017
%
%%%
if nargin == 1, k = 32; end

theta = linspace(0,2*pi,k); %range of angles
fovA  = zeros(k,1);         %boundary points
eigvA = 0;

%opts.v0     = v0max;
opts.tol    = 1e-8;
opts.isreal = 0;
opts.disp   = 0;
opts.maxit  = 100;
opts.p      = min(N,20);
opts.issym  = false;

parfor j=1:k
    
    %We rotate the matrix A to obtain At=exp(i*theta(j))*A
    %and compute the max eigenvalue and unit eigenvector of
    %Ht = Hermitian part of At
    et = exp(1i*theta(j));
    Ht = @(x) 0.5*(et*feval(A,x) + et'*feval(AH,x));
    
    fprintf('\n step %d of %d in fov computation %d \n',j,k);
    [vmaxHt,~,] = eigs(Ht,N,1,'LR',opts);
    
    %fprintf('convergence flag step %d: %d  \n', j, flag);
    %
    %      if flag1 ~=0
    %         fovA(j) = fovA(j-1);
    %      else
    %         %The boundary point is the rotated max eigenvalue
    %         v  = vmaxHt/norm(vmaxHt);
    %         fovA(j) = v'*feval(A,v);
    %         vinit=v;
    %      end
    
    %The boundary point is the rotated max eigenvalue
    v  = vmaxHt/norm(vmaxHt);
    fovA(j) = v'*feval(A,v);
    
end

%The approximate fov is the convex hull of the computed boundary points
%clf
%plot(fv,'LineWidth',3);
%hold on

% To compute the inner numerical radius
% we first check if 0 is in fov(A)
xbd = real(fovA);
ybd = imag(fovA);
in  = inpolygon(0,0,xbd,ybd);

if in==1
    m=0;
else
    m = min(abs(fovA));
end

M = max(abs(fovA));


end
