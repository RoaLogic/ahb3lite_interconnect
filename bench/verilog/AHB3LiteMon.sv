////////////////////////////////////////////////////////////////////
//   ,------.                    ,--.                ,--.         //
//   |  .--. ' ,---.  ,--,--.    |  |    ,---. ,---. `--' ,---.   //
//   |  '--'.'| .-. |' ,-.  |    |  |   | .-. | .-. |,--.| .--'   //
//   |  |\  \ ' '-' '\ '-'  |    |  '--.' '-' ' '-' ||  |\ `--.   //
//   `--' '--' `---'  `--`--'    `-----' `---' `-   /`--' `---'   //
//                                             `---'              //
//                                                                //
//     AHB3-Lite Interconnect Switch Testbench                    //
//     AHB3-Lite Monitor Class                                    //
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
import ahb3lite_pkg::*;

class AHB3LiteMon extends BaseMon;
  virtual ahb3lite_if.slave slave;            //Virtual IF, Slave Port
  ScoreBoard scb;                             //ScoreBoard
  AHBBusTr tr;                                //current transfer

  function new(input int                       PortId,
               input ScoreBoard                scb,
               input virtual ahb3lite_if.slave slave);

    super.new(PortId);
    this.scb   = scb;
    this.slave = slave;
  endfunction : new

  extern virtual task run();
  extern         task initialize();
  extern         task wait4transfer();
  extern         task wait4hready();
  extern         task ahb_hreadyout();
  extern         task ahb_setup(input AHBBusTr tr);
  extern         task ahb_next(input AHBBusTr tr);
  extern         task ahb_data(input AHBBusTr tr);

  extern function byte_array_t getHADDR(ref byte_array_t arg);
  extern function int unsigned HSIZE2BytesPerTransfer(input logic [2:0] HSIZE);
  extern function int unsigned HBURST2TransferSize(input logic [2:0] HBURST);
endclass : AHB3LiteMon


/////////////////////////////////////////////////////////////////
//
// Class Methods
//

//-------------------------------------
//Reset Response
task AHB3LiteMon::initialize();
  slave.HREADYOUT <= 1'b1;
  slave.HRESP     <= HRESP_OKAY;

  //wait for reset to negate
  @(posedge slave.HRESETn);
endtask : initialize


//-------------------------------------
//AHB3-Lite response
//Get transactions from AHB slave signals and respond
task AHB3LiteMon::run();

  forever
  begin
      if (!slave.HRESETn) initialize();

      //wait for a new transfer 
      wait4transfer();

      //generate new transaction (stores received signals and data)
      tr = new(slave.HADDR_SIZE, slave.HDATA_SIZE);
      ahb_setup(tr);

      fork
        ahb_next(tr);
        ahb_data(tr);
      join_any
  end
endtask : run


//-------------------------------------
//Check if slave is addressed
task AHB3LiteMon::wait4transfer();
  while (!slave.cb_slave.HREADY ||
         !slave.cb_slave.HSEL   ||
          slave.cb_slave.HTRANS == HTRANS_IDLE)
  begin
      @(slave.cb_slave);
      slave.HREADYOUT <= 1'b1;
  end
endtask : wait4transfer


//-------------------------------------
//Wait for HREADY to assert
task AHB3LiteMon::wait4hready();
  while (slave.cb_slave.HREADY !== 1'b1 || slave.cb_slave.HTRANS == HTRANS_BUSY) @(slave.cb_slave);
endtask : wait4hready


//-------------------------------------
//Create new BusTransaction (receive side)
//
//When we get here, the previous transaction completed (HREADY='1')
task AHB3LiteMon::ahb_setup(input AHBBusTr tr);
  byte address[];

  //Get AHB Setup cycle signals
  address = new[ (tr.AddressSize+7)/8 ];
  getHADDR(address);
  tr.AddressQueue.push_back( address );

  tr.BytesPerTransfer = HSIZE2BytesPerTransfer(slave.cb_slave.HSIZE);
  tr.TransferSize     = 1; //set to 1. Actually count transfers per burst
  tr.Write            = slave.cb_slave.HWRITE;
endtask : ahb_setup


//-------------------------------------
//Get next transfer
//
//When we get here, we only stored the data of the 1st cycle of the transaction
//and we're still in the 1st cycle
task AHB3LiteMon::ahb_next(input AHBBusTr tr);
  byte address[];

  //progress bus cycle (2nd cycle of burst)
  //HREADY='1' (from 'wait4transfer'), so proceed 1 cycle
  @(slave.cb_slave);

//$display ("%0t %0d %0d %0d %0d", $time, PortId, slave.cb_slave.HSEL, slave.cb_slave.HTRANS, slave.cb_slave.HREADY);

  while (slave.cb_slave.HSEL   == 1'b1 &&
         (slave.cb_slave.HTRANS == HTRANS_SEQ || slave.cb_slave.HTRANS == HTRANS_BUSY || slave.cb_slave.HREADY !== 1'b1) )
  begin
//$display ("%0t %0d %0d %0d", $time, PortId, slave.cb_slave.HREADY, slave.cb_slave.HTRANS);
      if (slave.cb_slave.HREADY && slave.cb_slave.HTRANS == HTRANS_SEQ)
      begin
          address = new[ (tr.AddressSize+7)/8 ];
          getHADDR(address);
          tr.AddressQueue.push_back( address );

          //one more cycle in this burst. Increase TransferSize, force another datacycle
          tr.TransferSize++;
      end

      @(slave.cb_slave);
  end
endtask : ahb_next


//-------------------------------------
//AHB Data task
//
//When we get here, we only stored the metadata of the 1st cycle of the transaction
//and we're still in the 1st cycle
//We're in control of HREADY (actually HREADYOUT)
task AHB3LiteMon::ahb_data(input AHBBusTr tr);
  byte data[], address[];
  byte data_queue[$];
  int unsigned data_offset,
               cnt;

  //what's the start address?
  address = tr.AddressQueue[0];

  //what's the offset in the databus?
  data_offset = address[0] & 'hff; //get address LSB in UNSIGNED format
  data_offset %= ((tr.DataSize+7)/8);

  cnt = 0;
//$display ("%0t %0d tr=%0d", $time, PortId, tr.TransferSize);
  while (cnt !== tr.TransferSize)
  begin
      //increase transfer counter
      cnt++;
//$display ("%0t %0d tr=%0d cnt=%0d", $time, PortId, tr.TransferSize, cnt);

      //generate new 'data' object
      data = new[ tr.BytesPerTransfer ];

      //send/receive actual data
      if (tr.Write)
      begin
          //This is a write cycle

          //generate HREADYOUT (delay)
          ahb_hreadyout();

          //proceed to next cycle of burst (this drives HREADYOUT high)
          @(slave.cb_slave);

          //and read data from HWDATA (while HREADYOUT is high)
          foreach (data[i])
            data[i] = slave.cb_slave.HWDATA[(i + data_offset)*8 +: 8];
      end
      else
      begin
          //This is a read cycle

          //generate HREADYOUT (delay)
          ahb_hreadyout();

          //Provide data on HRDATA
          foreach (data[i])
          begin
              data[i] = $random;
              slave.cb_slave.HRDATA[(i + data_offset)*8 +: 8] <= data[i];
          end

          //and proceed to next cycle of burst
          //This drives HREADYOUT high and drives the data
          @(slave.cb_slave);
      end

      //push handle into the queue
      tr.DataQueue.push_back(data);

      data_offset = (data_offset + tr.BytesPerTransfer) % ((tr.DataSize+7)/8);
  end


  //check transaction
  scb.check_actual(tr, PortId);

  `ifdef DEBUG
      //Execute here to ensure last data cycle completes before display
      //and 'tr' doesn't get mixed up with new transaction
      tr.display($sformatf("@%0t Mon%0d: ", $time, PortId));
  `endif
endtask : ahb_data


//-------------------------------------
//Generate HREADYOUT
//Generate useful HREADYOUT delays
task AHB3LiteMon::ahb_hreadyout();
  //useful delays;
  // no delay    : 0
  // some delay  : 1, 2, 
  // burst delay : 4, 8, 16 (check for buffer overrun)

  int delay_opt,
      delay,
      cnt;

  //generate HREADYOUT
  delay_opt = $urandom_range(0,5); //pick a number between 0 and 5

  case (delay_opt)
     0: delay = 0;
     1: delay = 1;
     2: delay = 2;
     3: delay = 4;
     4: delay = 8;
     5: delay = 16;
  endcase

  //drive HREADYOUT low for the duration of the delay
  for (int n=1; n < delay; n++)
  begin
      slave.cb_slave.HREADYOUT <= 1'b0;
      @(slave.cb_slave);
  end

  //drive HREADYOUT high
  slave.cb_slave.HREADYOUT <= 1'b1;
endtask : ahb_hreadyout


//-------------------------------------
//Gets current HADDR
function byte_array_t AHB3LiteMon::getHADDR(ref byte_array_t arg);
  foreach (arg[i]) arg[i] = slave.cb_slave.HADDR[i*8 +: 8];

  return arg;
endfunction : getHADDR


//-------------------------------------
//Convert HSIZE to Bytes-per-Transfer
function int unsigned AHB3LiteMon::HSIZE2BytesPerTransfer(input logic [2:0] HSIZE);
  case (HSIZE)
    HSIZE_BYTE : return 1;
    HSIZE_HWORD: return 2;
    HSIZE_WORD : return 4;
    HSIZE_DWORD: return 8;
    default    : $error("@%0t: Unsupported HSIZE(%3b)", $time, HSIZE);
  endcase
endfunction : HSIZE2BytesPerTransfer


//-------------------------------------
//Convert HBURST to TransferSize
function int unsigned AHB3LiteMon::HBURST2TransferSize(input logic [2:0] HBURST);
  int unsigned TransferSize;

  case (HBURST)
    HBURST_SINGLE: return 1;
    HBURST_INCR4 : return 4;
    HBURST_INCR8 : return 8;
    HBURST_INCR16: return 16;
    HBURST_INCR  : return 0;
    default      : begin
                       $error("@%0t: Unsupported HBURST(%3b)", $time, HBURST);
                       TransferSize = 0;
                   end
  endcase
endfunction : HBURST2TransferSize


`ifdef DEBUG
  `undef DEBUG
`endif
