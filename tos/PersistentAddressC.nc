/**
 * Stores the address assigned with the initial installation in InternalFlash
 * and restores it on subsequent boots.
 *
 * @author Raido Pahtma
 * @license MIT
*/
configuration PersistentAddressC {
	provides interface Boot;
	uses interface Boot as SysBoot;
}
implementation {

	components PersistentAddressP;
	PersistentAddressP.SysBoot = SysBoot;
	Boot = PersistentAddressP.Boot;

	components InternalFlashC;
	PersistentAddressP.InternalFlash -> InternalFlashC;

	components CrcC;
	PersistentAddressP.Crc -> CrcC;

	components ActiveMessageAddressC;
	PersistentAddressP.ActiveMessageAddress -> ActiveMessageAddressC;

}