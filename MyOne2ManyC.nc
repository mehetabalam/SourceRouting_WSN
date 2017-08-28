//This is the configuration file for one-to-many data forwarding.

//Declare the interfaces MyOne2ManyC provides.
configuration MyOne2ManyC {
	provides interface MyOne2Many;
}//End of declaration

//Implementation of MyOne2ManyC module
implementation {
	//Declaration of the components in MyOne2ManyC module
	components MyOne2ManyP;
	components new AMSenderC(AM_O2MDATA) as AMSendC;
	components new AMReceiverC(AM_O2MDATA) as AMReceiveC;
	components PacketLinkC;

	//Wire all the components in MyOne2ManyC.
	MyOne2Many = MyOne2ManyP.MyOne2Many;
	MyOne2ManyP.AMSend -> AMSendC;
	MyOne2ManyP.Receive -> AMReceiveC;
	MyOne2ManyP.PacketLink -> PacketLinkC;
}//End of implementation