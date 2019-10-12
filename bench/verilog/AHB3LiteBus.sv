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

class BusGenerator extends BaseTr;
  bit TrWrite;      //read/write transaction
  int TrType;
  int TrSize;
  

  extern function new();
  extern virtual function bit    compare (input BaseTr to);
  extern virtual function BaseTr copy    (input BaseTr to=null);
  extern virtual function void   display (input string prefix="");
endclass : BusGenerator


/////////////////////////////////////////////////////////////////
//
// Class Methods
//
function BusGenerator::new();
  super.new();
endfunction : new


function bit BusGenerator::compare (input BaseTr to);
  BusGenerator cmp;

  if (!$cast(cmp, to))  //is 'to' the correct type?
    $finish;

  return ( (this.TrWrite == cmp.TrWrite ) &&
           (this.TrType  == cmp.TrType  ) &&
           (this.TrSize  == cmp.TrSize  ));
endfunction : compare


function BaseTr BusGenerator::copy (input BaseTr to=null);
  BusGenerator cp;

  if (to==null) cp = new();
  else          $cast(cp, to);
endfunction : copy
