////////////////////////////////////////////////////////////////////
//   ,------.                    ,--.                ,--.         //
//   |  .--. ' ,---.  ,--,--.    |  |    ,---. ,---. `--' ,---.   //
//   |  '--'.'| .-. |' ,-.  |    |  |   | .-. | .-. |,--.| .--'   //
//   |  |\  \ ' '-' '\ '-'  |    |  '--.' '-' ' '-' ||  |\ `--.   //
//   `--' '--' `---'  `--`--'    `-----' `---' `-   /`--' `---'   //
//                                             `---'              //
//                                                                //
//     AHB3-Lite Interconnect Switch Testbench                    //
//     Test Environment Class                                     //
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

`define DEBUG

import testbench_pkg::*;

class Environment #(parameter HADDR_SIZE=32);
  Config       #(HADDR_SIZE) cfg;         //Test configuration
  BusGenerator #(AHBBusTr  ) gen[];       //Transaction generator
  AHB3LiteDrv                drv[];       //Bus driver
  AHB3LiteMon                mon[];       //Bus monitor
  ScoreBoard                 scb;         //Score Board

  mailbox gen2drv[];
  event   drv2gen[];

  int nmasters,                           //number of masters
      nslaves;                            //number of slaves
  virtual ahb3lite_if.master masters[];   //master interfaces
  virtual ahb3lite_if.slave  slaves[];    //slave interfaces

  extern function new (input virtual ahb3lite_if.master masters[],
                       input virtual ahb3lite_if.slave  slaves[],
                       input logic [           2:0] mst_priority[], //TODO
                       input logic [HADDR_SIZE-1:0] slv_addr_base[],
                                                    slv_addr_mask[]);
  extern virtual function void gen_cfg();
  extern virtual function void build();
  extern task run();
  extern virtual function void wrap_up();
endclass : Environment


/////////////////////////////////////////////////////////////////
//
// Class Methods
//

//-------------------------------------
// Construct Environment object
function Environment::new (
  input virtual ahb3lite_if.master masters[],
  input virtual ahb3lite_if.slave  slaves[],
  input logic [           2:0] mst_priority[],
  input logic [HADDR_SIZE-1:0] slv_addr_base[],
                               slv_addr_mask[]
);
  //create and hookup masters
  this.nmasters = masters.size();
  this.masters = new[nmasters];
  foreach (masters[i]) this.masters[i] = masters[i];

  //create and hookup slaves
  this.nslaves = slaves.size();
  this.slaves = new[nslaves];
  foreach (slaves[i]) this.slaves[i] = slaves[i];

  //create the configuration
  this.cfg = new(this.nmasters,this.nslaves,mst_priority,slv_addr_base,slv_addr_mask);
endfunction : new


//-------------------------------------
// Build the configuration
function void Environment::gen_cfg();
  cfg.random();
  cfg.display();
endfunction : gen_cfg


//-------------------------------------
// Build the environment objects
function void Environment::build();
`ifdef DEBUG
  $display("Environment::Build #masters=%0d, #slaves=%0d", nmasters, nslaves);
`endif
  gen     = new[nmasters];
  drv     = new[nmasters];
  mon     = new[nslaves ];

  gen2drv = new[nmasters];
  drv2gen = new[nmasters];

  scb     = new(cfg);

  //Build generators
  foreach (gen[i])
  begin
      gen2drv[i] = new();
      gen[i] = new(gen2drv[i],drv2gen[i],i,masters[i].HADDR_SIZE,masters[i].HDATA_SIZE);
      drv[i] = new(gen2drv[i],drv2gen[i],i,scb,masters[i]);
  end

  //Build monitors
  foreach (mon[i])
    mon[i] = new(i,scb,slaves[i]);
endfunction : build


//-------------------------------------
// Start environment
task Environment::run();
  bit done;

`ifdef DEBUG
  $display("Environment::run");
`endif

  // For each master, start generator and driver
  foreach (gen[i])
  begin
      int j=i;
      fork
         gen[j].run( cfg.nTransactions[j] );
         drv[j].run();
      join_none
  end


  //for each slave, start monitor
  foreach (mon[i])
  begin
      int j=i;
      fork
         mon[j].run();
      join_none
  end


  //wait for drivers, monitors, and scoreboards to complete
  do
  begin
    done = 1;
    foreach (gen[i]) done &= gen[i].done;
    @(masters[0].cb_master);
  end
  while (!done);

  repeat (1000) @(masters[0].cb_master);
endtask : run


//-------------------------------------
// Wrap-up, cleanup, reporting
function void Environment::wrap_up();
  $display("\n\n---------------------------");
  $display ("------------------------------------------------------------");
  $display (" ,------.                    ,--.                ,--.       ");
  $display (" |  .--. ' ,---.  ,--,--.    |  |    ,---. ,---. `--' ,---. ");
  $display (" |  '--'.'| .-. |' ,-.  |    |  |   | .-. | .-. |,--.| .--' ");
  $display (" |  |\\  \\ ' '-' '\\ '-'  |    |  '--.' '-' ' '-' ||  |\\ `--. ");
  $display (" `--' '--' `---'  `--`--'    `-----' `---' `-   /`--' `---' ");
  $display ("- Simulation Ended ----------------------  `---'  ----------");

  //Call scoreboard wrap-up function for actual reports
  scb.wrap_up();

  $display("-------------------------------------------------------------\n\n");
endfunction : wrap_up


`ifdef DEBUG
  `undef DEBUG
`endif
