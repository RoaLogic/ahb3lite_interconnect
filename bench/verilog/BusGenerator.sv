////////////////////////////////////////////////////////////////////
//   ,------.                    ,--.                ,--.         //
//   |  .--. ' ,---.  ,--,--.    |  |    ,---. ,---. `--' ,---.   //
//   |  '--'.'| .-. |' ,-.  |    |  |   | .-. | .-. |,--.| .--'   //
//   |  |\  \ ' '-' '\ '-'  |    |  '--.' '-' ' '-' ||  |\ `--.   //
//   `--' '--' `---'  `--`--'    `-----' `---' `-   /`--' `---'   //
//                                             `---'              //
//                                                                //
//     AHB3-Lite Interconnect Switch Testbench                    //
//     Bus Generator Transaction Class                            //
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

//`define DEBUG


import testbench_pkg::*;

//-------------------------------------
// BusGenerator Class
// Generates bus transactions
class BusGenerator #(type T=BaseTr);
  T       blueprint;      //BluePrint for generator
  mailbox gen2drv;        //mailbox from generator to driver
  event   drv2gen;        //trigger from driver to generator
  int     MasterId;       //Which master port are we connected to
  bit     done;           //Are we done??

  function new (
    input mailbox      gen2drv,
    input event        drv2gen,
    input int unsigned MasterId,
                       AddressSize,
                       DataSize
  );
    this.done          = 0;
    this.gen2drv       = gen2drv;
    this.drv2gen       = drv2gen;
    this.MasterId      = MasterId;
    blueprint          = new(AddressSize,DataSize);

`ifdef DEBUG
  $display("BusGenerator::new id=%0d", MasterId);
`endif
  endfunction : new


  task run(input int unsigned nTransactions);
    T tr;

    repeat (nTransactions)
    begin
        //randomize transfer
        blueprint.randomize_bus();

        //send copy of transfer to driver
        $cast(tr, blueprint.copy());
        tr.display( $sformatf("@%0t Master%0d ", $time, MasterId) );
        gen2drv.put(tr);

        //wait for driver to finish the transfer
        @drv2gen;
    end

    //idle bus
    idle();
  endtask : run


  task idle();
    $display ("@%0t: Master%0d going idle", $time, MasterId);

    //signal 'done'
    done = 1;

    //put bus in IDLE
    blueprint.idle();

    //send transaction to driver
    gen2drv.put(blueprint);

    //wait for driver to finish transfer
    @drv2gen;
  endtask : idle

endclass : BusGenerator


`ifdef DEBUG
  `undef DEBUG
`endif
