//This is the implementation file for the spanning tree module.

//Declaration of the module MyTreeP
module MyTreeP {
	//Declaration of the interfaces MyTreeP provides
	provides interface MyTree;

	//Declaration of the interfaces MyTreeP uses
	uses {
		interface MyMany2One;
		interface SplitControl;
		interface AMSend;
		interface Receive;
		interface LowPowerListening;
		interface AMPacket;
		interface CC2420Packet;
		interface Timer<TMilli> as JitterTimer;
		interface Random;
	}
}//End of declaration

//Implementation of the module MyTreeP
implementation {
	message_t sBCPacket;
	BeaconPacket* psBeacon;
	bool bSending = FALSE, bRadioStarted = FALSE;

	void broadcast(void);

	//Command function to build the tree. All the nodes switch on their
	//radio just after they wake up. Additinally, root node starts broadcasting
	//to create the tree.
	command void MyTree.buildTree(void) {    
		//Switch on the radio and initialize the metric value.
		if (bRadioStarted == FALSE) {
			psBeacon->nxu16Metric = 0xFFFF; //Default metric
			call LowPowerListening.setLocalWakeupInterval(
											LPL_DEF_REMOTE_WAKEUP);
			call SplitControl.start();
		}

		//Start broadcasting from the root node.
		if (TOS_NODE_ID == 1) {
			psBeacon = call AMSend.getPayload(&sBCPacket,
											sizeof(BeaconPacket));
			psBeacon->nxu16Metric = 0;
			psBeacon->nxu8SeqNum++;
			psBeacon->bIsBeaconData = TRUE;

			broadcast();
		}
	}

	//This event is signalled when radio switch-on process is complete.
	event void SplitControl.startDone(error_t error) {
		if (error == SUCCESS)
			bRadioStarted = TRUE;
		else
			//Try again to turn on the radio.
			call SplitControl.start();
	}

	//This event should be defined to map all the events of SplitControl
	//component. However it does nothing in our implementation.
	event void SplitControl.stopDone(error_t err) {
		//Do nothing.
	}

	//This event implements the receving of beacons by each non-root node,
	//setting its parent node id and boradcasting the beacon to its neighbours.
	event message_t* Receive.receive(message_t* psMessage, void* payload,
														uint8_t u8Length) {
		int iRssi = 0;

		BeaconPacket* psRecvBeacon = (BeaconPacket*)payload;

		if ((u8Length != sizeof(BeaconPacket)) || 
						(psRecvBeacon->bIsBeaconData == FALSE))//Sanity check
			return psMessage; //Return the incoming buffer back to the stack.

		//Calculate RSSI of the received signal.
		iRssi = (int8_t)call CC2420Packet.getRssi(psMessage) - 45;

		//Consider the signal only if RSSI is greater than -90.
		if (iRssi > -90) {
			if ((psRecvBeacon->nxu8SeqNum > psBeacon->nxu8SeqNum) || 
									(psBeacon->nxu8SeqNum == 0xFF)) {
				psBeacon = call AMSend.getPayload(&sBCPacket, 
										sizeof(BeaconPacket));
				psBeacon->nxu16Metric = psRecvBeacon->nxu16Metric+1;
				psBeacon->nxu8SeqNum = psRecvBeacon->nxu8SeqNum;
				psBeacon->bIsBeaconData = TRUE;
				parentId = call AMPacket.source(psMessage);

				//This jitter timer is used to avoid multiple nodes to 
				//broadcast simultaneuously.
				call JitterTimer.startOneShot(call Random.rand16() 
													% TREE_JITTER);
			} else if ((psRecvBeacon->nxu8SeqNum == psBeacon->nxu8SeqNum) && 
						(psRecvBeacon->nxu16Metric+1 < psBeacon->nxu16Metric)) {
				psBeacon = call AMSend.getPayload(&sBCPacket, 
										sizeof(BeaconPacket));
				psBeacon->nxu16Metric = psRecvBeacon->nxu16Metric+1;
				psBeacon->nxu8SeqNum = psRecvBeacon->nxu8SeqNum;
				psBeacon->bIsBeaconData = TRUE;
				parentId = call AMPacket.source(psMessage);
						
				//This jitter timer is used to avoid multiple nodes to 
				//broadcast simultaneuously.
				call JitterTimer.startOneShot(call Random.rand16() % 
														TREE_JITTER);
			} else {
				//Do nothing
			}
		}

		return psMessage;//Return the incoming buffer back to the stack.
	}

	//Timer-fired event for JitterTimer
	event void JitterTimer.fired(void) {
		broadcast();
	}
  
	//This event is signalled when sending is done in broadcast.
	event void AMSend.sendDone(message_t* msg, error_t error) {
		M2OAppData sM2OPId;
		bSending = FALSE; //Now we can touch the output buffer again.
		
		if (error != SUCCESS)
			printf("Error in broadcast-send! Code: %d\n", error);

		//If the parent has changed for this node, then send the parent ID
		//to root node.
		if ((TOS_NODE_ID != 1) && (prev_parentId != parentId)) {
			sM2OPId.nxu16data = parentId;
			sM2OPId.bIsAppData = FALSE;
			call MyMany2One.send(&sM2OPId);
			prev_parentId = parentId;
		}
	}

	//This event implements receving the parent IDs in root node to create
	//source routing table.
	event void MyMany2One.receive(am_addr_t from, M2OAppData* psData){
		if ((TOS_NODE_ID == 1) && (psData->bIsAppData == FALSE)) {
			//Check whether there's a loop present.
			if(aPid[psData->nxu16data - 1] != from) {
				aPid[from-1] = psData->nxu16data;
				printf("Parent of %d: %d\n", from, aPid[from-1]);
			}
		}
	}
	
	//This function boradcasts the beacon to form the tree.
	void broadcast(void) {
		error_t error;

		if (!bSending) { 
			error = call AMSend.send(AM_BROADCAST_ADDR, &sBCPacket, 
													sizeof(BeaconPacket));

			if (error == SUCCESS)
				//Memorize that the radio is now busy serving our request
				//and we have passed the ownership of our output message_t
				//to the stack (until sendDone is signaled).
				bSending = TRUE;
			else
				printf("Error broadcasting! Code: %d\n", error);
		}
	}
}//End of implementation