//This is the configuration file for application module.

//Declare the interfaces AppC provides.
configuration AppC {
	//Do nothing. AppC provides no interfaces.
}//End of declaration

//Implementation of AppC module
implementation {
	//Declaration of the components in AppC module.
	components AppP;
	components MyTreeC;
	components MyMany2OneC;
	components MyOne2ManyC;
	components SerialPrintfC, SerialStartC;
	components new TimerMilliC() as StartTimerC,
			   new TimerMilliC() as M2OPeriodicTimerC,
			   new TimerMilliC() as O2MPeriodicTimerC,
			   new TimerMilliC() as O2MStartTimerC,
			   new TimerMilliC() as M2OJitterTimerC;
	components MainC;
	components RandomC;

	//Wire all the components in AppC.
	AppP.Boot -> MainC.Boot;
	AppP.MyTree -> MyTreeC.MyTree;
	AppP.MyMany2One -> MyMany2OneC.MyMany2One;
	AppP.MyOne2Many -> MyOne2ManyC.MyOne2Many;
	AppP.Random -> RandomC.Random;
	AppP.StartTimer -> StartTimerC;
	AppP.M2OPeriodicTimer -> M2OPeriodicTimerC;
	AppP.O2MPeriodicTimer -> O2MPeriodicTimerC;
	AppP.O2MStartTimer -> O2MStartTimerC;
	AppP.M2OJitterTimer -> M2OJitterTimerC;
}//End of implementation
