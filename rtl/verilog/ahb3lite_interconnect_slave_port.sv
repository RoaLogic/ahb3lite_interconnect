/////////////////////////////////////////////////////////////////////
//   ,------.                    ,--.                ,--.          //
//   |  .--. ' ,---.  ,--,--.    |  |    ,---. ,---. `--' ,---.    //
//   |  '--'.'| .-. |' ,-.  |    |  |   | .-. | .-. |,--.| .--'    //
//   |  |\  \ ' '-' '\ '-'  |    |  '--.' '-' ' '-' ||  |\ `--.    //
//   `--' '--' `---'  `--`--'    `-----' `---' `-   /`--' `---'    //
//                                             `---'               //
//    AHB3-Lite Interconnect Switch (Multi-Layer Switch)           //
//    Slave Port (AHB Master)                                      //
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
// FILE NAME      : ahb3lite_interconnect_slave_port.sv
// DEPARTMENT     :
// AUTHOR         : rherveille
// AUTHOR'S EMAIL :
// ------------------------------------------------------------------
// RELEASE HISTORY
// VERSION DATE        AUTHOR      DESCRIPTION
// 1.0     2017-03-29  rherveille  initial release
// 1.1     2019-08-01  rherveille  Fixed onehot2int size
// ------------------------------------------------------------------
// KEYWORDS : AMBA AHB AHB3-Lite Interconnect Matrix
// ------------------------------------------------------------------
// PURPOSE  : AHB3Lite Interconnect Matrix, Slave Port
// ------------------------------------------------------------------
// PARAMETERS
//  PARAM NAME        RANGE    DESCRIPTION              DEFAULT UNITS
//  HADDR_SIZE        1+       Address bus size         8       bits
//  HDATA_SIZE        1+       Data bus size            32      bits
//  MASTERS           1+       Number of Master ports   3       ports
// ------------------------------------------------------------------
// REUSE ISSUES 
//   Reset Strategy      : external asynchronous active low; HRESETn
//   Clock Domains       : HCLK, rising edge
//   Critical Timing     : 
//   Test Features       : na
//   Asynchronous I/F    : no
//   Scan Methodology    : na
//   Instantiations      : none
//   Synthesizable (y/n) : Yes
//   Other               :                                         
// -FHDR-------------------------------------------------------------


module ahb3lite_interconnect_slave_port
import ahb3lite_pkg::*;
#(
  parameter HADDR_SIZE  = 32,
  parameter HDATA_SIZE  = 32,
  parameter MASTERS     = 3,  //number of slave-ports

  //actually localparam
  parameter MASTER_BITS = MASTERS==1 ? 1 : $clog2(MASTERS)
)
(
  input                                        HRESETn,
                                               HCLK,

  //AHB Slave Interfaces (receive data from AHB Masters)
  //AHB Masters conect to these ports
  input      [MASTERS-1:0][MASTER_BITS-1:0] mstpriority,
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


  //////////////////////////////////////////////////////////////////
  //
  // Variables
  //
  logic [MASTER_BITS-1:0]                  requested_priority_lvl;  //requested priority level
  logic [MASTERS    -1:0]                  priority_masters;        //all masters at this priority level

  logic [MASTER_BITS-1:0]                  pending_master_idx,      //next master waiting to be served
                                           last_granted_master_idx; //last granted master for requested priority level
  logic [MASTERS    -1:0][MASTER_BITS-1:0] last_granted_masters;    //per priority level, for round-robin

  
  logic [MASTER_BITS-1:0]                  granted_master_idx,      //granted master as index
                                           granted_master_idx_dly;  //deleayed granted master index (for HWDATA)
  
  logic                                    can_switch_master;       //Slave may switch to a new master

  
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
    input [MASTERS-1:0] onehot;

    integer i;

    onehot2int = 0; //prevent latch behaviour
    for (i=1; i < MASTERS; i++) if (onehot[i]) onehot2int = i;
  endfunction : onehot2int


`ifdef RECURSIVE_FUNCTIONS_SUPPORTED
  /*
   * Intel Quartus and Verilator do not support recursive functions.
   * Even though this one would be perfectly fine
   * Verilator doesn't even like reading recursive functions
  */
  function automatic [MASTER_BITS-1:0] highest_requested_priority (
    input [MASTERS-1:0]                  hsel,
    input [MASTERS-1:0][MASTER_BITS-1:0] priorities,
    input int                            hi,
    input int                            lo
  );

    logic [MASTER_BITS-1:0] priority_hi, priority_lo;

    //build binary decision tree
    if (hi - lo > 1)
    begin
        priority_hi = highest_requested_priority(hsel, priorities, hi            , hi - (hi-lo)/2);
        priority_lo = highest_requested_priority(hsel, priorities, lo + (hi-lo)/2, lo            );
    end
    else
    begin
        priority_hi = hsel[hi] ? priorities[hi] : {MASTER_BITS{1'b0}};
        priority_lo = hsel[lo] ? priorities[lo] : {MASTER_BITS{1'b0}};
    end

    //finally compare lo and hi priorities
    return (priority_hi > priority_lo) ? priority_hi : priority_lo;
  endfunction : highest_requested_priority
`endif

  //If every master has its own unique priority, this just becomes HSEL
  function [MASTERS-1:0] requesters;
    input [MASTERS-1:0]                  hsel;
    input [MASTERS-1:0][MASTER_BITS-1:0] priorities;
    input              [MASTER_BITS-1:0] priority_select;

    for (int n=0; n<MASTERS; n++)
      requesters[n] = (priorities[n] == priority_select) & hsel[n];
  endfunction : requesters


/*
 * too slow and too big ...
  function [MASTER_BITS-1:0] nxt_master;
    input [MASTERS    -1:0] pending_masters;  //pending masters for the requesed priority level
    input [MASTER_BITS-1:0] last_master;      //last granted master for the priority level
    input [MASTER_BITS-1:0] current_master;   //current granted master (indpendent of priority level)

    int                   offset;
    logic [MASTERS*2-1:0] sr;

    //default value, don't switch if not needed
    nxt_master = current_master;
	 
    //implement round-robin
    offset = last_master +1;
    sr = {pending_masters,pending_masters};

    for (int n = 0; n < MASTERS; n++)
      if (sr[n + offset]) return ((n + offset) % MASTERS);
  endfunction : nxt_master
*/


  function [MASTER_BITS-1:0] nxt_master;
    input [MASTERS    -1:0] pending_masters;            //pending masters for the requesed priority level
    input [MASTER_BITS-1:0] last_master;                //last granted master for the priority level
    input [MASTER_BITS-1:0] current_master;             //current granted master (indpendent of priority level)

    int                   offset;
    logic [MASTERS*2-1:0]                  mst_lst;     //list of requesting masters
    logic [MASTERS*2-1:0][MASTER_BITS-1:0] mst_idx_lst; //list of master indexes

    for (int n=0; n < MASTERS; n++)
    begin
        mst_idx_lst[n        ] = n[MASTER_BITS-1:0];
        mst_idx_lst[n+MASTERS] = n[MASTER_BITS-1:0];
    end

    //default value, don't switch if not needed
    nxt_master = current_master;
	 
    //implement round-robin
    mst_lst     = {pending_masters,pending_masters} >> last_master;
    mst_idx_lst = mst_idx_lst >> (last_master * MASTER_BITS);

    for (int n = 1; n < MASTERS+1; n++)
      if (mst_lst[n]) return mst_idx_lst[n];
  endfunction : nxt_master


  //////////////////////////////////////////////////////////////////
  //
  // Module Body
  //

  /*
   * Select which master to service
   * 1. Priority
   * 2. Round-Robin
   */

//Impossible to prevent usage of ifdef here ...
`ifdef RECURSIVE_FUNCTIONS_SUPPORTED

  //get highest priority from requesting masters
  assign requested_priority_lvl = highest_requested_priority(mstHSEL, mstpriority, MASTERS-1, 0);

`else

  //recursive functions are not supported in Intel Quartus. Use Verilog Module instead
  ahb3lite_interconnect_slave_priority #(
    .MASTERS    ( MASTERS                )
  )
  requested_priority_inst (
    .HSEL       ( mstHSEL                ),
    .priority_i ( mstpriority            ),
    .priority_o ( requested_priority_lvl ) );

`endif

  //get pending masters for the highest priority requested
  assign priority_masters = requesters(mstHSEL, mstpriority,requested_priority_lvl);

  //get last granted master for the priority requested
  assign last_granted_master_idx = last_granted_masters[requested_priority_lvl];

  //get next master to serve
  assign pending_master_idx = nxt_master(priority_masters,last_granted_master_idx, granted_master_idx);

  //Switch masters when
  // 1. Current active master port signals it can be switched
  // 2. Current active master isn't actually addressing this slave
  assign can_switch_master = can_switch[granted_master_idx] | ~mstHSEL[granted_master_idx];


  //select new master
  always @(posedge HCLK, negedge HRESETn)
    if      (!HRESETn       ) granted_master <= 'h1;
    else if ( slv_HREADY    )
      if (can_switch_master) granted_master <= (1 << pending_master_idx);


  //store current master (for this priority level)
  always @(posedge HCLK, negedge HRESETn)
    if      (!HRESETn       ) last_granted_masters <= 'h1;
    else if ( slv_HREADY)
      if (can_switch_master) last_granted_masters[requested_priority_lvl] <= pending_master_idx;


  /*
   * Get signals from current requester
   */
  always @(posedge HCLK, negedge HRESETn)
    if      (!HRESETn   ) granted_master_idx <= 'h0;
    else if ( slv_HREADY)
      if (can_switch_master) granted_master_idx <= pending_master_idx;


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


