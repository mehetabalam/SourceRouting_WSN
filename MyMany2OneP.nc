//This is the implementation file for many-to-one data forwarding.

//Declaration of the module MyMany2OneP
module MyMany2OneP {
	//Declaration of the interfaces MyMany2OneP provides
	provides interface MyMany2One;

	//Declaration of the interfaces MyMany2OneP uses
	uses {
		interface AMSend;
		interface Receive;
		interface PacketLink;
	}
}//End of declaration

//Implementation of the module MyMany2OneP
implementation {
	message_t sDataPacket;
	M2ONwData* psM2ONwData;
	bool bSending = FALSE, bSendWaitng = FALSE;
  
	void sendDataUp(void);

	//Command function to send the many-to-one data from the source to sink.
	//This is used by the nodes from where the concerned data originiates.
	command void MyMany2One.send(M2OAppData* psM2OData) {
		if (TOS_NODE_ID != 1) {  
			psM2ONwData = call AMSend.getPayload(&sDataPacket, 
											sizeof(M2ONwData));

			psM2ONwData->from = TOS_NODE_ID;
			psM2ONwData->hops = 0;
			psM2ONwData->data.nxu16data = psM2OData->nxu16data;
			psM2ONwData->data.bIsAppData = psM2OData->bIsAppData;

			sendDataUp();
		} else {
			printf("Error! Many-to-one data can't originiate at the root \
																node.\n");
		}
	}
  
	//This event implements receiving of the network data from child nodes and
	//forwarding to the parent node.
	event message_t* Receive.receive(message_t* psMessage, void* payload,
														uint8_t u8Length) {
		M2ONwData* psRecvData = (M2ONwData*)payload;

		if ((u8Length != sizeof(M2ONwData)) ||
		(psRecvData->bIsM2OData == FALSE))//Sanity check
			return psMessage; //Return the incoming buffer back to the stack.

		psRecvData->hops++;

		signal MyMany2One.receive(psRecvData->from, &psRecvData->data);

		if (TOS_NODE_ID != 1) {
			psM2ONwData = call AMSend.getPayload(&sDataPacket, 
											sizeof(M2ONwData));
			
			psM2ONwData->from = psRecvData->from;
			psM2ONwData->hops = psRecvData->hops;
			psM2ONwData->data.nxu16data = psRecvData->data.nxu16data;
			psM2ONwData->data.bIsAppData = psRecvData->data.bIsAppData;

			sendDataUp();
		}

		return psMessage; //Return the incoming buffer back to the stack.
	}

	//This event is signalled when sending is done.
	event void AMSend.sendDone(message_t* msg, error_t error) {
		bSending = FALSE; //Now we can touch the output buffer again.
		if (error != SUCCESS)
			printf("Error in sendDone! Code: %d\n", error);

		//Send again if there's some data is waiting to be sent.
		if (bSendWaitng) {
			sendDataUp();
		}
	}
	
	//This functions sends the network data in an upwards direction to the 
	//parent of the current node.
	void sendDataUp(void) {
		error_t error;
		
		psM2ONwData->bIsM2OData = TRUE;

		if (!bSending) {
			bSendWaitng = FALSE;
			
			call PacketLink.setRetries(&sDataPacket, NUM_RETRIES);
			error = call AMSend.send(parentId,&sDataPacket, sizeof(M2ONwData));

			if (error == SUCCESS) {
				//Memorize that the radio is now busy serving our request
				//and we have passed the ownership of our output message_t
				//to the stack (until sendDone is signaled).
				bSending = TRUE;
			} else {
				printf("Error in sending! Code: %d\n", error);
			}
		} else {
			bSendWaitng = TRUE;
		}
	}
}//End of implementation