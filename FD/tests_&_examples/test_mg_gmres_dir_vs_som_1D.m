%% Test multigrid and GMRES, Sommerfeld BCs vs Dirichlet BCs
clear global; 
close all;
clc;

%% Parameters
k     = 100;       %wavenumber
ppw   = 20;       %min points per wavelength%
npcg  = 1;        %number of points in coarsest grid
dim   = 1;        %dimension
eps   = 0.5*k^2 ; %imaginary shift of shifted Laplacian

% Parameters of multigrid solver
npre = 2; npos = 1; w = 0.6; smo = 'wjac';

%% Sommerfeld problem
bc           = 'som';      %boundary conditions
[npf,numlev] = fd_npc_to_npf(npcg,k,ppw); 
op_type      = 'gal';

%npf = 127; numlev = 7;
%k=0; eps=0;

%Multigrid setup for shifted Laplacian
profile on
[mg_mat_som,mg_split_som,restrict_som,interp_som] = mg_setup(k,eps,op_type,npcg,numlev,bc,dim);

%%
% right hand side and initial guess
M_som          = mg_mat_som{1}; 
ex_sol_dir     = ones(length(M_som),1);
b_som          = M_som*ex_sol_dir;
x0_som         = rand(length(M_som),1); 

numcycles = 12;
% multigrid cycle for shifted Laplacian Sommerfeld
relres_som = zeros(numcycles+1,1); relres_som(1)=norm(b_som-M_som*x0_som); 
relerr_som = zeros(numcycles+1,1); relerr_som(1)=norm(ex_sol_dir);

for i=1:numcycles
    [x_sol] = Vcycle(mg_mat_som,mg_split_som,restrict_som,interp_som,x0_som,b_som,npre,npos,w,smo,1);
    relres_som(i+1)=norm(b_som-M_som*x_sol);
    x0_som =x_sol;
end
 
relres_som = relres_som/relres_som(1);
factor_som = relres_som(2:length(relres_som))./relres_som(1:length(relres_som)-1);

profile off

%% Dirichlet problem
bc = 'dir';

% Multigrid setup for shifted Laplacian
[mg_mat_dir,mg_split_dir,restrict_dir,interp_dir] = mg_setup(k,eps,op_type,npcg,numlev,bc,dim);

%Matrix, right hand side and initial guess
M_dir      =  mg_mat_dir{1}; 
ex_sol_dir =  ones(length(M_dir),1);
b_dir      =  M_dir*ex_sol_dir;
x0         =  rand(length(M_dir),1); 

%Setup of residuals and error
relres_dir = zeros(numcycles+1,1); relres_dir(1) = norm(b_dir-M_dir*x0); 
relerr_dir = zeros(numcycles+1,1); relerr_dir(1) = norm(ex_sol_dir);

tic
for i=1:numcycles
    [x_sol] = Vcycle(mg_mat_dir,mg_split_dir,restrict_dir,interp_dir,x0,b_dir,npre,npos,w,smo,1);
    relres_dir(i+1)=norm(b_dir-M_dir*x_sol);
    x0 =x_sol;
end
time_dir = toc;  

relres_dir = relres_dir/relres_dir(1);
factor_dir = relres_dir(2:length(relres_dir))./relres_dir(1:length(relres_dir)-1);

relres_som
relres_dir

factor_som
factor_dir


%% Test of MG + GMRES (Shifted Laplacian + Helmholtz)

%% Dirichlet problem
A_dir      = helmholtz(k,0,npf,bc);
ex_sol_dir = ones(length(A_dir),1);
b_dir      = A_dir*ex_sol_dir;
x0         = zeros(length(A_dir),1);
numcycles  = 1;
Minv_dir   = @(v)feval(@Vcycle,mg_mat_dir,mg_split_dir,restrict_dir,interp_dir,x0,v,npre,npos,w,smo,numcycles);

%GMRes parameters
tol   = 1e-7;
maxit = min(150,length(A_dir));

 tic
 [x_gdir,flag_gdir,relres_gdir,iter_gdir,resvec_gdir] = gmres(A_dir,b_dir,[],tol,maxit,Minv_dir);
 time_gdir = toc;


%% Sommerfeld Problem
bc = 'som';
A_som      = helmholtz(k,0,npf,bc);
ex_sol_som = ones(length(A_som),1);
b_som      = A_som*ex_sol_som;
x0         = zeros(length(A_som),1); 
numcycles  = 1;
Minv_som   = @(v) feval(@Vcycle,mg_mat_som,mg_split_som,restrict_som,interp_som,x0,v,npre,npos,w,smo,numcycles);

%GMRes parameters
tol   = 1e-7;
maxit = min(150,size(A_som,1));

tic
[x_gsom,flag_gsom,relres_gsom,iter_gsom,resvec_gsom] = gmres(A_som,b_som,[],tol,maxit,Minv_som);
time_gsom = toc;

iter_gsom
iter_gdir


%% test of BiCGSTAB
[~,FLAG,RELRES,ITER,RESVEC] = bicgstab(A_som,b_som,tol,maxit,Minv_som);
ITER


%% Plots of GMRES results
figure(1)
semilogy(0:iter_gsom(2), resvec_gsom/resvec_gsom(1), 'k-');
hold on
semilogy(0:iter_gdir(2), resvec_gdir/resvec_gdir(1), 'b-');
ylabel('relative residual')
xlabel('iteration')

legend('Sommerfeld BCs', 'Dirichlet BCs')
title(['1D Helmholtz with CSL-preconditioner (k=',num2str(k),')'])
