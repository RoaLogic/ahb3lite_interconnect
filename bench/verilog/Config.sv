////////////////////////////////////////////////////////////////////
//   ,------.                    ,--.                ,--.         //
//   |  .--. ' ,---.  ,--,--.    |  |    ,---. ,---. `--' ,---.   //
//   |  '--'.'| .-. |' ,-.  |    |  |   | .-. | .-. |,--.| .--'   //
//   |  |\  \ ' '-' '\ '-'  |    |  '--.' '-' ' '-' ||  |\ `--.   //
//   `--' '--' `---'  `--`--'    `-----' `---' `-   /`--' `---'   //
//                                             `---'              //
//                                                                //
//     AHB3-Lite Interconnect Switch Testbench                    //
//     Test Configuration Class                                   //
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

import testbench_pkg::*;

class Config #(parameter HADDR_SIZE=32) extends BaseConfig;
  int nMasters, nSlaves;           //number of master and slave ports

  int MinTransactions = 100_000;   //Minimum number of transactions per master
  int MaxTransactions = 1000_000;  //Maximum number of transactions per master
  int nTransactions[];             //Actual number of transactions per master


  logic [           2:0] mst_priority []; //TODO
  logic [HADDR_SIZE-1:0] slv_addr_base[],
                         slv_addr_mask[];

  extern function new(input int                    nmasters, nslaves,
                      input logic [           2:0] mst_priority[], //TODO
                      input logic [HADDR_SIZE-1:0] slv_addr_base[],
                                                   slv_addr_mask[]);
  extern function void random();
//  extern virtual function void wrap_up();
  extern virtual function void display(string prefix="");
endclass : Config


/////////////////////////////////////////////////////////////////
//
// Class Methods
//

//-------------------------------------
//Construct Config object
function Config::new(
  input int                    nmasters, nslaves,
  input logic [           2:0] mst_priority[],
  input logic [HADDR_SIZE-1:0] slv_addr_base[],
                               slv_addr_mask[]
);
  this.nMasters      = nmasters;
  this.nSlaves       = nslaves;
  this.mst_priority  = mst_priority;
  this.slv_addr_base = slv_addr_base;
  this.slv_addr_mask = slv_addr_mask;

  //create space for the number of transactions per master
  nTransactions = new[ nMasters ];
endfunction : new


//-------------------------------------
//Randomize configuration
function void Config::random();
  foreach (nTransactions[i]) nTransactions[i] = $urandom_range(MinTransactions,MaxTransactions);
endfunction : random


//-------------------------------------
//Pretty print
function void Config::display(string prefix="");
  $display("%sTest configuration:", prefix);

  $display("--- Transactions per master --------");
  foreach (nTransactions[i])
    $display(" Port%0d: %5d", i, nTransactions[i]);

  $display("\n\n");
endfunction : display


