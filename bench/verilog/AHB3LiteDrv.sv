////////////////////////////////////////////////////////////////////
//   ,------.                    ,--.                ,--.         //
//   |  .--. ' ,---.  ,--,--.    |  |    ,---. ,---. `--' ,---.   //
//   |  '--'.'| .-. |' ,-.  |    |  |   | .-. | .-. |,--.| .--'   //
//   |  |\  \ ' '-' '\ '-'  |    |  '--.' '-' ' '-' ||  |\ `--.   //
//   `--' '--' `---'  `--`--'    `-----' `---' `-   /`--' `---'   //
//                                             `---'              //
//                                                                //
//     AHB3-Lite Interconnect Switch Testbench                    //
//     AHB3-Lite Driver Class                                     //
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
import ahb3lite_pkg::*;

class AHB3LiteDrv extends BaseDrv;
  virtual ahb3lite_if.master master;     //Virtual interface; master
  ScoreBoard scb;                        //ScoreBoard

  function new(input mailbox                    gen2drv,
               input event                      drv2gen,
               input int                        PortId,
               input ScoreBoard                 scb,
               input virtual ahb3lite_if.master master);

    super.new(gen2drv,drv2gen,PortId);
    this.scb    = scb;
    this.master = master;
  endfunction : new

  extern virtual task run();
  extern         task initialize();
  extern         task wait4hready(input exit_on_hresp_error);
  extern         task ahb_cmd(input AHBBusTr tr);
  extern         task ahb_data(input AHBBusTr tr);

  extern function bit[2:0] BytesPerTransfer2HSIZE(input int unsigned BytesPerTransfer);
  extern function bit[2:0] TransferSize2HBURST(input int unsigned TransferSize);
endclass : AHB3LiteDrv


/////////////////////////////////////////////////////////////////
//
// Class Methods
//

//-------------------------------------
//Put AHB3-Lite bus in initial state
task AHB3LiteDrv::initialize();
  master.HTRANS <= HTRANS_IDLE;

  //wait for reset to negate
  @(posedge master.HRESETn);
endtask : initialize


//-------------------------------------
//Wait for HREADY to assert
task AHB3LiteDrv::wait4hready(input exit_on_hresp_error);
  if (exit_on_hresp_error)
    do
      @(master.cb_master);
    while (master.cb_master.HREADY !== 1'b1 && master.cb_master.HRESP !== HRESP_ERROR);
  else
    do
      @(master.cb_master);
    while (master.cb_master.HREADY !== 1'b1);
endtask : wait4hready


//-------------------------------------
//Drive AHB3-Lite bus
//Get transactions from mailbox and translate them into AHB3Lite signals
task AHB3LiteDrv::run();
  AHBBusTr tr;

  forever
  begin
      if (!master.HRESETn) initialize();

      //read new transaction
      gen2drv.get(tr);

      //generate transfers
      /*!! tr.TransferSize==0 means an IDLE transfer; no data !!*/
      fork
        ahb_cmd(tr);
        ahb_data(tr);
      join_any

      //signal transfer-complete to driver
      ->drv2gen;
  end
endtask : run


//-------------------------------------
//AHB command signals
task AHB3LiteDrv::ahb_cmd(input AHBBusTr tr);
  byte address[];
  int  cnt;

  wait4hready(1);
  //Check HRESP
  if (master.cb_master.HRESP == HRESP_ERROR && master.cb_master.HREADY != 1'b1)
  begin
      //We are in the 1st error cycle. Next cycle must be IDLE
      master.cb_master.HTRANS <= HTRANS_IDLE;
      //wait for HREADY
      wait4hready(0);
  end


  //first cycle of a (potential) burst
  master.cb_master.HSEL      <= 1'b1;
  master.cb_master.HTRANS    <= tr.TransferSize > 0 ? HTRANS_NONSEQ : HTRANS_IDLE;
  master.cb_master.HWRITE    <= tr.Write;
  master.cb_master.HBURST    <= TransferSize2HBURST(tr.TransferSize);
  master.cb_master.HSIZE     <= BytesPerTransfer2HSIZE(tr.BytesPerTransfer);
  master.cb_master.HMASTLOCK <= 1'b0; //TODO: test

  if (tr.TransferSize > 0)
  begin
      address = tr.AddressQueue[0];
      foreach (address[i]) master.cb_master.HADDR[i*8 +: 8] <= address[i];

      //Next cycles (optional)
      cnt = 1;
      repeat (tr.TransferSize -1)
      begin
          //wait for HREADY
          wait4hready(1);

          //Check HRESP
          if (master.cb_master.HRESP == HRESP_ERROR)
          begin
              //error response. Next cycle must be IDLE. Exit current transaction
              master.cb_master.HTRANS <= HTRANS_IDLE;
              return;
          end

          master.cb_master.HTRANS <= HTRANS_SEQ;

          address = tr.AddressQueue[cnt++];
          foreach (address[i]) master.cb_master.HADDR[i*8 +: 8] <= address[i];     
      end
  end
  else
    master.cb_master.HADDR <= 'hx;

endtask : ahb_cmd


//-------------------------------------
//Transfer AHB data
task AHB3LiteDrv::ahb_data(input AHBBusTr tr);
  byte address[],
       data[];
  int unsigned data_offset, cnt;

  
  wait4hready(1);
  if (master.cb_master.HRESP == HRESP_ERROR && master.cb_master.HREADY != 1'b1)
  begin
      //We are in the 1st error cycle. Wait for error transaction to complete
      wait4hready(0);
  end


  if (tr.TransferSize > 0)
  begin
      //First data from queue (for write cycle)
      cnt = 0;

      //where to start?
      address     = tr.AddressQueue[0];       //Get first address of burst
      data_offset = address[0] & 'hff;        //Get start address's LSB in UNSIGNED format
      data_offset %= ((tr.DataSize+7)/8);

      if (!tr.Write)
      begin
          //Extra cycle for reading (read at the end of the cycle)
          wait4hready(0);

          //Check HRESP
          if (master.cb_master.HRESP == HRESP_ERROR)
            tr.Error = 1;

          //set HWDATA='xxxx'
          master.cb_master.HWDATA <= 'hx;
      end

      //transfer bytes
      repeat (tr.TransferSize)
      begin
          //wait for HREADY
          wait4hready(0);

          //Check HRESP
          if (master.cb_master.HRESP == HRESP_ERROR)
          begin
              tr.Error = 1;
              break;
          end

          if (tr.Write)
          begin
              //write data
              data = tr.DataQueue[cnt++];

              foreach (data[i])
                master.cb_master.HWDATA[(i + data_offset)*8 +: 8] <= data[i];

              //check error response of last transfer
              if (cnt == tr.TransferSize)
              begin
                  @(master.cb_master);

                 if (master.cb_master.HRESP == HRESP_ERROR)
                 begin
                     tr.Error = 1;
                     break;
                 end
              end
          end
          else
          begin
              //This is a read cycle. Read data from HRDATA
              data = new[ tr.BytesPerTransfer ];

              foreach (data[i])
                data[i] = master.cb_master.HRDATA[(i + data_offset)*8 +: 8];

              tr.DataQueue.push_back(data);
          end

          data_offset = (data_offset + tr.BytesPerTransfer) % ((tr.DataSize+7)/8);
      end
  end

  //Done transmit; send transaction to scoreboard
  scb.save_expected(tr);

//  tr.display($sformatf("@%0t: Drv%0d: ", $time, PortId));
endtask : ahb_data


//-------------------------------------
//calculate HSIZE
function bit[2:0] AHB3LiteDrv::BytesPerTransfer2HSIZE(input int unsigned BytesPerTransfer);
  case (BytesPerTransfer)
    0: return 0;
    1: return HSIZE_BYTE;
    2: return HSIZE_HWORD;
    4: return HSIZE_WORD;
    8: return HSIZE_DWORD;
    default: $error("Unsupported number of bytes per transfer %0d", BytesPerTransfer);
  endcase
endfunction : BytesPerTransfer2HSIZE


//-------------------------------------
//Generate HBURST
function bit[2:0] AHB3LiteDrv::TransferSize2HBURST(input int unsigned TransferSize);
  case (TransferSize)
    1      : return HBURST_SINGLE;
    4      : return HBURST_INCR4;
    8      : return HBURST_INCR8;
    16     : return HBURST_INCR16;
    default: return HBURST_INCR;
  endcase
endfunction : TransferSize2HBURST
