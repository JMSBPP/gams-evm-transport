$title @.spec/SupplyDemand_101.spec

* ----- INDEX -----
Set i /a,b/;
Set j /c,d/;

* ---- EXOGENOUS-VARIABLES -----
Parameter s(i)
	  / a 350
	    b 600 /;
Parameter d(j)
	  / c 325
	    d 300 /;


Table psi(i,j)
	    c      d     
    a      2.5    1.7 
    b      2.5    1.8  ;

Scalar gamma /4/ ;

Parameter c(i,j); c (i,j) = gamma* psi(i,j);


* ----- ENDOGENOUS VARIABLES -----
Variables q(i,j), Z;
Positive Variable q;


Equations cost, supply(i), demand(j);
	cost..        Z =e= sum((i,j), c(i,j)*q(i,j));
	supply (i)..  sum(j, q(i,j))  =l=  s(i) ;
	demand (j)..  sum(i, q(i,j))  =g=  d(j) ;


Model SupplyDemand_101 /cost, supply, demand/ ;


Solve SupplyDemand_101 using lp minimizing Z ;

Display q.l, q.m ;
