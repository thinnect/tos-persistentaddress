/**
 * Stores the address assigned with the initial installation in InternalFlash
 * and restores it on subsequent boots. Uses a storage key and does a seek
 * so the actual location of the address can be changed with new software.
 *
 * @author Raido Pahtma
 * @license MIT
*/
#include "InternalFlash.h"
module PersistentAddressP {
	provides {
		interface Boot;
	}
	uses {
		interface InternalFlash;
		interface Crc;
		interface ActiveMessageAddress;
		interface Boot as SysBoot;
	}
}
implementation {

	#define __MODUUL__ "addrstrg"
	#define __LOG_LEVEL__ ( LOG_LEVEL_PersistentAddressP & BASE_LOG_LEVEL )
	#include "log.h"

	#define ADDRSTRG_KEY 0xEB959DB20ED1F // == "ADDRSTRG"

	#ifndef ADDRSTRG_ADDR
	#warning "Using default ADDRSTRG_ADDR 512!"
	#define ADDRSTRG_ADDR (void*)(512) // I would like to use some kind of a volume system for the InternalFlash.
	#endif // ADDRSTRG_ADDR

	typedef nx_struct address_storage_t {
		nx_uint64_t key;
		nx_am_addr_t addr;
		nx_uint16_t crc;
	} address_storage_t;

	am_addr_t loadAddr(void* addr) {
		address_storage_t st;
		error_t err = call InternalFlash.read(addr, &st, sizeof(st));
		if(err == SUCCESS) {
			if(st.key == ADDRSTRG_KEY) {
				uint16_t crc = call Crc.crc16(&st, sizeof(st)-sizeof(st.crc));
				if(crc == st.crc) {
					return st.addr;
				}
				else warn1("crc %u %04X != %04X", addr, crc, (uint16_t)st.crc);
			}
		}
		return 0;
	}

	error_t storeAddr(void* addr, am_addr_t address) {
		error_t err;
		address_storage_t st;
		st.key = ADDRSTRG_KEY;
		st.addr = address;
		st.crc = call Crc.crc16(&st, sizeof(st)-sizeof(st.crc));
		err = call InternalFlash.write(addr, &st, sizeof(st));
		logger(err == SUCCESS ? LOG_DEBUG1: LOG_ERR1, "wr %u", err);
		return err;
	}

	void eraseAddr(void* addr) {
		uint8_t f[sizeof(address_storage_t)];
		memset(f, 0xFF, sizeof(address_storage_t));
		call InternalFlash.write(addr, f, sizeof(address_storage_t));
	}

	event void SysBoot.booted() {
		am_addr_t address;
		void* a;
		debug1("ld");
		for(a=0;a<(void*)(EEPROM_SIZE-sizeof(address_storage_t));a++) {
			address = loadAddr(a);
			if(address != 0) {
				debug1("ldd %p %04X", a, address);
				TOS_NODE_ID = address;
				call ActiveMessageAddress.setAddress(call ActiveMessageAddress.amGroup(), TOS_NODE_ID);
				if(a != ADDRSTRG_ADDR)
				{
					debug1("chng %p->%p", a, ADDRSTRG_ADDR);
					eraseAddr(a);
					storeAddr(ADDRSTRG_ADDR, TOS_NODE_ID);
				}
				break;
			}
		}

		if(address == 0) {
			warn1("ldd %u", a);
			storeAddr(ADDRSTRG_ADDR, TOS_NODE_ID);
		}

		signal Boot.booted();
	}

	async event void ActiveMessageAddress.changed() { }

}