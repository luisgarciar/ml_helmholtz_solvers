function err2= poisson_test
%POISSON_TEST Simple test to check that I can 
%at least solve Poisson equation  with the
%expected rate of convergence.

npt = ceil(10.^linspace(1,4,20));
err2   = npt*0;
h  = 1./(npt+1);
clf

for i = 1:length(npt)
    
    np = npt(i);
    
    % Construction of the matrix
    d       = 2*ones(np,1); 
    l       = -ones(np,1)*(1); 
    Lapl1d  =  spdiags([l d l],[-1 0 1],np,np)/h(i).^2; %Discrete Laplace operator
    
    x = (h(i):h(i):1-h(i))';
    f = f_corr(x); % right hand side
    size(f)
    size(Lapl1d)
    u = Lapl1d\f;
    
    u_diff = u-u_corr(x);                          % calculate difference
    u_diff = u_diff/norm(u_diff,inf);
    
    %subplot(1,2,1), plot(x,u_corr(x),'b-',x,u,'r-',x,u_diff,'k-')
    %legend('true solution','numerical approximation','scaled difference')
    %title('1d poisson equation')

    %subplot(1,2,2)
    err2(i) = norm(u-u_corr(x),inf);  % calculate error in max norm
    figure(111)
    loglog(h,err2,'b.-')
    title('error convergence')
    drawnow
end

end

function y = u_corr(x)                                 % correct solution
c = 9*pi;
y = sin(c*x.^2);
end

function y = f_corr(x)                                  % right hand side
c = 9*pi;
y = sin(c*x.^2).*(2*c*x).^2-cos(c*x.^2)*(2*c);
end