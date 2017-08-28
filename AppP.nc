//This is the implementation file for the application module.

#include "Common.h"

//Declaration of the module AppP
module AppP {
	//Declaration of the interfaces MyTreeP uses
	uses {
		interface MyTree;
		interface MyMany2One;
		interface MyOne2Many;
		interface Boot;
		interface Timer<TMilli> as StartTimer;
		interface Timer<TMilli> as M2OPeriodicTimer;
		interface Timer<TMilli> as O2MPeriodicTimer;
		interface Timer<TMilli> as O2MStartTimer;
		interface Timer<TMilli> as M2OJitterTimer;
		interface Random;
	}
}//End of declaration

//Implementation of the module AppP
implementation {
	//Application-level data packet
	M2OAppData sM2OAppData;
	O2MAppData sO2MAppData;
	uint8_t u8NodeId = 1;

	//Boot event after the system has been initialized. Root uptime is greater
	//than the uptime for non-route nodes, to ensure that all the non-route
	//nodes are awake when the root sends broadcast message to build the tree.
	event void Boot.booted(void) {
		if (TOS_NODE_ID == 1) {
			call StartTimer.startOneShot(ROOT_UPTIME);
			call O2MStartTimer.startOneShot(O2M_START_TIME);
		} else {
			call StartTimer.startOneShot(NODE_UPTIME);
			//call M2OPeriodicTimer.startPeriodic(M2O_DATA_PERIOD);
		}
	}

	//Timer-fired event for StartTimer
	event void StartTimer.fired(void) {
		call MyTree.buildTree();
		call StartTimer.startOneShot(REBUILD_PERIOD);
	}

	//Timer-fired event for M2OPeriodicTimer
	event void M2OPeriodicTimer.fired(void) {
		call M2OJitterTimer.startOneShot(call Random.rand16() %
														M2O_APP_JITTER);
	}

	//Timer-fired event for M2OJitterTimer. It sends data to the root.
	event void M2OJitterTimer.fired(void) {
		sM2OAppData.bIsAppData = TRUE;
		sM2OAppData.nxu16data++;
		printf("app:Send to sink seqn %d\n", sM2OAppData.nxu16data);
		call MyMany2One.send(&sM2OAppData);
	}

	//This event implements receving the application data for printing.
	event void MyMany2One.receive(am_addr_t from, M2OAppData* psRcvdData) {
		if (psRcvdData->bIsAppData == TRUE)
			printf("app:Recv from %d seqn %d\n", from, psRcvdData->nxu16data);
	}
	
	//Timer-fired event for O2MStartTimer
	event void O2MStartTimer.fired(void) {
		call O2MPeriodicTimer.startPeriodic(O2M_DATA_PERIOD);
	}
	
	//Timer-fired event for O2MPeriodicTimer
	event void O2MPeriodicTimer.fired(void) {
		//Randomize the node id to which data is to be sent.
		u8NodeId++;
		
		printf("app:Send to %d seqn %d\n", u8NodeId, 
											sO2MAppData.nxu16data);
		call MyOne2Many.send(u8NodeId, &sO2MAppData);
		
		if(u8NodeId == MAX_NODES)
		{
			u8NodeId = 1;
			sO2MAppData.nxu16data++;
		}
	}

	//This event implements receving the application data for printing.
	event void MyOne2Many.receive(am_addr_t to, O2MAppData* psRcvdData) {
		printf("app:Recv seqn %d target %d\n", psRcvdData->nxu16data, to);
	}	
}//End of implementation
