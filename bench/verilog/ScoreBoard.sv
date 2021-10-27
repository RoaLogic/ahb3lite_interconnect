////////////////////////////////////////////////////////////////////
//   ,------.                    ,--.                ,--.         //
//   |  .--. ' ,---.  ,--,--.    |  |    ,---. ,---. `--' ,---.   //
//   |  '--'.'| .-. |' ,-.  |    |  |   | .-. | .-. |,--.| .--'   //
//   |  |\  \ ' '-' '\ '-'  |    |  '--.' '-' ' '-' ||  |\ `--.   //
//   `--' '--' `---'  `--`--'    `-----' `---' `-   /`--' `---'   //
//                                             `---'              //
//                                                                //
//     AHB3-Lite Interconnect Switch Testbench                    //
//     Scoreboard Class                                           //
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

class ScoreBoard #(type T=AHBBusTr) extends BaseScoreBoard;
  T TrQueue[$],
    MismatchTrQueue[$];

  int matched_tr,
      mismatched_tr,
      idle_tr,
      error_tr;

  extern function new(BaseConfig cfg);
  extern virtual function void wrap_up();
  extern function void save_expected(T tr);
  extern function void check_actual(T tr, int PortId);
  extern function void display(string prefix="");
endclass : ScoreBoard


/////////////////////////////////////////////////////////////////
//
// Class Methods
//

//-------------------------------------
//Construct ScoreBoard object
function ScoreBoard::new(BaseConfig cfg);
  super.new(cfg);

  matched_tr = 0;
  mismatched_tr = 0;
  error_tr = 0;
endfunction : new


//-------------------------------------
//Wrap up ...
//Check if any transactions are remaining
function void ScoreBoard::wrap_up();
  int total_transactions;
  Config my_cfg;

  $cast(my_cfg, cfg);

  total_transactions = 0;
  foreach (my_cfg.nTransactions[i]) total_transactions += my_cfg.nTransactions[i];

  $display("-- Scoreboard Summary -----");
  $display("  Total transactions: %0d", total_transactions);
  $display("  Matched transaction: %0d", matched_tr);
  $display("  Mis-matched transactions: %0d", mismatched_tr);
  $display("  Idle transactions: %0d", idle_tr);
  $display("  Error transactions: %0d", error_tr);
  $display("  Queue still contains %0d transactions", TrQueue.size() );

  if (TrQueue.size())
  begin
      $display("\n -- Remaining transactions -----");
      foreach (TrQueue[i]) TrQueue[i].display();
  end

  if (MismatchTrQueue.size())
  begin
      $display("\n -- Mismatched transactions -----");
      foreach (MismatchTrQueue[i]) MismatchTrQueue[i].display();
  end
endfunction : wrap_up


//-------------------------------------
//Push transaction into transaction queue
function void ScoreBoard::save_expected(T tr);
  tr.display($sformatf("@%0t Scb-save ", $time));

  if (tr.Error)
    error_tr++;
  else if (tr.TransferSize == 0)
    idle_tr++;
  else
    TrQueue.push_back(tr);       //not an Idle transfer; push into transfer-queue
endfunction : save_expected


//-------------------------------------
//Find transaction in transaction queue
//and compare/check
function void ScoreBoard::check_actual(T tr, int PortId);
  tr.display($sformatf("@%0t Scb-check ", $time));

  foreach (TrQueue[i])
    if (TrQueue[i].compare(tr))
    begin
        $display("@%0t: Match found", $time);
        matched_tr++;
        TrQueue.delete(i);
        return;
    end

  $display("@%0t: Match failed", $time);
  mismatched_tr++;
  MismatchTrQueue.push_back(tr);
endfunction : check_actual


//-------------------------------------
//Pretty print
function void ScoreBoard::display(string prefix="");
endfunction : display



