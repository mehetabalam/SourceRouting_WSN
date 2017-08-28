//This file contains all the macros and data structures for the program.

#ifndef COMMON_H
#define COMMON_H

#include <Timer.h>
#include <AM.h>
#include <printf.h>

#define M2O_DATA_PERIOD     (60*1024L)
#define O2M_DATA_PERIOD     (2*1024L)
#define O2M_START_TIME	    (60*1024L)
#define M2O_APP_JITTER      (55*1024L)
#define ROOT_UPTIME         (2*1024L)
#define NODE_UPTIME         (1*1024L)
#define REBUILD_PERIOD      (120*1024L)
#define NUM_RETRIES         6
#define TREE_JITTER         (10*1024L)
#define MAX_PATH_LENGTH     5
#define MAX_NODES           15

am_addr_t parentId = 0, prev_parentId = 0;
am_addr_t aPid[MAX_NODES] = {0};

enum {
	AM_BEACON = 0x77,
	AM_M2ODATA = 0x88,
	AM_O2MDATA = 0x99,
};

//Beacon packet (Length = 4 bytes)
typedef nx_struct {	
	nx_uint8_t nxu8SeqNum;
	nx_uint16_t nxu16Metric;
	nx_bool	bIsBeaconData;
} BeaconPacket;

//Many2One data packet (Length = 3 bytes)
typedef nx_struct {
	nx_uint16_t nxu16data;
	nx_bool bIsAppData;
} M2OAppData;

//Network-level data packet for many-to-one routing (Length = 8 bytes)
typedef nx_struct {
	nx_uint16_t from;
	nx_uint16_t hops;
	M2OAppData data;
	nx_bool	bIsM2OData;
} M2ONwData;

//One2Many data packet (Length = 2 bytes)
typedef nx_struct {
	nx_uint16_t nxu16data;
} O2MAppData;

//Network-level data packet for one-to-many routing (Length = 
//MAX_PATH_LENGTH+3 bytes)
typedef nx_struct {
	nx_uint8_t anxu8Route[MAX_PATH_LENGTH];
	O2MAppData data;
	nx_bool	bIsO2MData;
} O2MNwData;

#endif
