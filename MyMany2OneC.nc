//This is the configuration file for many-to-one data forwarding.

//Declare the interfaces MyMany2OneC provides.
configuration MyMany2OneC {
	provides interface MyMany2One;
}//End of declaration

//Implementation of MyMany2OneC module
implementation {
	//Declaration of the components in MyMany2OneC module
	components MyMany2OneP;
	components new AMSenderC(AM_M2ODATA) as AMSendC;
	components new AMReceiverC(AM_M2ODATA) as AMReceiveC;
	components PacketLinkC;
	
	//Wire all the components in MyMany2OneC.
	MyMany2One = MyMany2OneP.MyMany2One;
	MyMany2OneP.AMSend -> AMSendC;
	MyMany2OneP.Receive -> AMReceiveC;
	MyMany2OneP.PacketLink -> PacketLinkC;
}//End of implementation