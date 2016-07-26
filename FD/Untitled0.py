# -*- coding: utf-8 -*-
# <nbformat>3.0</nbformat>

# <codecell>

from IPython.display import display
from sympy import *
from sympy.interactive import printing
printing.init_printing()
import sympy as sym

u = Symbol("\tilde{u}",complex=True)
k = Symbol("k",real=True,positive=True)
x = Symbol("x",real=True)
y = Symbol("y",real=True)
m = Symbol("m",real=True)
n = Symbol("n",real=True)

# <markdowncell>

# In this notebook we compute given a solution $u$ a right hand side $f$ for the Helmholtz boundary value problem 
# \begin{align}
# -u''-k^2u&=f \text{ in } \Omega= (0,1) ,\\
# u &=0 \text{ on } \partial\Omega \\
# \end{align}
# 
#  Let $u=x(x-1)^2$, then $f=-u''-k^2u$ is given by

# <codecell>

u = x*(x-1)**2*(y**2)*(y-1)
f = -diff(u,x,x)-diff(u,y,y)-k**2*u
simplify(f)

# <codecell>


