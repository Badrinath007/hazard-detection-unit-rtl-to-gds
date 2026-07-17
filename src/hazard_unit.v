// hazard_unit.v
// Detects load-use hazard and generates stall + flush signals.
//
// Load-use hazard: instruction in ID/EX is a LOAD (mem_read=1)
// and its destination register (id_ex_rd) matches rs1 or rs2
// of the instruction currently in IF/ID (decode stage).
//
// Response:
//   stall=1  → freeze PC and IF/ID register for one cycle
//   flush=1  → insert NOP bubble into ID/EX register

module hazard_unit (
    input        id_ex_mem_read, // 1 if instruction in EX stage is a LOAD
    input  [4:0] id_ex_rd,       // destination register of EX-stage instruction
    input  [4:0] if_id_rs1,      // source reg 1 of decode-stage instruction
    input  [4:0] if_id_rs2,      // source reg 2 of decode-stage instruction

    output reg   stall,          // freeze PC and IF/ID
    output reg   flush           // insert NOP into ID/EX
);

always @(*) begin
    stall = 1'b0;
    flush = 1'b0;

    if (id_ex_mem_read && (id_ex_rd != 5'b0)) begin
        if ((id_ex_rd == if_id_rs1) || (id_ex_rd == if_id_rs2)) begin
            stall = 1'b1;
            flush = 1'b1;
        end
    end
end

endmodule