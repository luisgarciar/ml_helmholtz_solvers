function [u,p,edge,A,eqn,info] = StokesCRP0(node,elem,pde,bdFlag,option)
%% STOKESCR Stokes equation: CR elements.
%
%   [u,p] = STOKESPCR(node,elem,pde,bdFlag) use Crouzeix and Raviart
%   nonconforming elements to approximate velocity u and piecewise constant
%   to approximate pressure p, repectively.
%
%       -div(mu*grad u) + grad p = f in \Omega,
%                        - div u = 0 in \Omega,
%   with
%       Dirichlet boundary condition        u = g_D  on \Gamma_D,
%       Neumann boundary condition du/dn - np = g_N  on \Gamma_N.
%
%  Created by Ming Wang at July, 2012, with discussion of Lin Zhong.
%
% See also Stokes, StokesP2P1, PoissonCR.
%
% Copyright (C) Long Chen. See COPYRIGHT.txt for details.

if ~exist('option','var'), option = []; end

%% Construct Data Structure
[elem2dof,edge] = dofedge(elem);
NE = size(edge,1); NT = size(elem,1); Nu = NE; Np = NT; N = size(node,1);

tic;
%% Compute geometric quantities and gradient of local basis
[Dlambda,area] = gradbasis(node,elem);

%% Assemble stiffness matrix for Laplace operator
A = sparse(Nu,Nu);
for i = 1:3
    for j = i:3
        % local to global index map
        ii = double(elem2dof(:,i));
        jj = double(elem2dof(:,j));
        % local stiffness matrix
        Aij = 4*dot(Dlambda(:,:,i),Dlambda(:,:,j),2).*area;
        if (j==i)
            A = A + sparse(ii,jj,Aij,Nu,Nu);
        else
            A = A + sparse([ii,jj],[jj,ii],[Aij; Aij],Nu,Nu);
        end
    end
end
clear Aij
A = blkdiag(A,A);

%% Assemble matrix for divergence operator
d1 = -2.*Dlambda(:,:,1).*[area,area];
d2 = -2.*Dlambda(:,:,2).*[area,area];
d3 = -2.*Dlambda(:,:,3).*[area,area];
Dx = sparse(repmat((1:Np)',3,1),double(elem2dof(:)),...
            [d1(:,1);d2(:,1);d3(:,1)],Np,Nu);
Dy = sparse(repmat((1:Np)',3,1),double(elem2dof(:)),...
            [d1(:,2);d2(:,2);d3(:,2)],Np,Nu);
B = -[Dx Dy];
clear d1 d2 d3 B1 B2

%% Assemble right hand side
f1 = zeros(Nu,1);
f2 = zeros(Nu,1);
if ~isfield(pde,'f') || (isreal(pde.f) && (pde.f==0))
    pde.f = [];
end
if ~isempty(pde.f)
    mid1 = (node(elem(:,2),:) + node(elem(:,3),:))/2;
    mid2 = (node(elem(:,3),:) + node(elem(:,1),:))/2;
    mid3 = (node(elem(:,1),:) + node(elem(:,2),:))/2;
    ft1 = repmat(area,1,2).*pde.f(mid1)/3;
    ft2 = repmat(area,1,2).*pde.f(mid2)/3;
    ft3 = repmat(area,1,2).*pde.f(mid3)/3;
    f1 = accumarray(elem2dof(:),[ft1(:,1);ft2(:,1);ft3(:,1)],[Nu 1]);
    f2 = accumarray(elem2dof(:),[ft1(:,2);ft2(:,2);ft3(:,2)],[Nu 1]);
end

[AD,BD,f,g,u,p,ufreeDof,pDof] = getbdStokesCR;


%% Record assembeling time
assembleTime = toc;
if ~isfield(option,'printlevel'), option.printlevel = 1; end
if option.printlevel >= 2
    fprintf('Time to assemble matrix equation %4.2g s\n',assembleTime);
end

%% Solve the system of linear equations
if isempty(ufreeDof), return; end
if isempty(option) || ~isfield(option,'solver')    % no option.solver
    if length(f)+length(g) <= 1e3  % Direct solver for small size systems
        option.solver = 'direct';
    else          % Multigrid-type  solver for large size systems
        option.solver = 'asmg';
    end
end
solver = option.solver;

%% Solver
switch solver
    case 'direct'
        tic;
        bigA = [AD, BD'; ...
                BD, sparse(Np,Np)];
        bigF = [f; g];
        bigu = [u; p];
        bigFreeDof = [ufreeDof; 2*Nu+pDof];
        bigu(bigFreeDof) = bigA(bigFreeDof,bigFreeDof)\bigF(bigFreeDof);
        u = bigu(1:2*Nu);
        p = bigu(2*Nu+1:end);
        residual = norm(bigF - bigA*bigu);
        info = struct('solverTime',toc,'itStep',0,'err',residual,'flag',2,'stopErr',residual);        
    case 'mg'
        option.solver  = 'WCYCLE';
        [u(ufreeDof),p,info] = mgstokes(A(ufreeDof,ufreeDof),B(:,ufreeDof),f(ufreeDof),g,...
                                        u(ufreeDof),p,elem,ufreeDof,option);         
    case 'asmg'
        [u(ufreeDof),p,info] = asmgstokes(A(ufreeDof,ufreeDof),B(:,ufreeDof),f(ufreeDof),g,...
                                          u,p,node,elem,bdFlag,ufreeDof,option); 
end

%% Post-process
if length(pDof) ~= Np % p is unique up to a constant
    % impose the condition int(p)=0
    c = sum(p.*area)/sum(area);
    p = p - c;
end

%% Output information
eqn = struct('A',AD,'B',BD,'f',f,'g',g,'ufreeDof',ufreeDof,'pDof',pDof);
info.assembleTime = assembleTime;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% subfunctions getbdStokesCR
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function [AD,BD,f,g,u,p,ufreeDof,pDof] = getbdStokesCR
        %% Boundary condition of Stokes equation: CR elements
        
        %% Initial set up
        f = [f1; f2];    % set in Neumann boundary condition
        g = zeros(Np,1);
        u = zeros(2*Nu,1);
        p = zeros(Np,1);
        ufreeDof = (1:Nu)';
        pDof = (1:Np)';
        
        if ~exist('bdFlag','var'), bdFlag = []; end
        if ~isfield(pde,'g_D'), pde.g_D = []; end
        if ~isfield(pde,'g_N'), pde.g_N = []; end
        if ~isfield(pde,'g_R'), pde.g_R = []; end
        
        %% Part 1: Find Dirichlet dof and modify the matrix
        % Find Dirichlet boundary dof: fixedDof and pDof
        isFixedDof = false(Nu,1);
        if ~isempty(bdFlag)       % case: bdFlag is not empty
            isDirichlet(elem2dof(bdFlag(:)==1)) = true;
            isFixedDof(isDirichlet) = true;% dof on D-edges
            fixedDof = find(isFixedDof);
            ufreeDof = find(~isFixedDof);
        end
        if isempty(bdFlag) && ~isempty(pde.g_D) && isempty(pde.g_N) && isempty(pde.g_R)
            s = accumarray(elem2dof(:), 1, [Nu 1]);
            isFixedDof = (s==1);
            fixedDof = find(isFixedDof);
            ufreeDof = find(~isFixedDof);
        end
        if isempty(fixedDof) % pure Neumann boundary condition
            % pde.g_N could be empty which is homogenous Neumann boundary condition
            fixedDof = 1;
            ufreeDof = 2:Nu;    % eliminate the kernel by enforcing u(1) = 0;
        end
        
        % Modify the matrix
        % Build Dirichlet boundary condition into the matrix AD by enforcing
        % AD(fixedDof,fixedDof)=I, AD(fixedDof,ufreeDof)=0, AD(ufreeDof,fixedDof)=0.
        % BD(:,fixedDof) = 0 and thus BD'(fixedDof,:) = 0.
        bdidx = zeros(2*Nu,1);
        bdidx(fixedDof) = 1;
        bdidx(Nu+fixedDof) = 1;
        Tbd = spdiags(bdidx,0,2*Nu,2*Nu);
        T = spdiags(1-bdidx,0,2*Nu,2*Nu);
        AD = T*A*T + Tbd;
        BD = B*T;
        
        %% Part 2: Find boundary edges and modify the right hand side f and g
        % Find boundary edges: Neumann and Robin
        Neumann = []; Robin = []; %#ok<*NASGU>
        if ~isempty(bdFlag)
            isNeumann(elem2dof((bdFlag(:)==2)|(bdFlag(:) == 3))) = true;
            isRobin(elem2dof(bdFlag(:)==3)) = true;
            Neumannidx = find(isNeumann);
            Neumann   = edge(isNeumann,:);
            Robin     = edge(isRobin,:);
        end
        if isempty(bdFlag) && (~isempty(pde.g_N) || ~isempty(pde.g_R))
            % no bdFlag, only pde.g_N or pde.g_R is given in the input
            [tempvar,Neumann] = findboundary(elem);
            if ~isempty(pde.g_R)
                Robin = Neumann;
            end
        end
        
        % Neumann boundary condition
        if ~isempty(pde.g_N) && ~isempty(Neumann) && ~(isnumeric(pde.g_N) && (pde.g_N == 0))
            [lambda,w] = quadpts1(3);
            nQuad = size(lambda,1);
            % edge bases 
            bdphi = 2*(lambda(:,1)+lambda(:,2))-1;
            % length of edge
            ve = node(Neumann(:,1),:) - node(Neumann(:,2),:);
            edgeLength = sqrt(sum(ve.^2,2));
            % update RHS
            for pp = 1:nQuad
                pxy = lambda(pp,1)*node(Neumann(:,1),:)+lambda(pp,2)*node(Neumann(:,2),:);
                gp = pde.g_N(pxy);
                f1(Neumannidx) = f1(Neumannidx) + w(pp)*edgeLength.*gp(:,1).*bdphi(pp); % interior bubble
                f2(Neumannidx) = f2(Neumannidx) + w(pp)*edgeLength.*gp(:,2).*bdphi(pp); % interior bubble
            end
        end
        f = [f1; f2];
        % The case non-empty Neumann but g_N=[] corresponds to the zero flux
        % boundary condition on Neumann edges and no modification is needed.
        
        % Dirichlet boundary conditions
        if ~isempty(fixedDof) && ~isempty(pde.g_D) && ~(isnumeric(pde.g_D) && (pde.g_D == 0))
            u1 = zeros(Nu,1);
            u2 = zeros(Nu,1);
            bdEdgeMid = (node(edge(fixedDof,1),:)+node(edge(fixedDof,2),:))/2;
            uD = pde.g_D(bdEdgeMid);         % bd values at middle points of edges
            u1(fixedDof) = uD(:,1);
            u2(fixedDof) = uD(:,2);
            u = [u1; u2]; % Dirichlet bd condition is built into u
            f = f - A*u;  % bring affect of nonhomgenous Dirichlet bd condition to
            g = g - B*u;  % the right hand side
            g = g - mean(g); % impose the compatible condition
            f(fixedDof) = u1(fixedDof);
            f(fixedDof+Nu) = u2(fixedDof);
            u = [u1; u2]; % Dirichlet bd condition is built into u
        end
        % The case non-empty Dirichlet but g_D=[] corresponds to the zero Dirichlet
        % boundary condition and no modification is needed.
        
        % modfiy pressure dof for pure Dirichlet
        if isempty(Neumann)
            pDof = (1:Np-1)';
        end
        
        ufreeDof = [ufreeDof; Nu+ufreeDof];                
    end % end of function getbdStokesCR
end