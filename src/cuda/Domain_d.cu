#include "Domain_d.cuh"
#include "Functions.cuh"
//Allocating from host
namespace SPH {
void Domain_d::SetDimension(const int &particle_count){
	//Allocae arrays (as Structure of arryays, SOA)

	cudaMalloc((void **)&x, particle_count * sizeof (Vector));
	cudaMalloc((void **)&v, particle_count * sizeof (Vector));
	cudaMalloc((void **)&a, particle_count * sizeof (Vector));

	cudaMalloc((void **)&T		, particle_count * sizeof (double));
	cudaMalloc((void **)&dTdt	, particle_count * sizeof (double));
	
	//To allocate Neighbours, it is best to use a equal sized double array in order to be allocated once
}

//Thread per particle
//dTdt+=1/cp* (mass/dens^2)*4(k)
void __global__ ThermalSolveKernel (double *dTdt,
																		double3 *x, double *h,
																		double *m, double *rho,
																		double *T, double *k_T, double *cp, 
																		int **neib, int *neibcount){
	int i = threadIdx.x+blockDim.x*blockIdx.x;
	dTdt[i] = 0.;

	for (int k=0;k < neibcount[i];k++) { //Or size
		int j = neib[i][k];
		double3 xij; 
		xij = x[i] - x[j];
		double h_ = (h[i] + h[j])/2.0;
		
		double GK	= GradKernel(3, 0, length(xij)/h_, h_);
		//		Particles[i]->dTdt = 1./(Particles[i]->Density * Particles[i]->cp_T ) * ( temp[i] + Particles[i]->q_conv + Particles[i]->q_source);	
		//   mc[i]=mj/dj * 4. * ( P1->k_T * P2->k_T) / (P1->k_T + P2->k_T) * ( P1->T - P2->T) * dot( xij , v )/ (norm(xij)*norm(xij));
		dTdt[i] += m[j]/rho[j]*( 4.0*k_T[i]*k_T[j]/(k_T[i]+k_T[j]) * (T[i] - T[j]));
	}
	dTdt[i] *=1/(rho[i]*cp[i]);
}

void Domain_d::ThermalSolve(){
	
	ThermalSolveKernel<<<1,1>>>(dTdt,	
																	x, h, //Vector has some problems
																	m, rho, 
																	T, k_T, cp_T,
																	neib, neibcount);
}

Domain_d::~Domain_d(){
	
		cudaFree(a);		
		cudaFree(v);
	
}

};//SPH
    // // Create host pointer to array-like storage of device pointers
    // Obj** h_d_obj = (Obj**)malloc(sizeof(Obj*) * 3); //    <--------- SEE QUESTION 1
    // for (int i = 0; i < 3; i++) {
        // // Allocate space for an Obj and assign
        // cudaMalloc((void**)&h_d_obj[i], sizeof(Obj));
        // // Copy the object to the device (only has single scalar field to keep it simple)
        // cudaMemcpy(h_d_obj[i], &(h_obj[i]), sizeof(Obj), cudaMemcpyHostToDevice);
    // }

    // /**************************************************/
    // /* CREATE DEVICE ARRAY TO PASS POINTERS TO KERNEL */
    // /**************************************************/

    // // Create a pointer which will point to device memory
    // Obj** d_d_obj = NULL;
    // // Allocate space for 3 pointers on device at above location
    // cudaMalloc((void**)&d_d_obj, sizeof(Obj*) * 3);
    // // Copy the pointers from the host memory to the device array
    // cudaMemcpy(d_d_obj, h_d_obj, sizeof(Obj*) * 3, cudaMemcpyHostToDevice);
