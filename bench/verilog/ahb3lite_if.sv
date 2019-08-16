////////////////////////////////////////////////////////////////////
//   ,------.                    ,--.                ,--.         //
//   |  .--. ' ,---.  ,--,--.    |  |    ,---. ,---. `--' ,---.   //
//   |  '--'.'| .-. |' ,-.  |    |  |   | .-. | .-. |,--.| .--'   //
//   |  |\  \ ' '-' '\ '-'  |    |  '--.' '-' ' '-' ||  |\ `--.   //
//   `--' '--' `---'  `--`--'    `-----' `---' `-   /`--' `---'   //
//                                             `---'              //
//                                                                //
//     AHB3-Lite Interconnect Switch Testbench                    //
//     AHB3-Lite Interface Definitions                            //
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

interface ahb3lite_if #(
    parameter HADDR_SIZE = 32,
    parameter HDATA_SIZE = 32
)
(
    input logic HCLK,HRESETn
);

    //declare interface signals
    logic                   HSEL;
    logic [HADDR_SIZE -1:0] HADDR;
    logic [HDATA_SIZE -1:0] HWDATA;
    logic [HDATA_SIZE -1:0] HRDATA;
    logic                   HWRITE;
    logic [            2:0] HSIZE;
    logic [            2:0] HBURST;
    logic [            3:0] HPROT;
    logic [            1:0] HTRANS;
    logic                   HMASTLOCK;
    logic                   HREADY;
    logic                   HREADYOUT;
    logic                   HRESP;


    // Master Interface Definitions
    clocking cb_master @(posedge HCLK);
      output HSEL;
      output HADDR;
      output HWDATA;
      input  HRDATA;
      output HWRITE;
      output HSIZE;
      output HBURST;
      output HPROT;
      output HTRANS;
      output HMASTLOCK;
      input  HREADY;
      input  HRESP;
    endclocking

    modport master (
      //synchronous signals
      clocking cb_master,

      //asynchronous reset signals
      input    HRESETn,
      output   HSEL,
      output   HTRANS
    );


    // Slave Interface Definitions
    clocking cb_slave @(posedge HCLK);
      input  HSEL;
      input  HADDR;
      input  HWDATA;
      output HRDATA;
      input  HWRITE;
      input  HSIZE;
      input  HBURST;
      input  HPROT;
      input  HTRANS;
      input  HMASTLOCK;
      input  HREADY;
      output HREADYOUT;
      output HRESP;
    endclocking

    modport slave (
      //synchronous signals
      clocking cb_slave,

      //asynchronous reset signals
      input  HRESETn,
      output HREADYOUT,
      output HRESP
    );
endinterface : ahb3lite_if


typedef virtual ahb3lite_if        v_ahb3lite;
typedef virtual ahb3lite_if.master v_ahb3lite_master;
typedef virtual ahb3lite_if.slave  v_ahb3lite_slave;



