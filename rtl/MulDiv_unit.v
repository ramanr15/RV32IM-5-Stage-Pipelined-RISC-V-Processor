module muldiv_unit (

    input wire [31:0] operand_a,
    input wire [31:0] operand_b,

    input wire [2:0] funct3,

    output reg [31:0] result

);

reg signed [63:0] signed_product;

reg [63:0] unsigned_product;

reg signed [63:0] signed_a_64;
reg signed [63:0] signed_b_64;

reg signed [63:0] signed_unsigned_product;


always @(*) begin

    signed_a_64 =
        {{32{operand_a[31]}}, operand_a};

    signed_b_64 =
        {{32{operand_b[31]}}, operand_b};

    signed_product =
        $signed(operand_a) * $signed(operand_b);

    unsigned_product =
        operand_a * operand_b;

    signed_unsigned_product =
        signed_a_64 * $signed({1'b0, operand_b});


    case (funct3)

        // MUL
        3'b000:
            result = signed_product[31:0];


        // MULH
        3'b001:
            result = signed_product[63:32];


        // MULHSU
        3'b010:
            result = signed_unsigned_product[63:32];


        // MULHU
        3'b011:
            result = unsigned_product[63:32];


        // DIV
        3'b100: begin

            if (operand_b == 32'b0)

                result = 32'hFFFFFFFF;

            else if ((operand_a == 32'h80000000) &&
                     (operand_b == 32'hFFFFFFFF))

                result = 32'h80000000;

            else

                result =
                    $signed(operand_a) /
                    $signed(operand_b);

        end


        // DIVU
        3'b101: begin

            if (operand_b == 32'b0)

                result = 32'hFFFFFFFF;

            else

                result =
                    operand_a / operand_b;

        end


        // REM
        3'b110: begin

            if (operand_b == 32'b0)

                result = operand_a;

            else if ((operand_a == 32'h80000000) &&
                     (operand_b == 32'hFFFFFFFF))

                result = 32'b0;

            else

                result =
                    $signed(operand_a) %
                    $signed(operand_b);

        end


        // REMU
        3'b111: begin

            if (operand_b == 32'b0)

                result = operand_a;

            else

                result =
                    operand_a % operand_b;

        end


        default:
            result = 32'b0;

    endcase

end

endmodule