////////////////////////////////////////////////////////////////////
//   ,------.                    ,--.                ,--.         //
//   |  .--. ' ,---.  ,--,--.    |  |    ,---. ,---. `--' ,---.   //
//   |  '--'.'| .-. |' ,-.  |    |  |   | .-. | .-. |,--.| .--'   //
//   |  |\  \ ' '-' '\ '-'  |    |  '--.' '-' ' '-' ||  |\ `--.   //
//   `--' '--' `---'  `--`--'    `-----' `---' `-   /`--' `---'   //
//                                             `---'              //
//                                                                //
//     AHB3-Lite Interconnect Switch Testbench                    //
//     Bus Transaction Class                                      //
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
// Bus Class
// Generates/Holds parameters for 1 transaction
class BusTr extends BaseTr;
  int          AddressSize,        //# of address BITS
               DataSize;           //# of data BITS
  bit          Write;              //read/write
  int          TransferSize;       //# of transfers/transfer-cycles
  int          BytesPerTransfer;   //Bytes per transfer
  byte_array_t AddressQueue[$];    //Addresses
  byte_array_t DataQueue[$];       //Data
  bit          Error;              //Error during transaction

  extern         function        new(input int unsigned AddressSize, DataSize);
  extern virtual function bit    compare  (input BaseTr to);
  extern virtual function BaseTr copy     (input BaseTr to=null);
  extern virtual function void   display  (input string prefix="");
  extern virtual function void   randomize_bus;
endclass : BusTr


/////////////////////////////////////////////////////////////////
//
// Class Methods
//

//-------------------------------------
//Constructor
function BusTr::new(input int unsigned AddressSize, DataSize);
  //call higher level
  super.new();

  //set data/addressbus sizes
  this.AddressSize = AddressSize;
  this.DataSize    = DataSize;
  this.Error       = 0;
endfunction : new


//-------------------------------------
//compare two Bus objects
function bit BusTr::compare(input BaseTr to);
  BusTr b;
  bit cmp_flags,
      cmp_address,
      cmp_data;

`ifdef DEBUG
  $display("BusTr::compare");
`endif


  $cast(b, to);

  //compare basic variables
  cmp_flags = (this.AddressSize      == b.AddressSize     ) &
              (this.DataSize         == b.DataSize        ) &
              (this.Write            == b.Write           ) &
              (this.TransferSize     == b.TransferSize    ) &
              (this.BytesPerTransfer == b.BytesPerTransfer) &
              (this.Error            == b.Error           );


   //compare addresses
   cmp_address = this.AddressQueue.size() == b.AddressQueue.size();
   if (cmp_address)
     foreach (this.AddressQueue[i])
     begin
         byte address_a[],
              address_b[];

         address_a = this.AddressQueue[i];
         address_b = b.AddressQueue[i];

         cmp_address &= ( address_a.size() == address_b.size() );

         if (cmp_address)
           foreach (address_a[j])
             cmp_address &= (address_a[j] == address_b[j]);
     end


   //compare data
   cmp_data = this.DataQueue.size() == b.DataQueue.size();
   if (cmp_data)
     foreach (this.DataQueue[i])
     begin
         byte data_a[],
              data_b[];

         data_a = this.DataQueue[i];
         data_b = b.DataQueue[i];

         cmp_data &= ( data_a.size() == data_b.size() );

         if (cmp_data)
           foreach (data_a[j])
             cmp_data &= (data_a[j] == data_b[j]);
     end


   //return result
   return cmp_flags & cmp_address & cmp_data;
endfunction : compare


//-------------------------------------
//Make a copy of this object
function BaseTr BusTr::copy (input BaseTr to=null);
  BusTr cp;
  byte address[], cp_address[],
       data[], cp_data[];
  
`ifdef DEBUG
  $display("BusTr::copy");
`endif

  if (to == null) cp = new(AddressSize,DataSize);
  else            $cast(cp, to);

  cp.AddressSize      = this.AddressSize;
  cp.DataSize         = this.DataSize;
  cp.Write            = this.Write;
  cp.TransferSize     = this.TransferSize;
  cp.BytesPerTransfer = this.BytesPerTransfer;
  cp.Error            = this.Error;

  foreach (this.AddressQueue[i])
  begin
      address = AddressQueue[i];
      cp_address = {address};                    //copy address elements
      cp.AddressQueue.push_back(cp_address);
  end

  foreach (this.DataQueue[i])
  begin
      data = DataQueue[i];
      cp_data = {data};                          //copy data elements
      cp.DataQueue.push_back(cp_data);
  end

  return cp;
endfunction : copy


//-------------------------------------
//Pretty print
function void BusTr::display (input string prefix="");
  int i;
  byte address[],
       data[];

  $display("%sTr-id:%0d, AddressSize=%0d DataSize=%0d %0s TransferSize=%0d BytesPerTransfer=%0d Error=%0d", prefix, id, AddressSize, DataSize, Write ? "Write":"Read", TransferSize, BytesPerTransfer, Error);

  $write(" Address=");
  foreach (AddressQueue[j])
  begin
      address = AddressQueue[j];
      for (i=address.size()-1; i>=0; i--)
         $write("%x", address[i]);

      $write(",");
  end
  $display();

  $write(" Data=");
  foreach (DataQueue[j])
  begin
      data = DataQueue[j];
      for (i=data.size()-1; i>=0; i--)
        $write("%x", data[i]);

      $write(",");
  end
  $display("");
endfunction : display


//Randomize class variables
function void BusTr::randomize_bus ();
  byte address[],
       data[];

  Write            = $random();
  TransferSize     = $urandom(8); //some sane number. Keep Data array in bounds
  BytesPerTransfer = $urandom( (DataSize+7)/8 );

  AddressQueue.delete(); //address object should be deleted by SV automatically
  DataQueue.delete();    //data objects should be deleted by SV automatically
  
  for (int j=0; j<TransferSize; j++)
  begin
      address = new[ (AddressSize+7)/8 ];
      foreach (address[i]) address[i] = $random();
      AddressQueue.push_back(address);
      
      if (Write)
      begin
          data = new[ BytesPerTransfer ];
          foreach (data[i]) data[i] = $random;
          DataQueue.push_back(data);
      end
  end
endfunction : randomize_bus


`ifdef DEBUG
  `undef DEBUG
`endif
