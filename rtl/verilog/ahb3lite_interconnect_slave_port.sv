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
//    AHB3-Lite Interconnect Switch (Multi-Layer Switch)       //
//    Slave Port (AHB Master)                                  //
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
 

module ahb3lite_interconnect_slave_port #(
  parameter HADDR_SIZE  = 32,
  parameter HDATA_SIZE  = 32,
  parameter MASTERS     = 3,  //number of slave-ports
  parameter SLAVES      = 8   //number of master-ports
)
(
  input                               HRESETn,
                                      HCLK,

  //AHB Slave Interfaces (receive data from AHB Masters)
  //AHB Masters conect to these ports
  input      [MASTERS-1:0][            2:0] mstpriority,
  input      [MASTERS-1:0]                  mstHSEL,
  input      [MASTERS-1:0][HADDR_SIZE -1:0] mstHADDR,
  input      [MASTERS-1:0][HDATA_SIZE -1:0] mstHWDATA,
  output                  [HDATA_SIZE -1:0] mstHRDATA,
  input      [MASTERS-1:0]                  mstHWRITE,
  input      [MASTERS-1:0][            2:0] mstHSIZE,
  input      [MASTERS-1:0][            2:0] mstHBURST,
  input      [MASTERS-1:0][            3:0] mstHPROT,
  input      [MASTERS-1:0][            1:0] mstHTRANS,
  input      [MASTERS-1:0]                  mstHMASTLOCK,
  input      [MASTERS-1:0]                  mstHREADY,         //HREADY input from master-bus
  output                                    mstHREADYOUT,      //HREADYOUT output to master-bus
  output                                    mstHRESP,

  //AHB Master Interfaces (send data to AHB slaves)
  //AHB Slaves connect to these ports
  output                                    slv_HSEL,
  output     [HADDR_SIZE-1:0]               slv_HADDR,
  output     [HDATA_SIZE-1:0]               slv_HWDATA,
  input      [HDATA_SIZE-1:0]               slv_HRDATA,
  output                                    slv_HWRITE,
  output     [           2:0]               slv_HSIZE,
  output     [           2:0]               slv_HBURST,
  output     [           3:0]               slv_HPROT,
  output     [           1:0]               slv_HTRANS,
  output                                    slv_HMASTLOCK,
  output                                    slv_HREADYOUT,
  input                                     slv_HREADY,
  input                                     slv_HRESP,

  input      [MASTERS   -1:0]               can_switch,
  output reg [MASTERS   -1:0]               granted_master
);
  //////////////////////////////////////////////////////////////////
  //
  // Constants
  //
  import ahb3lite_pkg::*;

  localparam MASTER_BITS = $clog2(MASTERS);


  //////////////////////////////////////////////////////////////////
  //
  // Variables
  //
  logic [            2:0]              requested_priority_lvl;  //requested priority level
  logic [MASTERS    -1:0]              priority_masters;        //all masters at this priority level

  logic [MASTERS    -1:0]              pending_master,          //next master waiting to be served
                                       last_granted_master;     //for requested priority level
  logic [            2:0][MASTERS-1:0] last_granted_masters;    //per priority level, for round-robin

  
  logic [MASTER_BITS-1:0]              granted_master_idx,      //granted master as index
                                       granted_master_idx_dly;  //deleayed granted master index (for HWDATA)
  
  logic                                can_switch_master;       //Slave may switch to a new master

  
  genvar m;
  

  //////////////////////////////////////////////////////////////////
  //
  // Tasks
  //


  //////////////////////////////////////////////////////////////////
  //
  // Functions
  //
  function integer onehot2int;
    input [SLAVES-1:0] onehot;

    for (onehot2int = -1; |onehot; onehot2int++) onehot = onehot >>1;
  endfunction //onehot2int


  function [2:0] highest_requested_priority (
    input [MASTERS-1:0]      hsel,
    input [MASTERS-1:0][2:0] priorities
  );

    highest_requested_priority = 0;
    for (int n=0; n<MASTERS; n++)
      if (hsel[n] && priorities[n] > highest_requested_priority) highest_requested_priority = priorities[n];
  endfunction //highest_requested_priority


  function [MASTERS-1:0] requesters;
    input [MASTERS-1:0]      hsel;
    input [MASTERS-1:0][2:0] priorities;
    input              [2:0] priority_select;

    for (int n=0; n<MASTERS; n++)
      requesters[n] = (priorities[n] == priority_select) & hsel[n];
  endfunction //requesters


  function [MASTERS-1:0] nxt_master;
    input [MASTERS-1:0] pending_masters;  //pending masters for the requesed priority level
    input [MASTERS-1:0] last_master;      //last granted master for the priority level
    input [MASTERS-1:0] current_master;   //current granted master (indpendent of priority level)

    integer offset;
    logic [MASTERS*2-1:0] sr;


    //default value, don't switch if not needed
    nxt_master = current_master;
	 
    //implement round-robin
    offset = onehot2int(last_master) +1;

    sr = {pending_masters,pending_masters};
    for (int n = 0; n < MASTERS; n++)
      if ( sr[n + offset] ) return (1 << ( (n+offset) % MASTERS));
  endfunction



  //////////////////////////////////////////////////////////////////
  //
  // Module Body
  //

  /*
   * Select which master to service
   * 1. Priority
   * 2. Round-Robin
   */

  //get highest priority from selected masters
  assign requested_priority_lvl = highest_requested_priority(mstHSEL,mstpriority);

  //get pending masters for the highest priority requested
  assign priority_masters = requesters(mstHSEL, mstpriority,requested_priority_lvl);

  //get last granted master for the priority requested
  assign last_granted_master = last_granted_masters[requested_priority_lvl];

  //get next master to serve
  assign pending_master = nxt_master(priority_masters,last_granted_master, granted_master);

  //Master port signals when it can be switched
  assign can_switch_master = can_switch [granted_master_idx];

  //select new master
  always @(posedge HCLK, negedge HRESETn)
    if      (!HRESETn       ) granted_master <= 'h1;
//    else if (!slv_HSEL      ) granted_master <= pending_master;
    else if ( slv_HREADY)
      if (can_switch_master) granted_master <= pending_master;


  //store current master (for this priority level)
  always @(posedge HCLK, negedge HRESETn)
    if      (!HRESETn       ) last_granted_masters <= 'h1;
//    else if (!slv_HSEL      ) last_granted_masters[requested_priority_lvl] <= pending_master;
    else if ( slv_HREADY)
      if (can_switch_master) last_granted_masters[requested_priority_lvl] <= pending_master;


  /*
   * Get signals from current requester
   */
  always @(posedge HCLK, negedge HRESETn)
    if      (!HRESETn   ) granted_master_idx <= 'h0;
//    else if (!slv_HSEL  ) granted_master_idx <= onehot2int( pending_master );
    else if ( slv_HREADY) granted_master_idx <= onehot2int( can_switch_master ? pending_master : granted_master );

  always @(posedge HCLK)
    if (slv_HREADY) granted_master_idx_dly <= granted_master_idx;


  /*
   * If first granted access from slave-port and HTRANS = SEQ, then change to NONSEQ
   * as this is most likely a burst going over a slave boundary
   * If it's not, then this was a bad access to start with and we're in a mess anyways
   *
   * Do NOT switch when HMASTLOCK is asserted
   * It is allowed to switch in the middle of a burst ... but that will get ugly pretty quick
   */
  assign slv_HSEL      =  mstHSEL     [granted_master_idx];
  assign slv_HADDR     =  mstHADDR    [granted_master_idx];
  assign slv_HWDATA    =  mstHWDATA   [granted_master_idx_dly];
  assign slv_HWRITE    =  mstHWRITE   [granted_master_idx];
  assign slv_HSIZE     =  mstHSIZE    [granted_master_idx];
  assign slv_HBURST    =  mstHBURST   [granted_master_idx];
  assign slv_HPROT     =  mstHPROT    [granted_master_idx];
  assign slv_HTRANS    =  mstHTRANS   [granted_master_idx];
  assign slv_HREADYOUT =  mstHREADY   [granted_master_idx]; //Slave Ports HREADYOUT connects to Master Port's HREADY
  assign slv_HMASTLOCK =  mstHMASTLOCK[granted_master_idx];

  assign mstHRDATA    =  slv_HRDATA;
  assign mstHREADYOUT =  slv_HREADY; //Master Port's HREADYOUT is driven by Slave Port's (local) HREADY signal
  assign mstHRESP     =  slv_HRESP;
endmodule


