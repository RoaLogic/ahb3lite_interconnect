////////////////////////////////////////////////////////////////////
//   ,------.                    ,--.                ,--.         //
//   |  .--. ' ,---.  ,--,--.    |  |    ,---. ,---. `--' ,---.   //
//   |  '--'.'| .-. |' ,-.  |    |  |   | .-. | .-. |,--.| .--'   //
//   |  |\  \ ' '-' '\ '-'  |    |  '--.' '-' ' '-' ||  |\ `--.   //
//   `--' '--' `---'  `--`--'    `-----' `---' `-   /`--' `---'   //
//                                             `---'              //
//                                                                //
//     AHB3-Lite Interconnect Switch Testbench                    //
//     AHB3-Lite Bus Transaction Class                            //
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

//-------------------------------------
// AHB Bus Class
// Specialisation for AHB, from Bus-class

//typedef enum {byte='b000, hword='b001, word='b010, dword='b011} tHSIZE;
//typedef enum {single='b000, incr='b001, incr4='b011, incr8='b101, incr16='b111} tHBURST;

import testbench_pkg::*;

class AHBBusTr extends BusTr;
  extern         function              new(input int unsigned AddressSize, DataSize);
  extern virtual function BaseTr       copy     (input BaseTr to=null);
  extern virtual function void         randomize_bus;
  extern         function void         idle;
  extern         function byte_array_t NextAddress(byte_array_t address);

endclass : AHBBusTr


/////////////////////////////////////////////////////////////////
//
// Class Methods
//

//-------------------------------------
//Constructor
function AHBBusTr::new(input int unsigned AddressSize, DataSize);
  super.new(AddressSize,DataSize);

`ifdef DEBUG
  $display("AHBBusTr::new");
`endif
endfunction : new


//-------------------------------------
//Make a copy of this object
//Keep $cast happy
function BaseTr AHBBusTr::copy (input BaseTr to=null);
  AHBBusTr cp;
  cp = new(AddressSize,DataSize);

  return super.copy(cp);
endfunction : copy


//-------------------------------------
//Randomize class variables
function void AHBBusTr::randomize_bus ();
  byte address[],
       data[];
  int unsigned address_check;


  //write or read?
  //Translates directly to HWRITE
  Write = $urandom_range(1);

  //Bytes-per-Transfer
  //Translates directly to HSIZE
  BytesPerTransfer = 1 << $urandom_range( $clog2( (DataSize+7)/8 ) );

  //number of bytes to transfers
  //Translates to HBURST (and HTRANS)
  TransferSize = $urandom_range(5);                   //This encodes HBURST
  case (TransferSize)
    0: TransferSize = 0;                              //IDLE
    1: TransferSize = 1;                              //Single
    2: TransferSize = $urandom_range(31);             //INCR burst
    3: TransferSize = 4;                              //INCR4
    4: TransferSize = 8;                              //INCR8
    5: TransferSize = 16;                             //INCR16
  endcase


  //Start Address
  //Translates to HADDR
  //TODO: AHB specifications say Address-burst must not cross 1KB boundary
  AddressQueue.delete();

  //chose a start address
  address = new[ (AddressSize+7)/8 ];
  foreach (address[i]) address[i] = $urandom();

  //Ensure burst doesn't cross 1K boundary (as specified by AMBA specs)
  if (AddressSize > 10)
  begin
      //get Address[9:0]
      address_check[ 7 :0] = address[0];
      address_check[15 :8] = address[1];
//$display("Check address boundary %02x%02x %4x", address[1],address[0], address_check);
//$display("%x, %0d, %0d -> %0x", address_check[9:0], TransferSize, BytesPerTransfer, address_check[9:0] + (TransferSize * BytesPerTransfer) );

      //Now check if the total address crosses the 1K boundary
      if (address_check[9:0] + (TransferSize * BytesPerTransfer) > 2**10)
      begin
//$display("Address crosses 1k boundary: %x", address);
          //start at 1K boundary
          address[0]  = 0;
          address[1] &= 'hc0;
          address[1] += 'h40;
      end
  end

  //clear LSBs based on BytesPerTransfer
  address[0] = address[0] & (8'hFF << $clog2(BytesPerTransfer));
  AddressQueue.push_back(address);
 
  for (int i=0; i<TransferSize -1; i++)
  begin
      address = NextAddress(address);
      AddressQueue.push_back(address);
  end


  //Create write-data
  //Translates to HWDATA
  DataQueue.delete();
  if (Write)
    for (int i=0; i<TransferSize; i++)
    begin
        data = new[ BytesPerTransfer ];
        foreach (data[i]) data[i] = $urandom;
        DataQueue.push_back(data);
    end
endfunction : randomize_bus


//-------------------------------------
//Calculate next AHB bus for transfer
function byte_array_t AHBBusTr::NextAddress(byte_array_t address);
  bit [15:0]   cnt;
  int unsigned incr;

  incr = BytesPerTransfer;

  //create new Address array
  NextAddress = new[ address.size() ];

  foreach (address[i])
  begin
      cnt            = address[i] + incr;
      NextAddress[i] = cnt[7:0];
      incr           = cnt[15:8];
  end
endfunction : NextAddress


//-------------------------------------
//IDLE bus
function void AHBBusTr::idle ();
  Write            = 'bx;         //don't care, but ensure no HWDATA is generated
  BytesPerTransfer = 'hx;         //don't care
  TransferSize     = 0;           //don't care, but set HTRANS=IDLE

  AddressQueue.delete();
  DataQueue.delete();
endfunction : idle


`ifdef DEBUG
  `undef DEBUG
`endif
