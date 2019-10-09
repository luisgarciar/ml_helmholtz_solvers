function [ml_mat,ml_prec,ml_prec_split,restrict,interp] = mlfgmres_setup_2D(npcc,numlev,pde1,pde2,option)
%% MLGMRES_SETUP_2D: Constructs a hierarchy of Galerkin coarse grid matrices,
% smoother splittings and interpolation operators for a 2D Helmholtz/shifted
% Laplace problem discretized with P1 finite elements on a uniform square
% grid 
%
% Requires the iFEM package!! 
%
%  Use:
% [ml_mat,ml_prec] = mg_setupfem_2D(npcc,numlev,pde,option)
%
%  Input: 
%  npcc:      number of interior points on coarsest grid in 1D          
%  numlev:    Total number of levels (number of coarse grids + 1)
%  pde:       Structure with the data of the pde problem
%  option:    structure with options
%            - option.twolevel: If 'true', the function only returns finest
%               and coarsest grid
%
%  Output:
%  ml_mat: Cell array with Galerkin matrices 
%          (grid_matrices{i}: Galerkin matrix level i)   
%
%  ml_prec: Cell array with preconditioners at level i
%           
%  Author:      Luis Garcia Ramos, 
%               Institut fur Mathematik, TU Berlin
%               Version 1.0 Sep 2017
%%

[ml_mat,~,restrict,interp]  = mg_setupfem_2D(npcc,numlev,pde1,option);
[ml_prec,ml_prec_split,~,~] = mg_setupfem_2D(npcc,numlev,pde2,option);

end
       


