//This is the implementation file for one-to-many data forwarding.

//Declaration of the module MyOne2ManyP
module MyOne2ManyP {
	//Declaration of the interfaces MyOne2ManyP provides
	provides interface MyOne2Many;

	//Declaration of the interfaces MyOne2ManyP uses
	uses {
		interface AMSend;
		interface Receive;
		interface PacketLink;
	}
}//End of declaration

//Implementation of the module MyOne2ManyP
implementation {
	message_t sDataPacket;
	O2MNwData* psO2MNwData;
	bool bSending = FALSE, bSendWaitng = FALSE;

	void sendDataDown(void);

	//Command function to send the one-to-many data from the root node.
	command void MyOne2Many.send(uint8_t u8DestId, O2MAppData* psO2MData) {
		int i;

		if (TOS_NODE_ID == 1) {
			psO2MNwData = call AMSend.getPayload(&sDataPacket, 
											sizeof(O2MNwData));
											
			psO2MNwData->data.nxu16data = psO2MData->nxu16data;
			
			psO2MNwData->anxu8Route[MAX_PATH_LENGTH-1] = u8DestId;
			
			for (i=1; i<MAX_PATH_LENGTH; i++) {
				psO2MNwData->anxu8Route[MAX_PATH_LENGTH-1-i] = 
							aPid[psO2MNwData->anxu8Route[MAX_PATH_LENGTH-i]-1];
				
				if (psO2MNwData->anxu8Route[MAX_PATH_LENGTH-1-i] == 1)
					break;					
			}
			
			for (i++; i<MAX_PATH_LENGTH; i++)
				psO2MNwData->anxu8Route[MAX_PATH_LENGTH-1-i] = 0;
			
			sendDataDown();
		} else {
			printf("Error! One-to-many data can't originiate at a non-root \
																	node.\n");
		}
	}
  
	//This event implements receiving of the network data from parent nodes and
	//forwarding to target node.
	event message_t* Receive.receive(message_t* psMessage, void* payload,
														uint8_t u8Length) {
		int i;
		O2MNwData* psRecvData = (O2MNwData*)payload;

		if ((u8Length != sizeof(O2MNwData)) ||
				(psRecvData->bIsO2MData == FALSE))//Sanity check
			return psMessage; //Return the incoming buffer back to the stack.

		if (TOS_NODE_ID != 1) {

			//If it's not the target node, forward data to the next node.
			if (psRecvData->anxu8Route[MAX_PATH_LENGTH-1] != 0) {
				signal MyOne2Many.receive(
					psRecvData->anxu8Route[MAX_PATH_LENGTH-1], &psRecvData->data);
				psO2MNwData = call AMSend.getPayload(&sDataPacket, 
														sizeof(O2MNwData));

				psO2MNwData->data.nxu16data = psRecvData->data.nxu16data;
				for (i=1; i<MAX_PATH_LENGTH; i++)
					psO2MNwData->anxu8Route[i] = psRecvData->anxu8Route[i];
				
				sendDataDown();
			} else {
				signal MyOne2Many.receive(TOS_NODE_ID, &psRecvData->data);			
			}
		}

		return psMessage; //Return the incoming buffer back to the stack.
	}

	//This event is signalled when sending is done.
	event void AMSend.sendDone(message_t* msg, error_t error) {
		bSending = FALSE; //Now we can touch the output buffer again.
		if (error != SUCCESS) {
			printf("Error in sendDone! Code: %d\n", error);
		}

		//Send again if there's some data waiting to be sent.
		if (bSendWaitng) {
			sendDataDown();
			bSendWaitng = FALSE;
		}
	}
	
	//This functions sends the network data in a downwards direction towards
	//the sink node.
	void sendDataDown(void) {
		int i;
		error_t error;

		am_addr_t chId = 0;

		for (i=0; i<MAX_PATH_LENGTH; i++) {
			if ((psO2MNwData->anxu8Route[i] != 0) && 
			(psO2MNwData->anxu8Route[i] != 1)) {
				chId = psO2MNwData->anxu8Route[i];
				psO2MNwData->anxu8Route[i] = 0;
				break;
			}
		}
		
		psO2MNwData->bIsO2MData = TRUE;

		if (!bSending) {
			call PacketLink.setRetries(&sDataPacket, NUM_RETRIES);
			error = call AMSend.send(chId, &sDataPacket, sizeof(O2MNwData));

			if(error == SUCCESS)
				//Memorize that the radio is now busy serving our request
				//and we have passed the ownership of our output message_t
				//to the stack (until sendDone is signaled).
				bSending = TRUE;
			else
				printf("Error in sending! Code: %d\n", error);
		} else {
			bSendWaitng = TRUE;
		}
	}
}//End of implementation