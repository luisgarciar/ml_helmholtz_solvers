function [x,flag,relres,iter] = mlfgmres(b,x0,ml_mat,ml_prec,ml_prec_split,restrict,interp,maxiter)
%% MLFGMRES: Computes the solution of Ax=b by flexible GMRES via coarse
% grid iteration with multilevel deflation 
%
% Input:
% ml_mat,ml_prec,ml_prec_split,restrict,interp  
%
%

%%
numlevs = len(ml_mat);
n1 = size(ml_mat{1});
n2 = size(ml_prec{1});

assert(n1==n2,'inconsistent size of matrix and preconditioner');
n = n1;

%if numlevs==1 solve exactly and return
if numlevs==1 
    x = ml_mat{1}\b;
else
    A = @x (ml_mat{1})
    M = @x (ml_prec{1}) %%setup multigrid call here
    
    
    maxit = maxiter(1);

    %FGMRES initialization
    r0 = b-A*x0; %initial residual
    %Check tolerance of initial residual

    %Arnoldi vectors V,Z and upper Hessenberg H matrix s.t. AZ = VH
    V = sparse(n,maxit+1);
    Z = sparse(n,maxit+1);
    H = sparse(maxit+1,maxit);

%    V = zeros(n,maxiter(1)+1);
%    Z = zeros(n,maxiter(1)+1);
%    H = zeros(maxit+1,maxit);


    %initialization of Arnoldi basis
    V(:,1) = r0/norm(r0);
    
    while (iter < maxiter)
        iter = iter +1;
        
        %preconditioning step
        z=
        
        
        
        %recursive call to function
        
        
        
        
        
        %end of preconditioning step
        
        
        %
        w = A*z
        
        %Arnoldi orthogonalization
        
        
        
        
    end


    