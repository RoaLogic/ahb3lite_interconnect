/////////////////////////////////////////////////////////////////////
//   ,------.                    ,--.                ,--.          //
//   |  .--. ' ,---.  ,--,--.    |  |    ,---. ,---. `--' ,---.    //
//   |  '--'.'| .-. |' ,-.  |    |  |   | .-. | .-. |,--.| .--'    //
//   |  |\  \ ' '-' '\ '-'  |    |  '--.' '-' ' '-' ||  |\ `--.    //
//   `--' '--' `---'  `--`--'    `-----' `---' `-   /`--' `---'    //
//                                             `---'               //
//    AHB3-Lite Interconnect Switch (Multi-Layer Switch)           //
//    Slave Priority decoder                                       //
//                                                                 //
/////////////////////////////////////////////////////////////////////
//                                                                 //
//             Copyright (C) 2016-2023 ROA Logic BV                //
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
// FILE NAME      : ahb3lite_interconnect_slave_priority.sv
// DEPARTMENT     :
// AUTHOR         : rherveille
// AUTHOR'S EMAIL :
// ------------------------------------------------------------------
// RELEASE HISTORY
// VERSION DATE        AUTHOR      DESCRIPTION
// 1.0     2019-09-01  rherveille  initial release
// ------------------------------------------------------------------
// KEYWORDS : AMBA AHB AHB3-Lite Interconnect Matrix
// ------------------------------------------------------------------
// PURPOSE  : Builds a binary tree to search for the highest priority
// ------------------------------------------------------------------
// PARAMETERS
//  PARAM NAME        RANGE  DESCRIPTION              DEFAULT UNITS
//  SOURCES           1+     No. of interupt sources  8
//  PRIORITIES        1+     No. of priority levels   8
//  HI
//  LO
// ------------------------------------------------------------------
// REUSE ISSUES 
//   Reset Strategy      : none
//   Clock Domains       : none
//   Critical Timing     :
//   Test Features       : na
//   Asynchronous I/F    : yes
//   Scan Methodology    : na
//   Instantiations      : Itself (recursive)
//   Synthesizable (y/n) : Yes
//   Other               :                                         
// -FHDR-------------------------------------------------------------

module ahb3lite_interconnect_slave_priority #(
  parameter MASTERS    = 3,
  parameter HI         = MASTERS-1,
  parameter LO         = 0,

  //really a localparam
  parameter PRIORITY_BITS = MASTERS==1 ? 1 : $clog2(MASTERS)
)
(
  input  [MASTERS      -1:0]                    HSEL,
  input  [MASTERS      -1:0][PRIORITY_BITS-1:0] priority_i,
  output [PRIORITY_BITS-1:0]                    priority_o
);

  //////////////////////////////////////////////////////////////////
  //
  // Variables
  //

  logic [PRIORITY_BITS-1:0] priority_hi, priority_lo;

  //initial if (HI-LO>1) $display ("HI=%0d, LO=%0d -> hi(%0d,%0d) lo(%0d,%0d)", HI, LO, HI, HI-(HI-LO)/2, LO+(HI-LO)/2, LO);

  //////////////////////////////////////////////////////////////////
  //
  // Module Body
  //

  generate
    if (HI - LO > 1)
    begin
        //built tree ...
        ahb3lite_interconnect_slave_priority #(
          .MASTERS ( MASTERS        ),
          .HI      ( LO + (HI-LO)/2 ),
          .LO      ( LO             )
        )
        lo (
          .HSEL       ( HSEL        ),
          .priority_i ( priority_i  ),
          .priority_o ( priority_lo )
        );

        ahb3lite_interconnect_slave_priority #(
          .MASTERS ( MASTERS        ),
          .HI      ( HI             ),
          .LO      ( HI - (HI-LO)/2 )
        ) hi
        (
          .HSEL       ( HSEL        ),
          .priority_i ( priority_i  ),
          .priority_o ( priority_hi )
        );
    end
    else
    begin
        //get priority for master[LO] and master[HI]
        //set priority to 0 when HSEL negated
        assign priority_lo = HSEL[LO] ? priority_i[LO] : {PRIORITY_BITS{1'b0}};
        assign priority_hi = HSEL[HI] ? priority_i[HI] : {PRIORITY_BITS{1'b0}};
    end
  endgenerate


  //finally do comparison
  assign priority_o = priority_hi > priority_lo ? priority_hi : priority_lo;

endmodule : ahb3lite_interconnect_slave_priority

