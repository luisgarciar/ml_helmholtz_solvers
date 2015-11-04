
k  = 500;    %wavenumber
% np = 600;   %number of interior discretization points
np = ceil( 10 * k / pi) ;
h  = 1/np; %gridsize
b  = 0.5;  %complex shift 

%1-D Helmholtz with Dirichlet boundary conditions (DBC)
l    = ones(np,1)*(-1/h^2);  %lower(=upper) diagonal
d    = ones(np,1)*(2/h^2); 
A_d  = spdiags([l d l],[-1 0 1],np,np)- k^2*speye(np); 

%1-D Shifted Laplacian with DBC
l    = ones(np,1)*(-1/h^2);  %lower(=upper) diagonal
d    = ones(np,1)*(2/h^2); 
M_d  = spdiags([l d l],[-1 0 1],np,np)- k^2*(1-1i*0.5)*speye(np); 

%Preconditioned matrix (with DBC)
S_d = M_d\A_d;


% Parameters for the bratwurst shaped set
lambda = -1 ;
phi = 0.1 * pi ;
sigma = 1.005 ;  %% sigma = 1+eps, which simplifies the notaton.
eps_thick = sigma-1 ;

[psi, ~, capacity, M, N] = bw_map(lambda, phi, eps_thick) ;




% %%% Control that eigenvalues lie in bw set
% 
% EV = eig(full(S_d)) ;
% 
% n = 2^14 ;
% unit_circle = exp(1i * (0: 2*pi/n : 2*pi - 2*pi/n).' ) ;  %% column !
% circle = unit_circle / 2 + 1/2 ;
% bdry_E = (psi(unit_circle) + 1)/2 ;
% 
% FS = 22 ; %% font size
% 
% figure(1)
% plot(real(bdry_E), imag(bdry_E), 'k-')
% hold on
% plot( real(circle), imag(circle), 'k--')
% plot( real(EV), imag(EV), 'rx','MarkerSize', 8,'LineWidth',2)
% hold off
% axis equal
% set(gca,'LooseInset',get(gca,'TightInset'))
% set(gca,'FontSize',FS);
% 

%%% Compute f(S_d) \approx S_d^{-1} ??

% kmax = 100 ;
% [fA, ~, ~] = fseries_inv_bw(S_d, kmax, M, N) ;
% Err = fA - inv(S_d) ;
% norm(S_d * fA - eye(np)) ;


% 
% kmax = 100 ;
% 
% invS = inv(S_d) ;
% norminvS = norm(full(invS)) ;
% 
% LW = 'LineWidth' ;
% lw = 2 ;
% 
% 
% for kk = 1:kmax
%     [fA, ~, ~] = fseries_inv_bw(S_d, kk, M, N) ;
% %     relerr(kk) = norm( fA - invS ) / norminvS ;
%     relerr(kk) = norm( fA * S_d - eye(size(S_d)) ) ;
%     newcond(kk) = cond(fA*S_d) ;
% end
% 
% figure(3)
% semilogy( 2:kmax, relerr(2:kmax), 'k-', LW, lw)
% % title(' || fA - inv(S) || / ||inv(S)||')
% title(' || fA * S_d - I ||', 'FontSize', FS)
% set(gca,'LooseInset',get(gca,'TightInset'))
% set(gca,'FontSize',FS);
% 
% 
% figure(4)
% plot(newcond, 'b-', LW, lw)
% title(['cond( fA * S), where cond(S) =',num2str(cond(S_d))],'FontSize',FS)
% set(gca,'LooseInset',get(gca,'TightInset'))
% set(gca,'FontSize',FS);
% 
% %%

b = rand(np,1) ;
tol = 1e-12 ;

tic
[X,FLAG,RELRES,ITER,RESVEC] = gmres(S_d, b, [], tol, np) ;
toc

tic
[fA, ~, ~] = fseries_inv_bw(S_d, 5, M, N) ;
B = fA*S_d ;
[X_F,FLAG_F,RELRES_F,ITER_F,RESVEC_F] = gmres(B, b, [], tol, np) ;
toc

% EVA = eig(fA * S_d) ;
% figure(6)
% plot( real(EVA), imag(EVA), 'rx', 'MarkerSize', 8, 'LIneWidth', 2)
% axis equal

figure(5)
semilogy(RESVEC, 'k-')
hold on
semilogy(RESVEC_F, 'r--')
hold off
