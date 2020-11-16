/////////////////////////////////////////////////////////////////////
//   ,------.                    ,--.                ,--.          //
//   |  .--. ' ,---.  ,--,--.    |  |    ,---. ,---. `--' ,---.    //
//   |  '--'.'| .-. |' ,-.  |    |  |   | .-. | .-. |,--.| .--'    //
//   |  |\  \ ' '-' '\ '-'  |    |  '--.' '-' ' '-' ||  |\ `--.    //
//   `--' '--' `---'  `--`--'    `-----' `---' `-   /`--' `---'    //
//                                             `---'               //
//    AHB3-Lite Interconnect Switch (Multi-Layer Switch)           //
//    Master Port (AHB Slave)                                      //
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
// FILE NAME      : ahb3lite_interconnect_master_port.sv
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
//  PARAM NAME          RANGE    DESCRIPTION              DEFAULT UNITS
//  HADDR_SIZE          1+       Address bus size         8       bits
//  HDATA_SIZE          1+       Data bus size            32      bits
//  SLAVES              1+       Number of Slave ports    8       ports
//  SLAVE_MASK                   Slave mask 0:slave is never addressed
//                                          1:slave can be addressed
//  ERROR_ON_SLAVE_MASK 1+       ERROR when addressing masked slave
//  ERROR_ON_NO_SLAVE   1+       ERROR when addressing unmapped address
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
 
module ahb3lite_interconnect_master_port #(
  parameter              HADDR_SIZE                  = 32,
  parameter              HDATA_SIZE                  = 32,
  parameter              MASTERS                     = 3, //number of AHB Masters
  parameter              SLAVES                      = 8, //number of AHB Slaves
  parameter [SLAVES-1:0] SLAVE_MASK                  = {SLAVES{1'b1}},
  parameter [SLAVES-1:0] ERROR_ON_SLAVE_MASK         = ~SLAVE_MASK,
  parameter              ERROR_ON_NO_SLAVE           = 1,

  //actually localparam
  parameter MASTER_BITS = MASTERS==1 ? 1 : $clog2(MASTERS)
)
(
  //Common signals
  input                                HRESETn,
                                       HCLK,

  //AHB Slave Interfaces (receive data from AHB Masters)
  //AHB Masters connect to these ports
  input  [MASTER_BITS-1:0]              mst_priority,
 
  input                                 mst_HSEL,
  input  [HADDR_SIZE -1:0]              mst_HADDR,
  input  [HDATA_SIZE -1:0]              mst_HWDATA,
  output [HDATA_SIZE -1:0]              mst_HRDATA,
  input                                 mst_HWRITE,
  input  [            2:0]              mst_HSIZE,
  input  [            2:0]              mst_HBURST,
  input  [            3:0]              mst_HPROT,
  input  [            1:0]              mst_HTRANS,
  input                                 mst_HMASTLOCK,
  output                                mst_HREADYOUT,
  input                                 mst_HREADY,
  output                                mst_HRESP,

  //AHB Master Interfaces; send data to AHB slaves
  input              [HADDR_SIZE -1:0] slvHADDRmask [SLAVES],
  input              [HADDR_SIZE -1:0] slvHADDRbase [SLAVES],
  output [SLAVES-1:0]                  slvHSEL,
  output             [HADDR_SIZE -1:0] slvHADDR,
  output             [HDATA_SIZE -1:0] slvHWDATA,
  input  [SLAVES-1:0][HDATA_SIZE -1:0] slvHRDATA,
  output                               slvHWRITE,
  output             [            2:0] slvHSIZE,
  output             [            2:0] slvHBURST,
  output             [            3:0] slvHPROT,
  output             [            1:0] slvHTRANS,
  output                               slvHMASTLOCK,
  input  [SLAVES-1:0]                  slvHREADY,
  output                               slvHREADYOUT,
  input  [SLAVES-1:0]                  slvHRESP,

  //Internal signals
  output reg                           can_switch,
  output             [MASTER_BITS-1:0] slvpriority,
  input  [SLAVES-1:0]                  master_granted
);

  //////////////////////////////////////////////////////////////////
  //
  // Constants
  //
  import ahb3lite_pkg::*;

  localparam SLAVES_BITS = $clog2(SLAVES);


  //////////////////////////////////////////////////////////////////
  //
  // Variables
  //
  enum logic [2:0] {NO_ACCESS=3'b001,ACCESS_PENDING=3'b010,ACCESS_GRANTED=3'b100} access_state;
  enum logic       {RESP_OKAY=1'b0, RESP_ERROR=1'b1} resp_state;

  logic                   no_access,
                          access_pending,
                          access_granted;


  logic [SLAVES     -1:0] current_HSEL,      //current-cycle addressed slave
                          pending_HSEL,      //pending-cycle addressed slave
                          error_masked_HSEL, //generate error when accessing masked slave
                          error_no_slave;    //generate error when accessing non-mapped memory region
  logic                   error_response;    //generate error response

  logic                   local_HREADYOUT,
                          local_HRESP;

  logic                   mux_sel;
  logic [SLAVES_BITS-1:0] slave_sel, slaves2int;

  logic [            3:0] burst_cnt;

  logic [MASTER_BITS-1:0] regpriority;
  logic [HADDR_SIZE -1:0] regHADDR;
  logic [HDATA_SIZE -1:0] regHWDATA;
  logic [            1:0] regHTRANS;
  logic                   regHWRITE;
  logic [            2:0] regHSIZE;
  logic [            2:0] regHBURST;
  logic [            3:0] regHPROT;
  logic                   regHMASTLOCK;

  genvar s;

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

    integer i;

    onehot2int = 0; //prevent latch behaviour
    for (i=1; i < SLAVES; i++) if (onehot[i]) onehot2int = i;
  endfunction //onehot2int


  //////////////////////////////////////////////////////////////////
  //
  // Module Body
  //

  /*
   * Register Address Phase Signals
   */
  always @(posedge HCLK,negedge HRESETn)
    if      (!HRESETn    ) regHTRANS <= HTRANS_IDLE;
    else if ( mst_HREADY ) regHTRANS <= mst_HSEL ? mst_HTRANS : HTRANS_IDLE;

  always @(posedge HCLK)
    if (mst_HREADY)
    begin
        regpriority  <= mst_priority;
        regHADDR     <= mst_HADDR;
        regHWDATA    <= mst_HWDATA;
        regHWRITE    <= mst_HWRITE;
        regHSIZE     <= mst_HSIZE;
        regHBURST    <= mst_HBURST;
        regHPROT     <= mst_HPROT;
        regHMASTLOCK <= mst_HMASTLOCK;
    end 

  /*
   * Generate local HREADY and HRESP
   * Local means the master port replies to the connected master
   *
   * Always generate HREADY when IDLE, otherwise insert wait state
   * HRESP is always OKAY, except when addressing masked or non-mapped address
   */

  always @(posedge HCLK,negedge HRESETn)
    if (!HRESETn)
    begin
        resp_state      <= RESP_OKAY;
        local_HREADYOUT <= 1'b1;
        local_HRESP     <= HRESP_OKAY;
    end
    else
      case (resp_state)
          RESP_OKAY: if (mst_HREADY)
                     begin
                         if (mst_HTRANS == HTRANS_IDLE || ~mst_HSEL)
                         begin
                             //idle response
                             local_HREADYOUT <= 1'b1;
                             local_HRESP     <= HRESP_OKAY;
                         end
                         else if (|error_masked_HSEL || &error_no_slave)
                         begin
                             //1st error response cycle
                             resp_state      <= RESP_ERROR;
                             local_HREADYOUT <= 1'b0;
                             local_HRESP     <= HRESP_ERROR;
                         end
                         else
                         begin
                             //wait state response
                             local_HREADYOUT <= 1'b0;
                             local_HRESP     <= HRESP_OKAY;
                         end
                     end

        RESP_ERROR: begin
                        //2nd error response cycle
                        resp_state      <= RESP_OKAY;
                        local_HREADYOUT <= 1'b1;
                        local_HRESP     <= HRESP_ERROR;
                    end
      endcase


  assign error_response = resp_state[0];


  /*
   * Access granted state machine
   *
   * NO_ACCESS     : reset state
   *                 If there's no access requested, stay in this state
   *                 If there's an access requested and we get an access-grant, go to ACCESS state
   *                 else the access is pending
   *
   * ACCESS_PENDING: Intermediate state to hold bus-command (HTRANS, ...)
   *
   * ACCESS_GRANTED: while access requested and granted stay in this state
   *                 else if access requested but not granted go to ACCESS_PENDING
   *                 else go to NO_ACCESS
   */

  always @(posedge HCLK,negedge HRESETn)
    if (!HRESETn) access_state <= NO_ACCESS;
    else 
      case (access_state)
        NO_ACCESS     : if      (~|current_HSEL && ~|pending_HSEL  ) access_state <= NO_ACCESS;
                        else if ( |(current_HSEL & master_granted) ) access_state <= ACCESS_GRANTED;
                        else                                         access_state <= ACCESS_PENDING;

        ACCESS_PENDING: if ( |(pending_HSEL & master_granted)  &&
                             slvHREADY[slave_sel]                  ) access_state <= ACCESS_GRANTED;

        ACCESS_GRANTED: if      (mst_HREADY && ~|current_HSEL                                ) access_state <= NO_ACCESS;
                        else if (mst_HREADY && ~|(current_HSEL & master_granted & slvHREADY) ) access_state <= ACCESS_PENDING;

        default       : access_state <= NO_ACCESS; //something went wrong, should never end up here
      endcase


  assign no_access      = access_state[0];
  assign access_pending = access_state[1];
  assign access_granted = access_state[2];

  /*
   * Generate burst counter
   */
  always @(posedge HCLK)
    if (mst_HREADY)
      if (mst_HTRANS == HTRANS_NONSEQ)
      begin
          case (mst_HBURST)
             HBURST_WRAP4 : burst_cnt <= 'd2;
             HBURST_INCR4 : burst_cnt <= 'd2;
             HBURST_WRAP8 : burst_cnt <= 'd6;
             HBURST_INCR8 : burst_cnt <= 'd6;
             HBURST_WRAP16: burst_cnt <= 'd14;
             HBURST_INCR16: burst_cnt <= 'd14;
             default      : burst_cnt <= 'd0;
          endcase
      end
      else
      begin
          burst_cnt <= burst_cnt - 'h1;
      end

  /*
   * Indicate that the slave may switch masters on the NEXT cycle
   */
  assign can_switch = ( no_access      & ~|(current_HSEL & master_granted) ) |
                      ( access_pending & ~|(pending_HSEL & master_granted) ) |
                      ( access_granted & ( ~mst_HSEL |
                                           (mst_HSEL & ~mst_HMASTLOCK & mst_HREADY & 
                                             ( (mst_HTRANS == HTRANS_IDLE                                              ) |
                                               (mst_HTRANS == HTRANS_NONSEQ & mst_HBURST == HBURST_SINGLE              ) |
                                               (mst_HTRANS == HTRANS_SEQ    & mst_HBURST != HBURST_INCR   & ~|burst_cnt) )
                                            )
                                         )
                      );

  /*
   * Decode slave-request; which AHB slave (slave-port) to address?
   *
   * Send out connection request to slave-port
   * Slave-port replies by asserting master_gnt
   * TODO: check for illegal combinations (more than 1 slvHSEL asserted)
   */
generate
  for (s=0; s<SLAVES; s++)
  begin: gen_HSEL
      assign current_HSEL     [s] = SLAVE_MASK[s] & (mst_HTRANS != HTRANS_IDLE) &
                                      ( (mst_HADDR & slvHADDRmask[s]) == (slvHADDRbase[s] & slvHADDRmask[s]) ) &
                                      ~error_response; //previous transaction generated an error, can not allow current transaction
      assign pending_HSEL     [s] = SLAVE_MASK[s] & (regHTRANS  != HTRANS_IDLE) &
                                      ( (regHADDR  & slvHADDRmask[s]) == (slvHADDRbase[s] & slvHADDRmask[s]) );
      assign slvHSEL          [s] = access_pending ? (pending_HSEL[s]) : (mst_HSEL & current_HSEL[s]);

      //generate an error while addressing a masked slave
      assign error_masked_HSEL[s] = ~SLAVE_MASK[s] & ERROR_ON_SLAVE_MASK[s] & mst_HSEL & (mst_HTRANS != HTRANS_IDLE) &
                                       ( (mst_HADDR & slvHADDRmask[s]) == (slvHADDRbase[s] & slvHADDRmask[s]) );

      //generate an error while addressing a non-mapped memory region (check if address is in any slave's memory map)
      assign error_no_slave[s] = ERROR_ON_NO_SLAVE & mst_HSEL & (mst_HTRANS != HTRANS_IDLE) &
                                   ( (mst_HADDR & slvHADDRmask[s]) != (slvHADDRbase[s] & slvHADDRmask[s]) );
  end
endgenerate

  /*
   * Check if granted access
   */
  always @(posedge HCLK,negedge HRESETn)
    if      (!HRESETn     ) slave_sel <= 'h0;
    else if ( mst_HREADY  ) slave_sel <= onehot2int( slvHSEL );

  /*
   * Outgoing data (to slaves)
   */
  assign mux_sel = ~access_pending;

  assign slvHADDR        = mux_sel ? mst_HADDR     : regHADDR;
  assign slvHWDATA       = mux_sel ? mst_HWDATA    : regHWDATA;
  assign slvHWRITE       = mux_sel ? mst_HWRITE    : regHWRITE;
  assign slvHSIZE        = mux_sel ? mst_HSIZE     : regHSIZE;
  assign slvHBURST       = mux_sel ? mst_HBURST    : regHBURST;
  assign slvHPROT        = mux_sel ? mst_HPROT     : regHPROT;
  assign slvHTRANS       = mux_sel ? mst_HTRANS    : regHTRANS == HTRANS_SEQ && regHBURST == HBURST_INCR ? HTRANS_NONSEQ : regHTRANS;
  assign slvHMASTLOCK    = mux_sel ? mst_HMASTLOCK : regHMASTLOCK;
  assign slvHREADYOUT    = mux_sel ? mst_HREADY & |(current_HSEL & slvHREADY) : slvHREADY[slave_sel]; //slave's HREADYOUT is driven by master's HREADY (mst_HREADY -> slv_HREADYOUT)
  assign slvpriority     = mux_sel ? mst_priority  : regpriority;


  /*
   * Incoming data (to masters)
   */
  assign mst_HRDATA    =                  slvHRDATA[slave_sel];
  assign mst_HREADYOUT = access_granted ? slvHREADY[slave_sel] : local_HREADYOUT; //master's HREADYOUT is driven by slave's HREADY (slv_HREADY -> mst_HREADYOUT)
  assign mst_HRESP     = access_granted ? slvHRESP [slave_sel] : local_HRESP; 
endmodule


