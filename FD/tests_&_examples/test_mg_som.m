%Test multigrid Sommerfeld BC's
clc;
bc  = 'som';
dim = 2;
k   = 5;
npc = 50; npf = 2*(npc)+1;

A = helmholtz2(k,0,npf,npf,bc);
restr  =  fwrestriction_som(npf,dim,bc); %size(restr)
interp =  4*restr';

%Two-grid cycle
npre = 2; npost = 2; smo = 'gs'; w = 2/3; numcycles = 11;

b       = zeros(length(A),1); %b(ceil(length(A)/2),1)=1;
x_init  = randn(length(A),1);

[x_sol,relres] = twogrid(A,restr,interp,b,x_init,dim,npre,npost,w,smo,numcycles);

