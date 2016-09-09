%Test multigrid Poisson
clear all;
npc = 5;  %number of points in coarsest grid (1D) 
par = 12; %discretization parameter (type help fd_npc_to_npf for more info)
k   = 40;
eps = 0.5*k^2;
dim = 2;
bc  = 'dir';

[npf,lev]  = fd_npc_to_npf(npc,k,par);  %number of interior points in finest grid (1D)

%% Poisson matrix and right hand side
k =  0;
npx = npf; npy = npf;  
npt = npx*npy;
A   = helmholtz2(k,0,npx,npy,bc);

% If u(x,y)=sin(m*pi*x)*sin(n*pi*y) then
% f =(-k^2+m^2*pi^2+pi^2*n^2)*sin(m*pi*x).*sin(n*pi*y)
m = 2; n=4; 
u = @(x,y) sin(m*pi*x).*sin(n*pi*y);
f = @(x,y) (-k^2+m^2*pi^2+pi^2*n^2)*sin(m*pi*x).*sin(n*pi*y); %f=-u''-k^2u;

%grid and meshgrid for plotting the solution
hx    = 1/(npx+1); gridx = hx*(1:1:npx); 
hy    = 1/(npy+1); gridy = hy*(1:1:npy);
[x,y] = meshgrid(gridx,gridy);

%right hand side vector
b   = f(x,y); b = b'; b = reshape(b,[npt,1]);

% %exact solution
% U_ex  = u(x,y); U_ex = U_ex'; 
% 
% %Plot of exact solution
% figure(1); surf(x,y,U_ex);  title('exact solution')
% 
% %computing the discrete solution
% u_d  = A\b; U_d  = reshape(u_d,[npx,npy]); 
% 
% %plotting solution and error distribution
% Err  = abs(U_d-U_ex);
% figure(2); surf(x,y,U_d);  title('computed solution')
% figure(3); surf(x,y,Err);  title('error')
% 
% %relative error
% u_ex   = reshape(U_ex,[npt,1]); 
% relerr = norm(u_ex-u_d,Inf)/norm(u_ex,Inf)
 
%% Multigrid Setup
  tic
  [galerkin_matrices,galerkin_split,restrict,interp] = mg_setup(A,lev,bc,dim);
  setuptime = toc;
 
% Parameters of V-cycle and Jacobi iteration
 npre = 2; npos = 2; w = 2/3; smo = 'gs'; numcycles = 10;
 x0       = zeros(size(b));
 normr0   = norm(b-A*x0);

% Test of multigrid on 2D Poisson problem
% Use the profiler to evaluate performance of code
 profile on
 [u_mg] = Vcycle(galerkin_matrices,galerkin_split,restrict,interp,x0,b,npre,npos,w,smo,numcycles);
 profile off
 
 r1     = b-A*u_mg;
 normr1 = norm(r1)
 relres = normr1/normr0
 
 %plot of solution computed with multigrid
 U_mg  = reshape(u_mg,[npx,npy]); 
 figure(4); surf(x,y,U_mg);  title('Multigrid Solution')

 
 
 
 
 