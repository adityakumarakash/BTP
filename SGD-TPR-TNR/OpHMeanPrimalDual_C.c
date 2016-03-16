#include "mex.h"
#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <time.h>

#define TRUNC(x) ((x)>0?x:0) 

struct valLocPair{
	double val;
	int loc;
};

typedef struct valLocPair vlPair;

/* Sort in ascending order */
int compVLPair(const void *a, const void *b){
	if(((vlPair*)a)->val > ((vlPair*)b)->val)
		return 1;
	else
		return -1;
}

void doOpTPRTNRPrimalDual(double* stream, double* labels, double p, double* wInit, double* wBar, int numData, int d, double C, int ticSpacing, int numTics, int numPasses, double upperBound){
    int tCounter, dCounter;
    double C_t;
    double *x_t, *x_temp, *w, *wInter;
	int ticCounter;
	double timeElapsed;
	clock_t tic, toc;
	
	double reward, ywx, cumPosRewards, cumNegRewards, coeff;
    double alpha_t;
    int dataCounter;
	
	ticCounter = 0;		/* No tics seen yet! */
	timeElapsed = 0;	/* We have not done any useful computation yet */
	
    tCounter = 0;
    dataCounter = 0;    
	
	C_t = 0;
    
    /* Intermediate weight vector */
	w = (double*)malloc(d*sizeof(double));
    
    /* Running Average weight vector */
    wInter = (double*)malloc(d*sizeof(double));
    
	/* Initialize the weight vectors properly */
    for(dCounter = 0; dCounter < d; dCounter++){
        *(w + dCounter) = *(wInit + dCounter);
		/* wInter set to wInit*/
        *(wInter + dCounter) = *(wInit + dCounter);
    }
	
	cumPosRewards = 0;
	cumNegRewards = 0;
	
	/* Initial dual variable value */
	alpha_t = 0.5;
	
	/* Upper bound on rewards. ||x||_2 <= upperBound, and we will have to ensure that ||w||_2 <= 1.*/
    double lambda = 9/upperBound;
 	upperBound = upperBound*lambda + 1;
    
	/* Go over the data stream */
	for(tCounter = 1; tCounter <= numData*numPasses; tCounter++)
	{
		/* Set step size for this epoch */
		C_t = C/sqrt(tCounter);
		
		/* Start the clock */
		tic = clock();
        
		/* Move to current point in stream */
		x_t = stream + d*dataCounter;
		
		/* Compute score w.x_t for current model w */
		ywx = 0;        
        for(dCounter = 0; dCounter < d; dCounter++){
			ywx += (*(x_t + dCounter))*(*(w + dCounter));
        }
        
		/* Compute hinge reward (upperBound - (1-w.x_t)_+) and coefficient: alpha^2/p (for positives), (1-alpha)^2/(1-p) (for negatives) */
		if(*(labels + dataCounter) == 1){
			reward = (upperBound - TRUNC(1-ywx))/p;
			cumPosRewards += reward;
			coeff = alpha_t*alpha_t/p;
		}
		else{
            ywx = -ywx;
			reward = (upperBound - TRUNC(1-ywx))/(1-p);
			cumNegRewards += reward;
			coeff = (1-alpha_t)*(1-alpha_t)/(1-p);            
		}              
        
		/* Update the intermediate primal weight vector using the gradient & project to l2 ball of radius (upperBound - 1) */        
		double wnorm = 0.0;
        
        for(dCounter = 0; dCounter < d; dCounter++){
            if(ywx < 1){
               *(w + dCounter) += C_t * coeff * (*(x_t + dCounter)) * *(labels + dataCounter);
                wnorm = wnorm  +  *(w + dCounter) * *(w + dCounter); 
            }
		}
		
		/* project on to l2 ball of radius (upperBound - 1) */
        wnorm = sqrt(wnorm);
        if(wnorm > lambda)
            for(dCounter = 0; dCounter < d; dCounter++){
                *(w + dCounter) /= wnorm * lambda; // * (upperBound - 1);
            }
        
		/* Update the final weight vector */
		for(dCounter = 0; dCounter < d; dCounter++){
			*(wInter + dCounter) = ((*(wInter + dCounter))*(tCounter - 1) + *(w + dCounter))/tCounter;
		}
		
		/* Update dual variable: alpha_t */
		alpha_t  =  cumNegRewards / (cumPosRewards + cumNegRewards);
        
		toc = clock();
		
		/* How much time did we spend doing any useful work */
		timeElapsed += (((double)toc-(double)tic)/((double)(CLOCKS_PER_SEC)));
		        
        /* If the time tic is appropriate, make a record of this vector */
		if(tCounter%ticSpacing == 0){            
		
			for(dCounter = 0; dCounter < d; dCounter++){
				*(wBar + (d+1)*ticCounter + dCounter) = *(wInter + dCounter);
			}
			*(wBar + (d+1)*ticCounter + d) = timeElapsed;			
			ticCounter++;        
		}		
        
        /* Increment dataCounter */
        dataCounter++;
        
        /* Reset data counter if exceeds total data points */
        if(dataCounter == numData)
            dataCounter = 0;        
        
	}
	
	/* Make one final record of the weight vector */
	for(dCounter = 0; dCounter < d; dCounter++){
		*(wBar + (d+1)*ticCounter + dCounter) = *(wInter + dCounter);
	}
	*(wBar + (d+1)*ticCounter + d) = timeElapsed;
    
    free(w);
	free(wInter);
}

void mexFunction(int nlhs, mxArray *plhs[], int rhs, const mxArray *prhs[]){
	double *stream;					/* Stream of data points */
	double *labels;					/* Labels of the data points in the stream */
	double *wInit;					/* Initial Value of parameter vector */
    double C;   					/* Length of epochs */
	double p;						/* k for prec@k : k < 0 indicates PRBEP */
	int ticSpacing;					/* Spacing between tics */
    double upperBoundL2;              /* Upper Bound on ||x||_2*/
    
    int numData, numEpochs, numTics;/* Length of the stream */
    int d;                          /* Dimensionality of training points */
	int numPasses;				/* Number of iterations */
    
	double *wBarTime;			    /* Final weight vector */
    
    double *temp;
    int dCounter;
    
	#define STREAM          prhs[0]		/* Stream of data points */
	#define LABELS          prhs[1]		/* Labels of the data points in the stream */
    #define P_IN            prhs[2]		/* Initial Value of parameter Vector */
	#define W_INIT          prhs[3]		/* Proportion of positives */
    #define C_IN            prhs[4]     /* C-SVM Value */
	#define TIC_SP          prhs[5]		/* Spacing between tics */
    #define NUMPASS        	prhs[6]		/* Number of iterations */
    #define UB_L2        	prhs[7]		/* Upper bound L2 norm */
    
	#define W_BARTIME       plhs[0]		/* Final weight vector and time marker */
            
    stream = mxGetPr(STREAM);
	labels = mxGetPr(LABELS);
    
    temp = mxGetPr(P_IN);
    p = *(temp);
    
	wInit = mxGetPr(W_INIT);    
    
    temp = mxGetPr(C_IN);
    C = *(temp);
	
	temp = mxGetPr(TIC_SP);
	ticSpacing = *(temp);
	
    temp = mxGetPr(NUMPASS);
	numPasses = *(temp);
    
    temp = mxGetPr(UB_L2);
	upperBoundL2 = *(temp);
    
	d = mxGetM(STREAM);
    numData = mxGetN(STREAM);
	
	numTics = floor((double)(numPasses*numData)/(double)ticSpacing) + 1;
    
    W_BARTIME = mxCreateDoubleMatrix(d+1, numTics, mxREAL);
    wBarTime = mxGetPr(W_BARTIME);
    
	/* Call the H-mean optimization routine */
	doOpTPRTNRPrimalDual(stream, labels, p, wInit, wBarTime, numData, d, C, ticSpacing, numTics, numPasses, upperBoundL2);
}