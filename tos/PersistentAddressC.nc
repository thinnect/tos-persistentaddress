/**
 * Stores the address assigned with the initial installation in InternalFlash
 * and restores it on subsequent boots.
 *
 * @author Raido Pahtma
 * @license MIT
*/
#include "AM.h"
configuration PersistentAddressC {
	provides {
		interface Boot;
		interface Get<am_addr_t>;
		interface Set<am_addr_t>;
	}
	uses interface Boot as SysBoot;
}
implementation {

	components PersistentAddressP;
	PersistentAddressP.SysBoot = SysBoot;
	Boot = PersistentAddressP.Boot;
	Get = PersistentAddressP;
	Set = PersistentAddressP;

	components InternalFlashC;
	PersistentAddressP.InternalFlash -> InternalFlashC;

	components CrcC;
	PersistentAddressP.Crc -> CrcC;

	components ActiveMessageAddressC;
	PersistentAddressP.ActiveMessageAddress -> ActiveMessageAddressC;

}
