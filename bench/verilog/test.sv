/////////////////////////////////////////////////////////////////
//                                                             //
//    ██████╗  ██████╗  █████╗                                 //
//    ██╔══██╗██╔═══██╗██╔══██╗                                //
//    ██████╔╝██║   ██║███████║                                //
//    ██╔══██╗██║   ██║██╔══██║                                //
//    ██║  ██║╚██████╔╝██║  ██║                                //
//    ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝                                //
//          ██╗      ██████╗  ██████╗ ██╗ ██████╗              //
//          ██║     ██╔═══██╗██╔════╝ ██║██╔════╝              //
//          ██║     ██║   ██║██║  ███╗██║██║                   //
//          ██║     ██║   ██║██║   ██║██║██║                   //
//          ███████╗╚██████╔╝╚██████╔╝██║╚██████╗              //
//          ╚══════╝ ╚═════╝  ╚═════╝ ╚═╝ ╚═════╝              //
//                                                             //
//    AHB3-Lite Switch Testbench (Program)                     //
//                                                             //
/////////////////////////////////////////////////////////////////
//                                                             //
//     Copyright (C) 2016 ROA Logic BV                         //
//     www.roalogic.com                                        //
//                                                             //
//    This source file may be used and distributed without     //
//  restrictions, provided that this copyright statement is    //
//  not removed from the file and that any derivative work     //
//  contains the original copyright notice and the associated  //
//  disclaimer.                                                //
//                                                             //
//    This soure file is free software; you can redistribute   //
//  it and/or modify it under the terms of the GNU General     //
//  Public License as published by the Free Software           //
//  Foundation, either version 3 of the License, or (at your   //
//  option) any later versions.                                //
//  The current text of the License can be found at:           //
//  http://www.gnu.org/licenses/gpl.html                       //
//                                                             //
//    This source file is distributed in the hope that it will //
//  be useful, but WITHOUT ANY WARRANTY; without even the      //
//  implied warranty of MERCHANTABILITY or FITTNESS FOR A      //
//  PARTICULAR PURPOSE. See the GNU General Public License for //
//  more details.                                              //
//                                                             //
/////////////////////////////////////////////////////////////////

program automatic test
#(
  parameter int MASTERS    = 3,
  parameter int SLAVES     = 5,
  parameter int HADDR_SIZE = 32,
  parameter int HDATA_SIZE = 32
)
(
//  ahb3lite_if.master master[MASTERS],
//  ahb3lite_if.slave  slave [SLAVES]
);

virtual ahb3lite_if.master #(HADDR_SIZE,HDATA_SIZE) master[MASTERS];
virtual ahb3lite_if.slave  #(HADDR_SIZE,HDATA_SIZE) slave [SLAVES ];

logic [           2:0] mst_priority [MASTERS];
logic [HADDR_SIZE-1:0] addr_base[SLAVES ],
                       addr_mask[SLAVES ];

Environment env;

initial begin
  foreach (mst_priority[i]) mst_priority[i] = $urandom(7);
  $root.testbench_top.mst_priority <= mst_priority;

 /*
  >> Riviera-Pro Bug <<
 */
//  master = $root.testbench_top.ahb_master;
  master[0] = $root.testbench_top.ahb_master[0];
  master[1] = $root.testbench_top.ahb_master[1];
  master[2] = $root.testbench_top.ahb_master[2];

//  slave  = $root.testbench_top.ahb_slave;
  slave[0] = $root.testbench_top.ahb_slave[0];
  slave[1] = $root.testbench_top.ahb_slave[1];
  slave[2] = $root.testbench_top.ahb_slave[2];
  slave[3] = $root.testbench_top.ahb_slave[3];
  slave[4] = $root.testbench_top.ahb_slave[4];

  env = new(master,slave,mst_priority,addr_base,addr_mask);
  env.gen_cfg();
  env.build();
  env.run();
  env.wrap_up();
end

endprogram : test
