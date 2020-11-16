/////////////////////////////////////////////////////////////////////
//   ,------.                    ,--.                ,--.          //
//   |  .--. ' ,---.  ,--,--.    |  |    ,---. ,---. `--' ,---.    //
//   |  '--'.'| .-. |' ,-.  |    |  |   | .-. | .-. |,--.| .--'    //
//   |  |\  \ ' '-' '\ '-'  |    |  '--.' '-' ' '-' ||  |\ `--.    //
//   `--' '--' `---'  `--`--'    `-----' `---' `-   /`--' `---'    //
//                                             `---'               //
//   RISC-V Platform-Level Interrupt Controller                    //
//                                                                 //
/////////////////////////////////////////////////////////////////////
//                                                                 //
//             Copyright (C) 2017-2020 ROA Logic BV                //
//             www.roalogic.com                                    //
//                                                                 //
//   This source file may be used and distributed without          //
//   restriction provided that this copyright statement is not     //
//   removed from the file and that any derivative work contains   //
//   the original copyright notice and the associated disclaimer.  //
//                                                                 //
//      THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY        //
//   EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED     //
//   TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS     //
//   FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR OR     //
//   CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,  //
//   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT  //
//   NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;  //
//   LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)      //
//   HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN     //
//   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR  //
//   OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS          //
//   SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.  //
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

