//This is the configuration file for the spanning tree module.

//Declare the interfaces MyTreeC provides.
configuration MyTreeC {
	provides interface MyTree;
}//End of declaration

//Implementation of MyTreeC module
implementation {
	//Declaration of the components in MyTreeC module
	components MyTreeP;
	components MyMany2OneC;
	components ActiveMessageC;
	components new AMSenderC(AM_BEACON) as AMSendC;
	components new AMReceiverC(AM_BEACON) as AMReceiveC;
	components CC2420PacketC;
	components RandomC;
	components new TimerMilliC() as JitterTimerC;

	//Wire all the components in MyTreeC.
	MyTree = MyTreeP.MyTree;
	MyTreeP.MyMany2One -> MyMany2OneC.MyMany2One;
	MyTreeP.SplitControl -> ActiveMessageC.SplitControl;
	MyTreeP.AMPacket -> ActiveMessageC.AMPacket;
	MyTreeP.AMSend -> AMSendC.AMSend;
	MyTreeP.Receive -> AMReceiveC.Receive;
	MyTreeP.CC2420Packet -> CC2420PacketC;
	MyTreeP.JitterTimer -> JitterTimerC;
	MyTreeP.Random -> RandomC.Random;
	MyTreeP.LowPowerListening -> ActiveMessageC.LowPowerListening;
}//End of implementation