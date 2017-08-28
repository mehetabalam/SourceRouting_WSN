//This file declares the interfaces provided by MyMany2One component.

//Declare the interface MyMany2One
interface MyMany2One {
	command void send(M2OAppData* psData);
	event void receive(am_addr_t from, M2OAppData* psData);
}