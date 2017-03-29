/////////////////////////////////////////////////////////////////
//                                                             //
//    ██████╗  ██████╗  █████╗                                 //
//    ██╔══██╗██╔═══██╗██╔══██╗                                //
//    ██████╔╝██║   ██║███████║                                //
//    ██╔══██╗██║   ██║██╔══██║                                //
//    ██║  ██║╚██████╔╝██║  ██║                                //
//    ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝                                //
//          ██╗      ██████╗  ██████╗ ██╗ ██████╗              //
//          ██║     ██╔═══██╗██╔════╝ ██║██╔════╝              //
//          ██║     ██║   ██║██║  ███╗██║██║                   //
//          ██║     ██║   ██║██║   ██║██║██║                   //
//          ███████╗╚██████╔╝╚██████╔╝██║╚██████╗              //
//          ╚══════╝ ╚═════╝  ╚═════╝ ╚═╝ ╚═════╝              //
//                                                             //
//    AHB3-Lite Switch (Multi-Layer Switch)                    //
//    Top Level                                                //
//                                                             //
/////////////////////////////////////////////////////////////////
//                                                             //
//             Copyright (C) 2016 ROA Logic BV                 //
//             www.roalogic.com                                //
//                                                             //
//    Unless specifically agreed in writing, this software is  //
//  licensed under the RoaLogic Non-Commercial License         //
//  version-1.0 (the "License"), a copy of which is included   //
//  with this file or may be found on the RoaLogic website     //
//  http://www.roalogic.com. You may not use the file except   //
//  in compliance with the License.                            //
//                                                             //
//    THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY        //
//  EXPRESS OF IMPLIED WARRANTIES OF ANY KIND.                 //
//  See the License for permissions and limitations under the  //
//  License.                                                   //
//                                                             //
/////////////////////////////////////////////////////////////////
 

/*
 * Dynamic AHB switch
 * MASTERS: sets the number of AHB slave-ports on the switch
 *          AHB bus masters connect to these ports. There should only be 1 bus master per slave port
 *
 *          HSEL is used to determine if the port is accessed. This allows a single AHB bus master to be connected to multiple switches. It is allowed to drive HSEL with a static/hardwired signal ('1').
 *
 *          'priority' sets the priority of the port. This is used to determine what slave-port (AHB bus master) gets granted access to a master-port when multiple slave-ports want to access the same master-port. The slave-port with the highest priority is granted access.
 *          'priority' may be a static value or it may be a dynamic value where the priority can be set per AHB transfer. In the latter case 'priority' has the same requirements/restrictions as HSIZE/HBURST/HPROT, that is it must remain stable during a burst transfer.
 *          Hardwiring 'priority' results in a smaller (less logic resources) switch.
 *
 *
 * SLAVES : sets the number of AHB master-ports on the switch
 *          AHB slaves connect to these ports. There may be multiple slaves connected to a master port.
 *          Additional address decoding (HSEL generation) is necessary in this case
 *
 *          'haddr_mask' and 'haddr_base' define when a master-port is addressed.
 *          'haddr_mask' determines the relevant bits for the address decoding and 'haddr_base' specifies the base offset.
 *          selected = (HADDR & haddr_mask) == (haddr_base & haddr_mask)
 *          'haddr_mask' and 'haddr_base' should be static signals. Hardwiring these signals results in a smaller (less logic resource) switch.
 */
module ahb3lite_interconnect #(
  parameter HADDR_SIZE  = 32,
  parameter HDATA_SIZE  = 32,
  parameter MASTERS     = 3, //number of AHB Masters
  parameter SLAVES      = 8  //number of AHB slaves
)
(
  //Common signals
  input                   HRESETn,
                          HCLK,

  //Master Ports; AHB masters connect to these
  // thus these are actually AHB Slave Interfaces
  input  [           2:0] mst_priority  [MASTERS],

  input                   mst_HSEL      [MASTERS],
  input  [HADDR_SIZE-1:0] mst_HADDR     [MASTERS],
  input  [HDATA_SIZE-1:0] mst_HWDATA    [MASTERS],
  output [HDATA_SIZE-1:0] mst_HRDATA    [MASTERS],
  input                   mst_HWRITE    [MASTERS],
  input  [           2:0] mst_HSIZE     [MASTERS],
  input  [           2:0] mst_HBURST    [MASTERS],
  input  [           3:0] mst_HPROT     [MASTERS],
  input  [           1:0] mst_HTRANS    [MASTERS],
  input                   mst_HMASTLOCK [MASTERS],
  output                  mst_HREADYOUT [MASTERS],
  input                   mst_HREADY    [MASTERS],
  output                  mst_HRESP     [MASTERS],

  //Slave Ports; AHB Slaves connect to these
  //  thus these are actually AHB Master Interfaces
  input  [HADDR_SIZE-1:0] slv_addr_mask [SLAVES],
  input  [HADDR_SIZE-1:0] slv_addr_base [SLAVES],

  output                  slv_HSEL      [SLAVES],
  output [HADDR_SIZE-1:0] slv_HADDR     [SLAVES],
  output [HDATA_SIZE-1:0] slv_HWDATA    [SLAVES],
  input  [HDATA_SIZE-1:0] slv_HRDATA    [SLAVES],
  output                  slv_HWRITE    [SLAVES],
  output [           2:0] slv_HSIZE     [SLAVES],
  output [           2:0] slv_HBURST    [SLAVES],
  output [           3:0] slv_HPROT     [SLAVES],
  output [           1:0] slv_HTRANS    [SLAVES],
  output                  slv_HMASTLOCK [SLAVES],
  output                  slv_HREADYOUT [SLAVES], //HREADYOUT to slave-decoder; generates HREADY to all connected slaves
  input                   slv_HREADY    [SLAVES], //combinatorial HREADY from all connected slaves
  input                   slv_HRESP     [SLAVES]
);
  //////////////////////////////////////////////////////////////////
  //
  // Constants
  //
  import ahb3lite_pkg::*;


  //////////////////////////////////////////////////////////////////
  //
  // Variables
  //
  logic [MASTERS-1:0]             [           2:0] frommstpriority;
  logic [MASTERS-1:0][SLAVES -1:0]                 frommstHSEL;
  logic [MASTERS-1:0]             [HADDR_SIZE-1:0] frommstHADDR;
  logic [MASTERS-1:0]             [HDATA_SIZE-1:0] frommstHWDATA;
  logic [MASTERS-1:0][SLAVES -1:0][HDATA_SIZE-1:0] tomstHRDATA;
  logic [MASTERS-1:0]                              frommstHWRITE;
  logic [MASTERS-1:0]             [           2:0] frommstHSIZE;
  logic [MASTERS-1:0]             [           2:0] frommstHBURST;
  logic [MASTERS-1:0]             [           3:0] frommstHPROT;
  logic [MASTERS-1:0]             [           1:0] frommstHTRANS;
  logic [MASTERS-1:0]                              frommstHMASTLOCK;
  logic [MASTERS-1:0]                              frommstHREADYOUT,
                                                   frommst_canswitch;
  logic [MASTERS-1:0][SLAVES -1:0]                 tomstHREADY;
  logic [MASTERS-1:0][SLAVES -1:0]                 tomstHRESP;
  logic [MASTERS-1:0][SLAVES -1:0]                 tomstgrant;


  logic [SLAVES -1:0][MASTERS-1:0][           2:0] toslvpriority;
  logic [SLAVES -1:0][MASTERS-1:0]                 toslvHSEL;
  logic [SLAVES -1:0][MASTERS-1:0][HADDR_SIZE-1:0] toslvHADDR;
  logic [SLAVES -1:0][MASTERS-1:0][HDATA_SIZE-1:0] toslvHWDATA;
  logic [SLAVES -1:0]             [HDATA_SIZE-1:0] fromslvHRDATA;
  logic [SLAVES -1:0][MASTERS-1:0]                 toslvHWRITE;
  logic [SLAVES -1:0][MASTERS-1:0][           2:0] toslvHSIZE;
  logic [SLAVES -1:0][MASTERS-1:0][           2:0] toslvHBURST;
  logic [SLAVES -1:0][MASTERS-1:0][           3:0] toslvHPROT;
  logic [SLAVES -1:0][MASTERS-1:0][           1:0] toslvHTRANS;
  logic [SLAVES -1:0][MASTERS-1:0]                 toslvHMASTLOCK;
  logic [SLAVES -1:0][MASTERS-1:0]                 toslvHREADY,
                                                   toslv_canswitch;
  logic [SLAVES -1:0]                              fromslvHREADYOUT;
  logic [SLAVES -1:0]                              fromslvHRESP;
  logic [SLAVES -1:0][MASTERS-1:0]                 fromslvgrant;


  genvar m,s;


  //////////////////////////////////////////////////////////////////
  //
  // Module Body
  //
  
  /*
   * Hookup Master Interfaces
   */
generate
  for (m=0;m < MASTERS; m++)
  begin: gen_master_ports
  ahb3lite_interconnect_master_port #(
    .HADDR_SIZE     ( HADDR_SIZE             ),
    .HDATA_SIZE     ( HDATA_SIZE             ),
    .MASTERS        ( MASTERS                ),
    .SLAVES         ( SLAVES                 ) )
  master_port (
    .HRESETn        ( HRESETn                ),
    .HCLK           ( HCLK                   ),
	 
    //AHB Slave Interfaces (receive data from AHB Masters)
    //AHB Masters conect to these ports
    .mst_priority   ( mst_priority       [m] ),
    .mst_HSEL       ( mst_HSEL           [m] ),
    .mst_HADDR      ( mst_HADDR          [m] ),
    .mst_HWDATA     ( mst_HWDATA         [m] ),
    .mst_HRDATA     ( mst_HRDATA         [m] ),
    .mst_HWRITE     ( mst_HWRITE         [m] ),
    .mst_HSIZE      ( mst_HSIZE          [m] ),
    .mst_HBURST     ( mst_HBURST         [m] ),
    .mst_HPROT      ( mst_HPROT          [m] ),
    .mst_HTRANS     ( mst_HTRANS         [m] ),
    .mst_HMASTLOCK  ( mst_HMASTLOCK      [m] ),
    .mst_HREADYOUT  ( mst_HREADYOUT      [m] ),
    .mst_HREADY     ( mst_HREADY         [m] ),
    .mst_HRESP      ( mst_HRESP          [m] ),
    
    //AHB Master Interfaces (send data to AHB slaves)
    //AHB Slaves connect to these ports
    .slvHADDRmask   ( slv_addr_mask          ),
    .slvHADDRbase   ( slv_addr_base          ),
    .slvpriority    ( frommstpriority    [m] ),
    .slvHSEL        ( frommstHSEL        [m] ),
    .slvHADDR       ( frommstHADDR       [m] ),
    .slvHWDATA      ( frommstHWDATA      [m] ),
    .slvHRDATA      ( tomstHRDATA        [m] ),
    .slvHWRITE      ( frommstHWRITE      [m] ),
    .slvHSIZE       ( frommstHSIZE       [m] ),
    .slvHBURST      ( frommstHBURST      [m] ),
    .slvHPROT       ( frommstHPROT       [m] ),
    .slvHTRANS      ( frommstHTRANS      [m] ),
    .slvHMASTLOCK   ( frommstHMASTLOCK   [m] ),
    .slvHREADY      ( tomstHREADY        [m] ),
    .slvHREADYOUT   ( frommstHREADYOUT   [m] ),
    .slvHRESP       ( tomstHRESP         [m] ),

    .can_switch     ( frommst_canswitch  [m] ),
    .master_granted ( tomstgrant         [m] ) );
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
    .MASTERS         ( MASTERS              ),
    .SLAVES          ( SLAVES               ) )
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


