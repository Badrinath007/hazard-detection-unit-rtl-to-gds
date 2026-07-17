`timescale 1ns/1ps
// ============================================================
// tb_hazard_unit.v
// Standalone unit testbench for hazard_unit.v
// Drives all hazard/no-hazard combinations, self-checking.
// Compatible with: iverilog, QuestaSim, Vivado Simulator
// ============================================================

module tb_hazard_unit;

// ---- DUT Ports ----
reg        id_ex_mem_read;
reg  [4:0] id_ex_rd;
reg  [4:0] if_id_rs1;
reg  [4:0] if_id_rs2;
wire       stall;
wire       flush;

// ---- Instantiate DUT ----
hazard_unit dut (
    .id_ex_mem_read (id_ex_mem_read),
    .id_ex_rd       (id_ex_rd),
    .if_id_rs1      (if_id_rs1),
    .if_id_rs2      (if_id_rs2),
    .stall          (stall),
    .flush          (flush)
);

// ---- Tracking ----
integer pass_count;
integer fail_count;

task check;
    input [63:0] test_num;
    input        exp_stall;
    input        exp_flush;
    input [127:0] name;
    begin
        #1; // let combinational settle
        if (stall === exp_stall && flush === exp_flush) begin
            $display("[PASS] Test %0d: %s | stall=%b flush=%b",
                     test_num, name, stall, flush);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Test %0d: %s | got stall=%b flush=%b | exp stall=%b flush=%b",
                     test_num, name, stall, flush, exp_stall, exp_flush);
            fail_count = fail_count + 1;
        end
    end
endtask

initial begin
    pass_count = 0;
    fail_count = 0;

    $display("============================================");
    $display(" hazard_unit — Unit Verification");
    $display("============================================");

    // --------------------------------------------------
    // TEST 1: No hazard — mem_read=0
    // --------------------------------------------------
    id_ex_mem_read = 0; id_ex_rd = 5'd1;
    if_id_rs1 = 5'd1;  if_id_rs2 = 5'd2;
    check(1, 0, 0, "No hazard: mem_read=0, rd matches rs1");

    // --------------------------------------------------
    // TEST 2: No hazard — mem_read=1 but rd=x0
    // --------------------------------------------------
    id_ex_mem_read = 1; id_ex_rd = 5'd0;
    if_id_rs1 = 5'd0;  if_id_rs2 = 5'd0;
    check(2, 0, 0, "No hazard: mem_read=1 but rd=x0");

    // --------------------------------------------------
    // TEST 3: Hazard — rd matches rs1
    // --------------------------------------------------
    id_ex_mem_read = 1; id_ex_rd = 5'd3;
    if_id_rs1 = 5'd3;  if_id_rs2 = 5'd7;
    check(3, 1, 1, "Hazard: mem_read=1, rd==rs1");

    // --------------------------------------------------
    // TEST 4: Hazard — rd matches rs2
    // --------------------------------------------------
    id_ex_mem_read = 1; id_ex_rd = 5'd5;
    if_id_rs1 = 5'd2;  if_id_rs2 = 5'd5;
    check(4, 1, 1, "Hazard: mem_read=1, rd==rs2");

    // --------------------------------------------------
    // TEST 5: Hazard — rd matches both rs1 and rs2
    // --------------------------------------------------
    id_ex_mem_read = 1; id_ex_rd = 5'd4;
    if_id_rs1 = 5'd4;  if_id_rs2 = 5'd4;
    check(5, 1, 1, "Hazard: mem_read=1, rd==rs1==rs2");

    // --------------------------------------------------
    // TEST 6: No hazard — mem_read=1, rd!=rs1, rd!=rs2
    // --------------------------------------------------
    id_ex_mem_read = 1; id_ex_rd = 5'd10;
    if_id_rs1 = 5'd1;  if_id_rs2 = 5'd2;
    check(6, 0, 0, "No hazard: mem_read=1 but rd!=rs1,rs2");

    // --------------------------------------------------
    // TEST 7: No hazard — mem_read=1, rd=x0, rs match x0
    // --------------------------------------------------
    id_ex_mem_read = 1; id_ex_rd = 5'd0;
    if_id_rs1 = 5'd0;  if_id_rs2 = 5'd1;
    check(7, 0, 0, "No hazard: rd=x0 guard holds even if rs1=x0");

    // --------------------------------------------------
    // TEST 8: Hazard — max register index (x31)
    // --------------------------------------------------
    id_ex_mem_read = 1; id_ex_rd = 5'd31;
    if_id_rs1 = 5'd31; if_id_rs2 = 5'd0;
    check(8, 1, 1, "Hazard: rd=x31 matches rs1=x31");

    // --------------------------------------------------
    // TEST 9: No hazard — mem_read=0 overrides everything
    // --------------------------------------------------
    id_ex_mem_read = 0; id_ex_rd = 5'd15;
    if_id_rs1 = 5'd15; if_id_rs2 = 5'd15;
    check(9, 0, 0, "No hazard: mem_read=0 suppresses stall");

    // --------------------------------------------------
    // TEST 10: Hazard clears when inputs change
    // --------------------------------------------------
    id_ex_mem_read = 1; id_ex_rd = 5'd2;
    if_id_rs1 = 5'd2;  if_id_rs2 = 5'd3;
    check(10, 1, 1, "Hazard asserts on match");
    id_ex_mem_read = 0;
    check(11, 0, 0, "Hazard clears when mem_read deasserts");

    $display("============================================");
    $display(" RESULTS: %0d PASSED  %0d FAILED", pass_count, fail_count);
    $display("============================================");
    if (fail_count == 0)
        $display(" ** ALL TESTS PASSED **");
    else
        $display(" ** %0d FAILURE(S) — SEE ABOVE **", fail_count);

    $finish;
end

endmodule
