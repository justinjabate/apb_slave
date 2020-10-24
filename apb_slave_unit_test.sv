// modified from https://www.edaplayground.com/s/example/192
// with respect to https://static.docs.arm.com/ihi0024/c/IHI0024C_amba_apb_protocol_spec.pdf

`include "svunit_defines.svh"

import svunit_pkg::*;

module apb_slave_unit_test;

	string name = "apb_slave_ut";
	svunit_testcase svunit_ut;
	
	logic [7:0]  i_addr;
  logic [31:0] i_wr_data, i_wr_data2, o_rd_data;

	// UUT 
	reg         rst_n;
	reg         clk;
	reg         select;  // select
	reg         wr_ena;  // wr_ena
	reg         en_vld;  // en_vld
  	reg   [7:0] addr;    // addr
	reg  [31:0] wr_data; // wr_i_wr_data
	wire [31:0] rd_data; // rd_i_wr_data

	// clk generator
	initial begin
		clk = 0;
		forever begin
			#5 clk = ~clk;
		end
	end

	// instantiation
	apb_slave my_apb_slave(.*); 

	// Build
	function void build();
		svunit_ut = new(name);
	endfunction

	// Unit test setup
	task setup();
		svunit_ut.setup();
		idle_task(); // move bus into IDLE state before each test
		rst_n = 0; // then do a reset
		repeat (8) @(posedge clk); // hold low for 8 clocks
		rst_n = 1;
	endtask

	// deconstruct anything needed after running Unit Tests
	task teardown();
		svunit_ut.teardown();
		/* Place Teardown Code Here */
	endtask

	// All testcases defined as
	// `SVTEST(_NAME_)
	//		{insert tests}
	// `SVTEST_END
	`SVUNIT_TESTS_BEGIN

  	$display(" ");
	`SVTEST(single_write_then_read) // write then read at the same i_address
		i_addr = 'h32;
		i_wr_data = 'h61;	
		wr_task(i_addr, i_wr_data);
		rd_task(i_addr, o_rd_data);
  		$display("PRNT:  in = 0x%H, out = 0x%H", i_wr_data, o_rd_data);
		`FAIL_IF(i_wr_data !== o_rd_data);
  	`SVTEST_END

  	$display(" ");  
	`SVTEST(write_wo_en_vld) // write without en_vld asserted during setup 
		i_addr = 'h43;
  		i_wr_data = 'hff;
		wr_task(i_addr, i_wr_data, 0, 0);
		rd_task(i_addr, o_rd_data);
  		$display("PRNT:  in = 0x%H, out = 0x%H", i_wr_data, o_rd_data);
		`FAIL_IF(i_wr_data == o_rd_data);
	`SVTEST_END
  
  	$display(" ");
	`SVTEST(write_wo_write) // write without wr_ena asserted during setup 
		i_addr = 'h54;
		i_wr_data = 'hba;
		wr_task(i_addr, i_wr_data, 0, 1, 0);
		rd_task(i_addr, o_rd_data);
  		$display("PRNT:  in = 0x%H, out = 0x%H", i_wr_data, o_rd_data);
  		`FAIL_IF(i_wr_data == o_rd_data);
	`SVTEST_END

  	$display(" ");
	`SVTEST(_2_writes_then_2_reads) // back-to-back writes then back-to-back reads
		i_addr = 'hfe;
		i_wr_data = 'h31;
		i_wr_data2 = 'h89;	
		wr_task(i_addr, i_wr_data, 1);
		wr_task(i_addr+1, i_wr_data2, 1);

  		rd_task(i_addr, o_rd_data, 1);
  		$display("PRNT:  in = 0x%H, out = 0x%H", i_wr_data, o_rd_data);
		`FAIL_IF(i_wr_data !== o_rd_data);		
  		rd_task(i_addr+1, o_rd_data, 1);
  		$display("PRNT:  in = 0x%H, out = 0x%H", i_wr_data2, o_rd_data);
		`FAIL_IF(i_wr_data2 !== o_rd_data);	
	`SVTEST_END

  	$display(" ");
	`SVUNIT_TESTS_END

	task wr_task(
		logic  [7:0] i_addr, 
		logic [31:0] i_wr_data,
		logic 		 back2back = 0, 
		logic 		 setup_en_vld = 1,
		logic 		 setup_wr_ena = 1
	);
	
		if (!back2back) begin // insert an idle cycle before the write
			@(negedge clk);
			en_vld = 0;
			select = 0;
		end
		
		// this is the SETUP state where the en_vld, wr_ena, addr and pi_wr_data are set
		@(negedge clk);
		addr = i_addr;
		wr_data = i_wr_data;
		select = 1; // previously 0
		wr_ena = setup_wr_ena;
		en_vld = setup_en_vld;
		
		@(negedge clk);
		select = 1; // ENABLE state where the select is asserted
		wr_ena = setup_wr_ena;
		en_vld = setup_en_vld;
	endtask
	
	task rd_task(
		logic [7:0] i_addr, 
		output logic [31:0] i_wr_data,
		input logic back2back = 0
	);
	
		if (!back2back) begin // insert an idle cycle before the read
			@(negedge clk);
			en_vld = 0;
			select = 0;
		end
		
		@(negedge clk); // SETUP state where the en_vld, wr_ena and addr are set
		addr = i_addr;
		select = 1; // previously 0
		wr_ena = 0;
		en_vld = 1;
		
		@(negedge clk); // ENABLE state where the select is asserted
		select = 1;
		
		@(posedge clk);
		#1 i_wr_data = rd_data; // rd_data should be flopped after the subsequent posedge
	endtask
	
	task idle_task();
		@(negedge clk);
		en_vld = 0;
		select = 0;
		wr_ena = 0;
		addr = 0;
		wr_data = 0;
	endtask
  
	initial begin
		$dumpvars(0, apb_slave_unit_test); // Dump waves
	end

endmodule
