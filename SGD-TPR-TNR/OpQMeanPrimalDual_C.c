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
	
	double loss, ywx, cumPosLoss, cumNegLoss, coeff;
    double alpha_t;
    int dataCounter;
	
	ticCounter = 0;		/* No tics seen yet! */
	timeElapsed = 0;	/* We have not done any useful computation yet */
	
    tCounter = 0;
    dataCounter = 0;    
	    
    /* Intermediate weight vector */
	w = (double*)malloc(d*sizeof(double));
    
    /* Running Average weight vector */
    wInter = (double*)malloc(d*sizeof(double));
    
	/* Initialize primal weight vectors */
    for(dCounter = 0; dCounter < d; dCounter++){
        *(w + dCounter) = *(wInit + dCounter);
		/* Modified for Harikrishna -- wInter set to wInit*/
        *(wInter + dCounter) = *(wInit + dCounter);
    }
	
	/* Initialize dual variable */
	alpha_t = 0.5;
	
	/* Cumulative losses and positives and negatives */
	cumPosLoss = 0;
	cumNegLoss = 0;	
	
	/* Go over the data stream (number of points x number of passes)*/
	for(tCounter = 1; tCounter <= numData*numPasses; tCounter++)
	{
		/* Set step size */
		C_t = C/sqrt(tCounter);
		
		/* Start the clock */
		tic = clock();
           
		/* Move to current point in stream */
		x_t = stream + d*dataCounter;
		
		/* Compute score w.x_t for current model w */
		/* Initially ywx contains the above score - later this would be updated to y_t * w.x_t */
		ywx = 0;        
        for(dCounter = 0; dCounter < d; dCounter++){
			ywx += (*(x_t + dCounter))*(*(w + dCounter));
        }
           
		/* Compute hinge loss (1-w.x_t)_+ and coefficient: sqrt(alpha)/p (for positives), sqrt(1-alpha)/(1-p) (for negatives) */
		/* Also maintain cumulative sum of postive and negative losses incurred: cumPosLoss, cumNegLoss */
		if(*(labels + dataCounter) == 1){
			loss = TRUNC(1-ywx)/p; // hinge loss on positives
			cumPosLoss += loss; // maintain cummulative loss on positives
			coeff = sqrt(alpha_t)/p; // compute (dual) coefficient for positives (normalized by p -- TPR)
		}
		else{
            ywx = -ywx; // ywx = y_t * w.x_t!
			loss = TRUNC(1-ywx)/(1-p); // hinge loss on negatives
			cumNegLoss += loss; // maintain cummulative loss on negatives
			coeff = sqrt(1-alpha_t)/(1-p); // compute (dual) coefficient for negatives (normalized by 1-p -- TNR)
		}
	    
		/* PRIMAL UPDATE */
		/****************/
		
		/* Update the (intermediate) primal weight vector: w*/
        /* Gradient update (descent) */
		// double wnorm = 0.0;
        
        for(dCounter = 0; dCounter < d; dCounter++){
            if(ywx < 1){
               *(w + dCounter) += C_t * coeff * (*(x_t + dCounter)) * *(labels + dataCounter);
                // wnorm = wnorm  +  *(w + dCounter) * *(w + dCounter); 
            }
		}       		
         
		/* Update the final weight vector */
		for(dCounter = 0; dCounter < d; dCounter++){
			*(wInter + dCounter) = ((*(wInter + dCounter))*(tCounter - 1) + *(w + dCounter))/tCounter;
		}		
		/****************/
		
		/* DUAL UPDATE */
		/****************/
		
		/* Update dual variable: alpha_t */
		/* FTRL update (ascent) */
		alpha_t  =  cumPosLoss*cumPosLoss / (cumPosLoss*cumPosLoss + cumNegLoss*cumNegLoss);
        
		/****************/
				
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
        
        /* Reset data counter if exceeds total data points (happens at the end of a pass) */
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