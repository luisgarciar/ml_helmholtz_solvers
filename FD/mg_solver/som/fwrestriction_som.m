function R = fwrestriction_som(npf,dim,bc)
%% FWRESTRICTION_SOM Constructs the matrix corresponding to the full weight restriction
%   operator from a fine grid with npf interior points.
%  
%   Use:    R = fwrestriction(npf,dim,bc)  
%
%   Input: 
%       npf:    number of interior points in 1-D fine grid (must be odd)
%       dim:    dimension (1 or 2)
%       
%   Output:
%       R:      restriction matrix of size npc x npf
%
%   Author: Luis Garcia Ramos, 
%           Institut fur Mathematik, TU Berlin
%  
%  Version 1.0, Jun 2016
%  Works on 1-D, 2-D Dirichlet boundary conditions
%               
%%
switch dim
    case 1
        %npc = round(npf/2)-1; %length of coarse grid vectors
        y = zeros(npf,1); y(1:3,1) = [1;2;1];
        R = gallery('circul',y');
        R = 0.25*sparse(R(1:2:(npf-2),:));
           
    case 2
        switch bc
            case 'dir'
                %npc = round(npf/2)-1;  
                y   = zeros(npf,1); y(1:3,1) = [1;2;1];
                R   = gallery('circul',y)';
                R   = 0.25*sparse(R(:,1:2:(npf-2))); %1D operator%
                R   = kron(R,R)';  %2D operator  
                
            case 'som'
                assert(mod(npf,2)==1,'number of interior points must be even')
                npc = round((npf+1)/2)+1;
                npff  = npf+2; %include endpoints
                npcc  = npc+2;
                
                R   = sparse(npcc^2,npff^2)';

                %We fill the matrix by rows (change this later!)
                %indc and indf are the index of in coarse and fine grid
                %resp.
                
                %(0,0)- South-West Corner
                indc=1; indf=1; 
                R(indc,indf)=4; R(indc,indf+1)=4;
                R(indc,indf+npff)=4; R(indc,indf+npff+1)=4;
                
                %(1,0)-  South-East Corner
                indc=npcc; indf=npff;
                R(indc,indf)=4;  R(indc,indf-1)=4;
                R(indc,indf+npff)=4; R(indc,indf+npff-1)=4;
                
                %(0,1)- North-West Corner
                indc=npcc*(npcc-1)+1; indf=npff*(npff-1)+1;
                R(indc,indf)=4;   R(indc,indf-npf)=4;
                R(indc,indf+1)=4; R(indc,indf-npf+1)=4;
                
                %(1,1)- North East Corner
                indc=npcc^2; indf=npff^2;
                R(indc,indf)=4; R(indc,indf-1)=4;
                R(indc,indf-npff)=4; R(indc,indf-npff-1)=4;

                %South boundary y=0
                for indc=2:npc-1
                    indf=2*indc-1;
                    R(indc,indf)=4; R(indc,indf+1)=2; R(indc,indf-1)=2;
                    R(indc,indf+npff)=4; R(indc,indf+npff+1)=2;
                    R(indc,indf+npff-1)=2;
                end
                
                %East boundary x=1
                
                for i=2:npc-1
                    indc=i*npcc; indf=(2*i-1)
                
                
                
        end      
      
end

end
