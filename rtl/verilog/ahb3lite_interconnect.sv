/////////////////////////////////////////////////////////////////////
//   ,------.                    ,--.                ,--.          //
//   |  .--. ' ,---.  ,--,--.    |  |    ,---. ,---. `--' ,---.    //
//   |  '--'.'| .-. |' ,-.  |    |  |   | .-. | .-. |,--.| .--'    //
//   |  |\  \ ' '-' '\ '-'  |    |  '--.' '-' ' '-' ||  |\ `--.    //
//   `--' '--' `---'  `--`--'    `-----' `---' `-   /`--' `---'    //
//                                             `---'               //
//    AHB3-Lite Interconnect Switch (Multi-Layer Switch)           //
//    Top Level                                                    //
//                                                                 //
/////////////////////////////////////////////////////////////////////
//                                                                 //
//             Copyright (C) 2016-2018 ROA Logic BV                //
//             www.roalogic.com                                    //
//                                                                 //
//     Unless specifically agreed in writing, this software is     //
//   licensed under the RoaLogic Non-Commercial License            //
//   version-1.0 (the "License"), a copy of which is included      //
//   with this file or may be found on the RoaLogic website        //
//   http://www.roalogic.com. You may not use the file except      //
//   in compliance with the License.                               //
//                                                                 //
//     THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY           //
//   EXPRESS OF IMPLIED WARRANTIES OF ANY KIND.                    //
//   See the License for permissions and limitations under the     //
//   License.                                                      //
//                                                                 //
/////////////////////////////////////////////////////////////////////

// +FHDR -  Semiconductor Reuse Standard File Header Section  -------
// FILE NAME      : ahb3lite_interconnect.sv
// DEPARTMENT     :
// AUTHOR         : rherveille
// AUTHOR'S EMAIL :
// ------------------------------------------------------------------
// RELEASE HISTORY
// VERSION DATE        AUTHOR      DESCRIPTION
// 1.0     2017-03-29  rherveille  initial release
// 1.1     2019-08-15  rherveille  added SLAVE_MASK parameter
// ------------------------------------------------------------------
// KEYWORDS : AMBA AHB AHB3-Lite Interconnect Matrix
// ------------------------------------------------------------------
// PURPOSE  : AHB3Lite Interconnect Matrix
// ------------------------------------------------------------------
// PARAMETERS
//  PARAM NAME        RANGE    DESCRIPTION              DEFAULT UNITS
//  HADDR_SIZE        1+       Address bus size         8       bits
//  HDATA_SIZE        1+       Data bus size            32      bits
//  MASTERS           1+       Number of Master ports   3       ports
//  SLAVES            1+       Number of Slave ports    8       ports
//  SLAVE_MASK                 Per Master Slave mask
//  ERROR_ON_SLAVE_MASK        Per Master error response on masked slave
//  ERROR_ON_NO_SLAVE          Per Master error response on unmapped address
// ------------------------------------------------------------------
// REUSE ISSUES 
//   Reset Strategy      : external asynchronous active low; HRESETn
//   Clock Domains       : HCLK, rising edge
//   Critical Timing     : 
//   Test Features       : na
//   Asynchronous I/F    : no
//   Scan Methodology    : na
//   Instantiations      : ahb3lite_interconnect_master_port
//                         ahb3lite_interconnect_slave_port
//   Synthesizable (y/n) : Yes
//   Other               :                                         
// -FHDR-------------------------------------------------------------

/*
 * Dynamic AHB switch
 * MASTERS:
 *   sets the number of AHB slave-ports on the switch
 *   AHB bus masters connect to these ports. There should only be 1 bus master per slave port
 *
 *   HSEL is used to determine if the port is accessed. This allows a single AHB bus master to be connected to multiple switches. 
 *   It is allowed to drive HSEL with a static/hardwired signal ('1'). This results in a smaller (less logic resources) and faster (larger slack) switch.
 *
 *   'priority' sets the priority of the port. This is used to determine what slave-port (AHB bus master) gets granted access to a master-port when multiple slave-ports want to access the same master-port. The slave-port with the highest priority is granted access.
 *   'priority' may be a static value or it may be a dynamic value where the priority can be set per AHB transfer. In the latter case 'priority' has the same requirements/restrictions as HSIZE/HBURST/HPROT, that is it must remain stable during a burst transfer. Priority has a range of 0..MASTERS-1
 *   Hardwiring 'priority' results in a smaller (less logic resources) and faster (larger slack) switch.
 *
 *
 * SLAVES:
 *   sets the number of AHB master-ports on the switch
 *   AHB slaves connect to these ports. There may be multiple slaves connected to a master port.
 *   Additional address decoding (HSEL generation) is necessary in this case
 *
 *   'haddr_mask' and 'haddr_base' define when a master-port is addressed.
 *   'haddr_mask' determines the relevant bits for the address decoding and 'haddr_base' specifies the base offset.
 *   selected = (HADDR & haddr_mask) == (haddr_base & haddr_mask)
 *   'haddr_mask' and 'haddr_base' should be static signals. Hardwiring these signals results in a smaller (less logic resource) and faster (larger slack) switch.
 *
 *
 * SLAVE_MASK:
 *   Indicates that a master can/will never access a slave
 *   There is a MASK for each master with a bit for each slave. I.e. SLAVE_MASK is an array of MASTERS x SLAVES.
 *   Setting a MASK bit to '0' indicates that master will never access the slave.
 *   Setting a MASK bit to '1' indicates that master will/can access the slave.
 *
 *   example: MASTERS=3, SLAVES=2. 
 *          | 2 1 0
 *          |------
 *         1| 1 1 0    Slave[1] can only be accessed by masters 2 and 1. Master[0] never accesses Slave[1]
 *         0| 0 1 1    Slave[0] can only be accessed by masters 1 and 0. Master[2] never accesses Slave[0]
 *         SLAVE_MASK = '{2'b10, 2'b11, 2'b01}
 *
 *
 * ERROR_ON_SLAVE_MASK:
 *   Indicates that an AHB transaction error response is generated when addressing a masked Slave
 *   When a Master tries to access a Slave that is masked for that Master, the Master Port generates an AHB transaction error response when ERROR_ON_SLAVE_MASK for that Master/Slave combination is set to '1'. If ERROR_ON_SLAVE_MASK is set to '0' (for a Master/Slave combo), the Master Port does not generate an error transaction response.
 *   In either case the Master Port will always transfer the Slave Ports transaction response when addressing a non-masked slave.
 *   ERROR_ON_SLAVE_MASK uses the same array form as SLAVE_MASK.
 *
 *   example; SLAVE_MASK = '{2'b10, 2'b11, 2'b01}, ERROR_ON_SLAVE_MASK = '{2'b11, 2'b11, 2'b00}
 *     When Master[2] accesses Slave[1], the parameter is ignored, because SLAVE_MASK='1' (i.e. not masked)
 *     When Master[2] accesses Slave[0], the Master Port generates a transaction error, because SLAVE_MASK='0' and ERROR_ON_SLAVE_MASK='1'
 *     For Master[1] the Master Port never generates a transaction error, because SLAVE_MASK=2'b11.
 *     When Master[0] accesses Slave[1], the Master Port does not generate a transaction error, because ERROR_ON_SLAVE_MASK='0'
 *     When Master[0] accesses Slave[0], the parameter is ignored, because SLAVE_MASK='1'
 *
 *   WARNING: when SLAVE_MASK='0' and ERROR_ON_SLAVE_MASK='0', the master must ensure not to address the masked slave, because that will cause deadlock on the master AHB bus, where the master waits indefinitely for a response that never comes.
 *
 *
 * ERROR_ON_NO_SLAVE:
 *  Indicates that an AHB transaction error response is generated when no slave port is addressed
 *  When a master tries to access an address that is not mapped to any Slave, the Master Port generates an AHB transaction error response when ERROR_ON_NO_SLAVE for that Master is set to '1'. If ERROR_ON_NO_SLAVE is set to '0', the Master Port does not generate and error transaction response. Note that the bus will hang in that case, because the master waits for a response that never comes.
 *
 */


module ahb3lite_interconnect
import ahb3lite_pkg::*;
#(
  parameter                  HADDR_SIZE                   = 32,
  parameter                  HDATA_SIZE                   = 32,
  parameter                  MASTERS                      = 3, //number of AHB Masters
  parameter                  SLAVES                       = 8, //number of AHB slaves

  parameter bit [SLAVES-1:0] SLAVE_MASK         [MASTERS] = '{MASTERS{ {SLAVES{1'b1}} }},
  parameter bit [SLAVES-1:0] ERROR_ON_SLAVE_MASK[MASTERS] = invert_slave_mask(),
  parameter bit              ERROR_ON_NO_SLAVE  [MASTERS] = '{MASTERS {1'b0 }},

  //actually localparam
  parameter                  MASTER_BITS = MASTERS==1 ? 1 : $clog2(MASTERS)
)
(
  //Common signals
  input                   HRESETn,
                          HCLK,

  //Master Ports; AHB masters connect to these
  // thus these are actually AHB Slave Interfaces
  input  [MASTER_BITS-1:0] mst_priority  [MASTERS],

  input                    mst_HSEL      [MASTERS],
  input  [HADDR_SIZE -1:0] mst_HADDR     [MASTERS],
  input  [HDATA_SIZE -1:0] mst_HWDATA    [MASTERS],
  output [HDATA_SIZE -1:0] mst_HRDATA    [MASTERS],
  input                    mst_HWRITE    [MASTERS],
  input  [            2:0] mst_HSIZE     [MASTERS],
  input  [            2:0] mst_HBURST    [MASTERS],
  input  [            3:0] mst_HPROT     [MASTERS],
  input  [            1:0] mst_HTRANS    [MASTERS],
  input                    mst_HMASTLOCK [MASTERS],
  output                   mst_HREADYOUT [MASTERS],
  input                    mst_HREADY    [MASTERS],
  output                   mst_HRESP     [MASTERS],

  //Slave Ports; AHB Slaves connect to these
  //  thus these are actually AHB Master Interfaces
  input  [HADDR_SIZE -1:0] slv_addr_mask [SLAVES],
  input  [HADDR_SIZE -1:0] slv_addr_base [SLAVES],

  output                   slv_HSEL      [SLAVES],
  output [HADDR_SIZE -1:0] slv_HADDR     [SLAVES],
  output [HDATA_SIZE -1:0] slv_HWDATA    [SLAVES],
  input  [HDATA_SIZE -1:0] slv_HRDATA    [SLAVES],
  output                   slv_HWRITE    [SLAVES],
  output [            2:0] slv_HSIZE     [SLAVES],
  output [            2:0] slv_HBURST    [SLAVES],
  output [            3:0] slv_HPROT     [SLAVES],
  output [            1:0] slv_HTRANS    [SLAVES],
  output                   slv_HMASTLOCK [SLAVES],
  output                   slv_HREADYOUT [SLAVES], //HREADYOUT to slave-decoder; generates HREADY to all connected slaves
  input                    slv_HREADY    [SLAVES], //combinatorial HREADY from all connected slaves
  input                    slv_HRESP     [SLAVES]
);
  //////////////////////////////////////////////////////////////////
  //
  // Constants
  //
  typedef bit [SLAVES-1:0] slave_mask_t [MASTERS];

  //////////////////////////////////////////////////////////////////
  //
  // Functions
  //
  function slave_mask_t invert_slave_mask;
    for (int i=0; i < MASTERS; i++)
      invert_slave_mask[i] = ~SLAVE_MASK[i];
  endfunction : invert_slave_mask


  //////////////////////////////////////////////////////////////////
  //
  // Variables
  //
  logic [MASTERS-1:0]             [MASTER_BITS-1:0] frommstpriority;
  logic [MASTERS-1:0][SLAVES -1:0]                  frommstHSEL;
  logic [MASTERS-1:0]             [HADDR_SIZE -1:0] frommstHADDR;
  logic [MASTERS-1:0]             [HDATA_SIZE -1:0] frommstHWDATA;
  logic [MASTERS-1:0][SLAVES -1:0][HDATA_SIZE -1:0] tomstHRDATA;
  logic [MASTERS-1:0]                               frommstHWRITE;
  logic [MASTERS-1:0]             [            2:0] frommstHSIZE;
  logic [MASTERS-1:0]             [            2:0] frommstHBURST;
  logic [MASTERS-1:0]             [            3:0] frommstHPROT;
  logic [MASTERS-1:0]             [            1:0] frommstHTRANS;
  logic [MASTERS-1:0]                               frommstHMASTLOCK;
  logic [MASTERS-1:0]                               frommstHREADYOUT,
                                                    frommst_canswitch;
  logic [MASTERS-1:0][SLAVES -1:0]                  tomstHREADY;
  logic [MASTERS-1:0][SLAVES -1:0]                  tomstHRESP;
  logic [MASTERS-1:0][SLAVES -1:0]                  tomstgrant;


  logic [SLAVES -1:0][MASTERS-1:0][MASTER_BITS-1:0] toslvpriority;
  logic [SLAVES -1:0][MASTERS-1:0]                  toslvHSEL;
  logic [SLAVES -1:0][MASTERS-1:0][HADDR_SIZE -1:0] toslvHADDR;
  logic [SLAVES -1:0][MASTERS-1:0][HDATA_SIZE -1:0] toslvHWDATA;
  logic [SLAVES -1:0]             [HDATA_SIZE -1:0] fromslvHRDATA;
  logic [SLAVES -1:0][MASTERS-1:0]                  toslvHWRITE;
  logic [SLAVES -1:0][MASTERS-1:0][            2:0] toslvHSIZE;
  logic [SLAVES -1:0][MASTERS-1:0][            2:0] toslvHBURST;
  logic [SLAVES -1:0][MASTERS-1:0][            3:0] toslvHPROT;
  logic [SLAVES -1:0][MASTERS-1:0][            1:0] toslvHTRANS;
  logic [SLAVES -1:0][MASTERS-1:0]                  toslvHMASTLOCK;
  logic [SLAVES -1:0][MASTERS-1:0]                  toslvHREADY,
                                                    toslv_canswitch;
  logic [SLAVES -1:0]                               fromslvHREADYOUT;
  logic [SLAVES -1:0]                               fromslvHRESP;
  logic [SLAVES -1:0][MASTERS-1:0]                  fromslvgrant;


  genvar m,s;


  //////////////////////////////////////////////////////////////////
  //
  // Module Body
  //

//synopsys translate_off
initial
begin
    //wait for potential always_comb signals to settle
    #1;
    $display("\n\n");
    $display ("------------------------------------------------------------");
    $display (" ,------.                    ,--.                ,--.       ");
    $display (" |  .--. ' ,---.  ,--,--.    |  |    ,---. ,---. `--' ,---. ");
    $display (" |  '--'.'| .-. |' ,-.  |    |  |   | .-. | .-. |,--.| .--' ");
    $display (" |  |\\  \\ ' '-' '\\ '-'  |    |  '--.' '-' ' '-' ||  |\\ `--. ");
    $display (" `--' '--' `---'  `--`--'    `-----' `---' `-   /`--' `---' ");
    $display ("- AHB3-Lite Interconnect Configuration---  `---'  ----------");
    $display ("- Module: %m");
    $display ("- Masters: %0d, Slaves: %0d", MASTERS, SLAVES);
    for (int n=0; n < MASTERS; n++)
      $display ("master[%2d] priority=%0d", n, mst_priority[n]);
    for (int n=0; n < SLAVES; n++)
      $display ("slv_addr_base[%3d]=%32b (0x%8h), slv_addr_mask[%3d]=%32b (0x%8h)", n, slv_addr_base[n], slv_addr_base[n], n, slv_addr_mask[n], slv_addr_mask[n]);
end
//synopsys translate_on


  /*
   * Hookup Master Interfaces
   */
generate
  for (m=0;m < MASTERS; m++)
  begin: gen_master_ports
  ahb3lite_interconnect_master_port #(
    .HADDR_SIZE          ( HADDR_SIZE             ),
    .HDATA_SIZE          ( HDATA_SIZE             ),
    .MASTERS             ( MASTERS                ),
    .SLAVES              ( SLAVES                 ),
    .SLAVE_MASK          ( SLAVE_MASK         [m] ),
    .ERROR_ON_SLAVE_MASK ( ERROR_ON_SLAVE_MASK[m] ),
    .ERROR_ON_NO_SLAVE   ( ERROR_ON_NO_SLAVE  [m] ) )
  master_port (
    .HRESETn             ( HRESETn                ),
    .HCLK                ( HCLK                   ),
	 
    //AHB Slave Interfaces (receive data from AHB Masters)
    //AHB Masters conect to these ports
    .mst_priority        ( mst_priority       [m] ),
    .mst_HSEL            ( mst_HSEL           [m] ),
    .mst_HADDR           ( mst_HADDR          [m] ),
    .mst_HWDATA          ( mst_HWDATA         [m] ),
    .mst_HRDATA          ( mst_HRDATA         [m] ),
    .mst_HWRITE          ( mst_HWRITE         [m] ),
    .mst_HSIZE           ( mst_HSIZE          [m] ),
    .mst_HBURST          ( mst_HBURST         [m] ),
    .mst_HPROT           ( mst_HPROT          [m] ),
    .mst_HTRANS          ( mst_HTRANS         [m] ),
    .mst_HMASTLOCK       ( mst_HMASTLOCK      [m] ),
    .mst_HREADYOUT       ( mst_HREADYOUT      [m] ),
    .mst_HREADY          ( mst_HREADY         [m] ),
    .mst_HRESP           ( mst_HRESP          [m] ),
    
    //AHB Master Interfaces (send data to AHB slaves)
    //AHB Slaves connect to these ports
    .slvHADDRmask        ( slv_addr_mask          ),
    .slvHADDRbase        ( slv_addr_base          ),
    .slvpriority         ( frommstpriority    [m] ),
    .slvHSEL             ( frommstHSEL        [m] ),
    .slvHADDR            ( frommstHADDR       [m] ),
    .slvHWDATA           ( frommstHWDATA      [m] ),
    .slvHRDATA           ( tomstHRDATA        [m] ),
    .slvHWRITE           ( frommstHWRITE      [m] ),
    .slvHSIZE            ( frommstHSIZE       [m] ),
    .slvHBURST           ( frommstHBURST      [m] ),
    .slvHPROT            ( frommstHPROT       [m] ),
    .slvHTRANS           ( frommstHTRANS      [m] ),
    .slvHMASTLOCK        ( frommstHMASTLOCK   [m] ),
    .slvHREADY           ( tomstHREADY        [m] ),
    .slvHREADYOUT        ( frommstHREADYOUT   [m] ),
    .slvHRESP            ( tomstHRESP         [m] ),

    .can_switch          ( frommst_canswitch  [m] ),
    .master_granted      ( tomstgrant         [m] ) );
    end
endgenerate


  /*
   * wire mangling
   */
  //Master-->Slave
  generate
    for (s=0; s<SLAVES; s++)
    begin: slave
      for (m=0; m<MASTERS; m++)
      begin: master
          assign toslvpriority    [s][m] = frommstpriority    [m];
          assign toslvHSEL        [s][m] = frommstHSEL        [m][s];
          assign toslvHADDR       [s][m] = frommstHADDR       [m];
          assign toslvHWDATA      [s][m] = frommstHWDATA      [m];
          assign toslvHWRITE      [s][m] = frommstHWRITE      [m];
          assign toslvHSIZE       [s][m] = frommstHSIZE       [m];
          assign toslvHBURST      [s][m] = frommstHBURST      [m];
          assign toslvHPROT       [s][m] = frommstHPROT       [m];
          assign toslvHTRANS      [s][m] = frommstHTRANS      [m];
          assign toslvHMASTLOCK   [s][m] = frommstHMASTLOCK   [m];
          assign toslvHREADY      [s][m] = frommstHREADYOUT   [m]; //feed Masters's HREADY signal to slave port
          assign toslv_canswitch  [s][m] = frommst_canswitch  [m];
      end //next m
    end //next s
  endgenerate


  /*
   * wire mangling
   */
  //Slave-->Master
  generate
    for (m=0; m<MASTERS; m++)
    begin: master
      for (s=0; s<SLAVES; s++)
      begin: slave
          assign tomstgrant [m][s] = fromslvgrant    [s][m];   
          assign tomstHRDATA[m][s] = fromslvHRDATA   [s];
          assign tomstHREADY[m][s] = fromslvHREADYOUT[s];
          assign tomstHRESP [m][s] = fromslvHRESP    [s];
      end //next s
    end //next m
  endgenerate


  /*
   * Hookup Slave Interfaces
   */
generate
  for (s=0;s < SLAVES; s++)
  begin: gen_slave_ports
  ahb3lite_interconnect_slave_port #(
    .HADDR_SIZE      ( HADDR_SIZE           ),
    .HDATA_SIZE      ( HDATA_SIZE           ),
    .MASTERS         ( MASTERS              ) )
  slave_port (
    .HRESETn         ( HRESETn              ),
    .HCLK            ( HCLK                 ),
	 
    //AHB Slave Interfaces (receive data from AHB Masters)
    //AHB Masters connect to these ports
    .mstpriority     ( toslvpriority    [s] ),
    .mstHSEL         ( toslvHSEL        [s] ),
    .mstHADDR        ( toslvHADDR       [s] ),
    .mstHWDATA       ( toslvHWDATA      [s] ),
    .mstHRDATA       ( fromslvHRDATA    [s] ),
    .mstHWRITE       ( toslvHWRITE      [s] ),
    .mstHSIZE        ( toslvHSIZE       [s] ),
    .mstHBURST       ( toslvHBURST      [s] ),
    .mstHPROT        ( toslvHPROT       [s] ),
    .mstHTRANS       ( toslvHTRANS      [s] ),
    .mstHMASTLOCK    ( toslvHMASTLOCK   [s] ),
    .mstHREADY       ( toslvHREADY      [s] ),
    .mstHREADYOUT    ( fromslvHREADYOUT [s] ),
    .mstHRESP        ( fromslvHRESP     [s] ),


    //AHB Master Interfaces (send data to AHB slaves)
    //AHB Slaves connect to these ports
    .slv_HSEL        ( slv_HSEL        [s] ),
    .slv_HADDR       ( slv_HADDR       [s] ),
    .slv_HWDATA      ( slv_HWDATA      [s] ),
    .slv_HRDATA      ( slv_HRDATA      [s] ),
    .slv_HWRITE      ( slv_HWRITE      [s] ),
    .slv_HSIZE       ( slv_HSIZE       [s] ),
    .slv_HBURST      ( slv_HBURST      [s] ),
    .slv_HPROT       ( slv_HPROT       [s] ),
    .slv_HTRANS      ( slv_HTRANS      [s] ),
    .slv_HMASTLOCK   ( slv_HMASTLOCK   [s] ),
    .slv_HREADYOUT   ( slv_HREADYOUT   [s] ),
    .slv_HREADY      ( slv_HREADY      [s] ),
    .slv_HRESP       ( slv_HRESP       [s] ),

    //Internal signals
    .can_switch      ( toslv_canswitch [s] ),
    .granted_master  ( fromslvgrant    [s] ) );
  end
endgenerate


endmodule


