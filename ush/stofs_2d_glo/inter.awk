{ STEP=0.1 } U {
#(STEP=="") { STEP=1 } U {
       	D=(U<$1)?1:-1;
       	M=((V-$2)/(U-$1)) * D * STEP;
       	while( ((-D)*((U+=(D*STEP)) - $1)) > (STEP/2))
	       	print U, V += M;
       	}
{ U=$1+0; V=$2+0; $1=$1 } 1
