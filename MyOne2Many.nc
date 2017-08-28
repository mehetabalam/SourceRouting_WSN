//This file declares the interfaces provided by MyOne2Many component.

//Declare the interface MyOne2Many
interface MyOne2Many {
	command void send(uint8_t u8DestId, O2MAppData* psO2MData);
	event void receive(am_addr_t to, O2MAppData* psData);
}