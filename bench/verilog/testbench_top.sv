////////////////////////////////////////////////////////////////////
//   ,------.                    ,--.                ,--.         //
//   |  .--. ' ,---.  ,--,--.    |  |    ,---. ,---. `--' ,---.   //
//   |  '--'.'| .-. |' ,-.  |    |  |   | .-. | .-. |,--.| .--'   //
//   |  |\  \ ' '-' '\ '-'  |    |  '--.' '-' ' '-' ||  |\ `--.   //
//   `--' '--' `---'  `--`--'    `-----' `---' `-   /`--' `---'   //
//                                             `---'              //
//                                                                //
//      AHB3-Lite Interconnect Switch Testbench (Top level)       //
//                                                                //
////////////////////////////////////////////////////////////////////
//                                                                //
//     Copyright (C) 2016-2019 ROA Logic BV                       //
//     www.roalogic.com                                           //
//                                                                //
//     This source file may be used and distributed without       //
//   restrictions, provided that this copyright statement is      //
//   not removed from the file and that any derivative work       //
//   contains the original copyright notice and the associated    //
//   disclaimer.                                                  //
//                                                                //
//     This soure file is free software; you can redistribute     //
//   it and/or modify it under the terms of the GNU General       //
//   Public License as published by the Free Software             //
//   Foundation, either version 3 of the License, or (at your     //
//   option) any later versions.                                  //
//   The current text of the License can be found at:             //
//   http://www.gnu.org/licenses/gpl.html                         //
//                                                                //
//     This source file is distributed in the hope that it will   //
//   be useful, but WITHOUT ANY WARRANTY; without even the        //
//   implied warranty of MERCHANTABILITY or FITTNESS FOR A        //
//   PARTICULAR PURPOSE. See the GNU General Public License for   //
//   more details.                                                //
//                                                                //
////////////////////////////////////////////////////////////////////

module testbench_top;
  parameter MASTERS = 3; //Number of master ports
  parameter SLAVES  = 4; //Number of slave ports

  parameter HADDR_SIZE = 16;
  parameter HDATA_SIZE = 32;


  /////////////////////////////////////////////////////////
  //
  // Variables
  //
  genvar m, s;

  logic [$clog2(MASTERS+1)-1:0] mst_priority  [MASTERS];
  logic [HADDR_SIZE       -1:0] slv_addr_mask [SLAVES ];
  logic [HADDR_SIZE       -1:0] slv_addr_base [SLAVES ];

  logic                         mst_HSEL      [MASTERS],
                                slv_HSEL      [SLAVES ];
  logic [HADDR_SIZE       -1:0] mst_HADDR     [MASTERS],
                                slv_HADDR     [SLAVES ];
  logic [HDATA_SIZE       -1:0] mst_HWDATA    [MASTERS],
                                slv_HWDATA    [SLAVES ];
  logic [HDATA_SIZE       -1:0] mst_HRDATA    [MASTERS],
                                slv_HRDATA    [SLAVES ];
  logic                         mst_HWRITE    [MASTERS],
                                slv_HWRITE    [SLAVES ];
  logic [                  2:0] mst_HSIZE     [MASTERS],
                                slv_HSIZE     [SLAVES ];
  logic [                  2:0] mst_HBURST    [MASTERS],
                                slv_HBURST    [SLAVES ];
  logic [                  3:0] mst_HPROT     [MASTERS],
                                slv_HPROT     [SLAVES ];
  logic [                  1:0] mst_HTRANS    [MASTERS],
                                slv_HTRANS    [SLAVES ];
  logic                         mst_HMASTLOCK [MASTERS],
                                slv_HMASTLOCK [SLAVES ];
  logic                         mst_HREADY    [MASTERS],
                                slv_HREADY    [SLAVES ];
  logic                         mst_HREADYOUT [MASTERS],
                                slv_HREADYOUT [SLAVES ];
  logic                         mst_HRESP     [MASTERS],
                                slv_HRESP     [SLAVES ];


  /////////////////////////////////////////////////////////
  //
  // Clock & Reset
  //
  bit HCLK, HRESETn;
  initial begin : gen_HCLK
      HCLK <= 1'b0;
      forever #10 HCLK = ~ HCLK;
  end : gen_HCLK

  initial begin : gen_HRESETn;
    HRESETn <= 1'b0;
    #32;
    HRESETn <= 1'b1;
  end : gen_HRESETn;

  /////////////////////////////////////////////////////////
  //
  // Master & Slave Model ports
  //
  ahb3lite_if #(HADDR_SIZE, HDATA_SIZE) ahb_master[MASTERS] (HCLK,HRESETn);
  ahb3lite_if #(HADDR_SIZE, HDATA_SIZE) ahb_slave [SLAVES ] (HCLK,HRESETn);


  /////////////////////////////////////////////////////////
  //
  // Master->Slave mapping
  //
  //TODO: Move into tb()
  assign slv_addr_base[0] = 'h0000;
  assign slv_addr_base[1] = 'h2000;
  assign slv_addr_base[2] = 'h3000;
  assign slv_addr_base[3] = 'h4000;
  assign slv_addr_base[4] = 'h8000;

  assign slv_addr_mask[0] = 'he000;
  assign slv_addr_mask[1] = 'hf000;
  assign slv_addr_mask[2] = 'hf000;
  assign slv_addr_mask[3] = 'hc000;
  assign slv_addr_mask[4] = 'h8000;


  /////////////////////////////////////////////////////////
  //
  // Map SystemVerilog Interface to ports
  //
generate
  for (m=0;m<MASTERS;m++)
  begin
      assign mst_HSEL     [m] = ahb_master[m].HSEL;
      assign mst_HADDR    [m] = ahb_master[m].HADDR;
      assign mst_HWDATA   [m] = ahb_master[m].HWDATA;
      assign mst_HWRITE   [m] = ahb_master[m].HWRITE;
      assign mst_HSIZE    [m] = ahb_master[m].HSIZE;
      assign mst_HBURST   [m] = ahb_master[m].HBURST;
      assign mst_HPROT    [m] = ahb_master[m].HPROT;
      assign mst_HTRANS   [m] = ahb_master[m].HTRANS;
      assign mst_HMASTLOCK[m] = ahb_master[m].HMASTLOCK;

      //HREADY-OUT -> HREADY logic (only 1 master/slave connection)
      assign mst_HREADY   [m] = mst_HREADYOUT[m];

      assign ahb_master[m].HRDATA = mst_HRDATA[m];
      assign ahb_master[m].HREADY = mst_HREADY[m];
      assign ahb_master[m].HRESP  = mst_HRESP [m];
  end

  for (s=0;s<SLAVES;s++)
  begin
      assign ahb_slave[s].HSEL      = slv_HSEL     [s];
      assign ahb_slave[s].HADDR     = slv_HADDR    [s];
      assign ahb_slave[s].HWDATA    = slv_HWDATA   [s];
      assign ahb_slave[s].HWRITE    = slv_HWRITE   [s];
      assign ahb_slave[s].HSIZE     = slv_HSIZE    [s];
      assign ahb_slave[s].HBURST    = slv_HBURST   [s];
      assign ahb_slave[s].HPROT     = slv_HPROT    [s];
      assign ahb_slave[s].HTRANS    = slv_HTRANS   [s];
      assign ahb_slave[s].HMASTLOCK = slv_HMASTLOCK[s];
      assign ahb_slave[s].HREADY    = slv_HREADYOUT[s]; //no decoder on slave bus. Interconnect's HREADYOUT drives single slave's HREADY input

      assign slv_HRDATA[s] = ahb_slave[s].HRDATA;
      assign slv_HREADY[s] = ahb_slave[s].HREADYOUT; //no decoder on slave bus. Interconnect's HREADY is driven by single slave's HREADYOUT
      assign slv_HRESP [s] = ahb_slave[s].HRESP;
  end
endgenerate


  /////////////////////////////////////////////////////////
  //
  // Instantiate the TB and DUT
  //
  test #(
    .MASTERS    ( MASTERS    ),
    .SLAVES     ( SLAVES     ),
    .HADDR_SIZE ( HADDR_SIZE ),
    .HDATA_SIZE ( HDATA_SIZE )
  )
  tb(
  );

  ahb3lite_interconnect #(
    .MASTERS           (   MASTERS           ),
    .SLAVES            (   SLAVES            ),
    .HADDR_SIZE        (   HADDR_SIZE        ),
    .HDATA_SIZE        (   HDATA_SIZE        ),
    .SLAVE_MASK        ( '{MASTERS{4'b1011}} ),
    .ERROR_ON_NO_SLAVE ( '{MASTERS{1'b1   }} )
  )
  dut (
    .*
  );
 
endmodule : testbench_top
